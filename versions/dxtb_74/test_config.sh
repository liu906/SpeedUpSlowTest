#!/bin/bash
# Test configuration for dxtb_74
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
TEST_COMMAND="python3 -m pytest test/test_hamiltonian/test_h0.py test/test_hamiltonian/test_scf_charged.py --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Python version to use - dxtb requires Python 3.8+
PYTHON_VERSION="python3.10"

# Optional: Setup command to run after activating venv
# Install dependencies and the project in editable mode
# dxtb requires PyTorch, xitorch, pydantic v1 (not v2), tomli, and tad-dftd3
SETUP_COMMAND="pip install --upgrade pip && pip install ase h5py pytest pytest-cov && pip install 'torch>=1.10' 'pydantic<2.0' tomli xitorch tad-dftd3 && pip install -e ."

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="dxtb_74"
