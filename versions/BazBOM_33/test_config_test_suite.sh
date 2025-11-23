#!/bin/bash
# Test configuration for BazBOM_33
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
TEST_COMMAND="python3 -m pytest --durations=0 -v"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
SETUP_COMMAND="pip install freezegun jinja2 jsonschema pytest pytest-cov pytest-mock requests pyyaml && pip install -e .[dev]"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="BazBOM_33"
