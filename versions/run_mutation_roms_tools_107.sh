#!/bin/bash
# Mutation testing script for roms-tools_107
# Runs mutmut 3.x on both before/ and after_careful_mock/ versions
#
# Usage:
#   bash run_mutation_roms_tools_107.sh                    # Run both versions
#   bash run_mutation_roms_tools_107.sh before             # Run only before
#   bash run_mutation_roms_tools_107.sh after_careful_mock # Run only after
#
# Requirements:
#   - Both venvs must exist: before/.venv and after_careful_mock/.venv
#   - mutmut must be installed in each venv (pip install mutmut)
#   - The project must be installed in each venv (SETUPTOOLS_SCM_PRETEND_VERSION=0.1.0.dev0 pip install -e .)
#
# Notes:
#   - Uses --max-children to limit CPU usage (default: half of available CPUs, max 8)
#   - Each version has a 30-minute timeout for the mutation run phase
#   - paths_to_mutate is set to roms_tools/setup (the relevant source for these tests)
#   - Generates at least 1500+ mutants (typically ~8000 for this project)
#   - Results are saved to versions/roms-tools_107/mutation_results_{version}_only_mock_part.txt
#   - After both versions, run:
#       cd versions && python3 parse_mutation_results.py roms-tools_107 before after_careful_mock only_mock_part

set -e

#############################################
# CONFIGURATION
#############################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="roms-tools_107"
PROJECT_DIR="$SCRIPT_DIR/$PROJECT_NAME"
SUFFIX="only_mock_part"
MUTATE_PATHS="roms_tools/setup"
VENV_PATH=".venv"
MAX_CHILDREN="${MAX_CHILDREN:-$(( $(nproc) / 2 ))}"
# Cap max children at 8 to avoid CPU overload
if [ "$MAX_CHILDREN" -gt 8 ]; then
    MAX_CHILDREN=8
fi
# Minimum 1 child
if [ "$MAX_CHILDREN" -lt 1 ]; then
    MAX_CHILDREN=1
fi
MUTATION_TIMEOUT="${MUTATION_TIMEOUT:-30m}"  # 30 minutes default

# Test command (from test_config_only_mock_part.sh)
TEST_COMMAND="pytest \
  roms_tools/tests/test_setup/test_boundary_forcing.py::test_boundary_forcing_data_consistency_plot_save \
  roms_tools/tests/test_setup/test_boundary_forcing.py::test_bgc_boundary_forcing_data_consistency_plot_save \
  roms_tools/tests/test_setup/test_initial_conditions.py::test_initial_conditions_data_consistency_plot_save \
  roms_tools/tests/test_setup/test_surface_forcing.py::test_successful_initialization_with_regional_data[grid_that_straddles_dateline] \
  --durations=0 -v"

# Extract test paths for mutmut tests_dir config
TEST_PATHS=(
    "roms_tools/tests/test_setup/test_boundary_forcing.py::test_boundary_forcing_data_consistency_plot_save"
    "roms_tools/tests/test_setup/test_boundary_forcing.py::test_bgc_boundary_forcing_data_consistency_plot_save"
    "roms_tools/tests/test_setup/test_initial_conditions.py::test_initial_conditions_data_consistency_plot_save"
    "roms_tools/tests/test_setup/test_surface_forcing.py::test_successful_initialization_with_regional_data[grid_that_straddles_dateline]"
)

LOG_FILE="$PROJECT_DIR/mutation_results_${SUFFIX}.log"

#############################################
# FUNCTIONS
#############################################

inject_mutmut_config() {
    # Inject [mutmut] section into setup.cfg
    # $1: paths_to_mutate, $2+: test paths array

    local mutate_paths="$1"
    shift
    local test_paths=("$@")

    # Backup existing setup.cfg
    if [ -f setup.cfg ]; then
        cp setup.cfg setup.cfg.mutmut_bak
    fi

    # Only inject if [mutmut] section doesn't already exist
    if ! grep -q '^\[mutmut\]' setup.cfg 2>/dev/null; then
        {
            echo ""
            echo "[mutmut]"
            echo "paths_to_mutate=${mutate_paths}"
            echo "also_copy=roms_tools"
            echo "tests_dir="
            for tp in "${test_paths[@]}"; do
                echo "    ${tp}"
            done
        } >> setup.cfg
    fi
}

restore_setup_cfg() {
    if [ -f setup.cfg.mutmut_bak ]; then
        mv setup.cfg.mutmut_bak setup.cfg
    else
        # Remove setup.cfg if it was created by us and only has our content
        if [ -f setup.cfg ] && grep -q '^\[mutmut\]' setup.cfg 2>/dev/null; then
            rm -f setup.cfg
        fi
    fi
}

run_mutation_for_version() {
    local VERSION="$1"
    local VERSION_DIR="$PROJECT_DIR/$VERSION"

    if [ ! -d "$VERSION_DIR" ]; then
        echo "ERROR: Version directory '$VERSION_DIR' not found!" | tee -a "$LOG_FILE"
        return 1
    fi

    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "Starting MUTATION TESTING for: $VERSION" | tee -a "$LOG_FILE"
    echo "Time: $(date)" | tee -a "$LOG_FILE"
    echo "Max children: $MAX_CHILDREN" | tee -a "$LOG_FILE"
    echo "Timeout: $MUTATION_TIMEOUT" | tee -a "$LOG_FILE"
    echo "Mutate paths: $MUTATE_PATHS" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"

    cd "$VERSION_DIR"

    # Activate venv
    if [ ! -d "$VENV_PATH" ]; then
        echo "ERROR: Virtual environment not found at '$VENV_PATH'" | tee -a "$LOG_FILE"
        cd "$SCRIPT_DIR"
        return 1
    fi
    echo "Activating virtual environment: $VENV_PATH" | tee -a "$LOG_FILE"
    source "$VENV_PATH/bin/activate"

    # Verify mutmut is available
    if ! command -v mutmut &>/dev/null; then
        echo "ERROR: mutmut not found in venv. Install with: pip install mutmut" | tee -a "$LOG_FILE"
        deactivate 2>/dev/null || true
        cd "$SCRIPT_DIR"
        return 1
    fi
    echo "mutmut version: $(mutmut --version 2>&1)" | tee -a "$LOG_FILE"

    # Set environment variable for setuptools_scm
    export SETUPTOOLS_SCM_PRETEND_VERSION=0.1.0.dev0

    # Clean previous mutation data
    echo "Cleaning previous mutation data..." | tee -a "$LOG_FILE"
    rm -rf mutants/ .mutmut-cache/

    # Inject mutmut config into setup.cfg
    echo "Injecting mutmut config..." | tee -a "$LOG_FILE"
    inject_mutmut_config "$MUTATE_PATHS" "${TEST_PATHS[@]}"
    echo "--- setup.cfg [mutmut] section ---" | tee -a "$LOG_FILE"
    grep -A 15 '^\[mutmut\]' setup.cfg 2>/dev/null | tee -a "$LOG_FILE"
    echo "---" | tee -a "$LOG_FILE"

    # Run mutmut (with timeout and limited children)
    echo "" | tee -a "$LOG_FILE"
    echo "Running mutmut run --max-children $MAX_CHILDREN ..." | tee -a "$LOG_FILE"
    echo "Start time: $(date)" | tee -a "$LOG_FILE"

    timeout "$MUTATION_TIMEOUT" mutmut run --max-children "$MAX_CHILDREN" 2>&1 | tee -a "$LOG_FILE" || {
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo "WARNING: mutmut run timed out after $MUTATION_TIMEOUT" | tee -a "$LOG_FILE"
        else
            echo "WARNING: mutmut run exited with code $exit_code" | tee -a "$LOG_FILE"
        fi
    }

    echo "End time: $(date)" | tee -a "$LOG_FILE"

    # Capture results
    echo "" | tee -a "$LOG_FILE"
    echo "=========================================" | tee -a "$LOG_FILE"
    echo "Mutation testing results for $VERSION:" | tee -a "$LOG_FILE"
    echo "=========================================" | tee -a "$LOG_FILE"

    local RESULTS_FILE="$PROJECT_DIR/mutation_results_${VERSION}_${SUFFIX}.txt"
    mutmut results --all true 2>&1 | tee "$RESULTS_FILE" | tee -a "$LOG_FILE" || {
        echo "WARNING: Failed to get mutmut results" | tee -a "$LOG_FILE"
    }

    # Count results
    if [ -f "$RESULTS_FILE" ] && [ -s "$RESULTS_FILE" ]; then
        local TOTAL=$(wc -l < "$RESULTS_FILE" | tr -d ' ')
        local KILLED=$(grep -c ": killed" "$RESULTS_FILE" || true)
        local SURVIVED=$(grep -c ": survived" "$RESULTS_FILE" || true)
        local TIMEOUT_CNT=$(grep -c ": timeout" "$RESULTS_FILE" || true)
        local NO_TESTS=$(grep -c ": no tests" "$RESULTS_FILE" || true)
        local NOT_CHECKED=$(grep -c ": not checked" "$RESULTS_FILE" || true)
        # Ensure they are integers
        KILLED=${KILLED:-0}; SURVIVED=${SURVIVED:-0}; TIMEOUT_CNT=${TIMEOUT_CNT:-0}; NO_TESTS=${NO_TESTS:-0}; NOT_CHECKED=${NOT_CHECKED:-0}

        echo "" | tee -a "$LOG_FILE"
        echo "Quick summary for $VERSION:" | tee -a "$LOG_FILE"
        echo "  Total mutants: $TOTAL" | tee -a "$LOG_FILE"
        echo "  Killed: $KILLED" | tee -a "$LOG_FILE"
        echo "  Survived: $SURVIVED" | tee -a "$LOG_FILE"
        echo "  Timeout: $TIMEOUT_CNT" | tee -a "$LOG_FILE"
        echo "  No tests: $NO_TESTS" | tee -a "$LOG_FILE"
        echo "  Not checked: $NOT_CHECKED" | tee -a "$LOG_FILE"
        local TESTABLE=$((TOTAL - NO_TESTS))
        if [ "$TESTABLE" -gt 0 ] && [ "$KILLED" -gt 0 ]; then
            echo "  Testable: $TESTABLE" | tee -a "$LOG_FILE"
            local SCORE=$(awk "BEGIN {printf \"%.2f\", ($KILLED / $TESTABLE) * 100}")
            echo "  Mutation Score: ${SCORE}%" | tee -a "$LOG_FILE"
        fi
    else
        echo "WARNING: Results file is empty or not found: $RESULTS_FILE" | tee -a "$LOG_FILE"
    fi

    # Save .mutmut-cache for potential re-use
    local CACHE_BACKUP="$PROJECT_DIR/mutmut_cache_${VERSION}_${SUFFIX}"
    if [ -d ".mutmut-cache" ]; then
        rm -rf "$CACHE_BACKUP"
        cp -r .mutmut-cache "$CACHE_BACKUP"
        echo "Mutation cache saved to: $CACHE_BACKUP" | tee -a "$LOG_FILE"
    fi

    # Restore setup.cfg
    echo "Restoring setup.cfg..." | tee -a "$LOG_FILE"
    restore_setup_cfg

    # Deactivate venv
    deactivate 2>/dev/null || true

    echo "" | tee -a "$LOG_FILE"
    echo "Completed $VERSION mutation testing at: $(date)" | tee -a "$LOG_FILE"

    cd "$SCRIPT_DIR"
}

#############################################
# MAIN
#############################################

# Determine which versions to run
RUN_BEFORE=true
RUN_AFTER=true

if [ $# -ge 1 ]; then
    case "$1" in
        before)
            RUN_BEFORE=true
            RUN_AFTER=false
            ;;
        after_careful_mock|after)
            RUN_BEFORE=false
            RUN_AFTER=true
            ;;
        both|"")
            RUN_BEFORE=true
            RUN_AFTER=true
            ;;
        *)
            echo "Usage: $0 [before|after_careful_mock|both]"
            echo ""
            echo "Options:"
            echo "  before             - Run mutation testing on before/ only"
            echo "  after_careful_mock - Run mutation testing on after_careful_mock/ only"
            echo "  both (default)     - Run on both versions"
            echo ""
            echo "Environment variables:"
            echo "  MAX_CHILDREN       - Max parallel mutmut workers (default: nproc/2, max 8)"
            echo "  MUTATION_TIMEOUT   - Timeout for each version's mutmut run (default: 30m)"
            exit 1
            ;;
    esac
fi

# Clear log
> "$LOG_FILE"

echo "========================================" | tee -a "$LOG_FILE"
echo "Mutation Testing for: $PROJECT_NAME" | tee -a "$LOG_FILE"
echo "Config suffix: $SUFFIX" | tee -a "$LOG_FILE"
echo "Mutate paths: $MUTATE_PATHS" | tee -a "$LOG_FILE"
echo "Max children: $MAX_CHILDREN" | tee -a "$LOG_FILE"
echo "Timeout per version: $MUTATION_TIMEOUT" | tee -a "$LOG_FILE"
echo "Date: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

if [ "$RUN_BEFORE" = true ]; then
    run_mutation_for_version "before"
fi

if [ "$RUN_BEFORE" = true ] && [ "$RUN_AFTER" = true ]; then
    echo "" | tee -a "$LOG_FILE"
    echo "Sleeping 10 seconds between versions..." | tee -a "$LOG_FILE"
    sleep 10
fi

if [ "$RUN_AFTER" = true ]; then
    run_mutation_for_version "after_careful_mock"
fi

echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "All mutation testing completed at: $(date)" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Print next steps
echo ""
echo "Results saved:"
if [ "$RUN_BEFORE" = true ]; then
    echo "  before: $PROJECT_DIR/mutation_results_before_${SUFFIX}.txt"
fi
if [ "$RUN_AFTER" = true ]; then
    echo "  after:  $PROJECT_DIR/mutation_results_after_careful_mock_${SUFFIX}.txt"
fi
echo ""
echo "To compare results and generate the comparison report:"
echo "  cd $SCRIPT_DIR"
echo "  python3 parse_mutation_results.py $PROJECT_NAME before after_careful_mock $SUFFIX"
echo ""
echo "This will produce: $PROJECT_DIR/mutation_comparison_${SUFFIX}.txt"
