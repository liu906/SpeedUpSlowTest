#!/bin/bash
# Test configuration for autosubmit_2367
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
TEST_COMMAND="python3 -m pytest  test/unit/test_autosubmit_helper.py::teste_handle_start_time --durations=0 -vv"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
SETUP_COMMAND="pip install pytest pytest-mock pytest-xdist & pip install -e ."  # Uncomment if needed

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="autosubmit_2367"
