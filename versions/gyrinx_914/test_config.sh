#!/bin/bash
# Test configuration for gyrinx_914
# This file is sourced by run_tests_generic.sh

# Test command - run all tests in gyrinx directory
# TEST_COMMAND="docker compose exec -T app pytest gyrinx/ --durations=0"
TEST_COMMAND="docker compose exec -T app pytest \
gyrinx/content/tests/test_default_assignment.py \
gyrinx/content/tests/test_equipment_list.py \
gyrinx/content/tests/test_migrations.py \
gyrinx/content/tests/test_policy.py \
gyrinx/content/tests/test_weapons.py \
gyrinx/core/tests/test_assignment_deletion_cost.py \
gyrinx/core/tests/test_captured_fighters.py \
gyrinx/core/tests/test_models_core.py \
--durations=0"

VENV_PATH=".venv"


# Start Docker containers
SETUP_COMMAND="docker compose up -d && docker compose exec -T app sleep 2"

# Wait time for containers to be ready
WAIT_TIME=5

# Project name
PROJECT_NAME="gyrinx_914"
