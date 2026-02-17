#!/bin/bash
# Mutation testing script for autosubmit_2367
# Runs mutmut 3.x on both before/ and after_careful_mock/ versions
#
# Usage:
#   bash run_mutation_autosubmit_2367.sh                    # Run both versions
#   bash run_mutation_autosubmit_2367.sh before             # Run only before
#   bash run_mutation_autosubmit_2367.sh after_careful_mock # Run only after
#
# Requirements:
#   - Both venvs must exist: before/.venv and after_careful_mock/.venv
#   - mutmut must be installed in each venv (pip install mutmut toml)
#   - The project must be installed in each venv (pip install -e .)
#
# Notes:
#   - Uses --max-children to limit CPU usage (default: half of available CPUs, max 8)
#   - Each version has a 30-minute timeout for the mutation run phase
#   - paths_to_mutate is set to "autosubmit" (the main source package)
#   - The pytest.ini has "-n auto" (xdist parallelism) which is temporarily disabled
#     during mutation testing to avoid CPU overload (mutmut handles its own parallelism)
#   - autosubmit/helpers/parameters.py is excluded from mutation (do_not_mutate)
#     because its autosubmit_parameter decorator uses stack frame introspection
#     (stack[1][0].f_locals['__qualname__']) which breaks under mutmut's trampoline wrapper
#   - Results are saved to versions/autosubmit_2367/mutation_results_{version}_only_mock_part.txt
#   - After both versions, run:
#       cd versions && python3 parse_mutation_results.py autosubmit_2367 before after_careful_mock only_mock_part

set -e

#############################################
# CONFIGURATION
#############################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="autosubmit_2367"
PROJECT_DIR="$SCRIPT_DIR/$PROJECT_NAME"
SUFFIX="only_mock_part"
MUTATE_PATHS="autosubmit"
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

# Test paths (from test_config_only_mock_part.sh)
TEST_PATHS=(
    "test/unit/test_autosubmit_helper.py::teste_handle_start_time"
)

LOG_FILE="$PROJECT_DIR/mutation_results_${SUFFIX}.log"

#############################################
# FUNCTIONS
#############################################

inject_mutmut_config() {
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
            echo "tests_dir="
            for tp in "${test_paths[@]}"; do
                echo "    ${tp}"
            done
            # Exclude files that use stack frame introspection (__qualname__)
            # which breaks when mutmut's trampoline wrapper modifies the call stack.
            echo "do_not_mutate="
            echo "    autosubmit/helpers/parameters.py"
        } >> setup.cfg
    fi
}

restore_setup_cfg() {
    if [ -f setup.cfg.mutmut_bak ]; then
        mv setup.cfg.mutmut_bak setup.cfg
    else
        if [ -f setup.cfg ] && grep -q '^\[mutmut\]' setup.cfg 2>/dev/null; then
            rm -f setup.cfg
        fi
    fi
}

# Temporarily replace pytest.ini with a minimal version for mutation testing.
# The original has options that conflict with mutmut:
#   - "-n auto --dist loadgroup" (xdist parallelism conflicts with mutmut)
#   - "--doctest-modules" (scans source for doctests, causes import errors)
#   - "--strict-markers" + "-m not docker" (can break mutmut's pytest invocation)
#   - testpaths includes "autosubmit" (for doctests; not needed for mutation)
disable_pytest_parallelism() {
    if [ -f pytest.ini ]; then
        cp pytest.ini pytest.ini.mutmut_bak
        # Write a minimal pytest.ini that only keeps what mutmut needs
        cat > pytest.ini << 'PYTEST_EOF'
[pytest]
testpaths =
    test/unit
PYTEST_EOF
        echo "Replaced pytest.ini with minimal version for mutation testing" | tee -a "$LOG_FILE"
    fi
}

restore_pytest_ini() {
    if [ -f pytest.ini.mutmut_bak ]; then
        mv pytest.ini.mutmut_bak pytest.ini
        echo "Restored original pytest.ini" | tee -a "$LOG_FILE"
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
    # Use explicit venv binary paths to avoid conda PATH interference
    local VENV_BIN="$(cd "$VENV_PATH/bin" && pwd)"
    export PATH="$VENV_BIN:$PATH"
    source "$VENV_PATH/bin/activate"

    # Define the mutmut binary path explicitly
    local MUTMUT_BIN="$VENV_BIN/mutmut"

    # Verify mutmut is available in the venv
    if [ ! -x "$MUTMUT_BIN" ]; then
        echo "ERROR: mutmut not found at $MUTMUT_BIN. Install with:" | tee -a "$LOG_FILE"
        echo "  $VENV_BIN/python3 -m pip install mutmut toml" | tee -a "$LOG_FILE"
        deactivate 2>/dev/null || true
        cd "$SCRIPT_DIR"
        return 1
    fi
    echo "mutmut binary: $MUTMUT_BIN" | tee -a "$LOG_FILE"
    echo "mutmut version: $($MUTMUT_BIN --version 2>&1)" | tee -a "$LOG_FILE"
    echo "python: $(which python3)" | tee -a "$LOG_FILE"

    # Disable pytest-xdist parallelism to avoid CPU overload
    disable_pytest_parallelism

    # Clean previous mutation data
    echo "Cleaning previous mutation data..." | tee -a "$LOG_FILE"
    rm -rf mutants/ .mutmut-cache/

    # Inject mutmut config into setup.cfg
    echo "Injecting mutmut config..." | tee -a "$LOG_FILE"
    inject_mutmut_config "$MUTATE_PATHS" "${TEST_PATHS[@]}"
    echo "--- setup.cfg [mutmut] section ---" | tee -a "$LOG_FILE"
    grep -A 10 '^\[mutmut\]' setup.cfg 2>/dev/null | tee -a "$LOG_FILE"
    echo "---" | tee -a "$LOG_FILE"

    # Run mutmut (with timeout and limited children)
    echo "" | tee -a "$LOG_FILE"
    echo "Running mutmut run --max-children $MAX_CHILDREN ..." | tee -a "$LOG_FILE"
    echo "Start time: $(date)" | tee -a "$LOG_FILE"

    timeout "$MUTATION_TIMEOUT" "$MUTMUT_BIN" run --max-children "$MAX_CHILDREN" 2>&1 | tee -a "$LOG_FILE" || {
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
    "$MUTMUT_BIN" results --all true 2>&1 | tee "$RESULTS_FILE" | tee -a "$LOG_FILE" || {
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

    # Restore setup.cfg and pytest.ini
    echo "Restoring setup.cfg..." | tee -a "$LOG_FILE"
    restore_setup_cfg
    restore_pytest_ini

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
