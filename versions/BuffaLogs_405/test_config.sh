#!/bin/bash
# Test configuration for BuffaLogs_405
# This file is sourced by run_tests_generic.sh

# Test command to run (without energibridge prefix)
# Updated to target the API tests that were modified in PR #405
# These are the tests where Client() instantiation was removed from setUp()
TEST_COMMAND="docker compose exec buffalogs pytest impossible_travel/tests/api/test_alerts_api.py impossible_travel/tests/api/test_ingestion_api.py --durations=0"

# Optional: Setup command to run after containers are up (e.g., install dependencies)
SETUP_COMMAND="docker compose exec buffalogs pip install pytest pytest-django"

# Optional: Wait time in seconds after docker compose up (for containers to be ready)
WAIT_TIME=10

# Optional: Additional project-specific variables
PROJECT_NAME="BuffaLogs_405"
