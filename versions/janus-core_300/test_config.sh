#!/bin/bash
# Test configuration for janus-core_300
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #300 testing: Run the three affected test modules with duration tracking
# This tests the optimizations made to train, eos, and phonon tests
TEST_COMMAND="pytest tests/test_train_cli.py tests/test_eos_cli.py tests/test_phonons_cli.py --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run BEFORE venv creation
# Install the package using poetry with dev dependencies
# Note: This project uses poetry for dependency management
# We install without extras to test core functionality (MACE only, fastest setup)
# For full MLIP testing, add: && poetry install --extras all
SETUP_COMMAND="pip install --upgrade pip && pip install poetry && poetry install --with dev && pip install chgnet"

# Flag to indicate this is NOT a uv-based project (uses poetry instead)
USE_UV="false"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (janus-core supports Python 3.9+, uses 3.9-3.12 in CI)
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="janus-core_300"

# Note: PR #300 improves unit testing efficiency by:
# 1. Training tests (test_train_cli.py):
#    - Reduced training data size (using NaCl instead of large datasets)
#    - Disabled stress computation (compute_stress: False)
#    - Reduced batch size and gradient clipping
# 2. EOS tests (test_eos_cli.py):
#    - Reduced number of volume calculations (--n-volumes 4)
# 3. Phonon tests (test_phonons_cli.py):
#    - Disabled HDF5 file creation (--no-hdf5)
#    - Reduced supercell sizes (--supercell 1x1x1)
#    - Optimized YAML file parsing (line-by-line instead of full load)
#    - Disabled full file writing (--no-write-full)
#
# To verify the fix: Compare test durations between before/ and after/ versions
# Expected improvement: Significant speedup in the three test modules mentioned above
