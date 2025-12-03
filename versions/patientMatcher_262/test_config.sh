#!/bin/bash
# Test configuration for patientMatcher_262
# This file is sourced by run_tests_generic.sh

# Use Docker for this project
USE_DOCKER=true

# Test command to run (without energibridge prefix)
TEST_COMMAND="docker compose run --rm --entrypoint pytest cli tests/ --durations=0"

# Optional: Setup command to run after containers are up (e.g., install dependencies)
SETUP_COMMAND=""

# Optional: Wait time in seconds after docker compose up (for containers to be ready)
WAIT_TIME=10

# Optional: Additional project-specific variables
PROJECT_NAME="patientMatcher_262"
