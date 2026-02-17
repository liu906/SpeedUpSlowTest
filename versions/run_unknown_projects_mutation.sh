#!/bin/bash
# Batch mutation testing runner for unknown projects
# Mirrors the structure of run_unknown_projects.sh
#
# Usage: bash run_unknown_projects_mutation.sh

set -e

echo "============================================"
echo "Mutation Testing Pipeline - Unknown Projects"
echo "============================================"
echo ""

# ---- Mutation testing runs ----
# Parameters: <project_name> <mutate_paths> <folder1> <folder2> <suffix>

# Venv-based projects
bash run_mutation_venv_generic.sh armi_1737 "armi" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh detection-rules_2626 "detection_rules" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh dfm_tools_976 "dfm_tools" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh lightning-thunder_2077 "thunder" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh opensearch-build_595 "bundle-workflow/src" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh pydicom_1636 "pydicom" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh python-dts-calibration_197 "src" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh roms-tools_107 "roms_tools" before after_careful_mock only_mock_part

# Docker-based projects
bash run_mutation_venv_generic.sh BuffaLogs_399 "impossible_travel" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh patientMatcher_262 "patientMatcher" before after_careful_mock only_mock_part

# ---- Parse and compare results ----

python3 parse_mutation_results.py armi_1737 before after_careful_mock only_mock_part
python3 parse_mutation_results.py detection-rules_2626 before after_careful_mock only_mock_part
python3 parse_mutation_results.py dfm_tools_976 before after_careful_mock only_mock_part
python3 parse_mutation_results.py lightning-thunder_2077 before after_careful_mock only_mock_part
python3 parse_mutation_results.py opensearch-build_595 before after_careful_mock only_mock_part
python3 parse_mutation_results.py pydicom_1636 before after_careful_mock only_mock_part
python3 parse_mutation_results.py python-dts-calibration_197 before after_careful_mock only_mock_part
python3 parse_mutation_results.py roms-tools_107 before after_careful_mock only_mock_part
python3 parse_mutation_results.py BuffaLogs_399 before after_careful_mock only_mock_part
python3 parse_mutation_results.py patientMatcher_262 before after_careful_mock only_mock_part

# ---- Summarize across projects ----

python3 summarize_mutation_results.py \
  -o summary_all_projects_unknown_mutation.csv \
  -s only_mock_part \
  armi_1737 \
  BuffaLogs_399 \
  detection-rules_2626 \
  dfm_tools_976 \
  lightning-thunder_2077 \
  opensearch-build_595 \
  patientMatcher_262 \
  pydicom_1636 \
  python-dts-calibration_197 \
  roms-tools_107

echo ""
echo "============================================"
echo "All unknown projects mutation testing done!"
echo "Summary: summary_all_projects_unknown_mutation.csv"
echo "============================================"
