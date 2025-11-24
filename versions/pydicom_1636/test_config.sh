#!/bin/bash
# Test configuration for pydicom_1636
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #1636 testing: Run tests that involve downloading test data
# This PR fixes issue #1611 about slow downloads with progress bars
# The test_data_manager.py file contains tests that exercise the download functionality
TEST_COMMAND="pytest pydicom/tests/test_data_manager.py -v --durations=0 --timeout=60"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Setup command to install dependencies
# The project uses setup.py and requires pytest for testing
# Also install tqdm which is used for progress bars in downloads
SETUP_COMMAND="pip install --upgrade pip && pip install -e . && pip install 'pytest>=7.0,<8.0' pytest-timeout tqdm"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Python version (pydicom supports Python 3.6+, using 3.10)
PYTHON_VERSION="python3.10"

# Project name
PROJECT_NAME="pydicom_1636"

# Note: PR #1636 fixes slow download performance with progress bars
# PR Title: "Sensible chunk size for test data download"
# PR URL: https://github.com/pydicom/pydicom/pull/1636
# Related Issue: #1611 "download test images is slow with USE_PROGRESS_BAR"
#
# Changes made in PR #1636:
#
# 1. pydicom/data/download.py (1 line modified - Line 104)
#    BEFORE:
#    ```python
#    for data in tqdm.tqdm(
#        r.iter_content(), total=total_size_in_bytes,
#        unit="B", unit_scale=True, miniters=1,
#        desc=url.split("/")[-1]
#    ):
#    ```
#
#    AFTER:
#    ```python
#    for data in tqdm.tqdm(
#        r.iter_content(chunk_size=4096), total=total_size_in_bytes,
#        unit="B", unit_scale=True, miniters=1,
#        desc=url.split("/")[-1]
#    ):
#    ```
#
#    IMPACT: Massive performance improvement for downloads with progress bars
#    - BEFORE: iter_content() with no chunk_size defaults to 1 byte chunks
#      * Progress bar updated after EVERY SINGLE BYTE
#      * Caused severe performance degradation
#      * Made downloads extremely slow
#    - AFTER: iter_content(chunk_size=4096) uses 4KB chunks
#      * Progress bar updated every 4096 bytes
#      * Drastically reduces overhead
#      * Downloads run at normal/expected speed
#
# 2. doc/release_notes/v2.4.0.rst (Documentation update)
#    - Added note about the performance fix in release notes
#
# Performance Impact:
# The issue was that when USE_PROGRESS_BAR is enabled (via tqdm library),
# the download would be extremely slow because:
# - requests.iter_content() defaults to chunk_size=1 when no argument provided
# - This means reading 1 byte at a time from the network stream
# - tqdm progress bar gets updated after every byte
# - For a typical test file of 1-10 MB, this means 1-10 MILLION updates!
#
# With chunk_size=4096 (4KB):
# - Reads 4096 bytes at a time (standard I/O block size)
# - Progress bar updates only ~250 times for 1MB file (instead of 1 million)
# - Expected speedup: 100x-1000x faster for typical test data files
# - Brings download speed back to normal network-limited performance
#
# Why 4096 bytes?
# - Standard filesystem block size on most systems
# - Common default for network I/O operations
# - Good balance between memory usage and performance
# - Aligns with typical TCP packet sizes
#
# Test files affected:
# - test_data_manager.py contains tests that download test data
#   * test_get_testdata_file_no_download()
#   * test_get_testdata_file_network_outage()
#   * test_get_testdata_files_network_outage()
#   * test_fetch_data_files_download_failure()
# - These tests use the download functionality that was optimized
# - However, they mock/simulate failures, so actual download perf may not be visible
# - The real performance impact is seen when actually downloading test data files
#
# Note from PR author:
# "This is a pretty trivial change and I don't think it necessarily needs a test."
# "Testing this would require setting up infrastructure to run performance tests."
#
# How PR #1636 was tested:
# - Manual testing of download functionality
# - Approved by @darcymason (project maintainer)
# - Coverage increased by +0.10%
#
# To verify the fix:
# The performance improvement is most visible when:
# 1. USE_PROGRESS_BAR environment variable is set (enables tqdm)
# 2. Actually downloading files from network (not mocked tests)
# 3. Comparing download time for same file before/after
#
# Expected improvement:
# - BEFORE: Download of 1MB file might take 10-60 seconds (depending on system)
#           due to 1 million progress bar updates
# - AFTER: Download of 1MB file takes 1-2 seconds (normal network speed)
#          with only ~250 progress bar updates
# - Speedup: 10x-100x improvement for typical test data files
#
# The test suite may not show dramatic timing differences because:
# - Tests often mock the download function
# - Test data files are relatively small
# - Tests may not enable progress bars
# But the fix prevents severe performance regression when progress bars are used
# in production/real-world scenarios
