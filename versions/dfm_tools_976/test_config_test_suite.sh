#!/bin/bash
# Test configuration for dfm_tools_976
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# dfm_tools is a Python package for pre- and postprocessing D-FlowFM model files
# The project uses pytest with durations tracking enabled
TEST_COMMAND="pytest --durations=0"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Setup command to install dependencies
# Install the package in editable mode with dev dependencies (includes pytest, pytest-cov, pytest-timeout)
# Note: Multiple dependency/API compatibility issues fixed:
# 1. copernicusmarine has a version conflict (requires >=1.3.2,<2.0.0 but only 2.x available)
#    Solution: Remove the <2.0.0 constraint from pyproject.toml
# 2. hydrolib-core API changed: hydrolib.core.utils moved to hydrolib.core.base.utils
#    Solution: Fix the import path in modelbuilder.py
# 3. pytest 9.x breaks fixtures with marks (PytestRemovedIn9Warning)
#    Solution: Install pytest<9.0 to avoid breaking changes
SETUP_COMMAND="pip install --upgrade pip && \
sed -i 's/\"copernicusmarine<2.0.0\",//' pyproject.toml && \
sed -i 's/\"pytest\",/\"pytest<9.0\",/' pyproject.toml && \
pip install -e .[dev] && \
sed -i 's/from hydrolib.core.utils import/from hydrolib.core.base.utils import/' dfm_tools/modelbuilder.py"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Python version (dfm_tools supports Python 3.9+, using 3.10)
PYTHON_VERSION="python3.10"

# Project name
PROJECT_NAME="dfm_tools_976"

# Note: dfm_tools is a package for pre- and post-processing Delft3D FM (D-FlowFM) model files
# Project URL: https://github.com/Deltares/dfm_tools
#
# IMPORTANT - Dependency & API Compatibility Workarounds:
# 1. copernicusmarine version conflict:
#    - Original requirement: copernicusmarine>=1.3.2,<2.0.0
#    - Only version 2.x available on PyPI now
#    - Fix: Remove the <2.0.0 constraint to allow installation
#    - Impact: Some tests using copernicusmarine may fail due to API changes (v1.x -> v2.x)
#
# 2. hydrolib-core API change:
#    - In hydrolib-core 0.10.x, the utils module location changed
#    - Old: from hydrolib.core.utils import get_path_style_for_current_operating_system
#    - New: from hydrolib.core.base.utils import get_path_style_for_current_operating_system
#    - Fix: Update import path in dfm_tools/modelbuilder.py
#
# 3. pytest 9.x breaking changes:
#    - pytest 9.0+ raises PytestRemovedIn9Warning for marks applied to fixtures
#    - The conftest.py applies @pytest.mark.requiressecrets to a fixture (deprecated pattern)
#    - Fix: Constrain pytest to version <9.0 to avoid breaking changes
#
# The project contains tests for various functionality:
# - test_bathymetry.py: Bathymetry data handling
# - test_coastlines.py: Coastline processing
# - test_data.py: Data management utilities
# - test_dfm_tools.py: Core dfm_tools functionality
# - test_download.py: Data download functionality
# - test_examples.py: Example scripts validation
# - test_external_packages.py: Integration with external packages
# - test_get_nc.py: NetCDF file handling
# - test_hydrolib_helpers.py: HYDROLIB-core integration helpers
# - test_interpolate_grid2bnd.py: Grid to boundary interpolation
# - test_meshkernel_helpers.py: MeshKernel integration helpers
# - test_modelbuilder.py: Model building utilities
# - test_observations.py: Observation data handling
# - test_xarray_helpers.py: xarray utility functions
# - test_xugrid_helpers.py: xugrid utility functions
#
# Dependencies include:
# - scipy, numpy, matplotlib, pandas
# - shapely, geopandas, fiona, contextily (geospatial)
# - xarray, dask, netcdf4, bottleneck, xugrid (multi-dimensional arrays)
# - cdsapi, pydap, erddapy, copernicusmarine, rws-ddlpy (data access)
# - pooch (data fetching), hydrolib-core, meshkernel (modeling)
