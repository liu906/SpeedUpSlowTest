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
# Install pytest first, install requirements with exact versions from requirements files
# Do NOT manually install packages that conflict with Home Assistant's requirements
SETUP_COMMAND="pip install --no-cache-dir freezegun pytest aiohttp pytest_socket requests_mock voluptuous python-slugify sqlalchemy pyfritzhome async_upnp_client && pip install --no-cache-dir -r requirements_test_all.txt 2>&1 | grep -v 'already satisfied' || true && python setup.py develop --no-deps 2>&1 | grep -v 'already satisfied' || true && pip install --no-cache-dir rxv aiomusiccast mutagen yeelight youless-api pyzerproc zigpy PyDispatcher zwave-js-server-python stdlib-list aiodiscover hass-nabucasa wolf-smartset holidays xbox-webapi construct python-miio yalesmartalarmclient zeroconf 2>&1 | grep -v 'already satisfied' || true"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="core_60348"
