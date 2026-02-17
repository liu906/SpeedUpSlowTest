#!/usr/bin/env python3
"""
Summarize mutation testing results across multiple projects into a CSV.

Usage: python3 summarize_mutation_results.py [-o output.csv] [project1 project2 ...]
Example: python3 summarize_mutation_results.py -o summary_mutation.csv armi_1737 pyjelly_235

Reads mutation_comparison_{suffix}.txt and mutation_results_{version}_{suffix}.txt
files from each project directory.

Output CSV columns:
- project_name
- before_total, before_killed, before_survived, before_timeout,
  before_no_tests, before_mutation_score
- after_total, after_killed, after_survived, after_timeout,
  after_no_tests, after_mutation_score
- mutation_score_diff
"""

import csv
import sys
from pathlib import Path
from parse_mutation_results import parse_mutation_results_file


def main():
    # Parse arguments
    projects = []
    output_file = "summary_mutation.csv"
    suffix = "only_mock_part"  # default suffix

    i = 1
    while i < len(sys.argv):
        arg = sys.argv[i]
        if arg in ('-o', '--output'):
            if i + 1 < len(sys.argv):
                output_file = sys.argv[i + 1]
                i += 2
            else:
                print("Error: -o requires an argument")
                sys.exit(1)
        elif arg in ('-s', '--suffix'):
            if i + 1 < len(sys.argv):
                suffix = sys.argv[i + 1]
                i += 2
            else:
                print("Error: -s requires an argument")
                sys.exit(1)
        else:
            projects.append(arg)
            i += 1

    if not projects:
        print("Error: No projects specified")
        print("Usage: python3 summarize_mutation_results.py [-o output.csv] [-s suffix] project1 project2 ...")
        sys.exit(1)

    script_dir = Path(__file__).parent
    mutation_suffix = f"_{suffix}" if suffix else ""

    fieldnames = [
        'project_name',
        'before_total',
        'before_killed',
        'before_survived',
        'before_timeout',
        'before_no_tests',
        'before_mutation_score',
        'after_total',
        'after_killed',
        'after_survived',
        'after_timeout',
        'after_no_tests',
        'after_mutation_score',
        'mutation_score_diff',
    ]

    results = []
    print(f"Summarizing mutation results for {len(projects)} projects...")
    print(f"Suffix: {suffix}")
    print()

    for project in projects:
        project_dir = script_dir / project

        before_file = project_dir / f"mutation_results_before{mutation_suffix}.txt"
        after_file = project_dir / f"mutation_results_after_careful_mock{mutation_suffix}.txt"

        before = parse_mutation_results_file(before_file)
        after = parse_mutation_results_file(after_file)

        if before is None or after is None:
            missing = []
            if before is None:
                missing.append(f"before ({before_file})")
            if after is None:
                missing.append(f"after ({after_file})")
            print(f"  {project}: SKIPPED (missing: {', '.join(missing)})")
            continue

        row = {
            'project_name': project,
            'before_total': before['total'],
            'before_killed': before['killed'],
            'before_survived': before['survived'],
            'before_timeout': before['timeout'],
            'before_no_tests': before['no_tests'],
            'before_mutation_score': before['mutation_score'],
            'after_total': after['total'],
            'after_killed': after['killed'],
            'after_survived': after['survived'],
            'after_timeout': after['timeout'],
            'after_no_tests': after['no_tests'],
            'after_mutation_score': after['mutation_score'],
            'mutation_score_diff': after['mutation_score'] - before['mutation_score'],
        }
        results.append(row)
        print(f"  {project}: before={before['mutation_score']:.1f}% after={after['mutation_score']:.1f}% diff={row['mutation_score_diff']:+.1f}%")

    if not results:
        print("\nNo results found.")
        sys.exit(1)

    # Sort by project name
    results.sort(key=lambda x: x['project_name'].lower())

    # Write CSV
    output_path = script_dir / output_file
    with open(output_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)

    print()
    print(f"Summary CSV written to: {output_path}")
    print(f"Total projects: {len(results)}")

    # Print overall stats
    if results:
        avg_before = sum(r['before_mutation_score'] for r in results) / len(results)
        avg_after = sum(r['after_mutation_score'] for r in results) / len(results)
        avg_diff = sum(r['mutation_score_diff'] for r in results) / len(results)
        print(f"\nOverall averages:")
        print(f"  Before mutation score: {avg_before:.2f}%")
        print(f"  After mutation score:  {avg_after:.2f}%")
        print(f"  Average difference:    {avg_diff:+.2f}%")


if __name__ == "__main__":
    main()
