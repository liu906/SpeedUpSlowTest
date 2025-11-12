#!/bin/bash
# Generic test runner for Docker and Python virtual environment-based projects
# Usage: ./run_tests_generic.sh <project_name> [number_of_runs] [folder1] [folder2] [suffix]
# Example: ./run_tests_generic.sh BuffaLogs_399 10
# Example: ./run_tests_generic.sh bilby_986 10 before after_mock
# Example: ./run_tests_generic.sh bilby_986 10 before after_mock mock
#   (This will use test_config_mock.sh and test_results_mock.log)
# If number_of_runs is not specified, defaults to 10
# If folder names are not specified, defaults to "before" and "after"
# If suffix is not specified, defaults to "" (uses test_config.sh and test_results.log)

set -e

# Check arguments
if [ $# -lt 1 ] || [ $# -gt 5 ]; then
    echo "Usage: $0 <project_name> [number_of_runs] [folder1] [folder2] [suffix]"
    echo "Example: $0 BuffaLogs_399 5"
    echo "Example: $0 bilby_986 10 before after_mock"
    echo "Example: $0 bilby_986 10 before after_mock mock"
    echo "  (This will use test_config_mock.sh and test_results_mock.log)"
    echo "If number_of_runs is not specified, defaults to 10"
    echo "If folder names are not specified, defaults to 'before' and 'after'"
    echo "If suffix is not specified, defaults to '' (uses test_config.sh and test_results.log)"
    exit 1
fi

PROJECT_NAME=$1
N=${2:-10}  # Default to 10 if not specified
FOLDER1=${3:-before}  # Default to "before" if not specified
FOLDER2=${4:-after}   # Default to "after" if not specified
SUFFIX=${5:-}  # Default to empty string if not specified

# Build config file and log file names based on suffix
if [ -z "$SUFFIX" ]; then
    CONFIG_FILE="test_config.sh"
    LOG_FILE_NAME="test_results.log"
else
    CONFIG_FILE="test_config_${SUFFIX}.sh"
    LOG_FILE_NAME="test_results_${SUFFIX}.log"
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

echo "========================================" | tee -a "$LOG_FILE"
echo "Starting test runs for project: $PROJECT_NAME" | tee -a "$LOG_FILE"
echo "Config file: $CONFIG_FILE" | tee -a "$LOG_FILE"
echo "Comparing: $FOLDER1 vs $FOLDER2" | tee -a "$LOG_FILE"
echo "Iterations: $N" | tee -a "$LOG_FILE"
echo "Test command: $TEST_COMMAND" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Function to run tests for a version (before/after)
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
    echo "Starting tests for $VERSION version" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"

    # Change to version directory
    cd "$VERSION_DIR"

    # Determine project type and handle accordingly
    if [ "$USE_DOCKER" = "true" ]; then
        # Docker-based project
        echo "Detected Docker-based project" | tee -a "$LOG_FILE"

        # Start Docker containers
        echo "Starting Docker containers..." | tee -a "$LOG_FILE"
        docker compose up -d 2>&1 | tee -a "$LOG_FILE"

        # Wait for containers to be ready (if specified in config)
        if [ ! -z "$WAIT_TIME" ]; then
            echo "Waiting ${WAIT_TIME}s for containers to be ready..." | tee -a "$LOG_FILE"
            sleep $WAIT_TIME
        fi

        # Run setup command if specified in config
        if [ ! -z "$SETUP_COMMAND" ]; then
            echo "Running setup command..." | tee -a "$LOG_FILE"
            eval "$SETUP_COMMAND" 2>&1 | tee -a "$LOG_FILE"
        fi

    else
        # Virtual environment-based project
        echo "Detected virtual environment-based project" | tee -a "$LOG_FILE"

        # Validate VENV_PATH is defined
        if [ -z "$VENV_PATH" ]; then
            echo "Error: VENV_PATH not defined in $CONFIG_FILE for venv project" | tee -a "$LOG_FILE"
            cd "$BASE_DIR"
            return 1
        fi

        # Check if this is a uv-based project
        if [ "$USE_UV" = "true" ]; then
            echo "Detected uv-based project, skipping traditional venv creation..." | tee -a "$LOG_FILE"
            echo "uv will manage the virtual environment via SETUP_COMMAND" | tee -a "$LOG_FILE"
        # Check if virtual environment exists, create if not
        elif [ ! -d "$VENV_PATH" ]; then
            echo "Virtual environment not found at '$VENV_PATH', creating..." | tee -a "$LOG_FILE"

            # Use custom Python version if specified, otherwise default to python3.10
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

            echo "Virtual environment setup complete" | tee -a "$LOG_FILE"
        else
            echo "Activating virtual environment..." | tee -a "$LOG_FILE"
            source "$VENV_PATH/bin/activate"
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
    fi

    # Run tests N times
    for i in $(seq 1 $N); do
        echo "" | tee -a "$LOG_FILE"
        echo "=========================================" | tee -a "$LOG_FILE"
        echo "Test run $i/$N for $VERSION" | tee -a "$LOG_FILE"
        echo "Time: $(date)" | tee -a "$LOG_FILE"
        echo "=========================================" | tee -a "$LOG_FILE"

        # Run test command with energibridge
        if [ "$USE_DOCKER" = "true" ]; then
            # Docker project - run command directly
            eval "energibridge --summary --quiet $TEST_COMMAND" 2>&1 | tee -a "$LOG_FILE"
        elif [ "$USE_UV" = "true" ]; then
            # UV project - don't source venv as uv run handles it
            eval "energibridge --summary --quiet $TEST_COMMAND" 2>&1 | tee -a "$LOG_FILE"
        else
            # Traditional venv project - ensure virtualenv PATH is used
            bash -c "source '$VENV_PATH/bin/activate' && energibridge --summary --quiet $TEST_COMMAND" 2>&1 | tee -a "$LOG_FILE"
        fi

        echo "" | tee -a "$LOG_FILE"

        # Sleep between runs if not the last run
        if [ $i -lt $N ]; then
            echo "Sleeping 5 seconds..." | tee -a "$LOG_FILE"
            sleep 5
        fi
    done

    # Cleanup based on project type
    if [ "$USE_DOCKER" = "true" ]; then
        # Stop and remove Docker containers
        echo "" | tee -a "$LOG_FILE"
        echo "Stopping Docker containers for $VERSION..." | tee -a "$LOG_FILE"
        docker compose down -v 2>&1 | tee -a "$LOG_FILE"
    elif [ "$USE_UV" != "true" ]; then
        # Deactivate virtual environment (skip for uv projects)
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
echo "Generic Test Runner (Docker & Venv)"
echo "Project: $PROJECT_NAME"
echo "Config file: $CONFIG_FILE"
echo "Log file: $LOG_FILE_NAME"
echo "Comparing: $FOLDER1 vs $FOLDER2"
echo "Runs per version: $N"
if [ "$USE_DOCKER" = "true" ]; then
    echo "Project type: Docker"
elif [ "$USE_UV" = "true" ]; then
    echo "Project type: UV (Python)"
else
    echo "Project type: Venv (Python)"
fi
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
echo "All tests completed at: $(date)" | tee -a "$LOG_FILE"
echo "Compared: $FOLDER1 vs $FOLDER2" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo ""
echo "Next steps:"
if [ -z "$SUFFIX" ]; then
    echo "1. Parse and visualize: python3 parse_results_generic_optimized.py $PROJECT_NAME \"\""
    echo "   (Note: Empty suffix uses test_results.log)"
else
    echo "1. Parse and visualize: python3 parse_results_generic_optimized.py $PROJECT_NAME $SUFFIX"
fi
echo "   (Plots are generated automatically)"
