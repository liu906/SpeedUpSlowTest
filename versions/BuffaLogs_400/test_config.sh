#!/bin/bash
# Test configuration for BuffaLogs_400
# This file is sourced by run_tests_generic.sh

# Test command to run (without energibridge prefix)
TEST_COMMAND="docker compose exec buffalogs pytest impossible_travel/tests/ingestion/test_opensearch_ingestion.py impossible_travel/tests/ingestion/test_splunk_ingestion.py --durations=0"

# Optional: Setup command to run after containers are up (e.g., install dependencies)
SETUP_COMMAND="docker compose exec buffalogs pip install pytest pytest-django opensearch-py splunk-sdk"

# Optional: Wait time in seconds after docker compose up (for containers to be ready)
WAIT_TIME=10

# Optional: Additional project-specific variables
PROJECT_NAME="BuffaLogs_400"
