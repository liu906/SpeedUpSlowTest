#!/bin/bash
# Generic test runner for Python virtual environment-based projects WITH COVERAGE
# This version runs tests WITHOUT energibridge to collect coverage data
# Usage: ./run_tests_venv_generic_coverage.sh <project_name> [number_of_runs] [folder1] [folder2] [suffix]
# Example: ./run_tests_venv_generic_coverage.sh python-dts-calibration_197 1 before after_careful_mock only_mock_part
# Example: ./run_tests_venv_generic_coverage.sh autosubmit_2367 1
# If number_of_runs is not specified, defaults to 1 (coverage usually only needs one run)
# If folder names are not specified, defaults to "before" and "after"
# If suffix is not specified, defaults to "" (uses test_config.sh)

set -e

# Check arguments
if [ $# -lt 1 ] || [ $# -gt 5 ]; then
    echo "Usage: $0 <project_name> [number_of_runs] [folder1] [folder2] [suffix]"
    echo "Example: $0 python-dts-calibration_197 1 before after_careful_mock only_mock_part"
    echo "Example: $0 autosubmit_2367 1"
    echo "If number_of_runs is not specified, defaults to 1"
    echo "If folder names are not specified, defaults to 'before' and 'after'"
    echo "If suffix is not specified, defaults to '' (uses test_config.sh)"
    exit 1
fi

PROJECT_NAME=$1
N=${2:-1}  # Default to 1 for coverage runs
FOLDER1=${3:-before}  # Default to "before" if not specified
FOLDER2=${4:-after}   # Default to "after" if not specified
SUFFIX=${5:-}  # Default to empty string if not specified

# Build config file and log file names based on suffix
if [ -z "$SUFFIX" ]; then
    CONFIG_FILE="test_config.sh"
    LOG_FILE_NAME="coverage_results.log"
    COVERAGE_SUFFIX=""
else
    CONFIG_FILE="test_config_${SUFFIX}.sh"
    LOG_FILE_NAME="coverage_results_${SUFFIX}.log"
    COVERAGE_SUFFIX="_${SUFFIX}"
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

if [ -z "$VENV_PATH" ]; then
    echo "Error: VENV_PATH not defined in $CONFIG_FILE"
    exit 1
fi

# Define log file
LOG_FILE="$PROJECT_DIR/$LOG_FILE_NAME"

# Clear previous log file
> "$LOG_FILE"

echo "========================================" | tee -a "$LOG_FILE"
echo "Starting COVERAGE collection for project: $PROJECT_NAME" | tee -a "$LOG_FILE"
echo "Config file: $CONFIG_FILE" | tee -a "$LOG_FILE"
echo "Comparing: $FOLDER1 vs $FOLDER2" | tee -a "$LOG_FILE"
echo "Iterations: $N" | tee -a "$LOG_FILE"
echo "Test command: $TEST_COMMAND" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "NOTE: Running WITHOUT energibridge to collect coverage data" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Function to run tests for a version (before/after) with coverage
run_version_tests() {
    local VERSION=$1
    local VERSION_DIR="$PROJECT_DIR/$VERSION"

    # Check if version directory exists
    if [ ! -d "$VERSION_DIR" ]; then
        echo "Warning: Version directory '$VERSION_DIR' not found, skipping..." | tee -a "$LOG_FILE"
        return
    fi

    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "Starting COVERAGE collection for $VERSION version" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"

    # Change to version directory
    cd "$VERSION_DIR"

    # Determine coverage source path
    # For symlinked directories (like after_careful_mock), we need to track the actual source
    COVERAGE_SOURCE=""
    if [ "$VERSION" != "$FOLDER1" ] && [ -L "src" ]; then
        # This is likely after/after_careful_mock with symlinked src
        COVERAGE_SOURCE="--source=../$FOLDER1/src"
        echo "Detected symlinked source, using: $COVERAGE_SOURCE" | tee -a "$LOG_FILE"
    fi

    # Check if this is a uv-based project
    if [ "$USE_UV" = "true" ]; then
        echo "Detected uv-based project, skipping traditional venv creation..." | tee -a "$LOG_FILE"
        echo "uv will manage the virtual environment via SETUP_COMMAND" | tee -a "$LOG_FILE"
    # Check if virtual environment exists, create if not
    elif [ ! -d "$VENV_PATH" ]; then
        echo "Virtual environment not found at '$VENV_PATH', creating..." | tee -a "$LOG_FILE"

        # Use custom Python version if specified, otherwise default to python3
        PYTHON_CMD="${PYTHON_VERSION:-python3.10}"
        echo "Using Python: $PYTHON_CMD" | tee -a "$LOG_FILE"

        $PYTHON_CMD -m venv "$VENV_PATH" 2>&1 | tee -a "$LOG_FILE"

        if [ $? -ne 0 ]; then
            echo "Error: Failed to create virtual environment" | tee -a "$LOG_FILE"
            cd "$BASE_DIR"
            return 1
        fi

        echo "Virtual environment created successfully" | tee -a "$LOG_FILE"

        # Activate and install dependencies if requirements file exists
        source "$VENV_PATH/bin/activate"

        # Check for various dependency files and install
        if [ -f "requirements.txt" ]; then
            echo "Installing dependencies from requirements.txt..." | tee -a "$LOG_FILE"
            pip install --upgrade pip 2>&1 | tee -a "$LOG_FILE"
            pip install -r requirements.txt 2>&1 | tee -a "$LOG_FILE"
        elif [ -f "pyproject.toml" ]; then
            echo "Installing project in editable mode from pyproject.toml..." | tee -a "$LOG_FILE"
            pip install --upgrade pip 2>&1 | tee -a "$LOG_FILE"
            pip install -e . 2>&1 | tee -a "$LOG_FILE"
        fi

        # Install coverage
        echo "Installing coverage..." | tee -a "$LOG_FILE"
        pip install coverage 2>&1 | tee -a "$LOG_FILE"

        echo "Virtual environment setup complete" | tee -a "$LOG_FILE"
    else
        echo "Activating virtual environment..." | tee -a "$LOG_FILE"
        source "$VENV_PATH/bin/activate"

        # Ensure coverage is installed
        pip install coverage 2>&1 | tee -a "$LOG_FILE"
    fi

    # Run setup command if specified
    if [ ! -z "$SETUP_COMMAND" ]; then
        echo "Running setup command..." | tee -a "$LOG_FILE"
        eval "$SETUP_COMMAND" 2>&1 | tee -a "$LOG_FILE"
    fi

    # Wait if specified
    if [ ! -z "$WAIT_TIME" ]; then
        echo "Waiting ${WAIT_TIME}s before starting tests..." | tee -a "$LOG_FILE"
        sleep $WAIT_TIME
    fi

    # Clean old coverage data
    echo "Cleaning old coverage data..." | tee -a "$LOG_FILE"
    rm -f .coverage "coverage_${VERSION}${COVERAGE_SUFFIX}.json"
    rm -rf "htmlcov_${VERSION}${COVERAGE_SUFFIX}"

    # Run tests N times with coverage
    for i in $(seq 1 $N); do
        echo "" | tee -a "$LOG_FILE"
        echo "=========================================" | tee -a "$LOG_FILE"
        echo "Coverage run $i/$N for $VERSION" | tee -a "$LOG_FILE"
        echo "Time: $(date)" | tee -a "$LOG_FILE"
        echo "=========================================" | tee -a "$LOG_FILE"

        # Modify TEST_COMMAND to use coverage
        # Replace "pytest", "python -m pytest", or "python3.x -m pytest" with "coverage run --branch"
        # Add -p no:cov to disable pytest-cov plugin and -o addopts="" to clear coverage-related options from pytest.ini
        COVERAGE_COMMAND=$(echo "$TEST_COMMAND" | sed -E 's/(python[0-9.]* -m )?pytest/coverage run --branch '"$COVERAGE_SOURCE"' -m pytest -p no:cov -o addopts=""/')

        echo "Running: $COVERAGE_COMMAND" | tee -a "$LOG_FILE"

        # Run test command WITHOUT energibridge but WITH coverage
        # For uv projects, don't source venv as uv run handles it
        if [ "$USE_UV" = "true" ]; then
            # Use eval to properly handle complex commands with arguments
            eval "$COVERAGE_COMMAND" 2>&1 | tee -a "$LOG_FILE" || true
        else
            # Use bash -c to ensure the virtualenv PATH is used
            bash -c "source '$VENV_PATH/bin/activate' && $COVERAGE_COMMAND" 2>&1 | tee -a "$LOG_FILE" || true
        fi

        echo "" | tee -a "$LOG_FILE"

        # Sleep between runs if not the last run
        if [ $i -lt $N ]; then
            echo "Sleeping 5 seconds..." | tee -a "$LOG_FILE"
            sleep 5
        fi
    done

    # Generate coverage reports
    echo "" | tee -a "$LOG_FILE"
    echo "=========================================" | tee -a "$LOG_FILE"
    echo "Generating coverage reports for $VERSION..." | tee -a "$LOG_FILE"
    echo "=========================================" | tee -a "$LOG_FILE"

    if [ "$USE_UV" != "true" ]; then
        source "$VENV_PATH/bin/activate"
    fi

    # Determine where the .coverage file is located
    # If TEST_COMMAND contains 'cd <dir>', we need to run coverage commands from that directory
    COVERAGE_DIR="."
    if [[ "$TEST_COMMAND" =~ cd[[:space:]]+([^[:space:]\&\;]+) ]]; then
        COVERAGE_DIR="${BASH_REMATCH[1]}"
        echo "Detected coverage data in subdirectory: $COVERAGE_DIR" | tee -a "$LOG_FILE"
    fi

    # Change to coverage directory if needed
    if [ "$COVERAGE_DIR" != "." ]; then
        cd "$COVERAGE_DIR"
        echo "Changed to directory: $(pwd)" | tee -a "$LOG_FILE"
    fi

    # Check for coverage data files
    # Some projects use parallel=true which creates multiple coverage files that need to be combined
    if [ ! -f ".coverage" ]; then
        # Check for parallel coverage files (*.cov.* pattern or .coverage.*)
        PARALLEL_FILES=$(ls .coverage.* 2>/dev/null || ls *.cov.* 2>/dev/null || true)
        if [ -n "$PARALLEL_FILES" ]; then
            echo "Detected parallel coverage files, combining them..." | tee -a "$LOG_FILE"
            coverage combine 2>&1 | tee -a "$LOG_FILE"
            if [ $? -eq 0 ]; then
                echo "Successfully combined coverage data" | tee -a "$LOG_FILE"
            else
                echo "Warning: Failed to combine coverage data" | tee -a "$LOG_FILE"
            fi
        else
            echo "Warning: No coverage data files found in $(pwd)" | tee -a "$LOG_FILE"
            echo "Coverage data may not have been collected properly" | tee -a "$LOG_FILE"
        fi
    fi

    # Generate terminal report (limit to source code only)
    echo "Coverage report:" | tee -a "$LOG_FILE"
    if [ -n "$COVERAGE_SOURCE" ]; then
        # If COVERAGE_SOURCE is set, use it for filtering
        coverage report 2>&1 | tee -a "$LOG_FILE"
    else
        # Try to detect source directory
        if [ -d "src" ]; then
            coverage report --include="src/*" 2>&1 | tee -a "$LOG_FILE"
        else
            coverage report 2>&1 | tee -a "$LOG_FILE"
        fi
    fi

    # Generate HTML report
    HTML_DIR="../htmlcov_${VERSION}${COVERAGE_SUFFIX}"
    if [ "$COVERAGE_DIR" = "." ]; then
        HTML_DIR="htmlcov_${VERSION}${COVERAGE_SUFFIX}"
    fi
    if [ -d "src" ]; then
        coverage html -d "$HTML_DIR" --include="src/*" 2>&1 | tee -a "$LOG_FILE"
    else
        coverage html -d "$HTML_DIR" 2>&1 | tee -a "$LOG_FILE"
    fi
    echo "HTML report saved to: $HTML_DIR/index.html" | tee -a "$LOG_FILE"

    # Generate JSON report
    JSON_FILE="../coverage_${VERSION}${COVERAGE_SUFFIX}.json"
    if [ "$COVERAGE_DIR" = "." ]; then
        JSON_FILE="coverage_${VERSION}${COVERAGE_SUFFIX}.json"
    fi
    if [ -d "src" ]; then
        coverage json -o "$JSON_FILE" --include="src/*" 2>&1 | tee -a "$LOG_FILE"
    else
        coverage json -o "$JSON_FILE" 2>&1 | tee -a "$LOG_FILE"
    fi
    echo "JSON report saved to: $JSON_FILE" | tee -a "$LOG_FILE"

    # Return to VERSION_DIR
    if [ "$COVERAGE_DIR" != "." ]; then
        cd "$VERSION_DIR"
    fi

    # Deactivate virtual environment (skip for uv projects)
    if [ "$USE_UV" != "true" ]; then
        deactivate
    fi

    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "Completed $VERSION version at: $(date)" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"

    # Return to base directory
    cd "$BASE_DIR"
}

# Main execution
echo "========================================"
echo "Generic Python Venv Coverage Runner"
echo "Project: $PROJECT_NAME"
echo "Config file: $CONFIG_FILE"
echo "Log file: $LOG_FILE_NAME"
echo "Comparing: $FOLDER1 vs $FOLDER2"
echo "Runs per version: $N"
echo "========================================"
echo ""

# Run tests for first folder
run_version_tests "$FOLDER1"

echo ""
echo "Sleeping 10 seconds between versions..."
sleep 10
echo ""

# Run tests for second folder
run_version_tests "$FOLDER2"

echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "All coverage collection completed at: $(date)" | tee -a "$LOG_FILE"
echo "Compared: $FOLDER1 vs $FOLDER2" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo ""
echo "Coverage reports saved:"
echo "  $FOLDER1:"
if [ -z "$SUFFIX" ]; then
    echo "    - HTML: $PROJECT_DIR/$FOLDER1/htmlcov_${FOLDER1}/index.html"
    echo "    - JSON: $PROJECT_DIR/$FOLDER1/coverage_${FOLDER1}.json"
else
    echo "    - HTML: $PROJECT_DIR/$FOLDER1/htmlcov_${FOLDER1}_${SUFFIX}/index.html"
    echo "    - JSON: $PROJECT_DIR/$FOLDER1/coverage_${FOLDER1}_${SUFFIX}.json"
fi
echo ""
echo "  $FOLDER2:"
if [ -z "$SUFFIX" ]; then
    echo "    - HTML: $PROJECT_DIR/$FOLDER2/htmlcov_${FOLDER2}/index.html"
    echo "    - JSON: $PROJECT_DIR/$FOLDER2/coverage_${FOLDER2}.json"
else
    echo "    - HTML: $PROJECT_DIR/$FOLDER2/htmlcov_${FOLDER2}_${SUFFIX}/index.html"
    echo "    - JSON: $PROJECT_DIR/$FOLDER2/coverage_${FOLDER2}_${SUFFIX}.json"
fi
echo ""
echo "Next step - Compare coverage:"
if [ -z "$SUFFIX" ]; then
    echo "  python3 compare_coverage.py $PROJECT_NAME $FOLDER1 $FOLDER2"
else
    echo "  python3 compare_coverage.py $PROJECT_NAME $FOLDER1 $FOLDER2 $SUFFIX"
fi
