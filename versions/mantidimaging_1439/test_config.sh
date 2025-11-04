#!/bin/bash
# Test configuration for mantidimaging_1439
# This file is sourced by run_tests_venv_generic.sh

# Test command to run
# Use full path to avoid conflict with Python's built-in test module
TEST_COMMAND="python -m pytest \
mantidimaging/core/parallel/test/utility_test.py \
-v"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Python version to use (defaults to python3.10 in run_tests_venv_generic.sh)
# PYTHON_VERSION="python3.9"

# Optional: Setup command to run after venv is activated (e.g., install test dependencies)
SETUP_COMMAND="pip install pytest h5py scikit-image PyQt5 pyqtgraph astropy psutil algotom jenkspy && pip install -e ."

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="mantidimaging_1439"