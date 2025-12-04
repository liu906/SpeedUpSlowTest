#!/bin/bash
# Test configuration for asapdiscovery_798
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# Using -p no:warnings to suppress import warnings from missing OpenEye
TEST_COMMAND="python -m pytest --durations=0 -v --tb=no -p no:warnings --continue-on-collection-errors || true"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv (e.g., install dependencies)
# This project requires OpenEye toolkit (proprietary, conda-only, needs license)
# Strategy: Create mock openeye module to allow import, mark tests that need it as skipped
SETUP_COMMAND="git init 2>/dev/null || true && \
git config user.email 'test@test.com' 2>/dev/null || true && \
git config user.name 'Test User' 2>/dev/null || true && \
git add -A 2>/dev/null || true && \
git commit -m 'Initial commit' 2>/dev/null || true && \
export SETUPTOOLS_SCM_PRETEND_VERSION=0.0.99 && \
pip install pytest pytest-cov pytest-xdist pytest-timeout && \
pip install click appdirs pandas 'pydantic>=1.10.8,<2.0.0a0' seaborn requests boto3 moto flask flask-cors typing-extensions biopython pyyaml sigfig validators ase && \
pip install pooch mdanalysis rdkit-pypi logomaker torch --index-url https://download.pytorch.org/whl/cpu && \
mkdir -p .venv/lib/python3.10/site-packages/openeye && \
echo 'class MockModule:
    def __getattr__(self, name):
        return MockModule()
    def __call__(self, *args, **kwargs):
        return MockModule()
    def OEChemIsLicensed(self):
        return False
import sys
oechem = MockModule()
oequacpac = MockModule()
oeiupac = MockModule()
oeomega = MockModule()
oedocking = MockModule()
oedepict = MockModule()
sys.modules[\"openeye.oechem\"] = oechem
sys.modules[\"openeye.oequacpac\"] = oequacpac
sys.modules[\"openeye.oeiupac\"] = oeiupac
sys.modules[\"openeye.oeomega\"] = oeomega
sys.modules[\"openeye.oedocking\"] = oedocking
sys.modules[\"openeye.oedepict\"] = oedepict' > .venv/lib/python3.10/site-packages/openeye/__init__.py && \
mkdir -p .venv/lib/python3.10/site-packages/openfe && \
echo 'class MockModule:
    def __getattr__(self, name):
        return MockModule()
    def __call__(self, *args, **kwargs):
        return MockModule()' > .venv/lib/python3.10/site-packages/openfe/__init__.py && \
mkdir -p .venv/lib/python3.10/site-packages/gufe && \
echo 'class MockModule:
    def __getattr__(self, name):
        return MockModule()
    def __call__(self, *args, **kwargs):
        return MockModule()' > .venv/lib/python3.10/site-packages/gufe/__init__.py && \
pip install -e asapdiscovery-data/. --no-deps && \
pip install -e asapdiscovery-cli/. --no-deps && \
pip install -e asapdiscovery-simulation/. --no-deps && \
pip install -e asapdiscovery-modeling/. --no-deps && \
pip install -e asapdiscovery-dataviz/. --no-deps && \
pip install -e asapdiscovery-docking/. --no-deps && \
pip install -e asapdiscovery-ml/. --no-deps && \
pip install -e asapdiscovery-alchemy/. --no-deps"

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Additional project-specific variables
PROJECT_NAME="asapdiscovery_798"

# Note: This project requires OpenEye toolkit (proprietary, conda-only, license-required)
# We create mock modules to allow imports but tests requiring actual functionality will fail
# This allows us to at least run tests that don't depend on OpenEye
# CI uses: mamba-org/setup-micromamba with devtools/conda-envs/asapdiscovery-ubuntu-latest.yml
