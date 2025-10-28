#!/bin/bash
# Test configuration for ai-platform_325
# This file is sourced by run_tests_generic.sh

# Test command to run (without energibridge prefix)
TEST_COMMAND="docker compose exec backend python -m pytest app/tests/api/routes/test_responses.py --durations=0"

# Optional: Setup command to run after containers are up (e.g., install dependencies)
# SETUP_COMMAND=""  # Add setup commands if needed

# Optional: Wait time in seconds after docker compose up (for containers to be ready)
WAIT_TIME=5

# Optional: Additional project-specific variables
PROJECT_NAME="ai-platform_325"
