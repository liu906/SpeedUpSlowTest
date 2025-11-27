#!/bin/bash
# Test configuration for hnn-core_839
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #839 testing: Run the test suite to measure overall improvement
TEST_COMMAND="pytest --durations=0 -v -vv"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run AFTER venv creation
# Install the package in editable mode with test dependencies
# hnn-core requires NEURON (>=7.7), numpy, scipy, matplotlib, h5io
# Test dependencies: flake8, pytest, pytest-cov
# Optional dependencies: scikit-learn, joblib, psutil
# GUI dependencies: ipywidgets, ipykernel, ipympl, voila (needed for test_gui.py)
# IMPORTANT: Pin NEURON to 8.x because the code uses nrnunit_use_legacy(1) which is not supported in NEURON 9.x
# CRITICAL: Delete pre-compiled mechanisms and rebuild them with nrnivmodl after installing NEURON
SETUP_COMMAND="pip install --upgrade pip && pip install 'NEURON>=7.7,<9.0' && rm -rf hnn_core/mod/x86_64 && cd hnn_core/mod && nrnivmodl && cd ../.. && pip install -e .[test,parallel,gui]"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (hnn-core requires Python >=3.8)
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="hnn-core_839"

# Note: PR #839 - Add specific PR description here
# hnn-core is a biophysical simulation package for cortical column modeling using NEURON
# The project uses NEURON for neuronal simulations and includes tests for:
# - Network simulations (test_network.py)
# - Cell models (test_cell.py)
# - Dipole calculations (test_dipole.py)
# - Batch simulations (test_batch_simulate.py)
# - I/O operations (test_io.py)
# - Visualization (test_viz.py)
# - And more...
#
# To verify the fix: Compare test durations between before/ and after/ versions
# Expected improvement: Identify which specific tests were optimized in PR #839
