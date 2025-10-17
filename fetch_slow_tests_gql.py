

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fetch top issues from GitHub search but split the search into yearly slices to
work around the search API ~1000-results per-query limitation.

Modified to also fetch linked PR URLs for each issue by including timelineItems
(CROSS_REFERENCED_EVENT) in the same GraphQL query to avoid extra per-issue
requests.
"""
import os
import csv
import time
import argparse
import requests
from datetime import datetime

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
          # timeline 中的 cross-references 可能包含来自 PR 的引用

        }
      }
    }
  }
}
"""

def safe_subtract_years(dt, years):
    """从 dt 中减去若干年，尽量处理闰年 2/29 的情况（转为 2/28）。"""
    try:
        return dt.replace(year=dt.year - years)
    except ValueError:
        # 可能是 2/29 -> 转为 2/28
        return dt.replace(month=2, day=28, year=dt.year - years)

def run_query(session, token, query, variables, max_retries=5):
    headers = {"Authorization": f"Bearer {token}"}
    backoff = 1.0
    for attempt in range(1, max_retries + 1):
        try:
            resp = session.post(GQL_ENDPOINT, json={"query": query, "variables": variables}, headers=headers, timeout=60)
        except requests.RequestException as e:
            # 网络异常也重试
            if attempt == max_retries:
                raise
            time.sleep(backoff)
            backoff *= 2
            continue

        if resp.status_code == 200:
            data = resp.json()
            if "errors" in data:
                # GraphQL 层面的错误，不一定能通过重试解决，但有时是暂时性的
                if attempt == max_retries:
                    raise RuntimeError(f"GraphQL errors: {data['errors']}")
                time.sleep(backoff)
                backoff *= 2
                continue
            return data["data"]
        elif 500 <= resp.status_code < 600:
            # 5xx，重试（包含 502）
            if attempt == max_retries:
                raise RuntimeError(f"HTTP {resp.status_code}: {resp.text[:500]}")
            time.sleep(backoff)
            backoff *= 2
            continue
        else:
            # 其他（4xx 等）直接报错
            raise RuntimeError(f"HTTP {resp.status_code}: {resp.text[:500]}")

    # 如果到这里，表示重试失败
    raise RuntimeError("Failed to fetch after retries")

def make_date_str(dt):
    return dt.strftime("%Y-%m-%d")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="slow_test_issues_by_year_only_python.csv", type=str, help="Output CSV path")
    # per-year limit (软编码，默认 1000)
    ap.add_argument("--per_year_max", type=int, default=200, help="Max results per year (soft limit)")
    ap.add_argument("--years", type=int, default=5, help="Number of years to go back (starting from today)")
    ap.add_argument("--q", default='"slow test" is:issue is:closed linked:pr language:Python', help="Base query (GraphQL uses Best match)")
    ap.add_argument("--min_stars", type=int, default=5, help="Client-side repo stargazer filter (strictly greater than)")
    ap.add_argument("--page_size", type=int, default=50, help="GraphQL search page size (max 100)")
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
        "issue_labels","issue_author_login",
        # linked PRs
        "linked_pr_urls",
        # meta
        "slice_start","slice_end","slice_year_index"
    ]

    rows = []
    today = datetime.utcnow().date()

    # 每年一次，i=0 -> [today -1year, today)
    for i in range(args.years):
        # 计算当前分段的日期范围【start_date .. end_date】
        end_dt = safe_subtract_years(today, i)  # 例如 i=0 => end_dt = today
        start_dt = safe_subtract_years(today, i + 1)
        # GitHub 的范围通常写成 start..end (inclusive..inclusive)；这里用 YYYY-MM-DD..YYYY-MM-DD
        slice_q = f"{args.q} closed:{make_date_str(start_dt)}..{make_date_str(end_dt)}"
        print(f"[Year slice {i}] Querying {make_date_str(start_dt)} .. {make_date_str(end_dt)}  -> q='{slice_q[:120]}...'")

        collected = 0
        after = None
        # 重置分页
        while collected < args.per_year_max:
            to_fetch = min(args.page_size, 100)  # GraphQL search.first 上限是 100
            variables = {"q": slice_q, "first": to_fetch, "after": after}
            data = run_query(session, token, GQL, variables)
            rl = data.get("rateLimit")
            srch = data.get("search", {})
            edges = srch.get("edges", []) or []

            if not edges:
                # 没有更多结果
                break

            for edge in edges:
                node = edge.get("node")
                if not node:
                    continue
                repo = node.get("repository") or {}
                stars = repo.get("stargazerCount") or 0
                if stars <= args.min_stars:
                    continue  # 客户端执行 stars > min_stars 过滤

                # # 解析 timelineItems 中的 cross-referenced PR 来源
                # linked_prs = []
                # timeline = node.get("timelineItems") or {}
                # for tnode in timeline.get("nodes", []) or []:
                #     if not tnode:
                #         continue
                #     src = tnode.get("source") or {}
                #     if (src.get("__typename") == "PullRequest") and src.get("url"):
                #         linked_prs.append(src.get("url"))

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
                    "issue_labels": ";".join(
                        [n["name"] for n in (node.get("labels") or {}).get("nodes", []) if n and n.get("name")]
                    ),
                    "issue_author_login": (node.get("author") or {}).get("login"),
                    # "linked_pr_urls": ";".join(linked_prs),
                    "linked_pr_urls": "",
                    "slice_start": make_date_str(start_dt),
                    "slice_end": make_date_str(end_dt),
                    "slice_year_index": i
                }
                rows.append(row)
                collected += 1
                if collected >= args.per_year_max:
                    break

            page_info = srch.get("pageInfo") or {}
            if not page_info.get("hasNextPage"):
                break
            after = page_info.get("endCursor")

            # 轻微节流：如果剩余额度很低，就等一会儿（谨慎）
            if rl and rl.get("remaining", 1) < 50:
                # resetAt 是 ISO 时间；简单保险等 10 秒（可按需改）
                print("Low rate limit remaining; sleeping 10s")
                time.sleep(20)

        print(f"[Year slice {i}] Collected {collected} rows (requested per_year_max={args.per_year_max})")

    # 写 CSV
    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)

    print(f"Done. Wrote {len(rows)} rows to {args.out}")

if __name__ == "__main__":
    main()
