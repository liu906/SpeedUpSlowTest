#!/bin/bash
# Test configuration for scikit-learn_21984
# This file is sourced by run_tests_venv_generic.sh

# Test command to run
TEST_COMMAND="python -m pytest --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Python version to use (defaults to python3.10 in run_tests_venv_generic.sh)
# PYTHON_VERSION="python3.9"

# Optional: Setup command to run after venv is activated (e.g., install test dependencies)
SETUP_COMMAND="pip install --upgrade pip setuptools wheel && pip install 'numpy<2.0' 'scipy<1.12' 'cython<3.0' joblib threadpoolctl && pip install pytest && python setup.py build_ext --inplace 2>&1 | tail -20"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="scikit-learn_21984"