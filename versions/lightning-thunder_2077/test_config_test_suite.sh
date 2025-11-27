#!/bin/bash
# Test configuration for lightning-thunder_2077
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #2077 testing: Run the entire test_dynamo.py file to measure overall improvement
# The 6 optimized tests (test_reports_benchmark, test_report_thunderfx_pytest_benchmark_report,
# test_fxreport_DynamoThunder_cuda_None, test_ThunderCompilerGraphBenchmarking_groupby,
# test_reports_repro, test_thunder_specific_reports) were reduced from ~240 seconds total
TEST_COMMAND="pytest --ignore=examples --ignore=thunder/benchmarks --ignore=thunder/executors/nvfuserex_impl.py --ignore=thunder/executors/transformer_engine_v2ex_impl.py --ignore=thunder/numpy \
--durations=0 -vv"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run BEFORE venv creation
# Install the package in editable mode with test dependencies
# Includes pytest, pytest-benchmark, hypothesis, and other testing tools
SETUP_COMMAND="pip install --upgrade pip && pip install -e . -r requirements/test.txt && pip install psutil"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (lightning-thunder supports Python 3.10-3.13, uses 3.10-3.12 in CI)
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="lightning-thunder_2077"

# Note: PR #2077 fixes issue #2051 by reducing test time in test_dynamo.py
# The 6 affected tests were taking ~240 seconds combined:
# 1. test_reports_benchmark - was 48.45s
# 2. test_report_thunderfx_pytest_benchmark_report - was 43.39s
# 3. test_fxreport_DynamoThunder_cuda_None[benchmark] - was 43.06s
# 4. test_ThunderCompilerGraphBenchmarking_groupby - was 38.60s
# 5. test_reports_repro - was 34.52s
# 6. test_thunder_specific_reports - was 32.47s
#
# Optimization strategy:
# - Used Hypothesis property-based testing framework
# - Added @hypothesis.given() decorators to generate test cases more efficiently
# - Reduced number of test iterations while maintaining coverage
# - Hypothesis provides reproducible failures with example strings
#
# To verify the fix: Compare test durations between before/ and after/ versions
# Expected improvement: Significant speedup (50-70% reduction) in these 6 tests
# Note: These tests may require CUDA for full execution (test_report_thunderfx_pytest_benchmark_report has @requiresCUDA)
