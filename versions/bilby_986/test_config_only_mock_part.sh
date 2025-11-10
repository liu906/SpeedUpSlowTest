#!/bin/bash
# Test configuration for bilby_986
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# Run with coverage first, then mutation testing
TEST_COMMAND="pytest test/bilby_mcmc/test_proposals.py::TestProposals::test_KDE_proposal test/bilby_mcmc/test_proposals.py::TestProposals::test_GMM_proposal test/bilby_mcmc/test_proposals.py::TestProposals::test_NF_proposal_15D test/gw/prior_test.py::TestAlignedSpin::test_non_analytic_form_has_correct_statistics test/gw/likelihood/relative_binning_test.py::TestRelativeBinningLikelihood::test_likelihood_when_waveform_extends_beyond_maximum_frequency -v --durations=0 -vv"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
SETUP_COMMAND="pip install numpy scipy pytest parameterized pytest-cov mutmut && pip install -e '.[all]' "

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="bilby_986"
