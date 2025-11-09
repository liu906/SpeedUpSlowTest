#!/bin/bash
# Test configuration for opensearch-build_595
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #595 testing: Run the specific test file that was modified in the PR
# This test verifies that time.sleep is properly mocked to avoid 100 second test delays
# Note: Using bash -c to wrap the entire command sequence so cd persists through pytest execution
TEST_COMMAND="bash -c 'cd bundle-workflow && PYTHONPATH=src pytest -v --durations=0'"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH="bundle-workflow/.venv"

# Setup command to install dependencies
# Installing packages directly with pip, using compatible versions for Python 3.10
# The project originally uses PyYAML 5.4, but that won't build on Python 3.10
# Using PyYAML 6.0+ which is compatible and functionally equivalent
SETUP_COMMAND="cd bundle-workflow && pip install --upgrade pip && pip install 'pyyaml>=6.0' 'requests>=2.26' pytest 'boto3>=1.18' 'botocore>=1.21' 'coverage>=4.5' 'pytest-cov>=2.10' 'jproperties>=2.1' sortedcontainers 'cerberus>=1.3' 'psutil>=5.8' 'semantic-version>=2.8'"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Optional: Python version (opensearch-build requires Python 3.7, using 3.10 as fallback)
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="opensearch-build_595"

# Note: PR #595 adds time.sleep mocking to prevent slow tests
# PR Title: "Add missing __init__.py files and mock time.sleep in test"
# PR URL: https://github.com/opensearch-project/opensearch-build/pull/595
#
# Changes made in PR #595:
#
# 1. tests/test_integ_workflow/__init__.py (NEW FILE - 10 lines added)
#    - Added sys.path.insert to allow proper module imports
#    - Enables tests to import from bundle-workflow/src directory
#    - BEFORE version: Empty file (0 lines)
#    - AFTER version: Contains sys.path setup (10 lines)
#
# 2. tests/test_integ_workflow/integ_test/__init__.py (NEW FILE - 11 lines added)
#    - Added sys.path.insert for proper imports at integ_test level
#    - Fixes Python path issues in nested test directories
#    - BEFORE version: Does not exist
#    - AFTER version: New file with sys.path setup
#
# 3. tests/test_perf_workflow/perf_test/__init__.py (NEW FILE - 11 lines added)
#    - Added sys.path.insert for perf_test imports
#    - Mirrors the fix applied to integ_test directory
#    - BEFORE version: Does not exist
#    - AFTER version: New file with sys.path setup
#
# 4. tests/test_integ_workflow/integ_test/test_local_test_cluster.py (2 lines modified)
#    Line 116: Added @patch("time.sleep") decorator
#    Line 117: Changed test signature from (self, mock_requests) to (self, *mocks)
#
#    IMPACT: test_wait_for_service_cluster_unavailable() previously took 100 seconds
#    - The test validates cluster unavailability by calling wait_for_service()
#    - wait_for_service() loops 10 times with time.sleep(10) between attempts
#    - Without mocking: 10 attempts × 10 seconds = 100 seconds of real sleep time
#    - With @patch("time.sleep"): Executes instantly (sleep calls are mocked)
#
# Test being modified:
# - test_wait_for_service_cluster_unavailable() in LocalTestClusterTests
#   - Tests the failure path when cluster doesn't become available
#   - Expects ClusterCreationException: "Cluster is not available after 10 attempts"
#   - Previously required 100 seconds to execute (10 sleep cycles)
#   - Now executes in milliseconds with mocked time.sleep
#
# Related source code:
# - bundle-workflow/src/test_workflow/integ_test/local_test_cluster.py:98-113
#   - wait_for_service() method contains the time.sleep(10) calls
#   - Called in a loop that retries up to 10 times
#
# Why we're not using pipenv for this test configuration:
# - The project officially requires Python 3.7 with pipenv
# - PyYAML 5.4.1 (in Pipfile.lock) has Cython build issues on Python 3.10
# - Using direct pip install with compatible package versions
# - PYTHONPATH is set in TEST_COMMAND to include src directory for imports
#   (this replicates what the AFTER version's __init__.py files do)
#
# How PR #595 was tested (per PR description):
# "Ran the tests locally to verify they pass"
#
# To verify the fix: Compare test execution time between before/ and after/ versions
# Expected improvement:
# - BEFORE: test_wait_for_service_cluster_unavailable takes ~100 seconds
# - AFTER: test_wait_for_service_cluster_unavailable takes <1 second
# This is a 100x+ speedup for this specific test
#
# Additional context:
# - The BEFORE version needs PYTHONPATH set because __init__.py is empty
# - The AFTER version has __init__.py files that set up the path automatically
# - Both versions will work with PYTHONPATH set in the test command
