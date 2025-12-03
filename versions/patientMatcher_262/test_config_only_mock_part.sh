#!/bin/bash
# Test configuration for patientMatcher_262
# This file is sourced by run_tests_generic.sh

# Use Docker for this project
USE_DOCKER=true

# Test command to run (without energibridge prefix)
TEST_COMMAND="docker compose run --rm --entrypoint pytest cli \
  tests/cli/test_add.py::test_cli_add_demo_data \
  tests/match/test_GT_matching.py::test_genotype_matching \
  tests/match/test_matching_handler.py::test_internal_matching \
  tests/server/test_server_responses.py::test_match_ensembl_patient \
  tests/server/test_server_responses.py::test_match_hgnc_symbol_patient \
  --durations=5 -v"

# Optional: Setup command to run after containers are up (e.g., install dependencies)
SETUP_COMMAND=""

# Optional: Wait time in seconds after docker compose up (for containers to be ready)
WAIT_TIME=10

# Optional: Additional project-specific variables
PROJECT_NAME="patientMatcher_262"
