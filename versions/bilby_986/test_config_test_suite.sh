#!/bin/bash
# Test configuration for bilby_986
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# Run with coverage first, then mutation testing
TEST_COMMAND="pytest --durations=0 --cov=. --cov-report=term --cov-report=html && mutmut run && mutmut results"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
SETUP_COMMAND="pip install numpy scipy pytest parameterized pytest-cov mutmut && pip install -e '.[all]' "

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="bilby_986"
