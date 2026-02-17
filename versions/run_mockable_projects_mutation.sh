#!/bin/bash
# Batch mutation testing runner for mockable projects
# Mirrors the structure of run_mockable_projects.sh
#
# Usage: bash run_mockable_projects_mutation.sh

set -e

echo "============================================="
echo "Mutation Testing Pipeline - Mockable Projects"
echo "============================================="
echo ""

# ---- Mutation testing runs ----
# Parameters: <project_name> <mutate_paths> <folder1> <folder2> <suffix>

bash run_mutation_venv_generic.sh pyjelly_235 "pyjelly" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh ert_11206 "src/ert" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh autosubmit_2367 "autosubmit" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh blueprints_691 "blueprints" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh ophyd-async_316 "src" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh quant-mind_58 "quantmind" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh nipoppy_697 "nipoppy" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh vulnerablecode_490 "vulnerabilities" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh SDV_2158 "sdv" before after_careful_mock only_mock_part
bash run_mutation_venv_generic.sh BazBOM_33 "tools/supplychain" before after_careful_mock only_mock_part

# ---- Parse and compare results ----

python3 parse_mutation_results.py pyjelly_235 before after_careful_mock only_mock_part
python3 parse_mutation_results.py ert_11206 before after_careful_mock only_mock_part
python3 parse_mutation_results.py autosubmit_2367 before after_careful_mock only_mock_part
python3 parse_mutation_results.py blueprints_691 before after_careful_mock only_mock_part
python3 parse_mutation_results.py ophyd-async_316 before after_careful_mock only_mock_part
python3 parse_mutation_results.py quant-mind_58 before after_careful_mock only_mock_part
python3 parse_mutation_results.py nipoppy_697 before after_careful_mock only_mock_part
python3 parse_mutation_results.py vulnerablecode_490 before after_careful_mock only_mock_part
python3 parse_mutation_results.py SDV_2158 before after_careful_mock only_mock_part
python3 parse_mutation_results.py BazBOM_33 before after_careful_mock only_mock_part

# ---- Summarize across projects ----

python3 summarize_mutation_results.py \
  -o summary_all_projects_mockable_mutation.csv \
  -s only_mock_part \
  autosubmit_2367 \
  BazBOM_33 \
  blueprints_691 \
  ert_11206 \
  nipoppy_697 \
  ophyd-async_316 \
  pyjelly_235 \
  quant-mind_58 \
  SDV_2158 \
  vulnerablecode_490

echo ""
echo "============================================="
echo "All mockable projects mutation testing done!"
echo "Summary: summary_all_projects_mockable_mutation.csv"
echo "============================================="
