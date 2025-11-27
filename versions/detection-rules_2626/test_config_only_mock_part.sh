#!/bin/bash
# Test configuration for detection-rules_2626
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
TEST_COMMAND="pytest tests/test_all_rules.py::TestValidRules::test_all_rule_queries_optimized \
       tests/test_all_rules.py::TestValidRules::test_production_rules_have_rta \
       tests/test_packages.py::TestPackages::test_package_summary \
       tests/test_packages.py::TestPackages::test_rule_versioning \
       --durations=10 -v -vv"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
SETUP_COMMAND="pip install setuptools wheel setuptools_scm pytest && pip install -e ."

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="detection-rules_2626"
