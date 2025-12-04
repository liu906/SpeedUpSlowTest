#!/bin/bash
# Test configuration for ocean.py_1140
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
TEST_COMMAND="python -m pytest --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
# Install PyYAML 6.0+ first, modify setup.py, use --only-binary for PyYAML specifically
SETUP_COMMAND="pip install 'PyYAML>=6.0' && sed -i 's/PyYAML==5.4.1/PyYAML>=5.4.1/g' setup.py && pip install --prefer-binary --only-binary=PyYAML -r requirements_dev.txt"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="ocean.py_1140"
