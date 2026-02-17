#!/bin/bash
# Coverage verification only (new workflow)
# Usage: ./commands_coverage_only.sh

echo "Running coverage verification for all projects"

# 1. opensearch-build_595
bash run_tests_venv_generic_coverage.sh opensearch-build_595 1 before after_careful_mock only_mock_part
python3 compare_coverage.py opensearch-build_595 before after_careful_mock only_mock_part

# 2. pydicom_1636
bash run_tests_venv_generic_coverage.sh pydicom_1636 1 before after_careful_mock only_mock_part
python3 compare_coverage.py pydicom_1636 before after_careful_mock only_mock_part

# 3. roms-tools_107
bash run_tests_venv_generic_coverage.sh roms-tools_107 1 before after_careful_mock only_mock_part
python3 compare_coverage.py roms-tools_107 before after_careful_mock only_mock_part

# 4. armi_1737
bash run_tests_venv_generic_coverage.sh armi_1737 1 before after_careful_mock only_mock_part
python3 compare_coverage.py armi_1737 before after_careful_mock only_mock_part

# 5. bilby_986
bash run_tests_venv_generic_coverage.sh bilby_986 1 before after_careful_mock only_mock_part
python3 compare_coverage.py bilby_986 before after_careful_mock only_mock_part

# 6. BuffaLogs_399 (uses run_tests_generic_coverage.sh - need to create this)
# Note: Need to create run_tests_generic_coverage.sh for non-venv projects
echo "Skipping BuffaLogs_399 - needs run_tests_generic_coverage.sh"

# 7. detection-rules_2626
bash run_tests_venv_generic_coverage.sh detection-rules_2626 1 before after_careful_mock only_mock_part
python3 compare_coverage.py detection-rules_2626 before after_careful_mock only_mock_part

# 8. lightning-thunder_2077
bash run_tests_venv_generic_coverage.sh lightning-thunder_2077 1 before after_careful_mock only_mock_part
python3 compare_coverage.py lightning-thunder_2077 before after_careful_mock only_mock_part

# 9. patientMatcher_262 (uses run_tests_generic_coverage.sh - need to create this)
echo "Skipping patientMatcher_262 - needs run_tests_generic_coverage.sh"

# 10. dfm_tools_976
bash run_tests_venv_generic_coverage.sh dfm_tools_976 1 before after_careful_mock only_mock_part
python3 compare_coverage.py dfm_tools_976 before after_careful_mock only_mock_part

# 11. python-dts-calibration_197 (uses run_tests_generic_coverage.sh - need to create this)
echo "Skipping python-dts-calibration_197 - needs run_tests_generic_coverage.sh"

# 12. evalml_2446
bash run_tests_venv_generic_coverage.sh evalml_2446 1 before after_careful_mock only_mock_part
python3 compare_coverage.py evalml_2446 before after_careful_mock only_mock_part

echo "All coverage verifications completed!"
echo ""
echo "Note: Some projects use run_tests_generic.sh instead of run_tests_venv_generic.sh"
echo "Need to create run_tests_generic_coverage.sh for those projects"
