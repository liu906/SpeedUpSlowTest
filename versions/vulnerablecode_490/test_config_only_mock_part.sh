#!/bin/bash
# Test configuration for vulnerablecode_490
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #697 testing: Run ALL test files that are affected by the Zenodo API refactoring
# Includes: Zenodo API tests, workflow tests, and CLI tests that use ZenodoAPI
TEST_COMMAND=".venv/bin/python -m pytest \
vulnerabilities/tests/test_upstream.py::test_updated_advisories \
--durations=0 -vv"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run AFTER venv creation and activation
# Install the package with test and gui dependencies (matching CI workflow)
# Note: 'tests' is an alias for 'test' in case of typo (both work)
# Set SETUPTOOLS_SCM_PRETEND_VERSION to bypass git version detection (hatch-vcs requirement)
SETUP_COMMAND="pip install -e . && pip install saneyaml psycopg2-binary"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (Nipoppy supports Python 3.9-3.13, CI tests all)
# Using python3.10 as a stable middle version
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="vulnerablecode_490"

