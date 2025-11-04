#!/bin/bash
# Test configuration for SDV_2158
# This file is sourced by run_tests_venv_generic.sh

# Test command to run
TEST_COMMAND="python -m pytest \
tests/integration/multi_table/test_hma.py \
tests/unit/metadata/test_single_table.py \
tests/unit/multi_table/test_base.py \
tests/unit/multi_table/test_hma.py \
--durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH="venv"

# Optional: Python version to use (defaults to python3.10 in run_tests_venv_generic.sh)
# PYTHON_VERSION="python3.9"

# Optional: Setup command to run after venv is activated (e.g., install test dependencies)
SETUP_COMMAND="pip install -e .[test]"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="SDV_2158"