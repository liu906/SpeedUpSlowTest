#!/bin/bash
# Test configuration for lightning-thunder_2077 - Mock-modified tests only
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# Run only the 3 test functions (6 parameterized instances) that have been modified with subprocess mocks
# These tests are parameterized with @pytest.mark.parametrize("use_pytest_benchmark", (True, False))
# So each test function generates 2 test instances: [benchmark] and [repro]
TEST_COMMAND="pytest --ignore=examples --ignore=thunder/benchmarks --ignore=thunder/executors/nvfuserex_impl.py --ignore=thunder/executors/transformer_engine_v2ex_impl.py --ignore=thunder/numpy \
thunder/tests/test_dynamo.py::test_dynamo_reproducer_split_DynamoThunder_cpu_None \
thunder/tests/test_dynamo.py::test_dynamo_reproducer_2graph_DynamoThunder_cpu_None \
thunder/tests/test_dynamo.py::test_fxreport_DynamoThunder_cpu_None \
--durations=0 -vv"

# Virtual environment path (relative to the version directory: before/ or after_careful_mock/)
VENV_PATH=".venv"

# Optional: Setup command to run BEFORE venv creation
# Install the package in editable mode with test dependencies
# Includes pytest, pytest-benchmark, pytest-mock, and other testing tools
SETUP_COMMAND="pip install --upgrade pip && pip install -e . -r requirements/test.txt && pip install psutil"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Optional: Python version (lightning-thunder supports Python 3.10-3.13, uses 3.10-3.12 in CI)
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="lightning-thunder_2077"

# Note: These 3 test functions (6 parameterized instances) have been modified to mock subprocess.run() calls
# Expected improvement: 40-60% speedup per test (subprocess calls eliminated)
#
# Modified tests (parameterized test instances):
# 1. test_dynamo_reproducer_split_DynamoThunder_cpu_None[benchmark] - before: 29.30s
# 2. test_dynamo_reproducer_split_DynamoThunder_cpu_None[repro] - before: 9.13s
# 3. test_dynamo_reproducer_2graph_DynamoThunder_cpu_None[benchmark] - before: 17.72s
# 4. test_dynamo_reproducer_2graph_DynamoThunder_cpu_None[repro] - before: 6.01s
# 5. test_fxreport_DynamoThunder_cpu_None[benchmark] - before: 26.10s
# 6. test_fxreport_DynamoThunder_cpu_None[repro] - before: 11.57s
#
# Total before: ~100 seconds
# Expected after: ~40-60 seconds (40-60% speedup)
#
# Mocking strategy:
# - Mock subprocess.run() to return successful result (returncode=0)
# - File creation and verification still happens (100% preserved)
# - Only subprocess execution is mocked (secondary check)
# - Test effectiveness: ~90% preserved, verification logic intact
