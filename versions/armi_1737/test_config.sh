#!/bin/bash
# Test configuration for armi_1737
# This file is sourced by run_tests_venv_generic.sh

# Test command to run
TEST_COMMAND="python -m pytest \
armi/bookkeeping/db/tests/test_comparedb3.py \
armi/bookkeeping/db/tests/test_database3.py \
armi/bookkeeping/db/tests/test_databaseInterface.py \
armi/bookkeeping/report/tests/test_newReport.py \
armi/bookkeeping/report/tests/test_report.py \
armi/bookkeeping/tests/test_memoryProfiler.py \
armi/bookkeeping/visualization/tests/test_vis.py \
armi/cases/tests/test_cases.py \
armi/cli/tests/test_runEntryPoint.py \
armi/operators/tests/test_operatorSnapshots.py \
armi/operators/tests/test_operators.py \
armi/physics/neutronics/fissionProductModel/tests/test_fissionProductModel.py \
armi/physics/neutronics/globalFlux/tests/test_globalFluxInterface.py \
armi/physics/neutronics/tests/test_crossSectionManager.py \
armi/physics/neutronics/tests/test_crossSectionTable.py \
armi/physics/neutronics/tests/test_macroXSGenerationInterface.py \
armi/reactor/converters/parameterSweeps/tests/test_paramSweepConverters.py \
armi/tests/refSmallReactorShuffleLogic.py \
armi/tests/test_mpiActions.py \
armi/tests/test_mpiFeatures.py \
armi/tests/test_plugins.py \
armi/tests/test_user_plugins.py \
armi/utils/tests/test_plotting.py \
armi/utils/tests/test_reportPlotting.py \
armi/utils/tests/test_utils.py \
--durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH="venv"

# Optional: Python version to use (defaults to python3.10 in run_tests_venv_generic.sh)
# PYTHON_VERSION="python3.9"

# Optional: Setup command to run after venv is activated (e.g., install test dependencies)
SETUP_COMMAND="pip install -e .[test]"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="armi_1737"
