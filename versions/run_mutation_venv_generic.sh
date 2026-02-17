#!/bin/bash
# Generic mutation testing runner for Python projects using mutmut 3.x
# Mirrors the pattern of run_tests_venv_generic_coverage.sh
#
# Usage: ./run_mutation_venv_generic.sh <project_name> <mutate_paths> [folder1] [folder2] [suffix]
# Example: ./run_mutation_venv_generic.sh armi_1737 "armi" before after_careful_mock only_mock_part
# Example: ./run_mutation_venv_generic.sh ert_11206 "src/ert" before after_careful_mock only_mock_part
#
# mutate_paths: comma-separated source directories to mutate (e.g., "armi" or "src/ert,src/_ert")
# folder1/folder2: version directories to compare (default: before / after)
# suffix: config file suffix (default: uses test_config.sh)

set -e

# Check arguments
if [ $# -lt 2 ] || [ $# -gt 5 ]; then
    echo "Usage: $0 <project_name> <mutate_paths> [folder1] [folder2] [suffix]"
    echo "Example: $0 armi_1737 \"armi\" before after_careful_mock only_mock_part"
    exit 1
fi

PROJECT_NAME=$1
MUTATE_PATHS=$2
FOLDER1=${3:-before}
FOLDER2=${4:-after}
SUFFIX=${5:-}

# Build config file and log file names based on suffix
if [ -z "$SUFFIX" ]; then
    CONFIG_FILE="test_config.sh"
    LOG_FILE_NAME="mutation_results.log"
    MUTATION_SUFFIX=""
else
    CONFIG_FILE="test_config_${SUFFIX}.sh"
    LOG_FILE_NAME="mutation_results_${SUFFIX}.log"
    MUTATION_SUFFIX="_${SUFFIX}"
fi

BASE_DIR="$(pwd)"
PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"

# Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project directory '$PROJECT_DIR' not found"
    exit 1
fi

# Check if config file exists
if [ ! -f "$PROJECT_DIR/$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found in '$PROJECT_DIR'"
    exit 1
fi

# Load project configuration
source "$PROJECT_DIR/$CONFIG_FILE"

# Validate required variables
if [ -z "$TEST_COMMAND" ]; then
    echo "Error: TEST_COMMAND not defined in $CONFIG_FILE"
    exit 1
fi

# Define log file
LOG_FILE="$PROJECT_DIR/$LOG_FILE_NAME"

# Clear previous log file
> "$LOG_FILE"

# Extract test paths from TEST_COMMAND for mutmut tests_dir config
# Strips: pytest invocation, common flags, pipe commands
extract_test_paths() {
    local cmd="$1"
    # Remove everything before pytest (handles: python -m pytest, uv run pytest, bash -c '...pytest')
    local pytest_args=$(echo "$cmd" | sed -E "s/.*pytest[0-9.]* //" )
    # Remove pipe and everything after
    pytest_args=$(echo "$pytest_args" | sed -E "s/ *\|.*//")
    # Remove trailing quote/single-quote (from bash -c wrapping)
    pytest_args=$(echo "$pytest_args" | sed -E "s/['\"]$//")
    # Remove common flags, keep test paths
    local test_paths=""
    for arg in $pytest_args; do
        case "$arg" in
            --durations=*|-v|-vv|-vvv|--tb=*|-x|-q|--strict-markers|-p|no:cov|-o|addopts=*|addopts=\"\")
                continue
                ;;
            -*)
                continue
                ;;
            *)
                test_paths="$test_paths
$arg"
                ;;
        esac
    done
    echo "$test_paths" | grep -v '^$' | tr '\n' '\n'
}

echo "========================================" | tee -a "$LOG_FILE"
echo "Starting MUTATION TESTING for project: $PROJECT_NAME" | tee -a "$LOG_FILE"
echo "Config file: $CONFIG_FILE" | tee -a "$LOG_FILE"
echo "Mutate paths: $MUTATE_PATHS" | tee -a "$LOG_FILE"
echo "Comparing: $FOLDER1 vs $FOLDER2" | tee -a "$LOG_FILE"
echo "Test command: $TEST_COMMAND" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Function to inject mutmut config into setup.cfg
inject_mutmut_config() {
    local mutate_paths="$1"
    local tests_dir="$2"

    # Backup existing setup.cfg
    if [ -f setup.cfg ]; then
        cp setup.cfg setup.cfg.mutmut_bak
    fi

    # Only inject if [mutmut] section doesn't already exist
    if ! grep -q '^\[mutmut\]' setup.cfg 2>/dev/null; then
        echo "" >> setup.cfg
        echo "[mutmut]" >> setup.cfg
        echo "paths_to_mutate=${mutate_paths}" >> setup.cfg
        if [ -n "$tests_dir" ]; then
            # Write tests_dir as multi-line entries
            echo "tests_dir=" >> setup.cfg
            echo "$tests_dir" | while IFS= read -r line; do
                if [ -n "$line" ]; then
                    echo "    ${line}" >> setup.cfg
                fi
            done
        fi
    fi
}

# Function to restore setup.cfg after mutation testing
restore_setup_cfg() {
    if [ -f setup.cfg.mutmut_bak ]; then
        mv setup.cfg.mutmut_bak setup.cfg
    else
        # setup.cfg was created by us, remove it
        # But only remove if it only contains our [mutmut] section
        if grep -q '^\[mutmut\]' setup.cfg 2>/dev/null; then
            rm -f setup.cfg
        fi
    fi
}

# Function to run mutation testing for a version (venv-based)
run_version_mutation_venv() {
    local VERSION=$1
    local VERSION_DIR="$PROJECT_DIR/$VERSION"

    if [ ! -d "$VERSION_DIR" ]; then
        echo "Warning: Version directory '$VERSION_DIR' not found, skipping..." | tee -a "$LOG_FILE"
        return
    fi

    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "Starting MUTATION TESTING for $VERSION version" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"

    cd "$VERSION_DIR"

    # Extract test paths from TEST_COMMAND
    local TESTS_DIR
    TESTS_DIR=$(extract_test_paths "$TEST_COMMAND")
    echo "Extracted test paths: $TESTS_DIR" | tee -a "$LOG_FILE"

    # Handle uv-based projects
    if [ "$USE_UV" = "true" ]; then
        echo "Detected uv-based project..." | tee -a "$LOG_FILE"

        # Run setup command if specified
        if [ -n "$SETUP_COMMAND" ]; then
            echo "Running setup command..." | tee -a "$LOG_FILE"
            eval "$SETUP_COMMAND" 2>&1 | tee -a "$LOG_FILE"
        fi

        # Install mutmut
        echo "Installing mutmut..." | tee -a "$LOG_FILE"
        uv pip install mutmut toml 2>&1 | tee -a "$LOG_FILE"

    else
        # Traditional venv
        if [ -z "$VENV_PATH" ]; then
            echo "Error: VENV_PATH not defined in $CONFIG_FILE" | tee -a "$LOG_FILE"
            cd "$BASE_DIR"
            return 1
        fi

        # Create venv if it doesn't exist
        if [ ! -d "$VENV_PATH" ]; then
            echo "Virtual environment not found at '$VENV_PATH', creating..." | tee -a "$LOG_FILE"
            PYTHON_CMD="${PYTHON_VERSION:-python3.10}"
            $PYTHON_CMD -m venv "$VENV_PATH" 2>&1 | tee -a "$LOG_FILE"
            source "$VENV_PATH/bin/activate"

            if [ -f "requirements.txt" ]; then
                pip install --upgrade pip 2>&1 | tee -a "$LOG_FILE"
                pip install -r requirements.txt 2>&1 | tee -a "$LOG_FILE"
            elif [ -f "pyproject.toml" ]; then
                pip install --upgrade pip 2>&1 | tee -a "$LOG_FILE"
                pip install -e . 2>&1 | tee -a "$LOG_FILE"
            fi
        else
            source "$VENV_PATH/bin/activate"
        fi

        # Run setup command if specified
        if [ -n "$SETUP_COMMAND" ]; then
            echo "Running setup command..." | tee -a "$LOG_FILE"
            eval "$SETUP_COMMAND" 2>&1 | tee -a "$LOG_FILE"
        fi

        # Install mutmut
        echo "Installing mutmut..." | tee -a "$LOG_FILE"
        pip install mutmut toml 2>&1 | tee -a "$LOG_FILE"
    fi

    # Wait if specified
    if [ -n "$WAIT_TIME" ]; then
        echo "Waiting ${WAIT_TIME}s..." | tee -a "$LOG_FILE"
        sleep "$WAIT_TIME"
    fi

    # Clean previous mutation data
    echo "Cleaning previous mutation data..." | tee -a "$LOG_FILE"
    rm -rf mutants/ .mutmut-cache/

    # Inject mutmut config into setup.cfg
    echo "Injecting mutmut config..." | tee -a "$LOG_FILE"
    inject_mutmut_config "$MUTATE_PATHS" "$TESTS_DIR"
    echo "setup.cfg [mutmut] section:" | tee -a "$LOG_FILE"
    grep -A 10 '^\[mutmut\]' setup.cfg 2>/dev/null | tee -a "$LOG_FILE"

    # Run mutmut
    echo "" | tee -a "$LOG_FILE"
    echo "Running mutmut..." | tee -a "$LOG_FILE"
    echo "Time: $(date)" | tee -a "$LOG_FILE"

    if [ "$USE_UV" = "true" ]; then
        timeout 30m uv run mutmut run --timeout-multiplier 3 2>&1 | tee -a "$LOG_FILE" || true
    else
        timeout 30m mutmut run --timeout-multiplier 3 2>&1 | tee -a "$LOG_FILE" || true
    fi

    # Capture results
    echo "" | tee -a "$LOG_FILE"
    echo "=========================================" | tee -a "$LOG_FILE"
    echo "Mutation testing results for $VERSION:" | tee -a "$LOG_FILE"
    echo "=========================================" | tee -a "$LOG_FILE"

    local RESULTS_FILE="$PROJECT_DIR/mutation_results_${VERSION}${MUTATION_SUFFIX}.txt"
    if [ "$USE_UV" = "true" ]; then
        uv run mutmut results --all true 2>&1 | tee "$RESULTS_FILE" | tee -a "$LOG_FILE" || true
    else
        mutmut results --all true 2>&1 | tee "$RESULTS_FILE" | tee -a "$LOG_FILE" || true
    fi

    # Save .mutmut-cache for later comparison
    local CACHE_BACKUP="$PROJECT_DIR/mutmut_cache_${VERSION}${MUTATION_SUFFIX}"
    if [ -d ".mutmut-cache" ]; then
        rm -rf "$CACHE_BACKUP"
        cp -r .mutmut-cache "$CACHE_BACKUP"
        echo "Mutation cache saved to: $CACHE_BACKUP" | tee -a "$LOG_FILE"
    fi

    # Restore setup.cfg
    echo "Restoring setup.cfg..." | tee -a "$LOG_FILE"
    restore_setup_cfg

    # Deactivate venv (skip for uv)
    if [ "$USE_UV" != "true" ]; then
        deactivate 2>/dev/null || true
    fi

    echo "" | tee -a "$LOG_FILE"
    echo "Completed $VERSION mutation testing at: $(date)" | tee -a "$LOG_FILE"

    cd "$BASE_DIR"
}

# Function to run mutation testing for a Docker-based version
run_version_mutation_docker() {
    local VERSION=$1
    local VERSION_DIR="$PROJECT_DIR/$VERSION"

    if [ ! -d "$VERSION_DIR" ]; then
        echo "Warning: Version directory '$VERSION_DIR' not found, skipping..." | tee -a "$LOG_FILE"
        return
    fi

    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "Starting MUTATION TESTING (Docker) for $VERSION version" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"

    cd "$VERSION_DIR"

    # Extract container name from TEST_COMMAND (docker compose exec <container> ...)
    local CONTAINER
    CONTAINER=$(echo "$TEST_COMMAND" | grep -oP 'docker compose exec \K\S+')
    if [ -z "$CONTAINER" ]; then
        echo "Error: Could not extract container name from TEST_COMMAND" | tee -a "$LOG_FILE"
        cd "$BASE_DIR"
        return 1
    fi
    echo "Docker container: $CONTAINER" | tee -a "$LOG_FILE"

    # Extract test paths from TEST_COMMAND (after container name)
    local DOCKER_PYTEST_CMD
    DOCKER_PYTEST_CMD=$(echo "$TEST_COMMAND" | sed -E "s/docker compose exec $CONTAINER //")
    local TESTS_DIR
    TESTS_DIR=$(extract_test_paths "$DOCKER_PYTEST_CMD")
    echo "Extracted test paths: $TESTS_DIR" | tee -a "$LOG_FILE"

    # Start containers
    echo "Starting Docker containers..." | tee -a "$LOG_FILE"
    docker compose up -d 2>&1 | tee -a "$LOG_FILE"

    if [ -n "$WAIT_TIME" ]; then
        echo "Waiting ${WAIT_TIME}s for containers to be ready..." | tee -a "$LOG_FILE"
        sleep "$WAIT_TIME"
    fi

    # Run setup command if specified
    if [ -n "$SETUP_COMMAND" ]; then
        echo "Running setup command..." | tee -a "$LOG_FILE"
        eval "$SETUP_COMMAND" 2>&1 | tee -a "$LOG_FILE"
    fi

    # Install mutmut inside the container
    echo "Installing mutmut inside container..." | tee -a "$LOG_FILE"
    docker compose exec "$CONTAINER" pip install mutmut toml 2>&1 | tee -a "$LOG_FILE"

    # Clean previous mutation data inside container
    echo "Cleaning previous mutation data..." | tee -a "$LOG_FILE"
    docker compose exec "$CONTAINER" bash -c "rm -rf mutants/ .mutmut-cache/" 2>&1 | tee -a "$LOG_FILE"

    # Inject mutmut config: create setup.cfg with [mutmut] section inside container
    echo "Injecting mutmut config inside container..." | tee -a "$LOG_FILE"
    local TESTS_DIR_ENTRIES=""
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            TESTS_DIR_ENTRIES="${TESTS_DIR_ENTRIES}    ${line}\n"
        fi
    done <<< "$TESTS_DIR"

    docker compose exec "$CONTAINER" bash -c "
        if [ -f setup.cfg ]; then cp setup.cfg setup.cfg.mutmut_bak; fi
        if ! grep -q '^\[mutmut\]' setup.cfg 2>/dev/null; then
            echo '' >> setup.cfg
            echo '[mutmut]' >> setup.cfg
            echo 'paths_to_mutate=${MUTATE_PATHS}' >> setup.cfg
            echo 'tests_dir=' >> setup.cfg
            printf '${TESTS_DIR_ENTRIES}' >> setup.cfg
        fi
        echo 'setup.cfg [mutmut] section:'
        grep -A 10 '^\[mutmut\]' setup.cfg 2>/dev/null
    " 2>&1 | tee -a "$LOG_FILE"

    # Run mutmut inside container
    echo "" | tee -a "$LOG_FILE"
    echo "Running mutmut inside container..." | tee -a "$LOG_FILE"
    echo "Time: $(date)" | tee -a "$LOG_FILE"
    timeout 30m docker compose exec "$CONTAINER" mutmut run 2>&1 | tee -a "$LOG_FILE" || true

    # Capture results
    echo "" | tee -a "$LOG_FILE"
    echo "=========================================" | tee -a "$LOG_FILE"
    echo "Mutation testing results for $VERSION:" | tee -a "$LOG_FILE"
    echo "=========================================" | tee -a "$LOG_FILE"

    local RESULTS_FILE="$PROJECT_DIR/mutation_results_${VERSION}${MUTATION_SUFFIX}.txt"
    docker compose exec "$CONTAINER" mutmut results --all true 2>&1 | tee "$RESULTS_FILE" | tee -a "$LOG_FILE" || true

    # Copy .mutmut-cache back from container
    local CACHE_BACKUP="$PROJECT_DIR/mutmut_cache_${VERSION}${MUTATION_SUFFIX}"
    rm -rf "$CACHE_BACKUP"
    docker compose cp "$CONTAINER:.mutmut-cache" "$CACHE_BACKUP" 2>&1 | tee -a "$LOG_FILE" || true
    echo "Mutation cache saved to: $CACHE_BACKUP" | tee -a "$LOG_FILE"

    # Restore setup.cfg inside container
    docker compose exec "$CONTAINER" bash -c "
        if [ -f setup.cfg.mutmut_bak ]; then
            mv setup.cfg.mutmut_bak setup.cfg
        else
            rm -f setup.cfg
        fi
    " 2>&1 | tee -a "$LOG_FILE"

    # Stop containers
    echo "Stopping Docker containers..." | tee -a "$LOG_FILE"
    docker compose down -v 2>&1 | tee -a "$LOG_FILE"

    echo "" | tee -a "$LOG_FILE"
    echo "Completed $VERSION mutation testing (Docker) at: $(date)" | tee -a "$LOG_FILE"

    cd "$BASE_DIR"
}

# Main execution
echo "========================================"
echo "Generic Mutation Testing Runner"
echo "Project: $PROJECT_NAME"
echo "Mutate paths: $MUTATE_PATHS"
echo "Config file: $CONFIG_FILE"
echo "Log file: $LOG_FILE_NAME"
echo "Comparing: $FOLDER1 vs $FOLDER2"
echo "========================================"
echo ""

# Determine project type and run accordingly
if [ "$USE_DOCKER" = "true" ]; then
    run_version_mutation_docker "$FOLDER1"
    echo ""
    echo "Sleeping 10 seconds between versions..."
    sleep 10
    echo ""
    run_version_mutation_docker "$FOLDER2"
else
    run_version_mutation_venv "$FOLDER1"
    echo ""
    echo "Sleeping 10 seconds between versions..."
    sleep 10
    echo ""
    run_version_mutation_venv "$FOLDER2"
fi

echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "All mutation testing completed at: $(date)" | tee -a "$LOG_FILE"
echo "Compared: $FOLDER1 vs $FOLDER2" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo ""
echo "Mutation results saved:"
echo "  $FOLDER1: $PROJECT_DIR/mutation_results_${FOLDER1}${MUTATION_SUFFIX}.txt"
echo "  $FOLDER2: $PROJECT_DIR/mutation_results_${FOLDER2}${MUTATION_SUFFIX}.txt"
echo ""
echo "Next steps:"
echo "  python3 parse_mutation_results.py $PROJECT_NAME $FOLDER1 $FOLDER2${SUFFIX:+ $SUFFIX}"
