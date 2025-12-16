#!/bin/bash
# Test configuration for python-dts-calibration_197 with coverage
# This file is sourced by run_tests_venv_generic.sh

# Test command to run WITH coverage collection
# Mock-based speedup: Run the 2 mockable tests from the slow test suite
# Test 1: time.sleep() mocked (7s delays eliminated)
# Test 2: read_silixa_files() mocked (file I/O eliminated)
TEST_COMMAND="coverage run -m pytest tests/test_datastore.py::test_to_mf_netcdf_open_mf_datastore tests/test_dtscalibration.py::test_exponential_variance_of_stokes --durations=0 -v && coverage report && coverage html"

# Virtual environment path (relative to the version directory: before/ or after_careful_mock/)
VENV_PATH="venv"

# Optional: Setup command to run AFTER venv creation and activation
# Install coverage if not already installed
SETUP_COMMAND="pip install coverage"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Optional: Python version
# The project uses Python 3.10.12
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="python-dts-calibration_197"
