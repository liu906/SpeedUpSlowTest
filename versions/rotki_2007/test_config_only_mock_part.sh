#!/bin/bash
# Test configuration for rotki_2007
# This file is sourced by run_tests_venv_generic.sh

# IMPORTANT: This project requires Python 3.7 and system dependencies
# gevent==1.5a2 is incompatible with Python 3.10+
# pysqlcipher3 requires sqlcipher library
#
# To install Python 3.7 and required system libraries:
#   sudo add-apt-repository ppa:deadsnakes/ppa
#   sudo apt-get update
#   sudo apt-get install python3.7 python3.7-venv python3.7-dev
#   sudo apt-get install libsqlcipher-dev sqlcipher

# Test command to run (rotki uses pytestgeventwrapper.py with gevent monkey patching)
# rotkehlchen/tests/integration/test_price_history.py::test_inconsistent_prices_double_checking \

# rotkehlchen/tests/integration/test_price_history.py::test_inconsistent_prices_double_checking \
# rotkehlchen/tests/integration/test_price_history.py::test_price_queries \
# rotkehlchen/tests/integration/test_price_history.py::test_cryptocompare_iota_query \
# rotkehlchen/tests/integration/test_price_history.py::test_cryptocompare_bchsv_query \
# rotkehlchen/tests/external_apis/test_cryptocompare.py::test_cryptocompare_dao_query \
# rotkehlchen/tests/exchanges/test_gemini.py::test_gemini_query_trades \
TEST_COMMAND="pytest -vs \
rotkehlchen/tests/exchanges/test_gemini.py::test_gemini_query_all_trades_pagination \
--durations=0 -vv"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Python version to use (rotki uses Python 3.7 in Travis CI)
PYTHON_VERSION="python3.7"

# Optional: Setup command to run after venv is activated (e.g., install test dependencies)
# Install system dependencies first (if running with sudo), then Python packages
# Note: gevent 1.5a2 requires compilation with older Python and Cython
# Note: Pin Jinja2<3.1 for Flask 1.1.1 compatibility (escape was moved in Jinja2 3.1+)
# Note: Pin itsdangerous<2.1 for Flask 1.1.1 compatibility (json module removed in 2.1+)
# Note: Pin Werkzeug<2.1 for Flask 1.1.1 compatibility (BaseResponse moved in 2.1+)
SETUP_COMMAND="(apt-get install -y libsqlcipher-dev sqlcipher 2>/dev/null || echo 'Note: If pysqlcipher3 fails, install: sudo apt-get install libsqlcipher-dev sqlcipher') && pip install 'cython<3.0' setuptools wheel 'Jinja2<3.1' 'itsdangerous<2.1' 'Werkzeug<2.1' && pip install -r requirements.txt && pip install -r requirements_dev.txt"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="rotki_2007"
