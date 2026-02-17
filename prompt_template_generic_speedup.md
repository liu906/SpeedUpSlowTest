[if you are gonna reach the limit during this task, stop before you reach the token limit and tell me why this task cause timeout]


PROJECT_PATH=versions/python-dts-calibration_197

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
3.30s call     pydicom/tests/test_pillow_pixel_data.py::TestPillowHandler_JPEG::test_color_3d
0.95s call     pydicom/tests/test_data_manager.py::test_fetch_data_files
0.41s call     pydicom/tests/test_pillow_pixel_data.py::TestPillowHandler_JPEG2K::test_properties[/root/.pydicom/data/RG1_J2KR.dcm-data11]
0.41s call     pydicom/tests/test_pillow_pixel_data.py::TestPillowHandler_JPEG2K::test_array[/root/.pydicom/data/RG1_J2KR.dcm-/root/.pydicom/data/RG1_UNCR.dcm-fixes3]
0.18s call     pydicom/tests/test_pillow_pixel_data.py::TestPillowHandler_JPEG::test_properties[/root/.pydicom/data/color3d_jpeg_baseline.dcm-data0]


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

### 4. Summary Report write to file system as a readme file
```markdown

### Tests Analyzed: 5



