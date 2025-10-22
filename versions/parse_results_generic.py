#!/usr/bin/env python3
"""
Generic script to parse test results and extract energy and duration data.
Usage: python3 parse_results_generic.py <project_path>
Example: python3 parse_results_generic.py BuffaLogs_399
"""

import re
import csv
import sys
from pathlib import Path


def parse_log_file(log_file_path):
    """Parse the test results log file and extract energy and duration data."""
    with open(log_file_path, 'r') as f:
        content = f.read()

    energy_data = []
    duration_data = []

    # Split by version sections
    sections = re.split(r'========================================\s*Starting tests for (before|after) version', content)

    for i in range(1, len(sections), 2):
        if i + 1 > len(sections):
            break

        version = sections[i].strip()
        section_content = sections[i + 1]

        # Extract energy consumption data
        # Pattern: "Energy consumption in joules: X for Y sec of execution."
        test_runs = re.finditer(
            r'Test run (\d+)/\d+ for ' + re.escape(version) + r'.*?' +
            r'Energy consumption in joules: ([\d.]+) for ([\d.]+) sec of execution\.',
            section_content, re.DOTALL
        )

        for match in test_runs:
            run_number = int(match.group(1))
            energy_joules = float(match.group(2))
            execution_time_sec = float(match.group(3))
            average_power_watts = energy_joules / execution_time_sec if execution_time_sec > 0 else 0

            energy_data.append({
                'version': version,
                'run_number': run_number,
                'energy_joules': energy_joules,
                'execution_time_sec': execution_time_sec,
                'average_power_watts': average_power_watts
            })

        # Extract test duration data
        # Pattern: slowest durations section with individual test times
        # Format: "0.26s setup    impossible_travel/tests/views/test_views.py::TestViews::test_alerts_api"
        test_duration_blocks = re.finditer(
            r'Test run (\d+)/\d+ for ' + re.escape(version) + r'.*?' +
            r'={20,}\s+slowest durations\s+={20,}\s*(.*?)\s*\(.*?durations.*?\).*?={20,}\s+\d+ passed.*?in ([\d.]+)s',
            section_content, re.DOTALL
        )

        for match in test_duration_blocks:
            run_number = int(match.group(1))
            durations_text = match.group(2)
            total_test_time = float(match.group(3))

            # Parse individual test durations
            # Pattern: "0.26s setup    impossible_travel/tests/views/test_views.py::TestViews::test_alerts_api"
            # Captures: duration, phase (setup/call/teardown), and full test path
            test_lines = re.finditer(r'([\d.]+)s\s+(\w+)\s+(.+?)(?:\s*$)', durations_text, re.MULTILINE)

            for test_match in test_lines:
                duration_sec = float(test_match.group(1))
                phase = test_match.group(2)  # setup, call, or teardown
                full_test_path = test_match.group(3).strip()

                # Extract test name from the full path (last part after ::)
                if '::' in full_test_path:
                    test_name = full_test_path.split('::')[-1]
                else:
                    test_name = full_test_path

                duration_data.append({
                    'version': version,
                    'run_number': run_number,
                    'test_name': test_name,
                    'test_path': full_test_path,
                    'phase': phase,
                    'duration_sec': duration_sec,
                    'total_test_time': total_test_time
                })

    return energy_data, duration_data


def save_to_csv(data, csv_file_path, fieldnames):
    """Save data to CSV file."""
    with open(csv_file_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)


def print_summary(energy_data, duration_data):
    """Print summary statistics."""
    print("\n" + "="*60)
    print("EXTRACTION SUMMARY")
    print("="*60)

    # Energy summary
    energy_before = [d for d in energy_data if d['version'] == 'before']
    energy_after = [d for d in energy_data if d['version'] == 'after']

    print(f"\nEnergy data extracted:")
    print(f"  Before version: {len(energy_before)} entries")
    print(f"  After version: {len(energy_after)} entries")

    if energy_before:
        avg_energy_before = sum(d['energy_joules'] for d in energy_before) / len(energy_before)
        print(f"  Average energy (before): {avg_energy_before:.2f} J")

    if energy_after:
        avg_energy_after = sum(d['energy_joules'] for d in energy_after) / len(energy_after)
        print(f"  Average energy (after): {avg_energy_after:.2f} J")

    if energy_before and energy_after:
        improvement = ((avg_energy_before - avg_energy_after) / avg_energy_before) * 100
        print(f"  Energy improvement: {improvement:.2f}%")

    # Duration summary
    duration_before = [d for d in duration_data if d['version'] == 'before']
    duration_after = [d for d in duration_data if d['version'] == 'after']

    print(f"\nTest duration data extracted:")
    print(f"  Before version: {len(duration_before)} entries")
    print(f"  After version: {len(duration_after)} entries")

    # Calculate average test durations
    if duration_before:
        avg_duration_before = sum(d['duration_sec'] for d in duration_before) / len(duration_before)
        print(f"  Average test duration (before): {avg_duration_before:.3f}s")

    if duration_after:
        avg_duration_after = sum(d['duration_sec'] for d in duration_after) / len(duration_after)
        print(f"  Average test duration (after): {avg_duration_after:.3f}s")

    if duration_before and duration_after:
        time_improvement = ((avg_duration_before - avg_duration_after) / avg_duration_before) * 100
        print(f"  Time improvement: {time_improvement:.2f}%")

    print("\n" + "="*60 + "\n")


def main():
    # Check if project path is provided
    if len(sys.argv) < 2:
        print("Error: Project path is required")
        print("Usage: python3 parse_results_generic.py <project_path>")
        print("Example: python3 parse_results_generic.py BuffaLogs_399")
        sys.exit(1)

    project_path = sys.argv[1]
    script_dir = Path(__file__).parent
    project_dir = script_dir / project_path

    # Check if project directory exists
    if not project_dir.exists():
        print(f"Error: Project directory not found: {project_dir}")
        sys.exit(1)

    log_file = project_dir / "test_results.log"
    energy_csv = project_dir / "energy_data.csv"
    duration_csv = project_dir / "duration_data.csv"

    # Check if log file exists
    if not log_file.exists():
        print(f"Error: Log file not found: {log_file}")
        print("Please run the tests first using run_tests_generic.sh")
        sys.exit(1)

    print(f"Parsing test results from: {log_file}")

    # Parse the log file
    energy_data, duration_data = parse_log_file(log_file)

    # Save to CSV files
    if energy_data:
        save_to_csv(energy_data, energy_csv,
                   ['version', 'run_number', 'energy_joules', 'execution_time_sec', 'average_power_watts'])
        print(f"Energy data saved to: {energy_csv}")
    else:
        print("Warning: No energy data found in log file")

    if duration_data:
        save_to_csv(duration_data, duration_csv,
                   ['version', 'run_number', 'test_name', 'test_path', 'phase', 'duration_sec', 'total_test_time'])
        print(f"Duration data saved to: {duration_csv}")
    else:
        print("Warning: No duration data found in log file")

    # Print summary
    print_summary(energy_data, duration_data)

    print(f"Next step: python3 visualize_results_generic.py {project_path}")


if __name__ == "__main__":
    main()
