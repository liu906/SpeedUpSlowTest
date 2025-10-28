#!/bin/bash
# Test configuration for core_60348 (Home Assistant)
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# Using the exact command from tox.ini
TEST_COMMAND="python -X dev -m pytest tests/components/fritzbox/test_config_flow.py --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Python version to use - Home Assistant 2021 requires Python 3.8 or 3.9
# Using Python 3.10 since 3.9 is not available on this system
PYTHON_VERSION="python3.10"

# Optional: Setup command to run after activating venv
# Reinstall pip (after auto-install downgrades it), then install test requirements, then homeassistant without deps
SETUP_COMMAND="python -m pip install --upgrade --force-reinstall pip && grep -v '^pip<' requirements_test_all.txt > /tmp/ha_requirements.txt && pip install -r /tmp/ha_requirements.txt && python setup.py develop --no-deps"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="core_60348"
