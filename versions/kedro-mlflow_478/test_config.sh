#!/bin/bash
# Test configuration for kedro-mlflow_478
# This file is sourced by run_tests_venv_generic.sh

# Test command to run
TEST_COMMAND="python -m pytest \
tests/conftest.py \
tests/io/artifacts/test_mlflow_artifact_dataset.py \
tests/io/metrics/test_mlflow_metrics_dataset.py \
tests/io/models/test_mlflow_model_tracking_dataset.py \
--durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH="venv"

# Optional: Python version to use (defaults to python3.10 in run_tests_venv_generic.sh)
# PYTHON_VERSION="python3.9"

# Optional: Setup command to run after venv is activated (e.g., install test dependencies)
SETUP_COMMAND="pip install -e .[test]"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="kedro-mlflow_478"