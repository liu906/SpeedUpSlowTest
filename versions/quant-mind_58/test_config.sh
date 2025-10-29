#!/bin/bash
# Test configuration for quant-mind_58
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #58 testing: Run ALL test files that were modified in the performance optimization PR
# These tests had timeout configurations reduced for faster execution
TEST_COMMAND="uv run pytest  -vv --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run AFTER venv creation and activation
# This project uses uv for dependency management
# Use uv pip install -e . to install in editable mode with all dependencies
# IMPORTANT: Set PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1 to work around tiktoken/PyO3 compatibility issue
# tiktoken v0.7.0 uses PyO3 v0.20.3 which only supports Python <=3.12
SETUP_COMMAND="export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1 && uv pip install -e ."

# Flag to indicate this IS a uv-based project
USE_UV="true"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (project requires Python 3.10+, using 3.11 to match CI)
# CRITICAL: Must use Python 3.10, 3.11, or 3.12 - NOT 3.13!
# tiktoken dependency uses PyO3 v0.20.3 which only supports Python <=3.12
PYTHON_VERSION="python3.11"

# Optional: Additional project-specific variables
PROJECT_NAME="quant-mind_58"

# Note: PR #58 optimizes test performance by reducing timeout configurations
# The PR title: "Test performance optimization"
#
# Performance Impact:
# - BEFORE: Total test suite execution time ~28.5 seconds
# - AFTER: Total test suite execution time ~2.8 seconds
# - IMPROVEMENT: ~10x faster (90% reduction in execution time)
#
# Changes made:
# 1. Reduced timeout values across multiple test files
# 2. Added configurable download_timeout to storage config
# 3. Enhanced test mocking to avoid actual network calls
# 4. Added performance reporting option to unittest.sh script
#
# Files changed in PR #58:
#
# SOURCE CODE FILES (2 files):
#
# 1. quantmind/config/storage.py (MODIFIED)
#    Changes:
#    - Added download_timeout field to BaseStorageConfig
#    - Default value: 30 seconds
#    - Allows configurable timeout instead of hardcoded value
#
# 2. quantmind/storage/base.py (MODIFIED)
#    Changes:
#    - Modified _download_file_content() method
#    - Accepts optional timeout parameter
#    - Uses configurable timeout from config instead of hardcoded 30 seconds
#
# TEST FILES (5 files):
#
# 3. tests/config/test_embedding.py (MODIFIED - included in test command)
#    Changes:
#    - Reduced timeout values from 30/60/600/3600 seconds to 1 second
#    - Tests: test_embedding_config_validation, test_retry_mechanism, etc.
#    - Multiple test cases optimized for faster execution
#
# 4. tests/llm/test_embedding_block.py (MODIFIED - included in test command)
#    Changes:
#    - Reduced timeout from 30 to 1 second in config
#    - Reduced retry_delay from 1.0 to 0.01 seconds
#    - Mock sleep assertions updated to match new delay
#    - Faster feedback loop without sacrificing test coverage
#
# 5. tests/llm/test_llm_block.py (MODIFIED - included in test command)
#    Changes:
#    - Added timeout=1 to test config
#    - Added retry_delay=0.01 to test config
#    - Reduced request_timeout from 60 to 1 second
#    - Tests LLM block functionality with optimized timeouts
#
# 6. tests/parsers/test_llama_parser.py (MODIFIED - included in test command)
#    Changes:
#    - Added timeout=10 to parser config
#    - Added retry_attempts=1 to reduce test time
#    - Enhanced test mocking for better isolation
#    - Tests parser functionality without long waits
#
# 7. tests/storage/test_local_storage.py (MODIFIED - included in test command)
#    Changes:
#    - Added download_timeout=1 to storage config
#    - Added request mocking to avoid actual network calls
#    - Tests storage operations with fast timeouts
#    - Uses new configurable download_timeout feature
#
# UTILITY FILES (1 file):
#
# 8. scripts/unittest.sh (MODIFIED - not tested here)
#    Changes:
#    - Added "report" option for performance analysis
#    - Usage: ./scripts/unittest.sh report
#    - Displays 20 slowest tests using pytest --durations=20
#    - Helps identify performance bottlenecks
#
# Test categories affected:
# - Config tests: Embedding configuration validation
# - LLM tests: LLM and embedding block operations
# - Parser tests: Llama parser functionality
# - Storage tests: Local storage with configurable timeouts
#
# Key optimizations:
# 1. Timeout reduction: 30-60s → 1s (97-98% reduction)
# 2. Retry delay: 1.0s → 0.01s (99% reduction)
# 3. Network mocking: Eliminates actual HTTP requests
# 4. Configurable timeouts: Allows flexible timeout management
#
# How PR #58 improves developer experience:
# - Faster CI/CD feedback loop (10x speedup)
# - Reduced development cycle time
# - Maintains test coverage while improving speed
# - Better test isolation through enhanced mocking
# - Performance monitoring via new reporting feature
#
# Project-specific notes:
# - This project uses uv for dependency management (NOT pip)
# - Installation: uv pip install -e .
# - README recommends: uv venv && source .venv/bin/activate
# - CI uses pip install -e . (GitHub Actions with pip)
# - Project has pyproject.toml with [tool.uv.index] pointing to Tsinghua mirror
# - Supported Python version: >=3.10 (using 3.11 for CI compatibility)
# - Project uses setuptools build backend, not hatch
# - Dependencies include: pytest, pytest-cov, arxiv, requests, openai, etc.
#
# To verify the optimization: Compare test execution times between before/ and after/ versions
# Expected outcome:
# - BEFORE: Tests take ~28.5 seconds total
# - AFTER: Tests take ~2.8 seconds total (90% faster)
# - All tests should pass in both versions
# - Test behavior remains identical, only execution speed improves
#
# Running with performance report:
# To see which tests are slowest, you can manually run:
# uv run pytest tests/config/test_embedding.py --durations=20
