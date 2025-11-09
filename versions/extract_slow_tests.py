#!/usr/bin/env python3
"""
Extract slow tests from pytest log files.

Usage:
    python3 extract_slow_tests.py <project_name> [--threshold SECONDS] [--output OUTPUT_FILE]

Example:
    python3 extract_slow_tests.py bilby_86
    python3 extract_slow_tests.py bilby_86 --threshold 5
    python3 extract_slow_tests.py bilby_86 --threshold 10 --output slow_tests.txt
"""

import argparse
import re
import sys
from pathlib import Path


def parse_pytest_durations(log_file_path, threshold_seconds=10.0):
    """
    Parse pytest log file and extract tests that took longer than threshold.

    Args:
        log_file_path: Path to the pytest log file
        threshold_seconds: Minimum duration in seconds to include a test

    Returns:
        List of tuples: (test_name, duration_seconds)
    """
    slow_tests = []

    try:
        with open(log_file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Log file not found: {log_file_path}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error reading log file: {e}", file=sys.stderr)
        sys.exit(1)

    # Pattern to match pytest duration lines like:
    # 0.50s call     test_file.py::TestClass::test_method
    # 10.23s setup   test_file.py::test_function
    duration_pattern = re.compile(r'(\d+\.\d+)s\s+(?:call|setup|teardown)\s+(.+)')

    for line in content.splitlines():
        match = duration_pattern.search(line)
        if match:
            duration = float(match.group(1))
            test_name = match.group(2).strip()

            if duration >= threshold_seconds:
                slow_tests.append((test_name, duration))

    # Sort by duration (descending)
    slow_tests.sort(key=lambda x: x[1], reverse=True)

    return slow_tests


def main():
    parser = argparse.ArgumentParser(
        description='Extract slow tests from pytest log files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument(
        'project_name',
        help='Project name (e.g., bilby_86)'
    )
    parser.add_argument(
        '--threshold',
        type=float,
        default=10.0,
        help='Minimum test duration in seconds (default: 10.0)'
    )
    parser.add_argument(
        '--output',
        type=str,
        default=None,
        help='Output file path (default: <project_name>_slow_tests.txt)'
    )

    args = parser.parse_args()

    # Construct the log file path
    # Script is in versions folder, so projects are siblings
    base_dir = Path(__file__).parent
    log_file = base_dir / args.project_name / 'test_results_test_suite.log'

    print(f"Reading log file: {log_file}")
    print(f"Threshold: {args.threshold} seconds")

    # Parse the log file
    slow_tests = parse_pytest_durations(log_file, args.threshold)

    if not slow_tests:
        print(f"\nNo tests found with duration >= {args.threshold} seconds")
        return

    # Determine output file
    if args.output:
        output_file = Path(args.output)
    else:
        output_file = Path(f"{args.project_name}_slow_tests.txt")

    # Write results to file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(f"# Slow tests for {args.project_name}\n")
        f.write(f"# Threshold: {args.threshold} seconds\n")
        f.write(f"# Total slow tests found: {len(slow_tests)}\n")
        f.write("#" + "="*70 + "\n\n")

        for test_name, duration in slow_tests:
            f.write(f"{test_name}\n")

    # Print summary
    print(f"\nFound {len(slow_tests)} slow tests:")
    print("-" * 80)
    for test_name, duration in slow_tests:
        print(f"{duration:>7.2f}s  {test_name}")
    print("-" * 80)
    print(f"\nResults saved to: {output_file}")


if __name__ == '__main__':
    main()
