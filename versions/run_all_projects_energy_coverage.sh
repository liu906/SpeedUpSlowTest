#!/bin/bash
# Complete workflow: Energy measurement + Coverage verification for all projects
# This script runs both energy measurement (with energibridge) and coverage collection (without energibridge)
# Usage: ./run_all_projects_energy_coverage.sh [REPEAT]
# Example: ./run_all_projects_energy_coverage.sh 10

set -e

REPEAT=${1:-10}  # Default to 10 runs for energy measurement
COVERAGE_RUNS=1  # Always 1 run for coverage

echo "=========================================="
echo "Complete Workflow: Energy + Coverage"
echo "Energy measurement runs: $REPEAT"
echo "Coverage verification runs: $COVERAGE_RUNS"
echo "=========================================="
echo ""

# Function to run both energy and coverage for a project
run_project() {
    local PROJECT=$1
    local RUNNER_SCRIPT=$2  # run_tests_venv_generic.sh or run_tests_generic.sh
    local FOLDER1=${3:-before}
    local FOLDER2=${4:-after_careful_mock}
    local SUFFIX=${5:-only_mock_part}

    echo ""
    echo "=========================================="
    echo "PROJECT: $PROJECT"
    echo "=========================================="

    # Step 1: Energy measurement
    echo ""
    echo "Step 1/4: Measuring energy consumption ($REPEAT runs)..."
    bash $RUNNER_SCRIPT $PROJECT $REPEAT $FOLDER1 $FOLDER2 $SUFFIX

    # Step 2: Parse energy results
    echo ""
    echo "Step 2/4: Analyzing energy results..."
    python3 parse_results_generic_optimized.py $PROJECT $SUFFIX

    # Step 3: Coverage collection
    echo ""
    echo "Step 3/4: Collecting coverage data ($COVERAGE_RUNS run)..."
    if [[ "$RUNNER_SCRIPT" == *"run_tests_generic.sh"* ]]; then
        # Use the generic coverage script (not venv-specific)
        bash run_tests_generic_coverage.sh $PROJECT $COVERAGE_RUNS $FOLDER1 $FOLDER2 $SUFFIX
    else
        # Use the venv coverage script
        bash run_tests_venv_generic_coverage.sh $PROJECT $COVERAGE_RUNS $FOLDER1 $FOLDER2 $SUFFIX
    fi

    # Step 4: Compare coverage
    echo ""
    echo "Step 4/4: Comparing coverage..."
    python3 compare_coverage.py $PROJECT $FOLDER1 $FOLDER2 $SUFFIX

    echo ""
    echo "✓ Completed $PROJECT"
    echo "  - Energy results: Plots and terminal output"
    echo "  - Coverage comparison: ${PROJECT}/coverage_comparison_${SUFFIX}.txt"
    echo ""

    # Sleep between projects
    echo "Sleeping 30 seconds before next project..."
    sleep 30
}

# Run all projects
echo "Starting complete workflow for all projects..."
echo ""

# 1. opensearch-build_595
run_project "opensearch-build_595" "run_tests_venv_generic.sh" "before" "after_careful_mock" "only_mock_part"

# 2. pydicom_1636
run_project "pydicom_1636" "run_tests_venv_generic.sh" "before" "after_careful_mock" "only_mock_part"

# 3. roms-tools_107
run_project "roms-tools_107" "run_tests_venv_generic.sh" "before" "after_careful_mock" "only_mock_part"

# 4. armi_1737
run_project "armi_1737" "run_tests_venv_generic.sh" "before" "after_careful_mock" "only_mock_part"

# 5. bilby_986
run_project "bilby_986" "run_tests_venv_generic.sh" "before" "after_careful_mock" "only_mock_part"

# 6. BuffaLogs_399
run_project "BuffaLogs_399/" "run_tests_generic.sh" "before" "after_careful_mock" "only_mock_part"

# 7. detection-rules_2626
run_project "detection-rules_2626" "run_tests_venv_generic.sh" "before" "after_careful_mock" "only_mock_part"

# 8. lightning-thunder_2077
run_project "lightning-thunder_2077" "run_tests_venv_generic.sh" "before" "after_careful_mock" "only_mock_part"

# 9. patientMatcher_262
run_project "patientMatcher_262/" "run_tests_generic.sh" "before" "after_careful_mock" "only_mock_part"

# 10. dfm_tools_976
run_project "dfm_tools_976" "run_tests_venv_generic.sh" "before" "after_careful_mock" "only_mock_part"

# 11. python-dts-calibration_197
run_project "python-dts-calibration_197/" "run_tests_generic.sh" "before" "after_careful_mock" "only_mock_part"

# 12. evalml_2446
run_project "evalml_2446" "run_tests_venv_generic.sh" "before" "after_careful_mock" "only_mock_part"

echo ""
echo "=========================================="
echo "ALL PROJECTS COMPLETED!"
echo "=========================================="
echo ""
echo "Summary of results:"
echo "  Each project has:"
echo "    1. Energy measurement plots"
echo "    2. Coverage comparison report: <project>/coverage_comparison_only_mock_part.txt"
echo ""
echo "To view a project's coverage comparison:"
echo "  cat <project>/coverage_comparison_only_mock_part.txt"
echo ""
echo "To view coverage HTML reports:"
echo "  xdg-open <project>/before/htmlcov_before_only_mock_part/index.html"
echo "  xdg-open <project>/<folder2>/htmlcov_<folder2>_only_mock_part/index.html"
echo ""
