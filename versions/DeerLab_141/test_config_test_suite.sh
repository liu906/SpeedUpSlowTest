#!/bin/bash
# Test configuration for DeerLab_141

# Test command to run
TEST_COMMAND="python -m pytest --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Setup command to install dependencies and package
SETUP_COMMAND="pip install 'scipy<1.11.0' numpy cvxopt matplotlib tqdm joblib memoization pytest && pip install -e ."

PYTHON_VERSION="python3.10"

# No need for wait time as this is not a Docker-based project
WAIT_TIME=0

# Additional project-specific variables
PROJECT_NAME="DeerLab_141"