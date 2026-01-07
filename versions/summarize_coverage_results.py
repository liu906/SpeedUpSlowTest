#!/usr/bin/env python3
"""
Summarize coverage comparison results across multiple projects.
Reads coverage_comparison_only_mock_part.txt files from project directories.

Usage:
    python3 summarize_coverage_results.py [project1] [project2] ...

    If no projects are specified, all projects with coverage files will be included.
"""

import argparse
import os
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple


def parse_coverage_comparison(file_path: str) -> Optional[Dict]:
    """Parse a coverage comparison text file and extract key metrics."""
    try:
        with open(file_path, 'r') as f:
            content = f.read()

        result = {
            'project': None,
            'before_coverage': None,
            'after_coverage': None,
            'coverage_diff': None,
            'lines_covered_before': None,
            'lines_covered_after': None,
            'lines_covered_diff': None,
            'total_statements_before': None,
            'total_statements_after': None,
            'total_branches_before': None,
            'total_branches_after': None,
            'branches_covered_before': None,
            'branches_covered_after': None,
            'branches_covered_diff': None,
            'missing_branches_before': None,
            'missing_branches_after': None,
            'before_branch_coverage': None,
            'after_branch_coverage': None,
            'branch_coverage_diff': None,
            'significant_decreases': 0,
            'significant_improvements': 0,
            'status': None
        }

        # Extract project name from file path
        project_match = re.search(r'([^/]+)/coverage_comparison', file_path)
        if project_match:
            result['project'] = project_match.group(1)

        # Parse the metric table
        metric_section = re.search(
            r'Metric\s+before\s+after_careful_mock\s+Difference\s*\n-+(.*?)\n\n',
            content,
            re.DOTALL
        )

        if metric_section:
            metrics_text = metric_section.group(1)

            # Total Coverage
            coverage_match = re.search(
                r'Total Coverage \(%\)\s+([\d.]+)%\s+([\d.]+)%\s+([-+]?[\d.]+)%',
                metrics_text
            )
            if coverage_match:
                result['before_coverage'] = float(coverage_match.group(1))
                result['after_coverage'] = float(coverage_match.group(2))
                result['coverage_diff'] = float(coverage_match.group(3))

            # Lines Covered
            lines_match = re.search(
                r'Lines Covered\s+(\d+)\s+(\d+)\s+([-+]?\d+)',
                metrics_text
            )
            if lines_match:
                result['lines_covered_before'] = int(lines_match.group(1))
                result['lines_covered_after'] = int(lines_match.group(2))
                result['lines_covered_diff'] = int(lines_match.group(3))

            # Total Statements
            statements_match = re.search(
                r'Total Statements\s+(\d+)\s+(\d+)\s+([-+]?\d+)',
                metrics_text
            )
            if statements_match:
                result['total_statements_before'] = int(statements_match.group(1))
                result['total_statements_after'] = int(statements_match.group(2))

            # Total Branches
            branches_match = re.search(
                r'Total Branches\s+(\d+)\s+(\d+)\s+([-+]?\d+)',
                metrics_text
            )
            if branches_match:
                result['total_branches_before'] = int(branches_match.group(1))
                result['total_branches_after'] = int(branches_match.group(2))

            # Branches Covered
            branches_covered_match = re.search(
                r'Branches Covered\s+(\d+)\s+(\d+)\s+([-+]?\d+)',
                metrics_text
            )
            if branches_covered_match:
                result['branches_covered_before'] = int(branches_covered_match.group(1))
                result['branches_covered_after'] = int(branches_covered_match.group(2))
                result['branches_covered_diff'] = int(branches_covered_match.group(3))

            # Missing Branches
            missing_branches_match = re.search(
                r'Missing Branches\s+(\d+)\s+(\d+)\s+([-+]?\d+)',
                metrics_text
            )
            if missing_branches_match:
                result['missing_branches_before'] = int(missing_branches_match.group(1))
                result['missing_branches_after'] = int(missing_branches_match.group(2))

        # Branch Coverage Percentage (appears after the metric table)
        branch_coverage_match = re.search(
            r'Branch Coverage \(%\)\s+([\d.]+)%\s+([\d.]+)%\s+([-+]?[\d.]+)%',
            content
        )
        if branch_coverage_match:
            result['before_branch_coverage'] = float(branch_coverage_match.group(1))
            result['after_branch_coverage'] = float(branch_coverage_match.group(2))
            result['branch_coverage_diff'] = float(branch_coverage_match.group(3))

        # Count significant changes in file-level coverage
        file_section = re.search(
            r'FILE-LEVEL COVERAGE COMPARISON.*?Legend:',
            content,
            re.DOTALL
        )

        if file_section:
            file_text = file_section.group(0)
            result['significant_decreases'] = len(re.findall(r'!!!', file_text))
            result['significant_improvements'] = len(re.findall(r'\*\*\*', file_text))

        # Extract summary status
        summary_section = re.search(
            r'SUMMARY.*',
            content,
            re.DOTALL
        )

        if summary_section:
            summary_text = summary_section.group(0)
            if 'Coverage DECREASED' in summary_text or 'Coverage decreased' in summary_text:
                result['status'] = 'DECREASED'
            elif 'Coverage IMPROVED' in summary_text or 'Coverage improved' in summary_text:
                result['status'] = 'IMPROVED'
            elif 'IDENTICAL' in summary_text or 'identical' in summary_text:
                result['status'] = 'IDENTICAL'
            else:
                result['status'] = 'UNKNOWN'

        return result

    except Exception as e:
        print(f"Error parsing {file_path}: {e}")
        return None


def find_coverage_files(base_dir: str = ".", project_list: Optional[List[str]] = None) -> List[str]:
    """Find all coverage_comparison_only_mock_part.txt files.

    Args:
        base_dir: Base directory to search in (default: current directory)
        project_list: Optional list of specific project names to include

    Returns:
        List of paths to coverage comparison files
    """
    coverage_files = []
    base_path = Path(base_dir)

    if not base_path.exists():
        print(f"Warning: {base_dir} directory not found")
        return []

    if project_list:
        # Only look for specific projects
        for project_name in project_list:
            project_dir = base_path / project_name
            if not project_dir.exists():
                print(f"Warning: Project directory not found: {project_name}")
                continue
            if not project_dir.is_dir():
                print(f"Warning: Not a directory: {project_name}")
                continue

            coverage_file = project_dir / "coverage_comparison_only_mock_part.txt"
            if coverage_file.exists():
                coverage_files.append(str(coverage_file))
            else:
                print(f"Warning: Coverage file not found for project: {project_name}")
    else:
        # Search all subdirectories
        for project_dir in base_path.iterdir():
            if project_dir.is_dir():
                coverage_file = project_dir / "coverage_comparison_only_mock_part.txt"
                if coverage_file.exists():
                    coverage_files.append(str(coverage_file))

    return sorted(coverage_files)


def print_summary(results: List[Dict]):
    """Print a summary table of all results."""
    if not results:
        print("No results to summarize.")
        return

    print("=" * 120)
    print("COVERAGE COMPARISON SUMMARY - ALL PROJECTS")
    print("=" * 120)
    print()

    # Summary table
    print(f"{'Project':<40} {'Line Cov':<12} {'Branch Cov':<12} {'Diff':<10} {'Status':<12} {'Files !!!':<10}")
    print(f"{'':40} {'Before→After':<12} {'Before→After':<12} {'(Line/Br)':<10}")
    print("-" * 120)

    for r in results:
        project = r['project'] or 'Unknown'

        # Line coverage
        line_before = f"{r['before_coverage']:.2f}%" if r['before_coverage'] is not None else 'N/A'
        line_after = f"{r['after_coverage']:.2f}%" if r['after_coverage'] is not None else 'N/A'
        line_cov_str = f"{line_before}→{line_after}"

        # Branch coverage
        br_before = f"{r['before_branch_coverage']:.2f}%" if r['before_branch_coverage'] is not None else 'N/A'
        br_after = f"{r['after_branch_coverage']:.2f}%" if r['after_branch_coverage'] is not None else 'N/A'
        branch_cov_str = f"{br_before}→{br_after}"

        # Diffs
        line_diff = f"{r['coverage_diff']:+.2f}" if r['coverage_diff'] is not None else 'N/A'
        br_diff = f"{r['branch_coverage_diff']:+.2f}" if r['branch_coverage_diff'] is not None else 'N/A'
        diff_str = f"{line_diff}/{br_diff}"

        status = r['status'] or 'N/A'
        sig_decreases = r['significant_decreases']

        print(f"{project:<40} {line_cov_str:<12} {branch_cov_str:<12} {diff_str:<10} {status:<12} {sig_decreases:<10}")

    print("=" * 120)
    print()

    # Overall statistics
    print("OVERALL STATISTICS")
    print("=" * 120)

    total_projects = len(results)
    decreased = sum(1 for r in results if r['status'] == 'DECREASED')
    improved = sum(1 for r in results if r['status'] == 'IMPROVED')
    identical = sum(1 for r in results if r['status'] == 'IDENTICAL')

    # Line coverage statistics
    avg_coverage_diff = sum(r['coverage_diff'] for r in results if r['coverage_diff'] is not None) / total_projects

    # Branch coverage statistics
    branch_diffs = [r['branch_coverage_diff'] for r in results if r['branch_coverage_diff'] is not None]
    avg_branch_coverage_diff = sum(branch_diffs) / len(branch_diffs) if branch_diffs else 0

    total_sig_decreases = sum(r['significant_decreases'] for r in results)
    total_sig_improvements = sum(r['significant_improvements'] for r in results)

    print(f"Total Projects Analyzed: {total_projects}")
    print(f"  - Coverage Decreased:  {decreased} ({decreased/total_projects*100:.1f}%)")
    print(f"  - Coverage Improved:   {improved} ({improved/total_projects*100:.1f}%)")
    print(f"  - Coverage Identical:  {identical} ({identical/total_projects*100:.1f}%)")
    print()
    print(f"Average Line Coverage Change: {avg_coverage_diff:+.2f}%")
    print(f"Average Branch Coverage Change: {avg_branch_coverage_diff:+.2f}%")
    print(f"Total Files with Significant Decreases (>5%): {total_sig_decreases}")
    print(f"Total Files with Significant Improvements (>5%): {total_sig_improvements}")
    print()

    # Projects with largest decreases
    sorted_by_diff = sorted(
        [r for r in results if r['coverage_diff'] is not None],
        key=lambda x: x['coverage_diff']
    )

    print("TOP 5 PROJECTS WITH LARGEST COVERAGE DECREASE:")
    print("-" * 80)
    for i, r in enumerate(sorted_by_diff[:5], 1):
        print(f"{i}. {r['project']}: {r['coverage_diff']:+.2f}% "
              f"({r['before_coverage']:.2f}% → {r['after_coverage']:.2f}%)")
    print()

    print("TOP 5 PROJECTS WITH SMALLEST COVERAGE CHANGE (BEST):")
    print("-" * 80)
    sorted_by_abs_diff = sorted(
        [r for r in results if r['coverage_diff'] is not None],
        key=lambda x: abs(x['coverage_diff'])
    )
    for i, r in enumerate(sorted_by_abs_diff[:5], 1):
        print(f"{i}. {r['project']}: {r['coverage_diff']:+.2f}% "
              f"({r['before_coverage']:.2f}% → {r['after_coverage']:.2f}%)")

    print("=" * 120)


def save_csv_summary(results: List[Dict], output_file: str = "coverage_summary.csv"):
    """Save results to a CSV file, sorted by project name (case-insensitive)."""
    import csv

    # Sort results by project name (case-insensitive, A-Z)
    sorted_results = sorted(results, key=lambda x: (x['project'] or '').lower())

    with open(output_file, 'w', newline='') as f:
        fieldnames = [
            'project', 'before_coverage', 'after_coverage', 'coverage_diff',
            'lines_covered_before', 'lines_covered_after', 'lines_covered_diff',
            'total_statements_before', 'total_statements_after',
            'before_branch_coverage', 'after_branch_coverage', 'branch_coverage_diff',
            'total_branches_before', 'total_branches_after',
            'branches_covered_before', 'branches_covered_after', 'branches_covered_diff',
            'missing_branches_before', 'missing_branches_after',
            'significant_decreases', 'significant_improvements', 'status'
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(sorted_results)

    print(f"\nDetailed results saved to: {output_file}")


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description='Summarize coverage comparison results across multiple projects.',
        epilog='Example: python3 summarize_coverage_results.py pydicom_1636 roms-tools_107 armi_1737'
    )
    parser.add_argument(
        'projects',
        nargs='*',
        help='List of project names to analyze (if not specified, all projects with coverage files will be included)'
    )
    parser.add_argument(
        '-o', '--output',
        default='coverage_summary.csv',
        help='Output CSV file name (default: coverage_summary.csv)'
    )

    args = parser.parse_args()

    if args.projects:
        print(f"Searching for coverage comparison files for {len(args.projects)} specified projects...")
        coverage_files = find_coverage_files(project_list=args.projects)
    else:
        print("Searching for coverage comparison files for all projects...")
        coverage_files = find_coverage_files()

    if not coverage_files:
        print("\nNo coverage comparison files found.")
        if args.projects:
            print("Expected files: PROJECT_NAME/coverage_comparison_only_mock_part.txt")
            print(f"Specified projects: {', '.join(args.projects)}")
        else:
            print("Expected files: PROJECT_NAME/coverage_comparison_only_mock_part.txt")
        return

    print(f"Found {len(coverage_files)} coverage comparison files.\n")

    results = []
    for file_path in coverage_files:
        parsed = parse_coverage_comparison(file_path)
        if parsed:
            results.append(parsed)

    if results:
        print_summary(results)
        save_csv_summary(results, output_file=args.output)
    else:
        print("No results could be parsed.")


if __name__ == "__main__":
    main()
