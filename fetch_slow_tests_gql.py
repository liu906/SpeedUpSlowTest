#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fetch top N (default 500) GitHub issues matching:
  query: "slow test" is:issue is:closed comments:>3 linked:pr
Then client-side filter: repository stargazerCount > 5
Writes CSV with repo + issue fields.

Usage:
  export GITHUB_TOKEN=ghp_xxx
  python fetch_slow_tests_gql.py --out slow_test_issues.csv --max 500
"""

import os
import csv
import time
import argparse
import requests

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

def run_query(session, token, query, variables):
    headers = {"Authorization": f"Bearer {token}"}
    resp = session.post(GQL_ENDPOINT, json={"query": query, "variables": variables}, headers=headers, timeout=60)
    if resp.status_code != 200:
        raise RuntimeError(f"HTTP {resp.status_code}: {resp.text[:500]}")
    data = resp.json()
    if "errors" in data:
        raise RuntimeError(f"GraphQL errors: {data['errors']}")
    return data["data"]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="slow_test_issues.csv")
    ap.add_argument("--max", type=int, default=1000)
    # 你可以把查询词改成你想要的；GraphQL 默认就是网页的 Best match 排序
    ap.add_argument("--q", default='"slow test" is:issue is:closed linked:pr')
    ap.add_argument("--min_stars", type=int, default=5)
    args = ap.parse_args()

    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        raise SystemExit("GITHUB_TOKEN not set")

    session = requests.Session()

    fieldnames = [
        # repo
        "repo_full_name","repo_url","repo_stars","repo_forks","repo_language",
        "repo_created_at","repo_pushed_at","repo_archived",
        # issue
        "issue_number","issue_title","issue_url","issue_state",
        "issue_comments","issue_created_at","issue_closed_at",
        "issue_labels","issue_author_login"
    ]

    collected = 0
    after = None
    batch = 100  # 每页 100，取 5 页够 500
    rows = []

    while collected < args.max:
        data = run_query(session, token, GQL, {"q": args.q, "first": batch, "after": after})
        rl = data["rateLimit"]
        srch = data["search"]
        for edge in srch["edges"]:
            node = edge["node"]
            if not node:
                continue
            repo = node.get("repository") or {}
            stars = repo.get("stargazerCount") or 0
            if stars <= args.min_stars:
                continue  # 客户端执行 stars>5 过滤

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
                "issue_labels": ";".join([n["name"] for n in (node.get("labels") or {}).get("nodes", []) if n and n.get("name")]),
                "issue_author_login": (node.get("author") or {}).get("login"),
            }
            rows.append(row)
            collected += 1
            if collected >= args.max:
                break

        if not srch["pageInfo"]["hasNextPage"]:
            break
        after = srch["pageInfo"]["endCursor"]

        # 轻微节流：如果剩余额度很低，就等到 reset（通常不需要）
        if rl and rl.get("remaining", 1) < 50:
            # resetAt 是 ISO 时间；简单保险等 10 秒
            time.sleep(10)

    # 写 CSV
    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)

    print(f"Done. Wrote {len(rows)} rows to {args.out}")

if __name__ == "__main__":
    main()
