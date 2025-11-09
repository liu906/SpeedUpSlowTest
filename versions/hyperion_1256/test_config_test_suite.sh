#!/bin/bash
# Test configuration for hyperion_1256
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #1256 testing: Run tests without s03 marker and verify they complete in ~30s
TEST_COMMAND="pytest --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run BEFORE venv creation
# Install the package in editable mode with dev dependencies
# This includes pytest, pytest-cov, pytest-random-order, pytest-asyncio, etc.
# Note: This project requires old setuptools and pip<21.3 to support legacy editable installs
# Also requires specific nexgen and deprecated packages for compatibility
SETUP_COMMAND="pip install --upgrade 'pip<21.3' && pip install 'setuptools<57' 'wheel==0.33.1' && pip install -e .[dev] && pip uninstall -y nexgen && pip install 'nexgen==0.8.4' && pip install deprecated"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (hyperion supports Python 3.9+, uses 3.10 in CI)
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="hyperion_1256"

# Note: PR #1256 fixes issue #1220 by removing logging by default to speed up unit tests
# Expected test duration: ~30 seconds
# The tests should exclude s03 and dlstbx markers which require special simulators
# To verify the fix: tests should pass and complete in approximately 30 seconds
