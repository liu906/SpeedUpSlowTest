#!/bin/bash
# Test configuration for ophyd-async_316
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #316 testing: Run tests affected by MockSignalBackend performance improvements
# This PR fixes issue #312 about slow test performance since mock signal backend was added
# Run the core mock signal backend tests and related tests that use mocking
# Note: Tests crash during cleanup due to EPICS CA event loop issues, but results are valid
# Using || true to ignore the crash exit code since tests complete successfully before crash
TEST_COMMAND="pytest --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Setup command to install dependencies
# Install the package in editable mode with dev dependencies
# The project uses pyproject.toml with setuptools backend and setuptools-scm for versioning
# Since we don't have .git metadata, we need to set SETUPTOOLS_SCM_PRETEND_VERSION
# Using a fake version number to bypass the git requirement
SETUP_COMMAND="pip install --upgrade pip && SETUPTOOLS_SCM_PRETEND_VERSION=0.6.0 pip install -e '.[dev]'"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Python version (ophyd-async supports Python 3.10 and 3.11)
PYTHON_VERSION="python3.10"

# Project name
PROJECT_NAME="ophyd-async_316"

# Set fake version for setuptools-scm (no .git metadata in before/after directories)
export SETUPTOOLS_SCM_PRETEND_VERSION=0.6.0

# Note: PR #316 improves MockSignalBackend performance
# PR Title: "Improve performance of MockSignalBackend"
# PR URL: https://github.com/bluesky/ophyd-async/pull/316
# Related Issue: #312 "Fix the slow down in tests observed since the mock signal backend was added"
#
# Changes made in PR #316:
#
# 1. src/ophyd_async/core/mock_signal_backend.py (Major refactoring)
#    BEFORE:
#    - Used MagicMock for tracking all method calls
#    - Created mock.put, mock.get_value, mock.get_reading, etc. for every method
#    - put_proceeds event was created in __init__ for all instances
#    - Every method call recorded via self.mock.method_name()
#
#    AFTER:
#    - Replaced MagicMock with Mock (lighter weight)
#    - Only creates put_mock when actually needed (lazy initialization)
#    - Uses @cached_property for put_mock and put_proceeds (created on first access)
#    - Removed unnecessary mock tracking from methods like source(), connect(),
#      get_descriptor(), get_reading(), get_value(), get_setpoint(), set_callback()
#    - Only tracks put() calls since that's what tests actually verify
#
#    IMPACT: Massive performance improvement by eliminating unnecessary mock overhead
#    - Reduced memory allocation (no MagicMock for every instance)
#    - Lazy initialization of mocks (only created when needed)
#    - Eliminated mock tracking for methods that aren't tested
#
# 2. src/ophyd_async/core/mock_signal_utils.py (Timing restored)
#    - Put timing functionality back (referenced in commit "Put timing back")
#    - Related to motor timing as well (commit "Put back motor timing too")
#
# 3. tests/core/test_mock_signal_backend.py (3 lines removed)
#    Lines removed:
#    - mock_signal._backend.mock.get_value.assert_called_once
#    - mock_signal._backend.mock["get_value"].assert_called_once
#
#    Line modified:
#    BEFORE: assert mock_signal._backend.mock.put.call_args_list == [
#    AFTER:  assert mock_signal._backend.put_mock.call_args_list == [
#
#    IMPACT: Tests updated to use new put_mock instead of mock.put
#    - Removed assertions for get_value mocking (no longer tracked)
#    - Updated to use put_mock property instead of mock.put
#
# 4. tests/epics/demo/test_demo.py (Modified)
#    - Likely timing-related changes from "Put timing back" commit
#    - May involve motor simulation timing
#
# 5. tests/epics/motion/test_motor.py (Modified)
#    - Motor timing restored (commit "Put back motor timing too")
#    - Related to motor mock behavior
#
# Performance Impact:
# - MockSignalBackend is used extensively throughout the test suite
#   - Every test that creates mock signals benefits from this optimization
#   - Tests using sim detectors, motors, and other mock devices run faster
# - The optimization reduces overhead per mock signal instance:
#   - BEFORE: MagicMock created for every instance with full method tracking
#   - AFTER: Simple Mock only for put operations, created lazily
# - Expected improvement: Significant speedup in tests using mock signals
#   - Based on issue #312, this addresses "slow down in tests"
#   - Downstream impact noted in DiamondLightSource/dodal#533
#
# Why these specific test files:
# - test_mock_signal_backend.py: Directly tests the modified MockSignalBackend class
# - test_demo.py: Uses mock signals with timing that was restored
# - test_motor.py: Uses motor mocking with timing functionality
#
# How PR #316 was tested:
# - PR received LGTM from reviewer callumforrester
# - Fixes regression in test performance
# - All existing tests should pass faster
#
# To verify the fix:
# Compare test execution time between before/ and after/ versions
# Expected improvement:
# - BEFORE: Tests run slower due to MagicMock overhead on every signal operation
# - AFTER: Tests run significantly faster with optimized Mock usage
# - The improvement will be most noticeable in tests that create many mock signals
#   or perform many operations on mock signals
