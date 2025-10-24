#!/usr/bin/env python3
"""
Optimized script to parse test results and extract energy and duration data.
Usage: python3 parse_results_generic_optimized.py <project_path>
Example: python3 parse_results_generic_optimized.py BuffaLogs_400
"""

import re
import csv
import sys
from pathlib import Path


def parse_log_file(log_file_path):
    """Parse the test results log file and extract energy and duration data (optimized)."""
    energy_data = []
    duration_data = []

    # State machine variables
    current_version = None
    current_run_number = None
    in_slowest_durations = False
    pending_durations = []  # Temporary storage for durations in current test run

    # Pre-compiled regex patterns for better performance
    version_pattern = re.compile(r'Starting tests for (before|after) version')
    test_run_pattern = re.compile(r'Test run (\d+)/\d+ for (before|after)')
    energy_pattern = re.compile(r'Energy consumption in joules: ([\d.]+) for ([\d.]+) sec of execution\.')
    slowest_start_pattern = re.compile(r'={20,}\s+slowest durations\s+={20,}')
    test_duration_pattern = re.compile(r'([\d.]+)s\s+(\w+)\s+(.+?)$')
    total_time_pattern = re.compile(r'={10,}.*?\s+in\s+([\d.]+)s\s+={10,}')

    # Process file line by line instead of loading entire file
    with open(log_file_path, 'r') as f:
        for line in f:
            line = line.rstrip('\n')

            # Check for version header
            version_match = version_pattern.search(line)
            if version_match:
                current_version = version_match.group(1)
                continue

            # Check for test run header
            test_run_match = test_run_pattern.search(line)
            if test_run_match:
                current_run_number = int(test_run_match.group(1))
                in_slowest_durations = False
                pending_durations = []  # Clear pending durations for new run
                continue

            # Check for energy consumption data
            if current_version and current_run_number:
                energy_match = energy_pattern.search(line)
                if energy_match:
                    energy_joules = float(energy_match.group(1))
                    execution_time_sec = float(energy_match.group(2))
                    average_power_watts = energy_joules / execution_time_sec if execution_time_sec > 0 else 0

                    energy_data.append({
                        'version': current_version,
                        'run_number': current_run_number,
                        'energy_joules': energy_joules,
                        'execution_time_sec': execution_time_sec,
                        'average_power_watts': average_power_watts
                    })
                    continue

            # Check for slowest durations section start
            if slowest_start_pattern.search(line):
                in_slowest_durations = True
                continue

            # Check for total time line (comes AFTER duration lines)
            if current_version and current_run_number:
                total_time_match = total_time_pattern.search(line)
                if total_time_match:
                    total_test_time = float(total_time_match.group(1))

                    # Update all pending durations with the total test time
                    for duration_entry in pending_durations:
                        duration_entry['total_test_time'] = total_test_time
                        duration_data.append(duration_entry)

                    pending_durations = []
                    in_slowest_durations = False
                    continue

            # Parse individual test durations
            if in_slowest_durations and current_version and current_run_number:
                # Parse duration line
                duration_match = test_duration_pattern.match(line)
                if duration_match:
                    duration_sec = float(duration_match.group(1))
                    phase = duration_match.group(2)
                    full_test_path = duration_match.group(3).strip()

                    # Extract test name from the full path (last part after ::)
                    if '::' in full_test_path:
                        test_name = full_test_path.split('::')[-1]
                    else:
                        test_name = full_test_path

                    # Add to pending list (will be updated with total_test_time later)
                    pending_durations.append({
                        'version': current_version,
                        'run_number': current_run_number,
                        'test_name': test_name,
                        'test_path': full_test_path,
                        'phase': phase,
                        'duration_sec': duration_sec,
                        'total_test_time': None  # Will be filled in when we find the total time
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
        print("Usage: python3 parse_results_generic_optimized.py <project_path>")
        print("Example: python3 parse_results_generic_optimized.py BuffaLogs_400")
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
