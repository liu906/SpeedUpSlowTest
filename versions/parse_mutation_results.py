#!/usr/bin/env python3
"""
Parse and compare mutmut mutation testing results between two versions.

Usage: python3 parse_mutation_results.py <project_name> [folder1] [folder2] [suffix]
Example: python3 parse_mutation_results.py armi_1737 before after_careful_mock only_mock_part

This script reads mutation_results_{version}_{suffix}.txt files produced by
run_mutation_venv_generic.sh and compares the mutation scores between versions.

Output:
- Terminal report with comparison
- mutation_comparison_{suffix}.txt in the project directory
"""

import sys
import re
from pathlib import Path
from collections import Counter


def parse_mutation_results_file(filepath):
    """
    Parse a mutmut results file (output of `mutmut results --all true`).

    Each line has format: "    module.function__mutmut_N: status"
    where status is one of: killed, survived, timeout, no tests, suspicious, skipped, segfault

    Returns a dict with counts and a list of per-mutant results.
    """
    status_counts = Counter()
    mutant_details = []

    try:
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or ':' not in line:
                    continue
                # Parse "mutant_name: status"
                parts = line.rsplit(': ', 1)
                if len(parts) != 2:
                    continue
                mutant_name = parts[0].strip()
                status = parts[1].strip()
                status_counts[status] += 1
                mutant_details.append((mutant_name, status))
    except FileNotFoundError:
        return None

    if not mutant_details:
        return None

    total = sum(status_counts.values())
    killed = status_counts.get('killed', 0)
    survived = status_counts.get('survived', 0)
    timeout = status_counts.get('timeout', 0)
    no_tests = status_counts.get('no tests', 0)
    suspicious = status_counts.get('suspicious', 0)
    skipped = status_counts.get('skipped', 0)
    segfault = status_counts.get('segfault', 0)

    # Mutation score = killed / (total - no_tests - skipped) * 100
    testable = total - no_tests - skipped
    mutation_score = (killed / testable * 100) if testable > 0 else 0.0

    return {
        'total': total,
        'killed': killed,
        'survived': survived,
        'timeout': timeout,
        'no_tests': no_tests,
        'suspicious': suspicious,
        'skipped': skipped,
        'segfault': segfault,
        'testable': testable,
        'mutation_score': mutation_score,
        'details': mutant_details,
    }


def compare_mutation_results(before_results, after_results):
    """Compare mutation results between two versions."""
    lines = []
    lines.append("=" * 60)
    lines.append("Mutation Testing Comparison")
    lines.append("=" * 60)
    lines.append("")

    # Header
    lines.append(f"{'Metric':<30} {'Before':>12} {'After':>12} {'Diff':>12}")
    lines.append("-" * 66)

    metrics = [
        ('Total Mutants', 'total'),
        ('Killed', 'killed'),
        ('Survived', 'survived'),
        ('Timeout', 'timeout'),
        ('No Tests', 'no_tests'),
        ('Suspicious', 'suspicious'),
        ('Skipped', 'skipped'),
        ('Segfault', 'segfault'),
        ('Testable', 'testable'),
    ]

    for label, key in metrics:
        bv = before_results[key]
        av = after_results[key]
        diff = av - bv
        diff_str = f"+{diff}" if diff > 0 else str(diff)
        lines.append(f"{label:<30} {bv:>12} {av:>12} {diff_str:>12}")

    lines.append("-" * 66)

    bs = before_results['mutation_score']
    as_ = after_results['mutation_score']
    diff = as_ - bs
    diff_str = f"+{diff:.2f}" if diff > 0 else f"{diff:.2f}"
    lines.append(f"{'Mutation Score (%)':<30} {bs:>12.2f} {as_:>12.2f} {diff_str:>12}")

    lines.append("")

    # Status summary
    if diff > 0:
        lines.append(f"Status: IMPROVED (mutation score increased by {diff:.2f}%)")
    elif diff < 0:
        lines.append(f"Status: DECREASED (mutation score decreased by {abs(diff):.2f}%) !!!")
    else:
        lines.append("Status: IDENTICAL (mutation score unchanged)")

    lines.append("")
    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 parse_mutation_results.py <project_name> [folder1] [folder2] [suffix]")
        sys.exit(1)

    project_name = sys.argv[1]
    folder1 = sys.argv[2] if len(sys.argv) > 2 else "before"
    folder2 = sys.argv[3] if len(sys.argv) > 3 else "after"
    suffix = sys.argv[4] if len(sys.argv) > 4 else ""

    mutation_suffix = f"_{suffix}" if suffix else ""

    script_dir = Path(__file__).parent
    project_dir = script_dir / project_name

    if not project_dir.exists():
        print(f"Error: Project directory not found: {project_dir}")
        sys.exit(1)

    # Parse results for both versions
    before_file = project_dir / f"mutation_results_{folder1}{mutation_suffix}.txt"
    after_file = project_dir / f"mutation_results_{folder2}{mutation_suffix}.txt"

    print(f"Parsing mutation results for: {project_name}")
    print(f"  Before: {before_file}")
    print(f"  After:  {after_file}")
    print()

    before_results = parse_mutation_results_file(before_file)
    after_results = parse_mutation_results_file(after_file)

    if before_results is None:
        print(f"Error: Could not parse before results: {before_file}")
        sys.exit(1)
    if after_results is None:
        print(f"Error: Could not parse after results: {after_file}")
        sys.exit(1)

    # Generate comparison
    report = compare_mutation_results(before_results, after_results)
    print(report)

    # Save report
    report_suffix = f"_{suffix}" if suffix else ""
    report_file = project_dir / f"mutation_comparison{report_suffix}.txt"
    with open(report_file, 'w') as f:
        f.write(report)
    print(f"Report saved to: {report_file}")


if __name__ == "__main__":
    main()
