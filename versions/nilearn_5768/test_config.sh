#!/bin/bash
# Test configuration for nilearn_5768
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# Using -o to override pytest config and avoid --template argument that requires pytest-reporter-html1
TEST_COMMAND="python -m pytest nilearn/decomposition/tests/test_decomposition_estimators.py nilearn/glm/tests/test_second_level.py nilearn/maskers/tests/test_nifti_masker.py nilearn/regions/tests/test_parcellations.py --durations=0 -o addopts=''"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Python version to use - nilearn requires Python 3.8+
PYTHON_VERSION="python3.10"

# Optional: Setup command to run after activating venv
# Install test dependencies and the project in editable mode
# Note: nilearn uses setuptools-scm which requires git, so we need to initialize git and create a tag
SETUP_COMMAND="pip install --upgrade pip && pip install numpydoc pytest pytest-cov pytest-csv pytest-randomly 'pytest-reporter-html1>=0.9.2,<0.9.4' pytest-timeout 'pytest-xdist[psutil]' pytest-mpl && pip install numpy scipy scikit-learn pandas nibabel joblib requests lxml matplotlib && git init && git config user.email 'test@example.com' && git config user.name 'Test User' && git add -A && git commit -m 'initial commit' && git tag v0.10.0 && pip install -e ."

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="nilearn_5768"
