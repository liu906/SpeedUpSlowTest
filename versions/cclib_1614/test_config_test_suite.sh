#!/bin/bash
# Test configuration for cclib_1614
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# Run only unit tests (exclude regression tests, method tests, and bridge tests)
# Unit tests are in test/ directory but exclude regression.py, regression_io.py, and bridge/
# Also exclude method tests using the 'is_method' marker
TEST_COMMAND="pytest --durations=0 -m 'not is_method' --ignore=test/regression.py --ignore=test/regression_io.py --ignore=test/bridge"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
# cclib requires:
# 1. Core dependencies from pyproject.toml (numpy, scipy, packaging, periodictable)
# 2. Test infrastructure (pytest, coverage, pytest-cov, pyyaml)
# 3. Bridge dependencies for full test suite (ase, biopython, pandas, pyscf, etc.)
# 4. Install cclib itself
# Note: cclib uses versioningit which requires Git. Since before/after dirs aren't Git repos,
# we need to create a minimal _version.py file manually before installation
# We'll skip bridge dependencies as they may require git-based installs that can fail
SETUP_COMMAND="echo '__version__ = \"1.0.0\"' > cclib/_version.py && pip install pytest pytest-cov pyyaml numpy scipy packaging periodictable && export PYTHONPATH=\$PWD:\$PYTHONPATH"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Python version (cclib supports Python 3.8-3.12, using 3.10 as stable default)
PYTHON_VERSION="python3.10"

# Optional: Additional project-specific variables
PROJECT_NAME="cclib_1614"

# Note: cclib project structure
# - cclib/: Main package with parsers and algorithms for computational chemistry
# - test/: Test directory with unit tests, regression tests, and method tests
# - data/: Test data directory (regression tests download additional data)
#
# Test organization:
# - Unit tests: test/test*.py, test/data/, test/io/, test/parser/ (what we run)
# - Regression tests: test/regression.py and test/regression_io.py (EXCLUDED)
# - Method tests: test/method/*.py files marked with 'is_method' (EXCLUDED)
# - Bridge tests: test/bridge/*.py files (EXCLUDED - require optional dependencies: ase, pyscf, etc.)
#
# This config runs ONLY core unit tests for energy measurement:
# - Includes: test_data.py, test_utils.py, test/data/, test/io/, test/parser/
# - Excludes: regression.py, regression_io.py (expensive parser tests)
# - Excludes: test/method/ tests (marked with 'is_method' marker)
# - Excludes: test/bridge/ tests (require optional dependencies we don't install)
#
# The CI uses pytest-xdist for parallel execution but we use sequential for energy measurement
# Test files are in test/ directory, not tests/
