#!/bin/bash

# Global parameter controlling repeat times
REPEAT=40

# bash run_tests_venv_generic.sh sktime_8324 $REPEAT
# # bash run_tests_venv_generic.sh sonic-mgmt_6122 $REPEAT
# bash run_tests_venv_generic.sh transformers_38480 $REPEAT
# bash run_tests_venv_generic.sh nipoppy_697 $REPEAT
# bash run_tests_venv_generic.sh opensearch-build_595 $REPEAT
# # bash run_tests_venv_generic.sh ophyd-async_316 $REPEAT
# bash run_tests_venv_generic.sh pydicom_1636 $REPEAT
# bash run_tests_venv_generic.sh pyjelly_235 $REPEAT
# # bash run_tests_venv_generic.sh quant-mind_58 $REPEAT

# bash run_tests_venv_generic.sh roms-tools_107 $REPEAT
# bash run_tests_venv_generic.sh pymodbus_1995 $REPEAT
# bash run_tests_venv_generic.sh xarray-regrid_45 $REPEAT
# bash run_tests_venv_generic.sh proxystore_173 $REPEAT
# bash run_tests_venv_generic.sh sentry-python_4822 $REPEAT
# bash run_tests_generic.sh gyrinx_914 $REPEAT
# bash run_tests_venv_generic.sh DeerLab_141 $REPEAT
# bash run_tests_venv_generic.sh nilearn_5768 $REPEAT
# bash run_tests_venv_generic.sh dxtb_74 $REPEAT


# bash run_tests_venv_generic.sh armi_1737 $REPEAT
# bash run_tests_venv_generic.sh kedro-mlflow_478 $REPEAT
# bash run_tests_venv_generic.sh SDV_2158 $REPEAT
# bash run_tests_venv_generic.sh trio_2664 $REPEAT
# bash run_tests_venv_generic.sh python-zeroconf_853 $REPEAT

# bash ./run_tests_generic.sh pyjelly_235/ $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_venv_generic.sh ert_11206/ $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_venv_generic.sh autosubmit_2367 $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_venv_generic.sh blueprints_691 $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_venv_generic.sh ophyd-async_316 $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_generic.sh quant-mind_58/ $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_generic.sh nipoppy_697/ $REPEAT before after_careful_mock only_mock_part


# python3 parse_results_generic_optimized.py pyjelly_235 only_mock_part
# python3 parse_results_generic_optimized.py ert_11206 only_mock_part
# python3 parse_results_generic_optimized.py vulnerablecode_490  only_mock_part
# python3 parse_results_generic_optimized.py autosubmit_2367  only_mock_part
# python3 parse_results_generic_optimized.py blueprints_691  only_mock_part
# python3 parse_results_generic_optimized.py ophyd-async_316  only_mock_part
# python3 parse_results_generic_optimized.py quant-mind_58 only_mock_part
# python3 parse_results_generic_optimized.py nipoppy_697 only_mock_part

# bash ./run_tests_venv_generic.sh vulnerablecode_490 $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py vulnerablecode_490 only_mock_part

bash ./run_tests_venv_generic.sh SDV_2158 $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py SDV_2158 only_mock_part

bash run_tests_venv_generic.sh BazBOM_33 $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py BazBOM_33 only_mock_part

bash run_tests_venv_generic.sh roms-tools_107 $REPEAT before after_careful_mock only_mock_part
python3 parse_results_generic_optimized.py roms-tools_107 only_mock_part

# https://github.com/scikit-learn/scikit-learn/pull/21984
# https://github.com/mantidproject/mantidimaging/pull/1439

