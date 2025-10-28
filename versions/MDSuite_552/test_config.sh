#!/bin/bash
# Test configuration for MDSuite_552
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #552 testing: Run ALL test files that were modified in the PR
# Includes: helper methods (JAX functions), transformations, and GK distinct diffusion
# Note: Integration tests may fail due to SSL cert issues when downloading test data
TEST_COMMAND="pytest CI/unit_tests/utils/test_calculator_helper_methods.py CI/unit_tests/transformations/test_transformator_parent.py CI/integration_tests/calculators/test_green_kubo_distinct_diffusion_coefficients.py -v --durations=0"
# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run AFTER venv creation and activation
# Install development dependencies which include pytest, coverage, and testing tools
# Pin scipy<1.14.0 to avoid cumtrapz deprecation (cumtrapz removed in scipy 1.14+)
# Install tf-keras for tensorflow-probability compatibility (required since TF 2.16+)
# Then install the package in editable mode using setup.py
SETUP_COMMAND="pip install -r dev-requirements.txt && pip install 'scipy<1.14.0' tf-keras && pip install -e ."

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (MDSuite supports Python 3.7-3.9, CI tests all three)
# Using python3.10 since it's available on this system (3.9 not installed)
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="MDSuite_552"

# Environment variables to force CPU-only execution (matching CI)
# MDSuite uses TensorFlow but tests should run on CPU for reproducibility
export CUDA_VISIBLE_DEVICES=-1
export TF_CPP_MIN_LOG_LEVEL=3

# Note: PR #552 fixes issues #463, #462, #530 by optimizing distinct coefficient calculations
# The PR title states: "Move distinct coefficient to jax for large speedup"
#
# Changes made:
# 1. Moved Green-Kubo distinct diffusion coefficients to JAX vmapping (100x faster)
# 2. Moved Einstein distinct diffusion coefficients to JAX
# 3. Added JAX and jaxlib to requirements.txt
# 4. Moved helper functions to improve code organization
# 5. Added tests to verify the new implementation
#
# ALL test files modified in PR #552 (based on https://github.com/zincware/MDSuite/pull/552/files):
#
# 1. CI/unit_tests/utils/test_calculator_helper_methods.py (71 lines added)
#    Changes:
#    - Updated imports to include correlate and msd_operation
#    - test_fit_einstein_curve() - Existing test (no changes)
#    - test_correlate() - NEW: Tests correlate() JAX helper function (lines 72-103)
#    - test_msd_operation() - NEW: Tests msd_operation() JAX helper function (lines 105-136)
#    Before: 1 test | After: 3 tests
#
# 2. CI/unit_tests/transformations/test_transformator_parent.py (1 line removed)
#    Changes:
#    - Line 216: Removed blank line (formatting only)
#    - No test function changes, just code cleanup
#
# 3. CI/integration_tests/calculators/test_green_kubo_distinct_diffusion_coefficients.py (1 line modified)
#    Changes:
#    - Line 95: correlation_time parameter changed from 100 to 500
#    - test_project() - Unchanged
#    - test_experiment() - Modified parameter only
#    Note: May fail with SSL errors when downloading NaCl simulation data from GitHub
#
# Performance Impact:
# The new JAX helper functions (test_correlate, test_msd_operation) provide the core
# 100x speedup mentioned in PR #552 by replacing TensorFlow operations with JAX vmapping.
#
# How PR #552 was tested (per PR description):
# "Run the GK distinct test"
#
# To verify the fix: Compare test execution time between before/ and after/ versions
# Expected improvement: 100x speedup (from TensorFlow to JAX vmapping)
# These are integration tests that:
# - Download NaCl simulation data from DataHub (cached via session-scoped fixture)
# - Run the distinct diffusion coefficient calculators
# - Verify they execute successfully (note: actual value assertions are commented out)
