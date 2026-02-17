#!/bin/bash
# Energy measurement only (original workflow)
# Usage: ./commands_energy_only.sh [REPEAT]

REPEAT=${1:-10}

echo "Running energy measurement only for all projects (REPEAT=$REPEAT)"

# 1. opensearch-build_595
bash run_tests_venv_generic.sh opensearch-build_595 $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py opensearch-build_595 only_mock_part

# 2. pydicom_1636
bash run_tests_venv_generic.sh pydicom_1636 $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py pydicom_1636 only_mock_part

# 3. roms-tools_107
bash run_tests_venv_generic.sh roms-tools_107 $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py roms-tools_107 only_mock_part

# 4. armi_1737
bash run_tests_venv_generic.sh armi_1737 $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py armi_1737 only_mock_part

# 5. bilby_986
bash run_tests_venv_generic.sh bilby_986 $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py bilby_986 only_mock_part

# 6. BuffaLogs_399
bash ./run_tests_generic.sh BuffaLogs_399/ $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py BuffaLogs_399 only_mock_part

# 7. detection-rules_2626
bash run_tests_venv_generic.sh detection-rules_2626 $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py detection-rules_2626 only_mock_part

# 8. lightning-thunder_2077
bash run_tests_venv_generic.sh lightning-thunder_2077 $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py lightning-thunder_2077 only_mock_part

# 9. patientMatcher_262
bash ./run_tests_generic.sh patientMatcher_262/ $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py patientMatcher_262 only_mock_part

# 10. dfm_tools_976
bash run_tests_venv_generic.sh dfm_tools_976 $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py dfm_tools_976 only_mock_part

# 11. python-dts-calibration_197
bash ./run_tests_generic.sh python-dts-calibration_197/ $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py python-dts-calibration_197 only_mock_part

# 12. evalml_2446
bash run_tests_venv_generic.sh evalml_2446 $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py evalml_2446 only_mock_part

echo "All energy measurements completed!"
