#!/usr/bin/env python3
"""
Script to generate summary CSV for multiple projects.

Usage: python3 summarize_projects.py <project1> <project2> ... [--suffix <log_suffix>] [--output <output_file>]
Example: python3 summarize_projects.py autosubmit_2367 bilby_986 opensearch-build_595 --suffix only_mock_part

This script reads the CSV data files from each project directory and generates
a summary CSV with key metrics for all projects.

Output columns:
- project_name: Name of the project
- before_avg_energy_j: Average energy consumption before optimization (Joules)
- after_avg_energy_j: Average energy consumption after optimization (Joules)
- energy_reduction_pct: Percentage reduction in energy consumption
- energy_saved_j: Absolute energy saved (Joules)
- before_avg_test_time_s: Average total test time before optimization (seconds)
- after_avg_test_time_s: Average total test time after optimization (seconds)
- test_time_reduction_pct: Percentage reduction in test time
- test_speedup_ratio: Speed ratio (before/after)
- before_avg_exec_time_s: Average energibridge execution time before (seconds)
- after_avg_exec_time_s: Average energibridge execution time after (seconds)
- exec_time_reduction_pct: Percentage reduction in execution time
- exec_speedup_ratio: Execution speed ratio (before/after)
"""

import csv
import sys
from pathlib import Path
from collections import defaultdict


def read_csv_data(csv_file):
    """Read CSV file and return list of dictionaries."""
    data = []
    try:
        with open(csv_file, 'r') as f:
            reader = csv.DictReader(f)
            data = list(reader)
    except FileNotFoundError:
        pass
    return data


def calculate_energy_metrics(energy_data):
    """Calculate energy-related metrics from energy data."""
    if not energy_data:
        return {}

    # Group by version
    versions = defaultdict(list)
    for row in energy_data:
        version = row['version']
        energy = float(row['energy_joules'])
        versions[version].append(energy)

    # Sort versions: put "before" first if it exists
    version_names = sorted(versions.keys(), key=lambda x: (x != 'before', x))

    if len(version_names) < 2:
        # Not enough versions to compare
        return {}

    version1 = version_names[0]
    version2 = version_names[1]

    if not versions[version1] or not versions[version2]:
        return {}

    avg_energy_before = sum(versions[version1]) / len(versions[version1])
    avg_energy_after = sum(versions[version2]) / len(versions[version2])

    energy_reduction_pct = ((avg_energy_before - avg_energy_after) / avg_energy_before) * 100
    energy_saved = avg_energy_before - avg_energy_after

    return {
        'before_avg_energy_j': avg_energy_before,
        'after_avg_energy_j': avg_energy_after,
        'energy_reduction_pct': energy_reduction_pct,
        'energy_saved_j': energy_saved
    }


def calculate_duration_metrics(duration_data):
    """Calculate test duration metrics from duration data."""
    if not duration_data:
        return {}

    # Group by version and run number to get total test times
    versions = defaultdict(dict)
    for row in duration_data:
        version = row['version']
        run_number = int(row['run_number'])
        total_time = row.get('total_test_time')

        if total_time and total_time != '':
            total_time = float(total_time)
            if run_number not in versions[version]:
                versions[version][run_number] = total_time

    # Sort versions: put "before" first if it exists
    version_names = sorted(versions.keys(), key=lambda x: (x != 'before', x))

    if len(version_names) < 2:
        return {}

    version1 = version_names[0]
    version2 = version_names[1]

    if not versions[version1] or not versions[version2]:
        return {}

    avg_time_before = sum(versions[version1].values()) / len(versions[version1])
    avg_time_after = sum(versions[version2].values()) / len(versions[version2])

    time_reduction_pct = ((avg_time_before - avg_time_after) / avg_time_before) * 100
    speedup_ratio = avg_time_before / avg_time_after if avg_time_after > 0 else 0

    return {
        'before_avg_test_time_s': avg_time_before,
        'after_avg_test_time_s': avg_time_after,
        'test_time_reduction_pct': time_reduction_pct,
        'test_speedup_ratio': speedup_ratio
    }


def calculate_execution_metrics(execution_data):
    """Calculate execution time metrics from execution time data."""
    if not execution_data:
        return {}

    # Group by version
    versions = defaultdict(list)
    for row in execution_data:
        version = row['version']
        exec_time = float(row['energibridge_time_sec'])
        versions[version].append(exec_time)

    # Sort versions: put "before" first if it exists
    version_names = sorted(versions.keys(), key=lambda x: (x != 'before', x))

    if len(version_names) < 2:
        return {}

    version1 = version_names[0]
    version2 = version_names[1]

    avg_exec_before = sum(versions[version1]) / len(versions[version1])
    avg_exec_after = sum(versions[version2]) / len(versions[version2])

    exec_reduction_pct = ((avg_exec_before - avg_exec_after) / avg_exec_before) * 100
    exec_speedup_ratio = avg_exec_before / avg_exec_after if avg_exec_after > 0 else 0

    return {
        'before_avg_exec_time_s': avg_exec_before,
        'after_avg_exec_time_s': avg_exec_after,
        'exec_time_reduction_pct': exec_reduction_pct,
        'exec_speedup_ratio': exec_speedup_ratio
    }


def process_project(project_name, base_dir, log_suffix):
    """Process a single project and return summary metrics."""
    project_dir = base_dir / project_name

    if not project_dir.exists():
        print(f"Warning: Project directory not found: {project_dir}")
        return None

    # Construct file names
    if log_suffix:
        energy_csv = project_dir / f"energy_data_{log_suffix}.csv"
        duration_csv = project_dir / f"duration_data_{log_suffix}.csv"
        execution_csv = project_dir / f"execution_time_data_{log_suffix}.csv"
    else:
        energy_csv = project_dir / "energy_data.csv"
        duration_csv = project_dir / "duration_data.csv"
        execution_csv = project_dir / "execution_time_data.csv"

    # Read data files
    energy_data = read_csv_data(energy_csv)
    duration_data = read_csv_data(duration_csv)
    execution_data = read_csv_data(execution_csv)

    if not energy_data and not duration_data and not execution_data:
        print(f"Warning: No data found for project: {project_name}")
        return None

    # Calculate metrics
    metrics = {'project_name': project_name}

    energy_metrics = calculate_energy_metrics(energy_data)
    metrics.update(energy_metrics)

    duration_metrics = calculate_duration_metrics(duration_data)
    metrics.update(duration_metrics)

    execution_metrics = calculate_execution_metrics(execution_data)
    metrics.update(execution_metrics)

    # Fill in missing values with N/A
    fieldnames = [
        'project_name',
        'before_avg_energy_j',
        'after_avg_energy_j',
        'energy_reduction_pct',
        'energy_saved_j',
        'before_avg_test_time_s',
        'after_avg_test_time_s',
        'test_time_reduction_pct',
        'test_speedup_ratio',
        'before_avg_exec_time_s',
        'after_avg_exec_time_s',
        'exec_time_reduction_pct',
        'exec_speedup_ratio'
    ]

    for field in fieldnames:
        if field not in metrics:
            metrics[field] = 'N/A'

    return metrics


def main():
    if len(sys.argv) < 2:
        print("Error: No projects specified")
        print("Usage: python3 summarize_projects.py <project1> <project2> ... [--suffix <log_suffix>] [--output <output_file>]")
        print("Example: python3 summarize_projects.py autosubmit_2367 bilby_986 --suffix only_mock_part")
        sys.exit(1)

    # Parse arguments
    projects = []
    log_suffix = None
    output_file = None

    i = 1
    while i < len(sys.argv):
        arg = sys.argv[i]
        if arg == '--suffix':
            if i + 1 < len(sys.argv):
                log_suffix = sys.argv[i + 1]
                i += 2
            else:
                print("Error: --suffix requires an argument")
                sys.exit(1)
        elif arg == '--output':
            if i + 1 < len(sys.argv):
                output_file = sys.argv[i + 1]
                i += 2
            else:
                print("Error: --output requires an argument")
                sys.exit(1)
        else:
            projects.append(arg)
            i += 1

    if not projects:
        print("Error: No projects specified")
        sys.exit(1)

    # Default output file
    if not output_file:
        if log_suffix:
            output_file = f"project_summary_{log_suffix}.csv"
        else:
            output_file = "project_summary.csv"

    # Base directory (where all project directories are located)
    script_dir = Path(__file__).parent

    print(f"Processing {len(projects)} projects...")
    if log_suffix:
        print(f"Using log suffix: {log_suffix}")
    print()

    # Process each project
    summary_data = []
    for project in projects:
        print(f"Processing: {project}...", end=' ')
        metrics = process_project(project, script_dir, log_suffix)
        if metrics:
            summary_data.append(metrics)
            print("✓")
        else:
            print("✗ (no data)")

    # Write summary CSV
    if summary_data:
        fieldnames = [
            'project_name',
            'before_avg_energy_j',
            'after_avg_energy_j',
            'energy_reduction_pct',
            'energy_saved_j',
            'before_avg_test_time_s',
            'after_avg_test_time_s',
            'test_time_reduction_pct',
            'test_speedup_ratio',
            'before_avg_exec_time_s',
            'after_avg_exec_time_s',
            'exec_time_reduction_pct',
            'exec_speedup_ratio'
        ]

        output_path = script_dir / output_file
        with open(output_path, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(summary_data)

        print()
        print("="*60)
        print(f"Summary written to: {output_path}")
        print(f"Total projects processed: {len(summary_data)}")
        print("="*60)

        # Print summary statistics
        print("\nSummary Statistics:")
        print("-" * 60)

        # Calculate averages across all projects
        energy_reductions = [float(d['energy_reduction_pct']) for d in summary_data
                           if d['energy_reduction_pct'] != 'N/A']
        time_reductions = [float(d['test_time_reduction_pct']) for d in summary_data
                         if d['test_time_reduction_pct'] != 'N/A']
        speedups = [float(d['test_speedup_ratio']) for d in summary_data
                   if d['test_speedup_ratio'] != 'N/A']

        if energy_reductions:
            print(f"Average energy reduction: {sum(energy_reductions)/len(energy_reductions):.2f}%")
        if time_reductions:
            print(f"Average test time reduction: {sum(time_reductions)/len(time_reductions):.2f}%")
        if speedups:
            print(f"Average speedup ratio: {sum(speedups)/len(speedups):.2f}x")

        print("-" * 60)
    else:
        print("\nNo data could be processed for any project.")
        sys.exit(1)


if __name__ == "__main__":
    main()
