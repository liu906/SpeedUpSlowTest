#!/usr/bin/env python3
"""
Generic script to visualize energy consumption and test duration data.
Creates violin plots comparing before and after versions.
Usage: python3 visualize_results_generic.py <project_path>
Example: python3 visualize_results_generic.py BuffaLogs_399
"""

import csv
import sys
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path


def load_energy_data(csv_file):
    """Load energy data from CSV file."""
    energy_data = {'before': [], 'after': []}

    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            version = row['version']
            energy_joules = float(row['energy_joules'])
            energy_data[version].append(energy_joules)

    return energy_data


def load_duration_data(csv_file):
    """Load test duration data from CSV file."""
    duration_data = {'before': {}, 'after': {}}

    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            version = row['version']
            run_number = int(row['run_number'])
            total_time = float(row['total_test_time'])

            # Store total test time per run (avoid duplicates)
            if run_number not in duration_data[version]:
                duration_data[version][run_number] = total_time

    # Convert to lists
    before_times = list(duration_data['before'].values())
    after_times = list(duration_data['after'].values())

    return {'before': before_times, 'after': after_times}


def print_summary(energy_data, duration_data, project_name):
    """Print summary statistics."""
    print("\n" + "="*60)
    print(f"SUMMARY STATISTICS - {project_name}")
    print("="*60)

    # Energy summary
    if energy_data['before']:
        avg_before = sum(energy_data['before']) / len(energy_data['before'])
        print(f"\nBefore version - Energy consumption:")
        print(f"  Runs: {len(energy_data['before'])}")
        print(f"  Average: {avg_before:.2f} J")
        print(f"  Min: {min(energy_data['before']):.2f} J")
        print(f"  Max: {max(energy_data['before']):.2f} J")

    if energy_data['after']:
        avg_after = sum(energy_data['after']) / len(energy_data['after'])
        print(f"\nAfter version - Energy consumption:")
        print(f"  Runs: {len(energy_data['after'])}")
        print(f"  Average: {avg_after:.2f} J")
        print(f"  Min: {min(energy_data['after']):.2f} J")
        print(f"  Max: {max(energy_data['after']):.2f} J")

    if energy_data['before'] and energy_data['after']:
        improvement = ((avg_before - avg_after) / avg_before) * 100
        print(f"\nEnergy improvement: {improvement:.2f}%")

    # Duration summary
    if duration_data['before'] and duration_data['after']:
        avg_before_time = sum(duration_data['before']) / len(duration_data['before'])
        avg_after_time = sum(duration_data['after']) / len(duration_data['after'])
        time_improvement = ((avg_before_time - avg_after_time) / avg_before_time) * 100

        print(f"\n\nTest Duration Summary:")
        print(f"  Average total test time (before): {avg_before_time:.3f}s")
        print(f"  Average total test time (after): {avg_after_time:.3f}s")
        print(f"  Time improvement: {time_improvement:.2f}%")

    print("\n" + "="*60 + "\n")


def create_violin_plots(energy_data, duration_data, output_dir, project_name):
    """Create violin plots for energy and duration comparison."""

    # Set style
    sns.set_style("whitegrid")
    sns.set_palette("Set2")

    # Create figure with two subplots
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

    # Add overall title
    fig.suptitle(f'Performance Comparison - {project_name}', fontsize=16, fontweight='bold')

    # Prepare data for violin plots
    energy_plot_data = []
    energy_labels = []
    for version in ['before', 'after']:
        if energy_data[version]:
            energy_plot_data.append(energy_data[version])
            energy_labels.append(version.capitalize())

    duration_plot_data = []
    duration_labels = []
    for version in ['before', 'after']:
        if duration_data[version]:
            duration_plot_data.append(duration_data[version])
            duration_labels.append(version.capitalize())

    # Plot 1: Energy consumption
    if energy_plot_data:
        parts1 = ax1.violinplot(energy_plot_data, positions=list(range(1, len(energy_plot_data) + 1)),
                                showmeans=True, showmedians=True)
        ax1.set_title('Energy Consumption Comparison', fontsize=14, fontweight='bold')
        ax1.set_ylabel('Energy (Joules)', fontsize=12)
        ax1.set_xlabel('Version', fontsize=12)
        ax1.set_xticks(list(range(1, len(energy_labels) + 1)))
        ax1.set_xticklabels(energy_labels)
        ax1.grid(True, alpha=0.3)

        # Add mean values as text
        for i, data in enumerate(energy_plot_data, 1):
            mean_val = sum(data) / len(data)
            ax1.text(i, mean_val, f'{mean_val:.2f} J', ha='center', va='bottom', fontweight='bold')
    else:
        ax1.text(0.5, 0.5, 'No energy data available', ha='center', va='center', transform=ax1.transAxes)
        ax1.set_title('Energy Consumption Comparison', fontsize=14, fontweight='bold')

    # Plot 2: Test duration
    if duration_plot_data:
        parts2 = ax2.violinplot(duration_plot_data, positions=list(range(1, len(duration_plot_data) + 1)),
                                showmeans=True, showmedians=True)
        ax2.set_title('Test Execution Time Comparison', fontsize=14, fontweight='bold')
        ax2.set_ylabel('Time (seconds)', fontsize=12)
        ax2.set_xlabel('Version', fontsize=12)
        ax2.set_xticks(list(range(1, len(duration_labels) + 1)))
        ax2.set_xticklabels(duration_labels)
        ax2.grid(True, alpha=0.3)

        # Add mean values as text
        for i, data in enumerate(duration_plot_data, 1):
            mean_val = sum(data) / len(data)
            ax2.text(i, mean_val, f'{mean_val:.3f} s', ha='center', va='bottom', fontweight='bold')
    else:
        ax2.text(0.5, 0.5, 'No duration data available', ha='center', va='center', transform=ax2.transAxes)
        ax2.set_title('Test Execution Time Comparison', fontsize=14, fontweight='bold')

    # Adjust layout and save
    plt.tight_layout()
    output_file = output_dir / 'comparison_violin_plots.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"Violin plots saved to: {output_file}")

    # Show the plot
    plt.show()


def main():
    # Check if project path is provided
    if len(sys.argv) < 2:
        print("Error: Project path is required")
        print("Usage: python3 visualize_results_generic.py <project_path>")
        print("Example: python3 visualize_results_generic.py BuffaLogs_399")
        sys.exit(1)

    project_path = sys.argv[1]
    script_dir = Path(__file__).parent
    project_dir = script_dir / project_path

    # Check if project directory exists
    if not project_dir.exists():
        print(f"Error: Project directory not found: {project_dir}")
        sys.exit(1)

    energy_csv = project_dir / "energy_data.csv"
    duration_csv = project_dir / "duration_data.csv"

    print(f"Loading data from: {project_dir}")
    print(f"Energy data: {energy_csv}")
    print(f"Duration data: {duration_csv}")

    if not energy_csv.exists():
        print(f"Error: Energy data file not found at {energy_csv}")
        print("Please run parse_results_generic.py first")
        sys.exit(1)

    if not duration_csv.exists():
        print(f"Error: Duration data file not found at {duration_csv}")
        print("Please run parse_results_generic.py first")
        sys.exit(1)

    # Load data
    energy_data = load_energy_data(energy_csv)
    duration_data = load_duration_data(duration_csv)

    # Print summary
    print_summary(energy_data, duration_data, project_path)

    # Create violin plots
    print("Generating violin plots...")
    create_violin_plots(energy_data, duration_data, project_dir, project_path)

    print("\nVisualization complete!")


if __name__ == "__main__":
    main()
