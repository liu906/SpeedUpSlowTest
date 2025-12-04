#!/bin/bash
# Test configuration for evalml_2644
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
TEST_COMMAND="pytest evalml/ --durations=0 --timeout=300"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Python version - numba 0.53 requires Python <3.10
PYTHON_VERSION="python3.9"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
# Install numpy first (needed for pmdarima build), then other dependencies
# pmdarima needs numpy at build time, so we install it separately first
SETUP_COMMAND="pip install 'numpy>=1.20.0,<1.24' && \
pip install -r core-requirements.txt && \
pip install -r requirements.txt && \
pip install -r test-requirements.txt && \
pip install -e . --no-deps"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="evalml_2644"
