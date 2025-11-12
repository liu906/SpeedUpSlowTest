#!/bin/bash
# Test configuration for blueprints_691
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
TEST_COMMAND="pytest tests/structural_sections/steel/steel_cross_sections/test_chs_profile.py::TestCHSSteelProfile::test_plot_shapes tests/structural_sections/steel/steel_cross_sections/test_rhs_profile.py::TestRHSSteelProfile::test_plot tests/structural_sections/steel/steel_cross_sections/test_i_profile.py::TestISteelProfile::test_plot  --durations=0 -vv"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
SETUP_COMMAND="pip install uv && uv sync --locked --all-groups"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="blueprints_691"
