#!/bin/bash
# Test configuration for mesmer_311
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
TEST_COMMAND="python -m pytest tests/ --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
# Note: numpy needs to be constrained to <2.0 for compatibility with pandas<2.0
# netcdf4 and cftime are required for xarray NetCDF support and calendar handling
SETUP_COMMAND="pip install 'numpy<2.0' netcdf4 cftime && pip install pytest pytest-cov pytest-xdist && pip install -e ."

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="mesmer_311"
