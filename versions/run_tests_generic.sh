#!/bin/bash
# Generic test runner for multiple project versions
# Usage: ./run_tests_generic.sh <project_path> [iterations]
#
# Example: ./run_tests_generic.sh BuffaLogs_399 10

set -e  # Exit on error

# Check if project path is provided
if [ -z "$1" ]; then
    echo "Error: Project path is required"
    echo "Usage: $0 <project_path> [iterations]"
    echo "Example: $0 BuffaLogs_399 10"
    exit 1
fi

PROJECT_PATH="$1"
N=${2:-10}  # Number of test iterations (default: 10)

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/$PROJECT_PATH"

# Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project directory not found: $PROJECT_DIR"
    exit 1
fi

# Load project configuration
CONFIG_FILE="$PROJECT_DIR/test_config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    echo "Please create test_config.sh in your project directory"
    exit 1
fi

# Source the configuration
source "$CONFIG_FILE"

# Validate required configuration variables
if [ -z "$TEST_COMMAND" ]; then
    echo "Error: TEST_COMMAND not defined in $CONFIG_FILE"
    exit 1
fi

# Define log file
LOG_FILE="$PROJECT_DIR/test_results.log"

# Clear previous log file
> "$LOG_FILE"

echo "========================================" | tee -a "$LOG_FILE"
echo "Starting test runs for project: $PROJECT_PATH" | tee -a "$LOG_FILE"
echo "Iterations: $N" | tee -a "$LOG_FILE"
echo "Test command: $TEST_COMMAND" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Function to run tests for a specific version
run_tests_for_version() {
    local version=$1
    local version_dir="$PROJECT_DIR/$version"

    if [ ! -d "$version_dir" ]; then
        echo "Warning: Version directory not found: $version_dir, skipping..." | tee -a "$LOG_FILE"
        return
    fi

    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "Starting tests for $version version" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"

    cd "$version_dir"

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
        sleep 5
    fi

    # Run tests N times
    for i in $(seq 1 $N); do
        echo "" | tee -a "$LOG_FILE"
        echo "----------------------------------------" | tee -a "$LOG_FILE"
        echo "Test run $i/$N for $version version" | tee -a "$LOG_FILE"
        echo "----------------------------------------" | tee -a "$LOG_FILE"

        # Run the test command with energy measurement
        energibridge --summary --quiet $TEST_COMMAND 2>&1 | tee -a "$LOG_FILE"

        echo "Test run $i/$N completed" | tee -a "$LOG_FILE"
    done

    # Stop and remove Docker containers
    echo "" | tee -a "$LOG_FILE"
    echo "Stopping Docker containers for $version..." | tee -a "$LOG_FILE"
    docker compose down -v 2>&1 | tee -a "$LOG_FILE"

    cd "$SCRIPT_DIR"
}

# Run tests for before version
run_tests_for_version "before"

# Run tests for after version
run_tests_for_version "after"

echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "All test runs completed!" | tee -a "$LOG_FILE"
echo "Results saved to: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo ""
echo "Next steps:"
echo "1. Parse the results: python3 parse_results_generic_optimized.py $PROJECT_PATH"
echo "2. Visualize the data: python3 visualize_results_generic.py $PROJECT_PATH"
