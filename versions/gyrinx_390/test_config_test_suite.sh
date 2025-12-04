#!/bin/bash
# Test configuration for gyrinx_390
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #390 testing: Run the complete test suite to verify parallel execution with pytest-xdist
# This Django project uses docker compose to run tests in a containerized environment
# NOTE: This config does NOT use docker - it runs tests directly in venv for energy measurement
TEST_COMMAND="pytest --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run AFTER venv creation and activation
# This project uses pip with editable install
# Install all dependencies including Django, pytest, and pytest-django
# IMPORTANT: This project requires a PostgreSQL database for tests
# We need to set up environment variables for Django test database
# Using SQLite for testing instead of PostgreSQL to avoid Docker dependency
SETUP_COMMAND="pip install --editable . && echo 'SECRET_KEY=test-secret-key-for-testing' > .env && echo 'DATABASE_URL=sqlite:///test_db.sqlite3' >> .env"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (project requires Python 3.12+)
# Using python3.13 since it's available and meets the >=3.12 requirement
PYTHON_VERSION="python3.13"

# Optional: Additional project-specific variables
PROJECT_NAME="gyrinx_390"

# Note: PR #390 adds pytest-xdist for parallel test execution
# The PR title: "feat: add pytest-xdist for parallel test execution"
#
# Changes made:
# 1. Added pytest-xdist==3.6.1 to requirements.txt
# 2. Updated scripts/test.sh to support --parallel flag
# 3. Created scripts/measure_test_performance.sh for benchmarking
# 4. Enhanced documentation (CLAUDE.md, README.md, docs/)
#
# Files changed in PR #390:
#
# DEPENDENCY FILES (1 file):
#
# 1. requirements.txt (MODIFIED)
#    Changes:
#    - Added pytest-xdist==3.6.1 for parallel test execution
#    - pytest-xdist enables running tests across multiple CPU cores
#    - Uses pytest -n auto to automatically detect CPU count
#
# SCRIPT FILES (2 files):
#
# 2. scripts/test.sh (MODIFIED - this is how tests are normally run)
#    Changes:
#    - Added --parallel flag support (lines 62-66)
#    - When --parallel or -p flag is used, adds "-n auto" to pytest args
#    - Passes through additional pytest arguments
#    - Example: ./scripts/test.sh --parallel runs "pytest -n auto"
#    - Backward compatible: sequential execution by default
#
# 3. scripts/measure_test_performance.sh (NEW - not tested here)
#    Changes:
#    - New script for measuring test performance with/without parallelization
#    - Runs tests sequentially and in parallel, comparing execution times
#    - Outputs detailed timing and speedup metrics
#
# DOCUMENTATION FILES (4 files - not tested):
#
# 4. docs/test-performance-improvements.md (NEW)
#    - Comprehensive guide on parallel testing setup and performance gains
#
# 5. README.md (MODIFIED)
#    - Updated testing section with --parallel flag usage
#    - Added performance expectations (3-4x on 4 cores, 5-6x on 8 cores)
#
# 6. CLAUDE.md (MODIFIED)
#    - Added examples of parallel test execution commands
#    - Updated testing best practices
#
# 7. .github/test-performance-config.md (NEW)
#    - CI/CD configuration guide for parallel testing
#
# Test structure:
# - Django application with pytest-django for testing
# - Tests located in gyrinx/core/tests/ and gyrinx/content/tests/
# - Total of 451 test cases across the codebase
# - Tests use Django ORM and require database connection
# - pytest.ini configures Django settings and test discovery
#
# Test organization:
# - Core tests: gyrinx/core/tests/test_*.py (55+ files)
#   * test_models_core.py - Core model tests (largest file)
#   * test_integration_core_functionality.py - Integration tests
#   * test_campaign*.py - Campaign-related tests
#   * test_fighter*.py - Fighter-related tests
#   * test_equipment*.py - Equipment-related tests
#   * test_injury*.py - Injury-related tests
#
# - Content tests: gyrinx/content/tests/test_*.py (14 files)
#   * test_equipment_upgrade_overrides.py - Equipment override tests
#   * test_cost_methods.py - Cost calculation tests
#   * test_weapons.py - Weapon tests
#   * test_contentpack.py - Content pack tests
#
# Performance Impact:
# This PR IMPROVES test performance significantly by:
# - Enabling parallel test execution across multiple CPU cores
# - Expected speedup on 4 cores: 3-4x faster
# - Expected speedup on 8 cores: 5-6x faster
# - Additional 20-30% improvement with --reuse-db flag
# - Reduces CI/CD feedback loop time
# - Better developer experience with faster local testing
#
# How parallel testing works with pytest-xdist:
# - pytest -n auto: Automatically detects number of CPU cores
# - pytest -n 4: Uses exactly 4 worker processes
# - Each worker gets a subset of tests to run independently
# - Workers use separate database instances (pytest-django handles this)
# - Results are aggregated at the end
#
# Project-specific notes:
# - This is a Django 5.2.3 application (Necromunda gang management tool)
# - Project uses standard pip + requirements.txt (NOT uv or poetry)
# - CI uses: pip install --editable . for installation
# - Normal test execution: docker compose run app pytest
# - Parallel execution: docker compose run app pytest -n auto
# - With script: ./scripts/test.sh --parallel
# - Project requires Python 3.12+ (uses latest Python 3.12.7)
# - Database: PostgreSQL 16.4 in production/CI, can use SQLite for testing
# - pytest configuration in pyproject.toml [tool.pytest.ini_options]
# - Django settings: DJANGO_SETTINGS_MODULE=gyrinx.settings_dev
#
# Configuration differences from normal setup:
# - Normal: Uses docker compose with PostgreSQL database
# - This test config: Uses venv directly with SQLite (for energy measurement)
# - Both approaches run the same test suite with pytest
#
# To verify the optimization: Compare test execution times between before/ and after/ versions
# Expected outcome:
# - BEFORE: Tests run sequentially (baseline performance)
# - AFTER: Tests can run in parallel with -n auto flag (3-6x speedup)
# - All tests should pass in both versions
# - Test behavior remains identical, only execution speed can improve
# - For this energy measurement, we run sequentially to get baseline metrics
#
# Additional dependencies introduced:
# - pytest-xdist==3.6.1 - Main parallel execution plugin
# - Includes: execnet (distributed execution), pytest-forked (process isolation)
#
# Database considerations for parallel testing:
# - pytest-django automatically creates separate test databases for each worker
# - Database names: test_db_gw0, test_db_gw1, test_db_gw2, etc.
# - Each worker operates on isolated database to prevent conflicts
# - Migrations run once, then database state is cloned to workers
#
# Known limitations:
# - Tests that depend on shared state may need modification
# - Database-heavy tests may not scale linearly (I/O bottleneck)
# - Some tests may need @pytest.mark.serial for sequential execution
# - Memory usage increases with number of workers
#
# Running tests with different parallelization levels:
# - Sequential (baseline): pytest
# - Auto-detect cores: pytest -n auto
# - 2 workers: pytest -n 2
# - 4 workers: pytest -n 4
# - With database reuse: pytest -n auto --reuse-db (30% faster)
#
# For this benchmark, we test the default sequential execution:
# This allows us to measure the baseline performance before optimization.
# The "after" version has the capability to run in parallel, but we're
# measuring the sequential execution to establish energy consumption baseline.
