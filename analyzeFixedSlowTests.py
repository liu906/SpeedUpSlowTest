#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Analyze slow-test CSV (from fetch_slow_tests_gql.py) and produce:
- Summary stats (printed + markdown report)
- CSV summaries (by language, label, org, repo)
- Charts: language pie, issues closed per month, comments histogram,
          time-to-close histogram, top labels bar, top repos by stars bar

Usage:
  python analyze_slow_tests.py --input data/slow_test_issues.csv --outdir reports --top 20
Deps:
  pip install pandas matplotlib
"""

import argparse
import os
from pathlib import Path
from typing import List

import pandas as pd
import matplotlib.pyplot as plt


REQUIRED_COLS = [
    # repo
    "repo_full_name","repo_url","repo_stars","repo_forks","repo_language",
    "repo_created_at","repo_pushed_at","repo_archived",
    # issue
    "issue_number","issue_title","issue_url","issue_state",
    "issue_comments","issue_created_at","issue_closed_at",
    "issue_labels","issue_author_login"
]


def read_csv(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    missing = [c for c in REQUIRED_COLS if c not in df.columns]
    if missing:
        raise ValueError(f"CSV is missing required columns: {missing}")

    # Normalize types
    for col in ["repo_stars", "repo_forks", "issue_comments"]:
        df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0).astype(int)

    # Dates
    for col in ["repo_created_at", "repo_pushed_at", "issue_created_at", "issue_closed_at"]:
        df[col] = pd.to_datetime(df[col], errors="coerce", utc=True)

    # Language/labels cleanup
    df["repo_language"] = df["repo_language"].fillna("Unknown")
    df["issue_labels"] = df["issue_labels"].fillna("")
    # Owner/org
    df["owner"] = df["repo_full_name"].str.split("/").str[0]

    # Derived: time to close (days)
    df["time_to_close_days"] = (
        (df["issue_closed_at"] - df["issue_created_at"]).dt.total_seconds() / 86400.0
    )

    return df


def ensure_outdir(outdir: Path):
    outdir.mkdir(parents=True, exist_ok=True)


def save_plot(outdir: Path, fname: str):
    fp = outdir / fname
    plt.tight_layout()
    plt.savefig(fp, dpi=150, bbox_inches="tight")
    plt.close()
    return fp


def language_pie(df: pd.DataFrame, outdir: Path, top_n: int = 12) -> Path:
    lang_counts = df["repo_language"].value_counts(dropna=False)
    if len(lang_counts) > top_n:
        top = lang_counts.head(top_n)
        other = pd.Series({"Other": lang_counts.iloc[top_n:].sum()})
        lang_counts = pd.concat([top, other])
    lang_counts = lang_counts.sort_values(ascending=False)

    plt.figure(figsize=(7, 7))
    plt.pie(lang_counts.values, labels=lang_counts.index, autopct="%1.1f%%", startangle=90)
    plt.title("Issues by Repository Primary Language")
    return save_plot(outdir, "language_pie.png")


def issues_by_month(df: pd.DataFrame, outdir: Path) -> Path:
    # Use closed month (if missing, fall back to created)
    base = df.copy()
    base["month"] = base["issue_closed_at"].fillna(base["issue_created_at"]).dt.to_period("M").astype(str)
    series = base.groupby("month").size().sort_index()

    plt.figure(figsize=(10, 4))
    plt.plot(series.index, series.values, marker="o")
    plt.xticks(rotation=60, ha="right")
    plt.title("Closed Issues per Month")
    plt.xlabel("Month")
    plt.ylabel("Count")
    return save_plot(outdir, "issues_per_month.png")


def comments_hist(df: pd.DataFrame, outdir: Path) -> Path:
    plt.figure(figsize=(7, 4))
    plt.hist(df["issue_comments"], bins=20)
    plt.title("Issue Comments Distribution")
    plt.xlabel("Comments")
    plt.ylabel("Frequency")
    return save_plot(outdir, "comments_hist.png")


def ttc_hist(df: pd.DataFrame, outdir: Path) -> Path:
    # Cap extreme values for readability (optional)
    data = df["time_to_close_days"].dropna()
    if len(data) == 0:
        return None
    cap = data.quantile(0.99)
    data = data.clip(upper=cap)

    plt.figure(figsize=(7, 4))
    plt.hist(data, bins=20)
    plt.title("Time to Close (days)")
    plt.xlabel("Days")
    plt.ylabel("Frequency")
    return save_plot(outdir, "time_to_close_hist.png")


def top_labels_bar(df: pd.DataFrame, outdir: Path, top_n: int = 20) -> Path:
    # split labels by ';'
    exploded = (
        df.assign(_labels=df["issue_labels"].str.split(";"))
          .explode("_labels")
    )
    exploded["_labels"] = exploded["_labels"].str.strip()
    exploded = exploded[exploded["_labels"].astype(bool)]  # drop empty
    if exploded.empty:
        return None
    counts = exploded["_labels"].value_counts().head(top_n)

    plt.figure(figsize=(10, 6))
    plt.barh(counts.index[::-1], counts.values[::-1])
    plt.title(f"Top {top_n} Labels")
    plt.xlabel("Count")
    return save_plot(outdir, "top_labels_bar.png")


def top_repos_by_stars(df: pd.DataFrame, outdir: Path, top_n: int = 20) -> Path:
    # aggregate by repo for stars and issue count
    agg = (df.groupby(["repo_full_name", "repo_url"], as_index=False)
             .agg(repo_stars=("repo_stars", "max"),
                  issue_count=("issue_url", "count")))
    top = agg.sort_values(["repo_stars", "issue_count"], ascending=[False, False]).head(top_n)

    plt.figure(figsize=(10, 6))
    plt.barh(top["repo_full_name"][::-1], top["repo_stars"][::-1])
    plt.title(f"Top {top_n} Repos by Stars (with issue count in CSV)")
    plt.xlabel("Stars")
    return save_plot(outdir, "top_repos_by_stars.png")


def write_summary_csvs(df: pd.DataFrame, outdir: Path, top_n: int):
    # language counts
    lang_counts = df["repo_language"].value_counts(dropna=False).rename_axis("language").reset_index(name="issues")
    lang_counts.to_csv(outdir / "languages.csv", index=False)

    # labels
    exploded = df.assign(_labels=df["issue_labels"].str.split(";")).explode("_labels")
    exploded["_labels"] = exploded["_labels"].str.strip()
    exploded = exploded[exploded["_labels"].astype(bool)]
    lbl_counts = exploded["_labels"].value_counts().rename_axis("label").reset_index(name="issues")
    lbl_counts.to_csv(outdir / "labels.csv", index=False)

    # org/owner counts
    owner_counts = df["owner"].value_counts().rename_axis("owner").reset_index(name="issues")
    owner_counts.to_csv(outdir / "owners.csv", index=False)

    # repo summary
    repo_summary = (df.groupby(["repo_full_name","repo_url","repo_stars","repo_language"], as_index=False)
                      .agg(issues=("issue_url","count"),
                           median_ttc_days=("time_to_close_days","median"),
                           avg_comments=("issue_comments","mean")))
    repo_summary.sort_values(["issues","repo_stars"], ascending=[False, False]).to_csv(outdir / "repos.csv", index=False)

    # basic stats (to markdown as well)
    stats = {
        "total_issues": int(len(df)),
        "unique_repos": int(df["repo_full_name"].nunique()),
        "median_comments": float(df["issue_comments"].median()) if len(df) else 0.0,
        "median_time_to_close_days": float(df["time_to_close_days"].median()) if df["time_to_close_days"].notna().any() else None,
        "time_range_created": f'{df["issue_created_at"].min()} — {df["issue_created_at"].max()}',
        "time_range_closed": f'{df["issue_closed_at"].min()} — {df["issue_closed_at"].max()}',
    }
    pd.Series(stats).to_csv(outdir / "summary_stats.csv")


def write_markdown_report(outdir: Path, figure_paths: List[Path], df: pd.DataFrame, top_n: int):
    md = outdir / "SUMMARY.md"
    total = len(df)
    uniq_repos = df["repo_full_name"].nunique()
    top_lang = df["repo_language"].value_counts().head(5).to_dict()
    with md.open("w", encoding="utf-8") as f:
        f.write("# Slow Test Analysis Summary\n\n")
        f.write(f"- Total issues: **{total}**\n")
        f.write(f"- Unique repositories: **{uniq_repos}**\n")
        f.write(f"- Top languages: {top_lang}\n")
        f.write(f"- CSV summaries: `languages.csv`, `labels.csv`, `owners.csv`, `repos.csv`, `summary_stats.csv`\n\n")
        for p in figure_paths:
            if p is None:
                continue
            f.write(f"![{p.name}]({p.name})\n\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", default="./slow_test_issues_by_year.csv", help="Path to slow_test_issues.csv")
    ap.add_argument("--outdir", default="reports", help="Output directory for charts and summaries")
    ap.add_argument("--top", type=int, default=20, help="Top-N for bar charts/tables")
    args = ap.parse_args()

    input_path = Path(args.input)
    outdir = Path(args.outdir)
    ensure_outdir(outdir)

    df = read_csv(input_path)

    # Save summary tables
    write_summary_csvs(df, outdir, args.top)

    # Charts
    figs = []
    figs.append(language_pie(df, outdir, top_n=12))
    figs.append(issues_by_month(df, outdir))
    figs.append(comments_hist(df, outdir))
    figs.append(ttc_hist(df, outdir))
    figs.append(top_labels_bar(df, outdir, top_n=args.top))
    figs.append(top_repos_by_stars(df, outdir, top_n=args.top))

    # Markdown report with embedded images
    write_markdown_report(outdir, figs, df, args.top)

    # Console summary
    print(f"[OK] Wrote summaries and charts to: {outdir.resolve()}")
    print("Files:")
    for p in sorted(outdir.glob("*")):
        print(" -", p.name)


if __name__ == "__main__":
    main()
