#!/bin/bash
# Test configuration for core_60348 (Home Assistant)
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# Using the exact command from tox.ini
TEST_COMMAND="python -m pytest --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Python version to use - Home Assistant 2021 requires Python 3.8 or 3.9
# Using Python 3.10 since 3.9 is not available on this system
PYTHON_VERSION="python3.10"

# Optional: Setup command to run after activating venv
# Install pytest first, then upgrade pip, filter out pip constraints, install test requirements, and install homeassistant without deps
SETUP_COMMAND="pip install freezegun pytest aiohttp pytest_socket requests_mock voluptuous slugify  sqlalchemy pyfritzhome async_upnp_client && python3 -m pip install --upgrade pip && pip install -r requirements_all.txt && pip install -r requirements_test_all.txt && grep -v '^pip<' requirements_test_all.txt > /tmp/ha_requirements.txt && pip install -r /tmp/ha_requirements.txt && python setup.py develop --no-deps"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="core_60348"
