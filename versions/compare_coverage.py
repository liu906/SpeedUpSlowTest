#!/usr/bin/env python3
"""
Compare code coverage between two versions (e.g., before and after mocking).

Usage:
    python3 compare_coverage.py <project_name> <folder1> <folder2> [suffix]

Examples:
    python3 compare_coverage.py python-dts-calibration_197 before after_careful_mock
    python3 compare_coverage.py python-dts-calibration_197 before after_careful_mock only_mock_part
    python3 compare_coverage.py autosubmit_2367 before after
"""

import json
import sys
import os
import subprocess
from pathlib import Path
from typing import Dict, Any, Tuple


def generate_coverage_json(version_dir: Path, version_name: str, suffix: str = "") -> Path:
    """
    Generate coverage JSON file from raw coverage data.
    Handles both standard .coverage files and parallel coverage files.

    Returns the path to the generated JSON file.
    """
    json_filename = f"coverage_{version_name}_{suffix}.json" if suffix else f"coverage_{version_name}.json"
    json_path = version_dir / json_filename

    # Check if JSON already exists in the main directory
    if json_path.exists():
        return json_path

    # Check if JSON already exists in common subdirectories (for Django projects, etc.)
    for subdir_name in ["bundle-workflow", "src", ".", "*"]:
        if subdir_name == "*":
            # Check all subdirectories for JSON files
            for subdir_path in version_dir.iterdir():
                if subdir_path.is_dir():
                    sub_json = subdir_path / json_filename
                    if sub_json.exists():
                        print(f"  Found existing JSON file in subdirectory: {sub_json}")
                        return sub_json
        else:
            subdir_path = version_dir / subdir_name
            if subdir_path.is_dir():
                sub_json = subdir_path / json_filename
                if sub_json.exists():
                    print(f"  Found existing JSON file in subdirectory: {sub_json}")
                    return sub_json

    print(f"  JSON file not found, attempting to generate it from coverage data...")

    # Look for coverage data files
    coverage_file = version_dir / ".coverage"
    parallel_files = list(version_dir.glob(".coverage.*")) + list(version_dir.glob("*.cov.*"))

    # Determine the working directory (might be in a subdirectory)
    work_dirs = [version_dir]

    # Check common subdirectories
    for subdir_name in ["bundle-workflow", "src", "."]:
        subdir_path = version_dir / subdir_name
        if subdir_path.is_dir():
            sub_coverage = subdir_path / ".coverage"
            sub_parallel = list(subdir_path.glob(".coverage.*")) + list(subdir_path.glob("*.cov.*"))
            if sub_coverage.exists() or sub_parallel:
                work_dirs.insert(0, subdir_path)

    # Also check ALL subdirectories (for Django projects with app-named directories like "buffalogs")
    for subdir_path in version_dir.iterdir():
        if subdir_path.is_dir() and subdir_path not in work_dirs:
            sub_coverage = subdir_path / ".coverage"
            sub_parallel = list(subdir_path.glob(".coverage.*")) + list(subdir_path.glob("*.cov.*"))
            if sub_coverage.exists() or sub_parallel:
                work_dirs.insert(0, subdir_path)

    for work_dir in work_dirs:
        coverage_file = work_dir / ".coverage"
        parallel_files = list(work_dir.glob(".coverage.*")) + list(work_dir.glob("*.cov.*"))

        if not coverage_file.exists() and parallel_files:
            # Need to combine parallel coverage files first
            print(f"  Found {len(parallel_files)} parallel coverage files in {work_dir}, combining...")
            try:
                result = subprocess.run(
                    ["coverage", "combine"],
                    cwd=work_dir,
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                if result.returncode != 0:
                    print(f"  Warning: coverage combine failed: {result.stderr}")
                    continue
                print(f"  Successfully combined coverage data")
            except Exception as e:
                print(f"  Warning: Failed to combine coverage: {e}")
                continue

        # Check for .coverage or custom coverage data file
        coverage_data_file = None
        if (work_dir / ".coverage").exists():
            coverage_data_file = work_dir / ".coverage"
        else:
            # Check for custom coverage files (e.g., coverage_results.cov)
            # Look for files that don't have the parallel suffix pattern
            for pattern in ["*.cov", "coverage_results*", ".coverage"]:
                potential_files = list(work_dir.glob(pattern))
                for f in potential_files:
                    # Skip parallel files (they have hostname.PID.random in name)
                    if '.' in f.stem and not f.name.endswith('.cov'):
                        continue
                    if f.is_file() and f.suffix in ['.cov', ''] and 'cov.' not in f.name:
                        coverage_data_file = f
                        break
                if coverage_data_file:
                    break

        if coverage_data_file and coverage_data_file.exists():
            # Generate JSON report
            print(f"  Generating JSON report from {coverage_data_file}...")

            # Determine output path
            if work_dir != version_dir:
                output_path = version_dir / json_filename
            else:
                output_path = json_path

            # Check if source directory exists to apply --include filter
            include_filter = []
            if (work_dir / "src").is_dir():
                include_filter = ["--include=src/*"]
            elif (work_dir / "armi").is_dir():
                include_filter = ["--include=armi/*"]

            # First try with include filter
            try:
                result = subprocess.run(
                    ["coverage", "json", "-o", str(output_path)] + include_filter,
                    cwd=work_dir,
                    capture_output=True,
                    text=True,
                    timeout=60
                )

                # If it failed with "No data to report" and we used a filter, try without filter
                # Note: "No data to report" can appear in either stdout or stderr
                if result.returncode != 0:
                    error_output = result.stderr + result.stdout
                    if "No data to report" in error_output and include_filter:
                        print(f"  No data with filter, retrying without filter...")
                        result = subprocess.run(
                            ["coverage", "json", "-o", str(output_path)],
                            cwd=work_dir,
                            capture_output=True,
                            text=True,
                            timeout=60
                        )

                # If failed due to missing source files (dynamic code), try to clean and regenerate
                if result.returncode != 0:
                    error_msg = result.stderr if result.stderr else result.stdout
                    if "No source for code:" in error_msg:
                        print(f"  Detected dynamically generated code, attempting to clean coverage data...")
                        # Create a temporary cleaned coverage database
                        import tempfile
                        import shutil

                        try:
                            # Import coverage module from system path
                            import sys
                            sys.path.insert(0, '/usr/local/lib/python3.10/dist-packages')
                            import coverage

                            # Load the original coverage data
                            cov = coverage.Coverage(data_file=str(coverage_data_file))
                            cov.load()
                            data = cov.get_data()

                            # Get all measured files and filter out non-existent ones
                            all_files = list(data.measured_files())
                            non_existent = [f for f in all_files if not os.path.exists(f)]

                            if non_existent:
                                print(f"  Found {len(non_existent)} dynamically generated files to exclude")

                                # Create a temporary cleaned coverage file
                                with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.coverage') as tmp:
                                    temp_cov_file = tmp.name

                                try:
                                    # Create new coverage object with branch support
                                    new_cov = coverage.Coverage(data_file=temp_cov_file, branch=True)

                                    # Copy data for files that exist
                                    # Collect all lines and arcs first, then add them together
                                    new_data = coverage.CoverageData(basename=temp_cov_file)
                                    lines_dict = {}
                                    arcs_dict = {}

                                    for filename in all_files:
                                        if os.path.exists(filename):
                                            # Get the line data for this file
                                            lines = data.lines(filename)
                                            if lines:
                                                lines_dict[filename] = lines

                                            # Get the arc data (branch coverage) for this file
                                            arcs = data.arcs(filename)
                                            if arcs:
                                                arcs_dict[filename] = arcs

                                    # Add arcs first (branch coverage), then lines for files without arcs
                                    if arcs_dict:
                                        new_data.add_arcs(arcs_dict)

                                    # Add line-only data for files that don't have arc data
                                    lines_only = {f: l for f, l in lines_dict.items() if f not in arcs_dict}
                                    if lines_only:
                                        new_data.add_lines(lines_only)

                                    # Save the new data
                                    new_data.write()

                                    # Generate JSON from the cleaned data
                                    result = subprocess.run(
                                        ["coverage", "json", "-o", str(output_path), "--data-file", temp_cov_file] + include_filter,
                                        cwd=work_dir,
                                        capture_output=True,
                                        text=True,
                                        timeout=60
                                    )

                                    if result.returncode == 0:
                                        print(f"  ✓ Successfully generated JSON from cleaned coverage data")

                                finally:
                                    # Clean up temp file
                                    try:
                                        os.unlink(temp_cov_file)
                                    except:
                                        pass

                        except ImportError as e:
                            print(f"  Warning: coverage module not available: {e}")
                        except Exception as e:
                            print(f"  Warning: Failed to clean coverage data: {e}")

                    # Final check
                    if result.returncode != 0:
                        error_msg = result.stderr if result.stderr else result.stdout
                        print(f"  Warning: coverage json failed: {error_msg}")
                        continue

                if output_path.exists():
                    print(f"  ✓ Successfully generated {output_path}")
                    return output_path
            except Exception as e:
                print(f"  Warning: Failed to generate JSON: {e}")
                continue

    # If we get here, we couldn't generate the JSON
    raise FileNotFoundError(f"Could not generate coverage JSON file: {json_path}")


def load_coverage_json(filepath: Path) -> Dict[str, Any]:
    """Load coverage data from JSON file."""
    if not filepath.exists():
        raise FileNotFoundError(f"Coverage file not found: {filepath}")

    with open(filepath, 'r') as f:
        return json.load(f)


def extract_file_basename(filepath: str) -> str:
    """Extract just the filename from a full path."""
    return os.path.basename(filepath)


def compare_coverage(
    before_data: Dict[str, Any],
    after_data: Dict[str, Any],
    folder1_name: str,
    folder2_name: str
) -> None:
    """Compare coverage data between two versions and print results."""

    # Extract totals
    before_total = before_data['totals']
    after_total = after_data['totals']

    print("=" * 80)
    print("CODE COVERAGE COMPARISON")
    print("=" * 80)
    print()

    # Overall comparison
    print(f"{'Metric':<30} {folder1_name:>15} {folder2_name:>15} {'Difference':>15}")
    print("-" * 80)

    # Store overall totals for use in summary (before they get overwritten by file-level loop)
    overall_before_pct = before_total['percent_covered']
    overall_after_pct = after_total['percent_covered']
    overall_diff_pct = overall_after_pct - overall_before_pct

    print(f"{'Total Coverage (%)':<30} {overall_before_pct:>14.2f}% {overall_after_pct:>14.2f}% {overall_diff_pct:>+14.2f}%")

    # Detailed metrics
    metrics = [
        ('covered_lines', 'Lines Covered'),
        ('num_statements', 'Total Statements'),
        ('missing_lines', 'Missing Lines'),
        ('num_branches', 'Total Branches'),
        ('covered_branches', 'Branches Covered'),
        ('missing_branches', 'Missing Branches'),
    ]

    for key, label in metrics:
        before_val = before_total.get(key, 0)
        after_val = after_total.get(key, 0)
        diff_val = after_val - before_val
        print(f"{label:<30} {before_val:>15} {after_val:>15} {diff_val:>+15}")

    print()

    # Branch coverage percentage
    if before_total.get('num_branches', 0) > 0 or after_total.get('num_branches', 0) > 0:
        before_branch_pct = (before_total.get('covered_branches', 0) /
                             before_total.get('num_branches', 1)) * 100
        after_branch_pct = (after_total.get('covered_branches', 0) /
                           after_total.get('num_branches', 1)) * 100
        diff_branch_pct = after_branch_pct - before_branch_pct

        print(f"{'Branch Coverage (%)':<30} {before_branch_pct:>14.2f}% {after_branch_pct:>14.2f}% {diff_branch_pct:>+14.2f}%")
        print()

    # File-level comparison
    print("=" * 80)
    print("FILE-LEVEL COVERAGE COMPARISON")
    print("=" * 80)
    print()

    # Create mapping of filenames to full paths
    before_files = {extract_file_basename(path): (path, data)
                   for path, data in before_data['files'].items()}
    after_files = {extract_file_basename(path): (path, data)
                  for path, data in after_data['files'].items()}

    # Get all unique filenames
    all_files = sorted(set(before_files.keys()) | set(after_files.keys()))

    print(f"{'File':<40} {folder1_name:>15} {folder2_name:>15} {'Difference':>15}")
    print("-" * 80)

    for filename in all_files:
        before_info = before_files.get(filename)
        after_info = after_files.get(filename)

        if before_info and after_info:
            before_pct = before_info[1]['summary']['percent_covered']
            after_pct = after_info[1]['summary']['percent_covered']
            diff_pct = after_pct - before_pct

            # Highlight significant changes
            marker = ""
            if abs(diff_pct) > 5:
                marker = " ***" if diff_pct > 0 else " !!!"

            print(f"{filename:<40} {before_pct:>14.2f}% {after_pct:>14.2f}% {diff_pct:>+14.2f}%{marker}")
        elif before_info:
            before_pct = before_info[1]['summary']['percent_covered']
            print(f"{filename:<40} {before_pct:>14.2f}% {'N/A':>15} {'REMOVED':>15}")
        else:
            after_pct = after_info[1]['summary']['percent_covered']
            print(f"{filename:<40} {'N/A':>15} {after_pct:>14.2f}% {'NEW FILE':>15}")

    print()
    print("Legend:")
    print("  *** = Significant improvement (>5%)")
    print("  !!! = Significant decrease (>5%)")
    print()

    # Summary
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print()

    if abs(overall_diff_pct) < 0.01:
        print(f"✓ Coverage is IDENTICAL between {folder1_name} and {folder2_name}")
        print(f"  Both versions have {overall_before_pct:.2f}% coverage")
        print(f"  This suggests that mocking did NOT reduce test effectiveness")
    elif overall_diff_pct > 0:
        print(f"✓ Coverage INCREASED by {overall_diff_pct:.2f}%")
        print(f"  {folder1_name}: {overall_before_pct:.2f}%")
        print(f"  {folder2_name}: {overall_after_pct:.2f}%")
        print(f"  Mocking may have enabled additional code paths to be tested")
    else:
        print(f"⚠ Coverage DECREASED by {abs(overall_diff_pct):.2f}%")
        print(f"  {folder1_name}: {overall_before_pct:.2f}%")
        print(f"  {folder2_name}: {overall_after_pct:.2f}%")
        print(f"  Review the mocking implementation - some code may no longer be executed")

    print()


def main():
    """Main entry point."""
    if len(sys.argv) < 4:
        print("Usage: python3 compare_coverage.py <project_name> <folder1> <folder2> [suffix]")
        print()
        print("Examples:")
        print("  python3 compare_coverage.py python-dts-calibration_197 before after_careful_mock")
        print("  python3 compare_coverage.py python-dts-calibration_197 before after_careful_mock only_mock_part")
        print("  python3 compare_coverage.py autosubmit_2367 before after")
        sys.exit(1)

    project_name = sys.argv[1]
    folder1 = sys.argv[2]
    folder2 = sys.argv[3]
    suffix = sys.argv[4] if len(sys.argv) > 4 else ""

    # Build paths
    base_dir = Path(__file__).parent / project_name
    folder1_dir = base_dir / folder1
    folder2_dir = base_dir / folder2

    # Try to generate/find JSON files
    print(f"Preparing coverage data...")
    print(f"  Project: {project_name}")
    print(f"  Comparing: {folder1} vs {folder2}")
    if suffix:
        print(f"  Suffix: {suffix}")
    print()

    try:
        print(f"Processing {folder1}...")
        coverage1_file = generate_coverage_json(folder1_dir, folder1, suffix)
        print()
    except FileNotFoundError as e:
        print(f"Error: {e}")
        print(f"\nMake sure you've run the coverage collection first:")
        if suffix:
            print(f"  ./run_tests_venv_generic_coverage.sh {project_name} 1 {folder1} {folder2} {suffix}")
        else:
            print(f"  ./run_tests_venv_generic_coverage.sh {project_name} 1 {folder1} {folder2}")
        sys.exit(1)

    try:
        print(f"Processing {folder2}...")
        coverage2_file = generate_coverage_json(folder2_dir, folder2, suffix)
        print()
    except FileNotFoundError as e:
        print(f"Error: {e}")
        print(f"\nMake sure you've run the coverage collection first:")
        if suffix:
            print(f"  ./run_tests_venv_generic_coverage.sh {project_name} 1 {folder1} {folder2} {suffix}")
        else:
            print(f"  ./run_tests_venv_generic_coverage.sh {project_name} 1 {folder1} {folder2}")
        sys.exit(1)

    # Load coverage data
    print(f"Loading coverage data from:")
    print(f"  {folder1}: {coverage1_file}")
    print(f"  {folder2}: {coverage2_file}")
    print()

    try:
        before_data = load_coverage_json(coverage1_file)
        after_data = load_coverage_json(coverage2_file)
    except Exception as e:
        print(f"Error loading coverage data: {e}")
        sys.exit(1)

    # Compare coverage
    compare_coverage(before_data, after_data, folder1, folder2)

    # Save comparison report
    report_suffix = f"_{suffix}" if suffix else ""
    report_file = base_dir / f"coverage_comparison{report_suffix}.txt"

    print(f"Comparison report also saved to: {report_file}")
    print()

    # Redirect stdout to file
    import io
    from contextlib import redirect_stdout

    f = io.StringIO()
    with redirect_stdout(f):
        compare_coverage(before_data, after_data, folder1, folder2)

    with open(report_file, 'w') as rf:
        rf.write(f.getvalue())


if __name__ == "__main__":
    main()
