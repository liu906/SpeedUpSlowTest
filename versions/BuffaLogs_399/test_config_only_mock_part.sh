#!/bin/bash
# Test configuration for BuffaLogs_399
# This file is sourced by run_tests_generic.sh

# Project type: Docker-based
USE_DOCKER=true

# Test command to run (without energibridge prefix)
TEST_COMMAND="docker compose exec buffalogs \
pytest \
  impossible_travel/tests/alerters/test_alert_rocketchat.py::TestRocketChatAlerting::test_alert_network_failure \
  impossible_travel/tests/alerters/test_alert_slack.py::TestSlackAlerting::test_alert_network_failure \
  impossible_travel/tests/alerters/test_alert_factory.py::TestAlertFactory::test_send_actual_alert \
  impossible_travel/tests/alerters/test_alert_telegram.py::TestTelegramAlerting::test_alert_network_failure \
  impossible_travel/tests/alerters/test_alert_discord.py::TestDiscordAlerting::test_alert_network_failure \
  impossible_travel/tests/alerters/test_alert_googlechat.py::TestGoogleChatAlerting::test_alert_network_failure \
  impossible_travel/tests/alerters/test_alert_microsoft_teams.py::TestMicrosoftTeamsAlerting::test_alert_network_failure \
  impossible_travel/tests/alerters/test_alert_pushover.py::TestPushoverAlerting::test_alert_network_failure \
  impossible_travel/tests/alerters/test_alert_mattermost.py::TestMattermostAlerting::test_alert_network_failure \
  --durations=0 -vv"
  

# Optional: Setup command to run after containers are up (e.g., install dependencies)
SETUP_COMMAND="docker compose exec buffalogs pip install pytest pytest-django opensearch-py splunk-sdk"

# Optional: Wait time in seconds after docker compose up (for containers to be ready)
WAIT_TIME=10

# Optional: Additional project-specific variables
PROJECT_NAME="BuffaLogs_399"
