#!/bin/bash
# Test configuration for xarray-regrid_45
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
TEST_COMMAND="python -m pytest tests/test_regrid.py --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
SETUP_COMMAND="pip install pytest pytest-cov cftime && pip install -e ."

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="xarray-regrid_45"
