#!/usr/bin/env python3
"""
Script to generate summary CSV for multiple projects.

Usage: python3 summarize_projects.py <project1> <project2> ... [--suffix <log_suffix>] [--output <output_file>]
Example: python3 summarize_projects.py autosubmit_2367 bilby_986 opensearch-build_595 --suffix only_mock_part

This script reads the CSV data files from each project directory and generates
a summary CSV with key metrics for all projects.

Output columns:
- project_name: Name of the project
- before_data_count: Number of data points in before version (after outlier filtering)
- after_data_count: Number of data points in after version (after outlier filtering)
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
import statistics
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend


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


def filter_outliers_iqr(data_values):
    """
    Filter outliers using IQR (Interquartile Range) method.

    Args:
        data_values: List of numeric values

    Returns:
        List of values with outliers removed
    """
    if len(data_values) < 4:
        # Need at least 4 data points for meaningful IQR calculation
        return data_values

    # Calculate Q1, Q3, and IQR
    q1 = statistics.quantiles(data_values, n=4)[0]  # 25th percentile
    q3 = statistics.quantiles(data_values, n=4)[2]  # 75th percentile
    iqr = q3 - q1

    # Define outlier bounds
    lower_bound = q1 - 1.5 * iqr
    upper_bound = q3 + 1.5 * iqr

    # Filter values within bounds
    filtered_values = [v for v in data_values if lower_bound <= v <= upper_bound]

    # Return original data if filtering removes too many points (>50%)
    if len(filtered_values) < len(data_values) * 0.5:
        return data_values

    return filtered_values if filtered_values else data_values


def calculate_energy_metrics(energy_data):
    """Calculate energy-related metrics from energy data with IQR outlier filtering."""
    if not energy_data:
        return {}, None

    # Group by version
    versions = defaultdict(list)
    for row in energy_data:
        version = row['version']
        energy = float(row['energy_joules'])
        versions[version].append(energy)

    # Apply IQR outlier filtering to each version
    filtered_versions = {}
    for version in versions:
        filtered_versions[version] = filter_outliers_iqr(versions[version])

    # Sort versions: put "before" first if it exists
    version_names = sorted(filtered_versions.keys(), key=lambda x: (x != 'before', x))

    if len(version_names) < 2:
        # Not enough versions to compare
        return {}, None

    version1 = version_names[0]
    version2 = version_names[1]

    if not filtered_versions[version1] or not filtered_versions[version2]:
        return {}, None

    avg_energy_before = sum(filtered_versions[version1]) / len(filtered_versions[version1])
    avg_energy_after = sum(filtered_versions[version2]) / len(filtered_versions[version2])

    energy_reduction_pct = ((avg_energy_before - avg_energy_after) / avg_energy_before) * 100
    energy_saved = avg_energy_before - avg_energy_after

    # Prepare filtered data for plotting
    plot_data = {
        'before': filtered_versions[version1],
        'after': filtered_versions[version2]
    }

    return {
        'before_data_count': len(filtered_versions[version1]),
        'after_data_count': len(filtered_versions[version2]),
        'before_avg_energy_j': avg_energy_before,
        'after_avg_energy_j': avg_energy_after,
        'energy_reduction_pct': energy_reduction_pct,
        'energy_saved_j': energy_saved
    }, plot_data


def calculate_duration_metrics(duration_data):
    """Calculate test duration metrics from duration data with IQR outlier filtering."""
    if not duration_data:
        return {}, None

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

    # Apply IQR outlier filtering to each version's duration values
    filtered_versions = {}
    for version in versions:
        duration_values = list(versions[version].values())
        filtered_values = filter_outliers_iqr(duration_values)
        filtered_versions[version] = filtered_values

    # Sort versions: put "before" first if it exists
    version_names = sorted(filtered_versions.keys(), key=lambda x: (x != 'before', x))

    if len(version_names) < 2:
        return {}, None

    version1 = version_names[0]
    version2 = version_names[1]

    if not filtered_versions[version1] or not filtered_versions[version2]:
        return {}, None

    avg_time_before = sum(filtered_versions[version1]) / len(filtered_versions[version1])
    avg_time_after = sum(filtered_versions[version2]) / len(filtered_versions[version2])

    time_reduction_pct = ((avg_time_before - avg_time_after) / avg_time_before) * 100
    speedup_ratio = avg_time_before / avg_time_after if avg_time_after > 0 else 0

    # Prepare filtered data for plotting
    plot_data = {
        'before': filtered_versions[version1],
        'after': filtered_versions[version2]
    }

    return {
        'before_avg_test_time_s': avg_time_before,
        'after_avg_test_time_s': avg_time_after,
        'test_time_reduction_pct': time_reduction_pct,
        'test_speedup_ratio': speedup_ratio
    }, plot_data


def calculate_execution_metrics(execution_data):
    """Calculate execution time metrics from execution time data with IQR outlier filtering."""
    if not execution_data:
        return {}, None

    # Group by version
    versions = defaultdict(list)
    for row in execution_data:
        version = row['version']
        exec_time = float(row['energibridge_time_sec'])
        versions[version].append(exec_time)

    # Apply IQR outlier filtering to each version
    filtered_versions = {}
    for version in versions:
        filtered_versions[version] = filter_outliers_iqr(versions[version])

    # Sort versions: put "before" first if it exists
    version_names = sorted(filtered_versions.keys(), key=lambda x: (x != 'before', x))

    if len(version_names) < 2:
        return {}, None

    version1 = version_names[0]
    version2 = version_names[1]

    avg_exec_before = sum(filtered_versions[version1]) / len(filtered_versions[version1])
    avg_exec_after = sum(filtered_versions[version2]) / len(filtered_versions[version2])

    exec_reduction_pct = ((avg_exec_before - avg_exec_after) / avg_exec_before) * 100
    exec_speedup_ratio = avg_exec_before / avg_exec_after if avg_exec_after > 0 else 0

    # Prepare filtered data for plotting
    plot_data = {
        'before': filtered_versions[version1],
        'after': filtered_versions[version2]
    }

    return {
        'before_avg_exec_time_s': avg_exec_before,
        'after_avg_exec_time_s': avg_exec_after,
        'exec_time_reduction_pct': exec_reduction_pct,
        'exec_speedup_ratio': exec_speedup_ratio
    }, plot_data


def process_project(project_name, base_dir, log_suffix):
    """Process a single project and return summary metrics and plot data."""
    project_dir = base_dir / project_name

    if not project_dir.exists():
        print(f"Warning: Project directory not found: {project_dir}")
        return None, None

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
        return None, None

    # Calculate metrics
    metrics = {'project_name': project_name}
    plot_data = {}

    energy_metrics, energy_plot_data = calculate_energy_metrics(energy_data)
    metrics.update(energy_metrics)
    if energy_plot_data:
        plot_data['energy'] = energy_plot_data

    duration_metrics, duration_plot_data = calculate_duration_metrics(duration_data)
    metrics.update(duration_metrics)
    if duration_plot_data:
        plot_data['duration'] = duration_plot_data

    execution_metrics, execution_plot_data = calculate_execution_metrics(execution_data)
    metrics.update(execution_metrics)
    if execution_plot_data:
        plot_data['execution'] = execution_plot_data

    # Fill in missing values with N/A
    fieldnames = [
        'project_name',
        'before_data_count',
        'after_data_count',
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

    return metrics, plot_data


def create_violin_plots(all_plot_data, output_dir, log_suffix):
    """
    Create violin plots for all projects showing before and after data.
    Arranges projects in 2 rows with 5 projects per row.

    Args:
        all_plot_data: Dict mapping project names to their plot data
        output_dir: Directory to save the plots
        log_suffix: Suffix for the output filenames
    """
    if not all_plot_data:
        print("No plot data available for visualization.")
        return

    metrics_to_plot = [
        ('energy', 'Energy Consumption (J)', 'energy_violin_plot'),
        ('duration', 'Test Duration (s)', 'duration_violin_plot'),
        ('execution', 'Execution Time (s)', 'execution_violin_plot')
    ]

    for metric_key, ylabel, filename_base in metrics_to_plot:
        # Collect projects that have this metric
        projects_with_metric = {
            proj: data[metric_key]
            for proj, data in all_plot_data.items()
            if metric_key in data
        }

        if not projects_with_metric:
            print(f"No data for {metric_key} metric, skipping plot.")
            continue

        # Sort projects alphabetically for consistent ordering
        sorted_projects = sorted(projects_with_metric.keys())
        n_projects = len(sorted_projects)

        # Determine subplot layout (2 rows, 5 columns max)
        n_cols = min(5, n_projects)
        n_rows = (n_projects + n_cols - 1) // n_cols  # Ceiling division

        # Create figure with subplots
        fig, axes = plt.subplots(n_rows, n_cols, figsize=(4*n_cols, 4*n_rows))

        # Handle case where axes is not an array
        if n_projects == 1:
            axes = [[axes]]
        elif n_rows == 1:
            axes = [axes]
        elif n_cols == 1:
            axes = [[ax] for ax in axes]

        # Plot each project
        for idx, project_name in enumerate(sorted_projects):
            row = idx // n_cols
            col = idx % n_cols
            ax = axes[row][col] if n_rows > 1 else axes[0][col]

            plot_data = projects_with_metric[project_name]
            before_data = plot_data['before']
            after_data = plot_data['after']

            # Create violin plot
            parts = ax.violinplot(
                [before_data, after_data],
                positions=[1, 2],
                showmeans=True,
                showmedians=True,
                widths=0.7
            )

            # Color the violins
            for pc in parts['bodies']:
                pc.set_facecolor('lightblue')
                pc.set_alpha(0.7)

            # Customize plot
            ax.set_xticks([1, 2])
            ax.set_xticklabels(['Before', 'After'])
            ax.set_ylabel(ylabel, fontsize=10)
            ax.set_title(project_name, fontsize=11, fontweight='bold')
            ax.grid(True, alpha=0.3, axis='y')

        # Hide unused subplots
        for idx in range(n_projects, n_rows * n_cols):
            row = idx // n_cols
            col = idx % n_cols
            ax = axes[row][col] if n_rows > 1 else axes[0][col]
            ax.axis('off')

        # Adjust layout and save
        plt.tight_layout()

        if log_suffix:
            output_file = output_dir / f"{filename_base}_{log_suffix}.png"
        else:
            output_file = output_dir / f"{filename_base}.png"

        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        plt.close()

        print(f"Violin plot saved: {output_file}")


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
    all_plot_data = {}
    for project in projects:
        print(f"Processing: {project}...", end=' ')
        metrics, plot_data = process_project(project, script_dir, log_suffix)
        if metrics:
            summary_data.append(metrics)
            if plot_data:
                all_plot_data[project] = plot_data
            print("✓")
        else:
            print("✗ (no data)")

    # Write summary CSV
    if summary_data:
        fieldnames = [
            'project_name',
            'before_data_count',
            'after_data_count',
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

        # Sort summary_data by project_name alphabetically (case-insensitive)
        summary_data.sort(key=lambda x: x['project_name'].lower())

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

        # Create violin plots
        print("\nGenerating violin plots...")
        create_violin_plots(all_plot_data, script_dir, log_suffix)
        print("Violin plots generated successfully!")
    else:
        print("\nNo data could be processed for any project.")
        sys.exit(1)


if __name__ == "__main__":
    main()
