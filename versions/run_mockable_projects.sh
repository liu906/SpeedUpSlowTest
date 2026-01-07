#!/bin/bash

# Global parameter controlling repeat times
# REPEAT=40


# bash ./run_tests_generic.sh pyjelly_235/ $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_venv_generic.sh ert_11206/ $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_venv_generic.sh autosubmit_2367 $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_venv_generic.sh blueprints_691 $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_venv_generic.sh ophyd-async_316 $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_generic.sh quant-mind_58/ $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_generic.sh nipoppy_697/ $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_venv_generic.sh vulnerablecode_490 $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_venv_generic.sh SDV_2158 $REPEAT before after_careful_mock only_mock_part
# bash run_tests_venv_generic.sh BazBOM_33 $REPEAT before after_careful_mock only_mock_part


# python3 parse_results_generic_optimized.py pyjelly_235 only_mock_part
# python3 parse_results_generic_optimized.py ert_11206 only_mock_part
# python3 parse_results_generic_optimized.py vulnerablecode_490  only_mock_part
# python3 parse_results_generic_optimized.py autosubmit_2367  only_mock_part
# python3 parse_results_generic_optimized.py blueprints_691  only_mock_part
# python3 parse_results_generic_optimized.py ophyd-async_316  only_mock_part
# python3 parse_results_generic_optimized.py quant-mind_58 only_mock_part
# python3 parse_results_generic_optimized.py nipoppy_697 only_mock_part
# python3 parse_results_generic_optimized.py vulnerablecode_490 only_mock_part
# python3 parse_results_generic_optimized.py SDV_2158 only_mock_part
# python3 parse_results_generic_optimized.py BazBOM_33 only_mock_part

# python3 summarize_projects.py pyjelly_235 ert_11206 autosubmit_2367 blueprints_691 ophyd-async_316 quant-mind_58 nipoppy_697 vulnerablecode_490 SDV_2158 BazBOM_33 --suffix only_mock_part --output summary_all_projects_mockable.csv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Coverage runs
REPEAT=1

bash ./run_tests_generic_coverage.sh pyjelly_235/ $REPEAT before after_careful_mock only_mock_part
bash ./run_tests_venv_generic_coverage.sh ert_11206/ $REPEAT before after_careful_mock only_mock_part
bash ./run_tests_venv_generic_coverage.sh autosubmit_2367 $REPEAT before after_careful_mock only_mock_part
bash ./run_tests_venv_generic_coverage.sh blueprints_691 $REPEAT before after_careful_mock only_mock_part
bash ./run_tests_venv_generic_coverage.sh ophyd-async_316 $REPEAT before after_careful_mock only_mock_part
bash ./run_tests_generic_coverage.sh quant-mind_58/ $REPEAT before after_careful_mock only_mock_part
bash ./run_tests_generic_coverage.sh nipoppy_697/ $REPEAT before after_careful_mock only_mock_part
bash ./run_tests_venv_generic_coverage.sh vulnerablecode_490 $REPEAT before after_careful_mock only_mock_part
bash ./run_tests_venv_generic_coverage.sh SDV_2158 $REPEAT before after_careful_mock only_mock_part
bash ./run_tests_venv_generic_coverage.sh BazBOM_33 $REPEAT before after_careful_mock only_mock_part

python3 compare_coverage.py pyjelly_235 before after_careful_mock only_mock_part
python3 compare_coverage.py ert_11206 before after_careful_mock only_mock_part
python3 compare_coverage.py autosubmit_2367 before after_careful_mock only_mock_part
python3 compare_coverage.py blueprints_691 before after_careful_mock only_mock_part
python3 compare_coverage.py ophyd-async_316 before after_careful_mock only_mock_part
python3 compare_coverage.py quant-mind_58 before after_careful_mock only_mock_part
python3 compare_coverage.py nipoppy_697 before after_careful_mock only_mock_part
python3 compare_coverage.py vulnerablecode_490 before after_careful_mock only_mock_part
python3 compare_coverage.py SDV_2158 before after_careful_mock only_mock_part
python3 compare_coverage.py BazBOM_33 before after_careful_mock only_mock_part

python3 summarize_coverage_results.py  -o summary_all_projects_mockable_codeCoverage.csv pyjelly_235 ert_11206 autosubmit_2367 blueprints_691 ophyd-async_316 quant-mind_58 nipoppy_697 vulnerablecode_490 SDV_2158 BazBOM_33
