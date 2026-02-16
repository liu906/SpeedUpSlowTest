PROJECT_PATH=versions/dfm_tools_976

here is my sudo pwd in case you need: 19970321
# Prompt: Test Speedup

## Task Overview
Analyze slow tests and apply developers' best practices to speed up test execution **without harming test effectiveness**, or **identify and fix existing mistake** that prevents it from working correctly.

## Critical Principles


### ❌ DO NOT Harm (Internal Logic):
- **Core business logic** under test
- **Verification logic** (validation checks, assertions, statistical tests)
- **Non-test code** unit under test cannot be modified.

### 🎯 Key Decision Rule:
**If your optimization bypasses the core functionality being tested, DON'T do it.**

---

## Task Instructions

### Step 1: Analyze Slow Tests
Given a list of slowest tests from project `{PROJECT_PATH}/before` with "venv/" :

```
331.62s call     tests/test_download.py::test_cds_credentials
127.41s call     tests/test_coastlines.py::test_get_coastlines_gdb_global
38.31s call     tests/test_download.py::test_download_hycom
34.56s call     tests/test_examples.py::test_run_examples[postprocess_mapnc_ugrid]
21.80s call     tests/test_dfm_tools.py::test_intersect_edges
20.69s call     tests/test_interpolate_grid2bnd.py::test_interpolate_tide_to_forcingmodel
11.93s call     tests/test_observations.py::test_ssh_catalog_subset[rwsddl]
11.64s call     tests/test_examples.py::test_run_examples[postprocess_exporttoshapefile]
9.46s call     tests/test_data.py::test_data_map
7.12s call     tests/test_observations.py::test_ssh_retrieve_data[rwsddl]
6.79s call     tests/test_examples.py::test_run_examples[postprocess_map_monthlymean]
6.16s call     tests/test_observations.py::test_rwsddl_ssh_get_time_max
5.87s call     tests/test_observations.py::test_ssh_netcdf_overview
5.69s call     tests/test_observations.py::test_ssh_catalog_subset_expected_fields[rwsddl]
5.14s call     tests/test_hydrolib_helpers.py::test_geodataframe_with_Polygon_to_PolyFile
4.51s call     tests/test_observations.py::test_ssh_catalog_subset_expected_fields[ioc]
4.27s call     tests/test_external_packages.py::test_ctx_add_basemap
4.18s call     tests/test_examples.py::test_run_examples[postprocess_hisnc]
4.08s call     tests/test_examples.py::test_run_examples[postprocess_interpolate_edgevar_tofaces]
3.97s call     tests/test_observations.py::test_ssh_catalog_subset_expected_fields[uhslc-fast]
3.63s call     tests/test_examples.py::test_run_examples[preprocess_meshkernel_creategrid]
3.62s call     tests/test_data.py::test_data_his
3.58s call     tests/test_examples.py::test_run_examples[preprocess_merge_meteofiles]
3.53s call     tests/test_examples.py::test_run_examples[preprocess_hydrolib_readtim]
3.51s call     tests/test_observations.py::test_ssh_retrieve_data[ioc]
3.48s call     tests/test_examples.py::test_run_examples[postprocess_delft3D4_netcdf]
3.28s call     tests/test_examples.py::test_run_examples[postprocess_mapfile_to_regulargrid]
3.18s call     tests/test_examples.py::test_run_examples[postprocess_CMCC_plotting]
3.13s call     tests/test_observations.py::test_ssh_catalog_subset[ioc]
3.03s call     tests/test_examples.py::test_run_examples[preprocess_hydrolib_readxyz_readxyn_readcrs]



```

For each slow test:
1. **Read the test code** to understand what it's testing
2. **Analyze test purpose**: What verification logic must be preserved?

### Step 2: Conduct modification for speedup


### Step 5: Validation Checklist

After applying modification:

- [ ] All modified tests **pass**
- [ ] Test **assertions remain unchanged** (same verification logic)
- [ ] Test **coverage is preserved** (no code paths skipped)
- [ ] **No false positives** (test can still catch real bugs)
- [ ] **Documentation added** explaining what is optimized and why

---

## Expected Deliverables

### 1. Analysis Document
For each slow test, provide:
```markdown
## Test: test/path/to/test.py::TestClass::test_method

**Duration**: 78.95s

**What it tests**: [Brief description]

**Source code issue** (in `src/ert/scheduler/job.py`):
```python
async def _verify_checksum(
    self,
    checksum_lock: asyncio.Lock,
    timeout: int = DEFAULT_FILE_VERIFICATION_TIMEOUT,  # ❌ Evaluated once at definition
):
    # ... sleeps for 'timeout' seconds
```

**Fix required**:
```python

```

**Expected speedup**: ~80x (120s → 1.5s) 🚀

**Decision**: Fix source code to make [placeholder] 
```

### 2. Modified Test Code
Only if available optmization chance found:
- Copy project to `{PROJECT_PATH}/after_generic_opt/`
- Apply modification to test files
- install modification related dependency in .venv 
- Document changes with comments

### 3. Validation Results
```bash
# Run modified tests
pytest test/path/to/test.py::TestClass::test_method --durations=0

# Compare:
Before: 78.95s
After:  55.32s
Speedup: 30%
Status: ✅ PASS
Verification preserved: ✅ YES
```

### 4. Summary Report
```markdown

### Tests Analyzed: 5



