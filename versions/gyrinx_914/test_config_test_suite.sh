#!/bin/bash
# Test configuration for gyrinx_914
# This file is sourced by run_tests_generic.sh

# Test command - run all tests in gyrinx directory
# TEST_COMMAND="docker compose exec -T app pytest --durations=0"
TEST_COMMAND="docker compose exec -T app pytest --durations=0"

VENV_PATH=".venv"


# No setup needed - migrations are handled in Dockerfile
SETUP_COMMAND=""

# Wait time for containers to be ready
WAIT_TIME=30

# Project name
PROJECT_NAME="gyrinx_914"
