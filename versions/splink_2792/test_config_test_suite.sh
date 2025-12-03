#!/bin/bash
# Test configuration for splink_2792
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #2792 testing: Run the test suite to measure overall improvement
# Splink uses pytest with markers to select test subsets
# The default marker runs the standard test suite
TEST_COMMAND=".venv/bin/pytest --durations=0 -v"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run AFTER venv creation
# Splink is a uv-based project - dependencies are managed by uv
# First create the uv virtual environment, then install the package in editable mode with testing dependencies
SETUP_COMMAND="uv venv .venv --python python3.10 && uv pip install -e . --group dev --group testing"

# Flag to indicate this IS a uv-based project
USE_UV="true"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (splink requires Python >=3.8.0,<4.0.0)
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="splink_2792"

# Note: PR #2792 - Add specific PR description here
# Splink is a fast probabilistic data linkage at scale package
# The project uses pytest with custom markers for different test backends:
# - core: tests where backend is irrelevant
# - default: standard test suite (default marker in pytest config)
# - duckdb, spark, sqlite, postgres: backend-specific tests
#
# Test dependencies (from testing group):
# - pytest>=7.3
# - pyarrow>=7.0.0
# - networkx>=2.5.1
# - rapidfuzz>=2.0.3
#
# To verify the fix: Compare test durations between before/ and after/ versions
# Expected improvement: Identify which specific tests were optimized in PR #2792
