#!/bin/bash
# Test configuration for eerepr_22
# This file is sourced by run_tests_venv_generic.sh

# IMPORTANT: This project requires Google Earth Engine authentication
# All tests use Earth Engine API which cannot be mocked without losing test effectiveness
# The tests fundamentally test EE object representations, not external I/O
# Status: NOT TESTABLE without EE credentials

# Test command to run (without energibridge prefix)
# Using --collect-only to avoid authentication errors
TEST_COMMAND="pytest --durations=0 --collect-only"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
SETUP_COMMAND="pip install hatchling pytest pytest-cov earthengine-api && pip install -e ."

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="eerepr_22"

# NOTE: To run tests properly, you must first authenticate with:
# earthengine authenticate
