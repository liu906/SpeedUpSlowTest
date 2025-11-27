#!/bin/bash
# Test configuration for running mocked tests in rotki_2007

cd "$(dirname "$0")/after_careful_mock"

# Activate virtual environment if it exists
if [ -d ".venv" ]; then
    source .venv/bin/activate
fi

# Run the specific tests that have been mocked
echo "Running mocked integration tests..."

# Price history tests (should_mock_price_queries now True)
pytest -xvs \
    rotkehlchen/tests/integration/test_price_history.py::test_inconsistent_prices_double_checking \
    rotkehlchen/tests/integration/test_price_history.py::test_price_queries \
    rotkehlchen/tests/integration/test_price_history.py::test_cryptocompare_iota_query \
    rotkehlchen/tests/integration/test_price_history.py::test_cryptocompare_bchsv_query \
    --durations=0

echo ""
echo "Running mocked external API tests..."

# CryptoCompare DAO test (now mocked)
pytest -xvs \
    rotkehlchen/tests/external_apis/test_cryptocompare.py::test_cryptocompare_dao_query \
    --durations=0

echo ""
echo "Running mocked Gemini exchange tests..."

# Gemini tests (now mocked)
pytest -xvs \
    rotkehlchen/tests/exchanges/test_gemini.py::test_gemini_query_trades \
    rotkehlchen/tests/exchanges/test_gemini.py::test_gemini_query_all_trades_pagination \
    --durations=0

echo ""
echo "All mocked tests completed!"
