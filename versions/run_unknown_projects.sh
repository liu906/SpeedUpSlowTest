#!/bin/bash

# Global parameter controlling repeat times
REPEAT=40

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# bash run_tests_venv_generic.sh sktime_8324 $REPEAT #extremely slow and make server crush
# # bash run_tests_venv_generic.sh sonic-mgmt_6122 $REPEAT # fails due to system dependencies
# bash run_tests_venv_generic.sh transformers_38480 $REPEAT # Not mockable

# bash run_tests_venv_generic.sh opensearch-build_595 $REPEAT 
# bash run_tests_venv_generic.sh pydicom_1636 $REPEAT

# bash run_tests_venv_generic.sh roms-tools_107 $REPEAT
# bash run_tests_venv_generic.sh pymodbus_1995 $REPEAT
# bash run_tests_venv_generic.sh xarray-regrid_45 $REPEAT # not mockable
# bash run_tests_venv_generic.sh proxystore_173 $REPEAT # not mockable


# bash run_tests_venv_generic.sh sentry-python_4822 $REPEAT # not mockable
# bash run_tests_generic.sh gyrinx_914 $REPEAT # not mockable on external dependencies
# bash run_tests_venv_generic.sh DeerLab_141 $REPEAT # not mockable on external dependencies
# bash run_tests_venv_generic.sh nilearn_5768 $REPEAT # running, slow
# bash run_tests_venv_generic.sh dxtb_74 $REPEAT # not mockable on external dependencies


# bash run_tests_venv_generic.sh armi_1737 $REPEAT 
# bash run_tests_venv_generic.sh kedro-mlflow_478 $REPEAT # not mockable on external dependencies
# bash run_tests_venv_generic.sh trio_2664 $REPEAT # not mockable on external dependencies
# bash run_tests_venv_generic.sh python-zeroconf_853 $REPEAT #not mockable on external dependencies

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Normal runs
# bash run_tests_venv_generic.sh opensearch-build_595 $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py opensearch-build_595 only_mock_part

# bash run_tests_venv_generic.sh pydicom_1636 $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py pydicom_1636 only_mock_part

# bash run_tests_venv_generic.sh roms-tools_107 $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py roms-tools_107 only_mock_part

# bash run_tests_venv_generic.sh armi_1737 $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py armi_1737 only_mock_part


# bash run_tests_venv_generic.sh bilby_986 $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py bilby_986 only_mock_part

# bash ./run_tests_generic.sh BuffaLogs_399/ $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py BuffaLogs_399 only_mock_part

# bash run_tests_venv_generic.sh detection-rules_2626 $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py detection-rules_2626 only_mock_part

# bash run_tests_venv_generic.sh lightning-thunder_2077 $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py lightning-thunder_2077 only_mock_part

# bash ./run_tests_generic.sh patientMatcher_262/ $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py patientMatcher_262 only_mock_part

# bash run_tests_venv_generic.sh dfm_tools_976 $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py dfm_tools_976 only_mock_part

# bash ./run_tests_generic.sh python-dts-calibration_197/ $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py python-dts-calibration_197 only_mock_part    

# bash run_tests_venv_generic.sh evalml_2446 $REPEAT before after_careful_mock only_mock_part
# python3 parse_results_generic_optimized.py evalml_2446 only_mock_part

# python3 summarize_projects.py python-dts-calibration_197 opensearch-build_595 pydicom_1636 roms-tools_107 armi_1737  BuffaLogs_399 detection-rules_2626 lightning-thunder_2077 patientMatcher_262 dfm_tools_976 --suffix only_mock_part --output summary_all_projects_unknown.csv


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Coverage runs
REPEAT=1

# bash run_tests_venv_generic_coverage.sh opensearch-build_595 $REPEAT before after_careful_mock only_mock_part
# bash run_tests_venv_generic_coverage.sh pydicom_1636 $REPEAT before after_careful_mock only_mock_part
# bash run_tests_venv_generic_coverage.sh roms-tools_107 $REPEAT before after_careful_mock only_mock_part
# bash run_tests_venv_generic_coverage.sh armi_1737 $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_generic_coverage.sh BuffaLogs_399/ $REPEAT before after_careful_mock only_mock_part
# bash run_tests_venv_generic_coverage.sh detection-rules_2626 $REPEAT before after_careful_mock only_mock_part
# bash run_tests_venv_generic_coverage.sh lightning-thunder_2077 $REPEAT before after_careful_mock only_mock_part
# bash ./run_tests_generic_coverage.sh patientMatcher_262/ $REPEAT before after_careful_mock only_mock_part
# bash run_tests_venv_generic_coverage.sh dfm_tools_976 $REPEAT before after_careful_mock only_mock_part
# bash run_tests_venv_generic_coverage.sh evalml_2446 $REPEAT before after_careful_mock only_mock_part


python3 compare_coverage.py python-dts-calibration_197 before after_careful_mock only_mock_part
python3 compare_coverage.py opensearch-build_595 before after_careful_mock only_mock_part
python3 compare_coverage.py pydicom_1636 before after_careful_mock only_mock_part
python3 compare_coverage.py roms-tools_107 before after_careful_mock only_mock_part
python3 compare_coverage.py armi_1737 before after_careful_mock only_mock_part
python3 compare_coverage.py BuffaLogs_399 before after_careful_mock only_mock_part
python3 compare_coverage.py detection-rules_2626 before after_careful_mock only_mock_part
python3 compare_coverage.py lightning-thunder_2077 before after_careful_mock only_mock_part
python3 compare_coverage.py patientMatcher_262 before after_careful_mock only_mock_part
python3 compare_coverage.py dfm_tools_976 before after_careful_mock only_mock_part

python3 summarize_coverage_results.py python-dts-calibration_197 opensearch-build_595 pydicom_1636 roms-tools_107 armi_1737 BuffaLogs_399 detection-rules_2626 lightning-thunder_2077 patientMatcher_262 dfm_tools_976