#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Shard GitHub GraphQL search by date windows to bypass the 1000-result cap per query.
Fetch issues matching a base query (e.g. `"slow test" is:issue is:closed comments:>3 linked:pr`)
and write a CSV with both repo + issue fields. Includes retries and rate-limit-aware throttling.

Usage:
  export GITHUB_TOKEN=ghp_xxx
  python fetch_slow_tests_gql_sharded.py \
      --out data/slow_test_issues_2000.csv \
      --max_total 2000 \
      --q '"slow test" is:issue is:closed comments:>3 linked:pr' \
      --time_field closed \
      --date_from 2015-01-01 \
      --date_to 2025-09-21 \
      --window_days 120 \
      --min_stars 5
Deps:
  pip install requests
"""

import os
import csv
import time
import argparse
import requests
from datetime import datetime, timedelta, timezone

GQL_ENDPOINT = "https://api.github.com/graphql"

GQL = """
query ($q: String!, $first: Int!, $after: String) {
  rateLimit { remaining cost resetAt }
  search(query: $q, type: ISSUE, first: $first, after: $after) {
    issueCount
    pageInfo { hasNextPage endCursor }
    edges {
      node {
        __typename
        ... on Issue {
          number
          title
          url
          state
          createdAt
          closedAt
          author { login }
          comments { totalCount }
          labels(first: 20) { nodes { name } }
          repository {
            nameWithOwner
            url
            stargazerCount
            forkCount
            isArchived
            primaryLanguage { name }
            createdAt
            pushedAt
          }
        }
      }
    }
  }
}
"""

FIELDNAMES = [
    # repo
    "repo_full_name","repo_url","repo_stars","repo_forks","repo_language",
    "repo_created_at","repo_pushed_at","repo_archived",
    # issue
    "issue_number","issue_title","issue_url","issue_state",
    "issue_comments","issue_created_at","issue_closed_at",
    "issue_labels","issue_author_login"
]

def run_query(session, token, query, variables, max_retries=5):
    headers = {"Authorization": f"Bearer {token}"}
    backoff = 2.0
    for attempt in range(max_retries):
        resp = session.post(GQL_ENDPOINT, json={"query": query, "variables": variables},
                            headers=headers, timeout=60)
        if resp.status_code == 200:
            data = resp.json()
            if "errors" in data:
                # GraphQL logical error—retry a couple times then raise
                if attempt < max_retries - 1:
                    time.sleep(backoff); backoff *= 1.6
                    continue
                raise RuntimeError(f"GraphQL errors: {data['errors']}")
            return data["data"]
        # For 5xx / gateway issues: retry with backoff
        if resp.status_code >= 500:
            if attempt < max_retries - 1:
                time.sleep(backoff); backoff *= 1.6
                continue
        # Other status: raise immediately (helps发现权限/语法问题)
        raise RuntimeError(f"HTTP {resp.status_code}: {resp.text[:500]}")
    raise RuntimeError("Exceeded max retries")

def iso_date(d):
    return d.strftime("%Y-%m-%d")

def daterange_windows(start: datetime, end: datetime, window_days: int):
    cur = start
    delta = timedelta(days=window_days)
    while cur <= end:
        win_end = min(cur + delta - timedelta(days=1), end)
        yield (cur, win_end)
        cur = win_end + timedelta(days=1)

def collect_rows_from_edges(edges, min_stars):
    rows = []
    for e in edges:
        node = e.get("node")
        if not node:
            continue
        repo = node.get("repository") or {}
        stars = repo.get("stargazerCount") or 0
        if stars <= min_stars:
            continue
        labels = ";".join([n["name"] for n in (node.get("labels") or {}).get("nodes", []) if n and n.get("name")])
        row = {
            "repo_full_name": repo.get("nameWithOwner"),
            "repo_url": repo.get("url"),
            "repo_stars": stars,
            "repo_forks": repo.get("forkCount"),
            "repo_language": (repo.get("primaryLanguage") or {}).get("name"),
            "repo_created_at": repo.get("createdAt"),
            "repo_pushed_at": repo.get("pushedAt"),
            "repo_archived": repo.get("isArchived"),
            "issue_number": node.get("number"),
            "issue_title": node.get("title"),
            "issue_url": node.get("url"),
            "issue_state": node.get("state"),
            "issue_comments": (node.get("comments") or {}).get("totalCount"),
            "issue_created_at": node.get("createdAt"),
            "issue_closed_at": node.get("closedAt"),
            "issue_labels": labels,
            "issue_author_login": (node.get("author") or {}).get("login"),
        }
        rows.append(row)
    return rows

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out",default="slow_test_issues_2000.csv")
    ap.add_argument("--q", default='"slow test" is:issue is:closed linked:pr')
    ap.add_argument("--max_total", type=int, default=2000)
    ap.add_argument("--min_stars", type=int, default=5, help="Keep repos with stars > this value (set 0 to disable)")
    ap.add_argument("--time_field", choices=["closed","created"], default="closed")
    ap.add_argument("--date_from", default="2015-01-01")
    ap.add_argument("--date_to", default=None, help="YYYY-MM-DD (default: today)")
    ap.add_argument("--window_days", type=int, default=120)
    ap.add_argument("--page_size", type=int, default=100)
    args = ap.parse_args()

    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if not token:
        raise SystemExit("GITHUB_TOKEN not set")

    if args.date_to:
        end = datetime.fromisoformat(args.date_to).replace(tzinfo=None)
    else:
        end = datetime.utcnow()
    start = datetime.fromisoformat(args.date_from).replace(tzinfo=None)

    session = requests.Session()
    seen = set()
    collected = 0

    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=FIELDNAMES)
        w.writeheader()

        for (ws, we) in daterange_windows(start, end, args.window_days):
            if collected >= args.max_total:
                break
            # shard the query by time window
            time_filter = f'{args.time_field}:{iso_date(ws)}..{iso_date(we)}'
            q = f"{args.q} {time_filter}"
            after = None
            while True:
                if collected >= args.max_total:
                    break
                data = run_query(session, token, GQL, {"q": q, "first": args.page_size, "after": after})
                rl = data.get("rateLimit") or {}
                search = data["search"]
                edges = search.get("edges") or []

                rows = collect_rows_from_edges(edges, args.min_stars)
                for row in rows:
                    key = row["issue_url"]
                    if key in seen:
                        continue
                    w.writerow(row)
                    seen.add(key)
                    collected += 1
                    if collected >= args.max_total:
                        break

                # pagination
                pi = search.get("pageInfo") or {}
                if not pi.get("hasNextPage"):
                    break
                after = pi.get("endCursor")

                # basic throttling: if remaining low, sleep until reset; else small pause
                remaining = rl.get("remaining", 1000)
                resetAt = rl.get("resetAt")
                if isinstance(remaining, int) and remaining < 50 and resetAt:
                    reset_ts = datetime.fromisoformat(resetAt.replace("Z","+00:00")).astimezone(timezone.utc).timestamp()
                    now_ts = datetime.now(timezone.utc).timestamp()
                    sleep_s = max(0, int(reset_ts - now_ts) + 2)
                    print(f"[rate-limit] sleeping {sleep_s}s until reset...")
                    time.sleep(sleep_s)
                else:
                    time.sleep(0.6)  # be gentle

            print(f"[window {iso_date(ws)}..{iso_date(we)}] collected={collected} (unique)")

    print(f"Done. Wrote {collected} unique rows to {args.out}")

if __name__ == "__main__":
    main()
