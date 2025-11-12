#!/bin/bash
# Test configuration for pyjelly_235
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #235 testing: Run the integration test file that was modified
# This test runs all example scripts in the examples/rdflib directory
TEST_COMMAND="uv run pytest tests/integration_tests/test_rdflib/test_examples.py::test_rdflib_examples[01_serialize.py] --durations=0 -v 2>&1 | tail -15"


# Virtual environment path (relative to the version directory: before/ or after/)
# Note: uv manages its own virtual environment, so we use a standard path
VENV_PATH=".venv"

# Optional: Setup command to run AFTER venv creation and activation
# This project uses uv for dependency management
# Run uv sync to install all dependencies including test dependencies
# IMPORTANT: The project specifies required-version = "~=0.7.3" in [tool.uv]
# but we have uv 0.8.19 installed. We temporarily remove this constraint to proceed.
# The sed command removes the "required-version" line before running uv sync.
SETUP_COMMAND="sed -i.bak '/^required-version.*=/d' pyproject.toml && uv sync"

# Flag to indicate this IS a uv-based project
USE_UV="true"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (pyjelly supports Python 3.9-3.13, CI tests multiple versions)
# Using python3.10 as a stable version
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="pyjelly_235"

# Note: PR #235 mocks HTTP requests in example tests
# The PR title: "Mock HTTP requests in example tests"
# Related issue: #233
#
# Changes made:
# 1. Added test data files to avoid actual HTTP requests during tests
# 2. Modified test_examples.py to mock urllib.request.urlopen
# 3. Added urlopen_mock() function to return local test data based on URL patterns
#
# Files changed in PR #235:
#
# 1. tests/integration_tests/test_rdflib/test_examples.py (MODIFIED - primary change)
#    Changes:
#    - Added urlopen_mock() function to intercept HTTP requests
#    - Modified test_rdflib_examples() to use monkeypatch for mocking
#    - Mock returns local test data files instead of making real HTTP calls
#    - Specific implementation:
#      * Mocks urllib.request.urlopen
#      * Returns sample.jelly, sample.jelly.gz, sample.nt, or sample.nt.gz
#      * Based on URL patterns in the request
#
# 2. tests/integration_tests/test_rdflib/example_data/sample.jelly (NEW)
#    - Binary Jelly format test data file (3.33 KB)
#
# 3. tests/integration_tests/test_rdflib/example_data/sample.jelly.gz (NEW)
#    - Compressed Jelly format test data file (1.39 KB)
#
# 4. tests/integration_tests/test_rdflib/example_data/sample.nt (NEW)
#    - RDF N-Triples format test data file (55 lines)
#
# 5. tests/integration_tests/test_rdflib/example_data/sample.nt.gz (NEW)
#    - Compressed N-Triples test data file (965 bytes)
#
# Test structure:
# - test_examples.py discovers all *.py files in examples/rdflib/ directory
# - Parametrizes test_rdflib_examples() with each example script
# - Runs each example script in a temp directory using runpy.run_path()
# - Mocks HTTP requests to prevent actual network calls
#
# Example scripts tested (in examples/rdflib/):
# - 01_serialize.py - Basic serialization example
# - 02_parse.py - Basic parsing example
# - 03_parse_autodetect.py - Auto-detect format parsing
# - 04_parse_grouped.py - Grouped stream parsing
# - 05_parse_flat.py - Flat stream parsing
# - 06_serialize_grouped.py - Grouped stream serialization
# - 07_serialize_flat.py - Flat stream serialization
#
# Performance Impact:
# This PR IMPROVES test performance and reliability by:
# - Eliminating network I/O during tests (faster execution)
# - Removing dependency on external HTTP services (more reliable)
# - Tests no longer fail due to network issues or service downtime
#
# How PR #235 was tested:
# The PR author noted: "This kind of works, I think it's still broken for the
# first example for some reason. I declare this 'good enough' if the CI will pass."
# The codecov report shows: "All modified and coverable lines are covered by tests ✅"
#
# Project-specific notes:
# - This project uses uv for dependency management (NOT pip)
# - CI uses: uv sync for installation
# - CI test command: uv run pytest -vv
# - With conformance tests: uv run pytest -vv --cov --cov-branch --cov-report=xml
# - Project has dependency-groups in pyproject.toml (not optional-dependencies for dev tools)
# - Supported Python versions: 3.9, 3.10, 3.11, 3.12, 3.13, PyPy3.10, PyPy3.11
# - Tests include: unit_tests/, integration_tests/, conformance_tests/, e2e_tests/
#
# To verify the fix: Compare test results between before/ and after/ versions
# Expected outcome: Tests pass without making actual HTTP requests
# The after/ version should have the new test data files in example_data/ directory
# The urlopen_mock function should be present in after/tests/integration_tests/test_rdflib/test_examples.py
