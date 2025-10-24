#!/bin/bash
# Test configuration for ert_11901
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# Note: For uv-based projects, we use 'uv run' to handle the environment automatically
TEST_COMMAND="uv run pytest -n auto --dist loadgroup tests/ert/unit_tests --hypothesis-profile=fast -m 'not (integration_test or flaky)' --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
# For uv-based projects, the venv is managed by uv in .venv
VENV_PATH=".venv"

# Optional: Setup command to run BEFORE venv creation
# For uv projects, we need to sync dependencies which creates and manages the venv
# The git submodule is required for test data
# IMPORTANT: Set SETUPTOOLS_SCM_PRETEND_VERSION_FOR_ERT to avoid git metadata requirement
SETUP_COMMAND="git init 2>/dev/null || true && export SETUPTOOLS_SCM_PRETEND_VERSION_FOR_ERT=11901.0.0 && uv sync --all-extras && git submodule update --init --recursive"

# Flag to indicate this is a uv-based project
# When set to "true", the generic script should skip pip installation
USE_UV="true"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (uv requires Python 3.11+)
PYTHON_VERSION="python3.13"

# Optional: Additional project-specific variables
PROJECT_NAME="ert_11901"

# Export environment variable for setuptools-scm to avoid git requirement
export SETUPTOOLS_SCM_PRETEND_VERSION_FOR_ERT="11901.0.0"

# Note: ERT uses uv for package management instead of traditional pip
# The rapid-tests justfile target runs:
# pytest -n auto --dist loadgroup tests/ert/unit_tests tests/everest --hypothesis-profile=fast -m "not (integration_test or flaky)"
