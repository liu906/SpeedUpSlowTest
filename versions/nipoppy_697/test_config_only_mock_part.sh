#!/bin/bash
# Test configuration for nipoppy_697
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #697 testing: Run ALL test files that are affected by the Zenodo API refactoring
# Includes: Zenodo API tests, workflow tests, and CLI tests that use ZenodoAPI
TEST_COMMAND="pytest \
tests/test_workflow_runner.py::test_run_multiple \
tests/test_cli.py::test_cli_pipeline_search \
'tests/test_workflow_pipeline_store_install.py::test_download_install_dir_exist[True-False]' \
--durations=0 -vv"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run AFTER venv creation and activation
# Install the package with test and gui dependencies (matching CI workflow)
# Note: 'tests' is an alias for 'test' in case of typo (both work)
# Set SETUPTOOLS_SCM_PRETEND_VERSION to bypass git version detection (hatch-vcs requirement)
SETUP_COMMAND="export SETUPTOOLS_SCM_PRETEND_VERSION=1.0.0.dev0 && pip install -U pip && pip install .[tests,gui]"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (Nipoppy supports Python 3.9-3.13, CI tests all)
# Using python3.10 as a stable middle version
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="nipoppy_697"

# Note: PR #697 refactors Zenodo API tests and increases coverage
# The PR title states: "Refactor Zenodo API tests and increase coverage"
#
# Changes made:
# 1. Separated unit tests from integration tests (new test_zenodo_api_integration.py)
# 2. Added pytest marker for API tests (@pytest.mark.api)
# 3. Fixed minor typo in error message: "file file" -> "file" in _upload_files()
# 4. Removed nipoppy/zenodo_api.py from codecov ignore list (now 100% coverage)
# 5. Updated CI workflow to conditionally run API tests
#
# ALL test files affected by PR #697:
#
# 1. tests/test_zenodo_api.py (MODIFIED - primary change)
#    Changes:
#    - Refactored existing unit tests with expanded coverage
#    - Tests ZenodoAPI class methods using mocked httpx responses
#    - No longer requires actual API access for unit tests
#
# 2. tests/test_zenodo_api_integration.py (NEW FILE - not in before/)
#    Changes:
#    - New integration tests marked with @pytest.mark.api
#    - Requires actual Zenodo API access (ZENODO_TOKEN env var)
#    - Skipped by default, only run with `-m api` flag
#
# 3. tests/test_workflow_zenodo.py (indirect dependency)
#    Dependencies:
#    - Uses nipoppy.workflows.pipeline_store.zenodo.ZenodoUploadWorkflow
#    - ZenodoUploadWorkflow wraps ZenodoAPI
#
# 4. tests/test_workflow_pipeline_store_install.py (indirect dependency)
#    Dependencies:
#    - Uses nipoppy.workflows.pipeline_store.install.PipelineInstallWorkflow
#    - PipelineInstallWorkflow.zenodo_api.download_record_files()
#
# 5. tests/test_workflow_pipeline_store_search.py (indirect dependency)
#    Dependencies:
#    - Uses nipoppy.workflows.pipeline_store.search.PipelineSearchWorkflow
#    - PipelineSearchWorkflow.zenodo_api.search_records()
#
# 6. tests/test_cli.py (indirect dependency)
#    Dependencies:
#    - CLI may have Zenodo-related commands
#    - Mentioned in grep results for zenodo usage
#
# Source files using ZenodoAPI:
# - nipoppy/zenodo_api.py (MODIFIED - bug fix)
# - nipoppy/workflows/pipeline_store/zenodo.py
# - nipoppy/workflows/pipeline_store/install.py
# - nipoppy/workflows/pipeline_store/search.py
# - nipoppy/cli.py
#
# Performance Impact:
# This is a test refactoring PR, not a performance optimization PR.
# The bug fix (duplicate "file" word in error message) has no performance impact.
# Test organization improvements make the test suite more maintainable.
#
# How PR #697 was tested (per PR description):
# "Refactor to separate unit and integration tests, achieve 100% coverage on zenodo_api.py"
#
# To verify the fix: Compare test results between before/ and after/ versions
# Expected outcome: All tests pass, no behavioral changes to the API
# The integration tests (test_zenodo_api_integration.py) won't exist in before/ version
# and may require ZENODO_TOKEN environment variable to run successfully.
