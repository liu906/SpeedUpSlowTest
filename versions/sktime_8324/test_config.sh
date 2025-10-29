#!/bin/bash
# Test configuration for sktime_8324
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #8324 testing: Run the classifier tests for ShapeDTW that were optimized
# This targets the specific classifier that had performance improvements
# Using -k ShapeDTW to run only ShapeDTW-related tests from test_all_classifiers.py
# IMPORTANT: Disable --matrixdesign and --only_changed_modules to avoid git errors
# These flags require git remote/main branch which doesn't exist in isolated test dirs
# Use -n 0 to disable parallel execution (clearer timing, avoids -n auto from setup.cfg)
TEST_COMMAND="python -m pytest sktime/classification/tests/test_all_classifiers.py -k ShapeDTW -v -vv --durations=0 --matrixdesign=False --only_changed_modules=False -n 0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run AFTER venv creation and activation
# This project uses pip for dependency management
# Install in editable mode with dev dependencies
# Project uses setup.cfg and pyproject.toml for configuration
# Need to install: pytest, pytest-xdist (for parallel execution), pytest-timeout
# Install with [all_extras_pandas2,dev] to match CI environment
# Force reinstall scipy to fix import issues
SETUP_COMMAND="python -m pip install --upgrade pip && python -m pip install scipy scikit-learn --force-reinstall --no-cache-dir && python -m pip install -e .[all_extras_pandas2,dev] --no-cache-dir"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (project supports Python 3.9-3.13, using 3.9 for compatibility)
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="sktime_8324"

# Note: PR #8324 optimizes ShapeDTW test performance by making grid search parameters configurable
# The PR title: "[MNT] Make grid search parameters in ShapeDTW configurable to enable faster testing"
#
# Performance Impact:
# - BEFORE: ShapeDTW params2 test execution time ~114.19 seconds
# - AFTER: ShapeDTW params2 test execution time ~26.51 seconds (with n_splits=2)
# - IMPROVEMENT: ~77% reduction (4.3x faster)
#
# Changes made:
# 1. Added n_splits parameter to ShapeDTW class (default: 10)
# 2. Made grid search cross-validation splits configurable
# 3. Updated test parameters to use n_splits=2 for faster testing
# 4. Enabled custom weighting_factor values via metric_params
#
# Files changed in PR #8324:
#
# SOURCE/TEST FILE (1 file):
#
# 1. sktime/classification/distance_based/_shape_dtw.py (MODIFIED - tested here)
#    Changes:
#    - Added n_splits parameter to __init__() method
#      * Default value: 10 (maintains backward compatibility)
#      * Configurable for testing scenarios
#
#    - Modified _calculate_weighting_factor_value() method (line 209-273)
#      * Changed hardcoded KFold(n_splits=10) to KFold(n_splits=self.n_splits)
#      * Allows flexible cross-validation configuration
#      * Reduces grid search time when n_splits is lower
#
#    - Updated get_test_params() method (line 524-550)
#      * params1: {} (unchanged - uses default parameters)
#      * params2: Added "n_splits": 2 to test configuration
#      * params2 triggers compound shape descriptor with grid search
#      * Grid search tests 11 weighting factors with 2-fold CV (down from 10-fold)
#
#    - Enhanced metric_params support
#      * Can now pass custom weighting_factor list via metric_params
#      * Bypasses grid search if weighting_factor is provided
#      * More flexible for different use cases
#
# What gets tested:
# The test suite runs all classifier tests for ShapeDTW with two parameter sets:
#
# params1 (baseline):
#   - n_neighbors: 1 (default)
#   - subsequence_length: 30
#   - shape_descriptor_function: "raw"
#   - No grid search involved
#   - Fast execution (~few seconds)
#
# params2 (optimized in this PR):
#   - n_neighbors: 3
#   - subsequence_length: 30
#   - shape_descriptor_function: "compound"
#   - shape_descriptor_functions: ["paa", "dwt"]
#   - n_splits: 2 (NEW - was 10 by default)
#   - Triggers grid search over 11 weighting factors
#   - BEFORE: 11 factors × 10-fold CV = 110 model fits
#   - AFTER: 11 factors × 2-fold CV = 22 model fits
#   - This is where the 77% speedup comes from
#
# Test execution flow:
# 1. test_all_classifiers.py discovers ShapeDTW via pytest_generate_tests
# 2. Creates test instances using get_test_params() (params1 and params2)
# 3. Runs standard classifier interface tests:
#    - test_fit_returns_self
#    - test_classifier_output
#    - test_multivariate_input_exception
#    - test_predict_proba
#    - And other generic estimator tests from test_all_estimators
# 4. Each test runs for both param sets
# 5. params2 tests run much faster with n_splits=2
#
# Why ShapeDTW was slow:
# ShapeDTW is a distance-based time series classifier that:
# 1. Extracts subsequences from time series data
# 2. Applies shape descriptor functions (raw, PAA, DWT, slope, derivative, HOG1D)
# 3. Uses DTW (Dynamic Time Warping) with 1-NN for classification
# 4. For "compound" mode: combines two shape descriptors
# 5. Tunes weighting_factor via grid search with cross-validation
#
# The grid search (line 257-268) was the bottleneck:
# - 11 weighting factors to test: [0.1, 0.125, 1/6, 0.25, 0.5, 1, 2, 4, 6, 8, 10]
# - 10-fold cross-validation for each factor
# - Each fold requires: subsequence extraction + shape transformation + DTW + 1-NN
# - This happens during the fit() call in test execution
#
# The optimization:
# By making n_splits configurable and using n_splits=2 in tests:
# - Reduces 10-fold CV to 2-fold CV
# - 80% fewer model fits during grid search
# - Test execution time drops from ~114s to ~27s
# - Production code still uses n_splits=10 by default (better model selection)
# - Tests run faster without sacrificing test coverage
#
# Key design principles:
# 1. Backward compatibility: Default n_splits=10 preserves existing behavior
# 2. Test optimization: Tests use n_splits=2 for speed
# 3. Flexibility: Users can override n_splits for their use cases
# 4. No accuracy loss: Tests still verify correctness, just faster
#
# Project-specific notes:
# - This project uses pip for dependency management (NOT uv or conda)
# - Installation: pip install -e .[all_extras_pandas2,dev]
# - CI uses multiple workflows: test.yml, test_module.yml, test_all.yml, etc.
# - Test command in CI: make test_without_datasets (uses pytest under the hood)
# - README recommends: pip install sktime[all_extras]
# - Supported Python versions: 3.9, 3.10, 3.11, 3.12, 3.13
# - Build system: setuptools (setup.cfg + pyproject.toml)
# - Key dependencies: numpy, pandas, scikit-learn, numba, statsmodels
# - Test framework: pytest with custom plugins (conftest.py)
# - Test parallelization: pytest-xdist with -n auto flag
# - Test timeout: 600 seconds default (setup.cfg)
#
# Pytest configuration (setup.cfg):
# - addopts:
#   * --ignore build_tools examples docs
#   * --durations 20 (show 20 slowest tests)
#   * --timeout 600 (10 minute timeout)
#   * --showlocals (show local variables on failure)
#   * --matrixdesign True (subsample estimators by OS/version)
#   * --only_changed_modules True (test only changed modules)
#   * -n auto (parallel execution with all CPU cores)
#
# Custom pytest options (conftest.py):
# - --matrixdesign: Enable OS/version partitioning for CI
# - --only_changed_modules: Test only changed modules (differential testing)
# - --only_cython_estimators: Test only cython estimators
#
# To verify the optimization: Compare test execution times between before/ and after/ versions
# Expected outcome:
# - BEFORE: ShapeDTW tests take ~114 seconds (params2 with n_splits=10 default)
# - AFTER: ShapeDTW tests take ~27 seconds (params2 with n_splits=2)
# - All tests should pass in both versions
# - Test behavior remains identical (same coverage, different speed)
#
# Performance expectation:
# The PR focuses on a specific classifier (ShapeDTW) with specific parameters (params2)
# The 77% speedup applies to ShapeDTW params2 tests specifically
# Other classifier tests are unaffected
# Overall test suite improvement depends on ShapeDTW test proportion
#
# Running specific test categories:
# - All classifiers: pytest sktime/classification/tests/test_all_classifiers.py
# - Only ShapeDTW: pytest sktime/classification/tests/test_all_classifiers.py -k ShapeDTW
# - Only params2: pytest sktime/classification/tests/test_all_classifiers.py -k ShapeDTW -k params2
# - With durations: pytest sktime/classification/tests/test_all_classifiers.py -k ShapeDTW --durations=0
# - Verbose output: pytest sktime/classification/tests/test_all_classifiers.py -k ShapeDTW -vv
#
# Alternative test commands:
#
# 1. Test only ShapeDTW with verbose output:
#    TEST_COMMAND="python -m pytest sktime/classification/tests/test_all_classifiers.py::TestAllClassifiers -k ShapeDTW -vv --durations=0"
#
# 2. Test all distance-based classifiers (includes ShapeDTW):
#    TEST_COMMAND="python -m pytest sktime/classification/distance_based/tests/ -v --durations=0"
#
# 3. Test with parallel execution disabled (for clearer timing):
#    TEST_COMMAND="python -m pytest sktime/classification/tests/test_all_classifiers.py -k ShapeDTW -v --durations=0 -p no:xdist"
#
# 4. Test with matrixdesign disabled (test all estimators):
#    TEST_COMMAND="python -m pytest sktime/classification/tests/test_all_classifiers.py -k ShapeDTW -v --durations=0 --matrixdesign=False"
#
# Understanding the test output:
# You'll see test cases like:
# - test_fit_returns_self[ShapeDTW-0]  # params1 (fast)
# - test_fit_returns_self[ShapeDTW-1]  # params2 (optimized)
# - test_classifier_output[ShapeDTW-0-scenario]  # params1
# - test_classifier_output[ShapeDTW-1-scenario]  # params2 (where speedup is visible)
#
# The [ShapeDTW-1] tests (params2) should be significantly faster in after/ version
#
# Debugging tips:
# 1. If tests fail with import errors, check if all dependencies are installed
# 2. If tests are still slow, verify n_splits=2 is in params2 (after/ version)
# 3. If parallel execution causes issues, add -n 0 or -p no:xdist
# 4. For memory issues, reduce parallelism: -n 2 (use 2 workers instead of auto)
#
# PR #8324 Timeline:
# - Opened: May 2025
# - Merged: June 2, 2025
# - Status: Merged into main
# - Checks: 51 passed
# - Labels: enhancement, module:classification
# - Reviewer: fkiraly (approved)
#
# Related issues:
# - Issue #8323: Original issue requesting configurable grid search parameters
# - Context: ShapeDTW tests were identified as slow during CI runs
# - Solution: Make grid search parameters configurable for testing
#
# Impact on development workflow:
# - Faster local testing for developers working on ShapeDTW
# - Faster CI feedback loop for PRs touching classification module
# - Better test maintainability (can adjust n_splits as needed)
# - Enables future optimizations (can add more configurable parameters)
#
# Future improvements suggested:
# - Make weighting_factor grid configurable (partially done via metric_params)
# - Add option to skip grid search entirely in tests (use fixed weighting_factor)
# - Consider caching grid search results for repeated tests
# - Profile other slow classifiers for similar optimizations
