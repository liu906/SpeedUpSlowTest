#!/usr/bin/env python3
"""
Optimized script to parse test results, extract data, and generate visualizations.

Usage: python3 parse_results_generic_optimized.py <project_path> <log_suffix> [--debug]
Example: python3 parse_results_generic_optimized.py bilby_986 mock

This script parses test result logs to extract:
- Energy consumption data (joules, watts, execution time)
- Test duration data (individual test times, total test time)
- Automatically generates violin plots for visualization

The script handles various pytest output formats automatically.

File naming:
- Input: test_results_<log_suffix>.log (e.g., test_results_mock.log)
- Output: energy_data_<log_suffix>.csv, duration_data_<log_suffix>.csv, etc.
- Plots: comparison_violin_plots.png

Version: 2.5 (Visualization now runs automatically after data extraction)
"""

import re
import csv
import sys
from pathlib import Path
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
import seaborn as sns


def parse_log_file(log_file_path, debug=False):
    """Parse the test results log file and extract energy and duration data (optimized).

    Args:
        log_file_path: Path to the test results log file
        debug: If True, print debug information during parsing

    Returns:
        Tuple of (energy_data, duration_data, execution_time_data) lists
    """
    energy_data = []
    duration_data = []
    execution_time_data = []  # New: Track energibridge-measured execution times

    # State machine variables
    current_version = None
    current_run_number = None
    in_slowest_durations = False
    pending_durations = []  # Temporary storage for durations in current test run

    # Debug counters
    debug_counters = {
        'total_time_matches': 0,
        'duration_entries': 0,
        'energy_entries': 0,
        'execution_time_entries': 0,
    } if debug else None

    # Pre-compiled regex patterns for better performance (flexible to match any version name)
    # Updated to match version names with underscores (e.g., "after_mock")
    version_pattern = re.compile(r'Starting tests for ([\w_]+) version')
    test_run_pattern = re.compile(r'Test run (\d+)/\d+ for ([\w_]+)')
    energy_pattern = re.compile(r'Energy consumption in joules: ([\d.]+) for ([\d.]+) sec of execution\.')
    slowest_start_pattern = re.compile(r'={20,}\s+slowest durations\s+={20,}')
    test_duration_pattern = re.compile(r'([\d.]+)s\s+(\w+)\s+(.+?)$')
    # Improved pattern to match various pytest output formats:
    # - "in 30.24s =" (with = after s)
    # - "in 30.24s " (with space after s)
    # - "in 30.24s" (nothing after s, end of line or more =)
    total_time_pattern = re.compile(r'in\s+([\d.]+)s(?:\s|=|$)')

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

                    # Also track execution time separately for comparison with pytest times
                    execution_time_data.append({
                        'version': current_version,
                        'run_number': current_run_number,
                        'energibridge_time_sec': execution_time_sec
                    })

                    if debug:
                        debug_counters['energy_entries'] += 1
                        debug_counters['execution_time_entries'] += 1

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

                    if debug:
                        debug_counters['total_time_matches'] += 1
                        print(f"[DEBUG] Found total time: {total_test_time}s for {current_version} run {current_run_number}")
                        print(f"[DEBUG] Updating {len(pending_durations)} pending duration entries")

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

                    if debug:
                        debug_counters['duration_entries'] += 1

    # Print debug summary if enabled
    if debug and debug_counters:
        print("\n[DEBUG] Parsing Summary:")
        print(f"  Total time matches found: {debug_counters['total_time_matches']}")
        print(f"  Duration entries parsed: {debug_counters['duration_entries']}")
        print(f"  Energy entries parsed: {debug_counters['energy_entries']}")
        print(f"  Execution time entries parsed: {debug_counters['execution_time_entries']}")

    return energy_data, duration_data, execution_time_data


def save_to_csv(data, csv_file_path, fieldnames):
    """Save data to CSV file."""
    with open(csv_file_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)


def print_summary(energy_data, duration_data, execution_time_data):
    """Print summary statistics."""
    print("\n" + "="*60)
    print("EXTRACTION SUMMARY")
    print("="*60)

    # Detect version names dynamically from the data
    version_names = list(set(d['version'] for d in energy_data))

    # Sort versions: put "before" first if it exists, otherwise alphabetical
    if 'before' in version_names:
        version_names.sort(key=lambda x: (x != 'before', x))
    else:
        version_names.sort()

    # Try to identify first and second versions
    version1 = version_names[0] if len(version_names) > 0 else 'before'
    version2 = version_names[1] if len(version_names) > 1 else 'after'

    # Energy summary
    energy_before = [d for d in energy_data if d['version'] == version1]
    energy_after = [d for d in energy_data if d['version'] == version2]

    print(f"\nEnergy data extracted:")
    print(f"  {version1} version: {len(energy_before)} entries")
    print(f"  {version2} version: {len(energy_after)} entries")

    if energy_before:
        avg_energy_before = sum(d['energy_joules'] for d in energy_before) / len(energy_before)
        print(f"  Average energy ({version1}): {avg_energy_before:.2f} J")

    if energy_after:
        avg_energy_after = sum(d['energy_joules'] for d in energy_after) / len(energy_after)
        print(f"  Average energy ({version2}): {avg_energy_after:.2f} J")

    if energy_before and energy_after:
        energy_reduction_pct = ((avg_energy_before - avg_energy_after) / avg_energy_before) * 100
        energy_saved = avg_energy_before - avg_energy_after
        energy_ratio = avg_energy_before / avg_energy_after
        print(f"  Energy ratio: {energy_ratio:.2f}x more energy consumed in '{version1}'")
        print(f"  Energy reduction: {energy_reduction_pct:.2f}%")
        print(f"  Energy saved: {energy_saved:.2f} J ({version1}: {avg_energy_before:.2f} J → {version2}: {avg_energy_after:.2f} J)")

    # Duration summary
    duration_before = [d for d in duration_data if d['version'] == version1]
    duration_after = [d for d in duration_data if d['version'] == version2]

    print(f"\nTest duration data extracted:")
    print(f"  {version1} version: {len(duration_before)} entries")
    print(f"  {version2} version: {len(duration_after)} entries")

    # Calculate average test durations
    if duration_before:
        avg_duration_before = sum(d['duration_sec'] for d in duration_before) / len(duration_before)
        print(f"  Average test duration ({version1}): {avg_duration_before:.3f}s")

    if duration_after:
        avg_duration_after = sum(d['duration_sec'] for d in duration_after) / len(duration_after)
        print(f"  Average test duration ({version2}): {avg_duration_after:.3f}s")

    if duration_before and duration_after:
        time_reduction_pct = ((avg_duration_before - avg_duration_after) / avg_duration_before) * 100
        if avg_duration_after > 0:
            time_speedup = avg_duration_before / avg_duration_after
            print(f"  Speed ratio: {time_speedup:.2f}x faster in '{version2}'")
        else:
            print(f"  Speed ratio: Unable to calculate (after duration is 0.00s - tests too fast to measure)")
        print(f"  Time reduction: {time_reduction_pct:.2f}%")

    # Calculate total test time (average across runs)
    if duration_before:
        # Get unique run numbers and their total_test_time
        before_runs = {}
        for d in duration_before:
            run_num = d['run_number']
            if run_num not in before_runs and d['total_test_time'] is not None:
                before_runs[run_num] = d['total_test_time']

        if before_runs:
            avg_total_before = sum(before_runs.values()) / len(before_runs)
            print(f"  Average total test time ({version1}): {avg_total_before:.2f}s")

    if duration_after:
        # Get unique run numbers and their total_test_time
        after_runs = {}
        for d in duration_after:
            run_num = d['run_number']
            if run_num not in after_runs and d['total_test_time'] is not None:
                after_runs[run_num] = d['total_test_time']

        if after_runs:
            avg_total_after = sum(after_runs.values()) / len(after_runs)
            print(f"  Average total test time ({version2}): {avg_total_after:.2f}s")

    if duration_before and duration_after and before_runs and after_runs:
        total_time_reduction_pct = ((avg_total_before - avg_total_after) / avg_total_before) * 100
        total_time_speedup = avg_total_before / avg_total_after
        print(f"  Total test speed ratio: {total_time_speedup:.2f}x faster in '{version2}'")
        print(f"  Total test time reduction: {total_time_reduction_pct:.2f}%")

    # Execution time comparison (energibridge vs pytest)
    exec_time_before = [d for d in execution_time_data if d['version'] == version1]
    exec_time_after = [d for d in execution_time_data if d['version'] == version2]

    print(f"\nExecution time comparison (Energibridge vs Pytest):")
    print(f"  Energibridge entries: {version1}={len(exec_time_before)}, {version2}={len(exec_time_after)}")

    if exec_time_before:
        avg_exec_time_before = sum(d['energibridge_time_sec'] for d in exec_time_before) / len(exec_time_before)
        print(f"  Average energibridge time ({version1}): {avg_exec_time_before:.2f}s")

    if exec_time_after:
        avg_exec_time_after = sum(d['energibridge_time_sec'] for d in exec_time_after) / len(exec_time_after)
        print(f"  Average energibridge time ({version2}): {avg_exec_time_after:.2f}s")

    if exec_time_before and exec_time_after:
        exec_time_reduction_pct = ((avg_exec_time_before - avg_exec_time_after) / avg_exec_time_before) * 100
        exec_time_speedup = avg_exec_time_before / avg_exec_time_after
        print(f"  Energibridge speed ratio: {exec_time_speedup:.2f}x faster in '{version2}'")
        print(f"  Energibridge time reduction: {exec_time_reduction_pct:.2f}%")

    # Compare energibridge time vs pytest time
    if exec_time_before and duration_before and before_runs:
        time_diff_before = avg_exec_time_before - avg_total_before
        time_diff_pct_before = (time_diff_before / avg_total_before) * 100
        print(f"  Time difference {version1} (energibridge - pytest): {time_diff_before:+.2f}s ({time_diff_pct_before:+.2f}%)")

    if exec_time_after and duration_after and after_runs:
        time_diff_after = avg_exec_time_after - avg_total_after
        time_diff_pct_after = (time_diff_after / avg_total_after) * 100
        print(f"  Time difference {version2} (energibridge - pytest): {time_diff_after:+.2f}s ({time_diff_pct_after:+.2f}%)")

    print("\n" + "="*60 + "\n")


def prepare_data_for_visualization(energy_data, duration_data, execution_time_data):
    """Convert parsed data into format suitable for visualization."""
    # Get version names
    version_names = list(set(d['version'] for d in energy_data))
    if 'before' in version_names:
        version_names.sort(key=lambda x: (x != 'before', x))
    else:
        version_names.sort()

    version1 = version_names[0] if len(version_names) > 0 else 'before'
    version2 = version_names[1] if len(version_names) > 1 else 'after'

    # Prepare energy data
    energy_viz = {
        version1: [d['energy_joules'] for d in energy_data if d['version'] == version1],
        version2: [d['energy_joules'] for d in energy_data if d['version'] == version2]
    }

    # Prepare duration data (total test times only)
    duration_viz = {version1: {}, version2: {}}
    for d in duration_data:
        version = d['version']
        run_num = d['run_number']
        if version in [version1, version2] and d['total_test_time'] is not None:
            if run_num not in duration_viz[version]:
                duration_viz[version][run_num] = d['total_test_time']

    duration_viz[version1] = list(duration_viz[version1].values())
    duration_viz[version2] = list(duration_viz[version2].values())

    # Prepare execution time data
    execution_viz = {
        version1: [d['energibridge_time_sec'] for d in execution_time_data if d['version'] == version1],
        version2: [d['energibridge_time_sec'] for d in execution_time_data if d['version'] == version2]
    }

    return energy_viz, duration_viz, execution_viz, version1, version2


def create_violin_plots(energy_data, duration_data, execution_data, version1, version2, output_dir, project_name, log_suffix):
    """Create violin plots for energy, duration, and execution time comparison."""

    # Set style
    sns.set_style("whitegrid")
    sns.set_palette("Set2")

    # Create figure with three subplots
    fig, (ax1, ax2, ax3) = plt.subplots(1, 3, figsize=(20, 6))

    # Add overall title
    fig.suptitle(f'Performance Comparison - {project_name}', fontsize=16, fontweight='bold')

    # Prepare data for violin plots
    energy_plot_data = []
    energy_labels = []
    for version in [version1, version2]:
        if energy_data.get(version):
            energy_plot_data.append(energy_data[version])
            energy_labels.append(version.replace('_', ' ').title())

    duration_plot_data = []
    duration_labels = []
    for version in [version1, version2]:
        if duration_data.get(version):
            duration_plot_data.append(duration_data[version])
            duration_labels.append(version.replace('_', ' ').title())

    execution_plot_data = []
    execution_labels = []
    for version in [version1, version2]:
        if execution_data.get(version):
            execution_plot_data.append(execution_data[version])
            execution_labels.append(version.replace('_', ' ').title())

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

    # Plot 2: Test duration (Pytest)
    if duration_plot_data:
        parts2 = ax2.violinplot(duration_plot_data, positions=list(range(1, len(duration_plot_data) + 1)),
                                showmeans=True, showmedians=True)
        ax2.set_title('Test Time - Pytest Measured', fontsize=14, fontweight='bold')
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
        ax2.set_title('Test Time - Pytest Measured', fontsize=14, fontweight='bold')

    # Plot 3: Execution time (Energibridge)
    if execution_plot_data:
        parts3 = ax3.violinplot(execution_plot_data, positions=list(range(1, len(execution_plot_data) + 1)),
                                showmeans=True, showmedians=True)
        ax3.set_title('Execution Time - Energibridge Measured', fontsize=14, fontweight='bold')
        ax3.set_ylabel('Time (seconds)', fontsize=12)
        ax3.set_xlabel('Version', fontsize=12)
        ax3.set_xticks(list(range(1, len(execution_labels) + 1)))
        ax3.set_xticklabels(execution_labels)
        ax3.grid(True, alpha=0.3)

        # Add mean values as text
        for i, data in enumerate(execution_plot_data, 1):
            mean_val = sum(data) / len(data)
            ax3.text(i, mean_val, f'{mean_val:.3f} s', ha='center', va='bottom', fontweight='bold')
    else:
        ax3.text(0.5, 0.5, 'No execution time data available', ha='center', va='center', transform=ax3.transAxes)
        ax3.set_title('Execution Time - Energibridge Measured', fontsize=14, fontweight='bold')

    # Adjust layout and save
    plt.tight_layout()
    # Construct output filename using log_suffix
    if log_suffix:
        output_file = output_dir / f'comparison_violin_plots_{log_suffix}.png'
    else:
        output_file = output_dir / f'comparison_violin_plots.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"\nViolin plots saved to: {output_file}")
    plt.close()


def main():
    # Check if required arguments are provided
    if len(sys.argv) < 3:
        print("Error: Missing required arguments")
        print("Usage: python3 parse_results_generic_optimized.py <project_path> <log_suffix> [--debug]")
        print("Example: python3 parse_results_generic_optimized.py bilby_986 mock")
        print("\nArguments:")
        print("  project_path    Project directory name (e.g., bilby_986)")
        print("  log_suffix      Log file suffix (e.g., 'mock' for test_results_mock.log)")
        print("\nOptions:")
        print("  --debug         Enable debug output during parsing")
        print("\nThe script will look for test_results_<log_suffix>.log")
        print("and create CSV files with the same suffix pattern.")
        print("Visualization plots are generated automatically.")
        sys.exit(1)

    project_path = sys.argv[1]
    log_suffix = sys.argv[2]
    debug_mode = '--debug' in sys.argv

    script_dir = Path(__file__).parent
    project_dir = script_dir / project_path

    # Check if project directory exists
    if not project_dir.exists():
        print(f"Error: Project directory not found: {project_dir}")
        sys.exit(1)

    # Construct file names using log_suffix parameter
    # Handle empty suffix (for test_results.log)
    if log_suffix:
        log_file = project_dir / f"test_results_{log_suffix}.log"
        energy_csv = project_dir / f"energy_data_{log_suffix}.csv"
        duration_csv = project_dir / f"duration_data_{log_suffix}.csv"
        execution_time_csv = project_dir / f"execution_time_data_{log_suffix}.csv"
    else:
        log_file = project_dir / "test_results.log"
        energy_csv = project_dir / "energy_data.csv"
        duration_csv = project_dir / "duration_data.csv"
        execution_time_csv = project_dir / "execution_time_data.csv"

    # Check if log file exists
    if not log_file.exists():
        print(f"Error: Log file not found: {log_file}")
        print(f"Please run the tests first to generate the log file")
        sys.exit(1)

    print(f"Parsing test results from: {log_file}")
    if debug_mode:
        print("[DEBUG] Debug mode enabled")

    # Parse the log file
    energy_data, duration_data, execution_time_data = parse_log_file(log_file, debug=debug_mode)

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

    if execution_time_data:
        save_to_csv(execution_time_data, execution_time_csv,
                   ['version', 'run_number', 'energibridge_time_sec'])
        print(f"Execution time data saved to: {execution_time_csv}")
    else:
        print("Warning: No execution time data found in log file")

    # Print summary
    print_summary(energy_data, duration_data, execution_time_data)

    # Generate plots automatically
    print("\n" + "="*60)
    print("GENERATING VISUALIZATIONS")
    print("="*60)
    try:
        energy_viz, duration_viz, execution_viz, version1, version2 = prepare_data_for_visualization(
            energy_data, duration_data, execution_time_data
        )
        create_violin_plots(energy_viz, duration_viz, execution_viz, version1, version2,
                          project_dir, project_path, log_suffix)
        print("\nVisualization complete!")
    except Exception as e:
        print(f"\nWarning: Failed to generate plots: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
