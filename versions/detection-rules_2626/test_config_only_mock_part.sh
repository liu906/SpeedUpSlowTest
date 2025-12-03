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
VENV_PATH="venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
# Note: typeguard must be <3.0 to work with marshmallow-dataclass 8.5.x
# typeguard 3.x changed the check_type() API, removing the 'argname' parameter
# IMPORTANT: Install typeguard constraint first to prevent incompatible versions
SETUP_COMMAND="pip install setuptools wheel setuptools_scm pytest 'typeguard>=2.0,<3.0' && pip install -e ."

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="detection-rules_2626"
