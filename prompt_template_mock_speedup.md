PROJECT_PATH=blueprints_691

# Prompt: Mock-Based Test Speedup

## Task Overview
Analyze slow tests and apply mocking **only to external dependencies** to speed up test execution **without harming test effectiveness**.

## Critical Principles

### ✅ DO Mock (External Dependencies Only):
- **Network calls** (HTTP requests, API calls)
- **Database access** (SQL queries, ORM operations)
- **File I/O** (reading/writing large files, especially from disk/network)
- **External APIs** (third-party services, cloud services)
- **Subprocess calls** (shell commands, external executables)
- **Time-consuming I/O operations** (socket operations, message queues)

### ❌ DO NOT Mock (Internal Logic):
- **Core business logic** under test
- **Verification logic** (validation checks, assertions, statistical tests)

### 🎯 Key Decision Rule:
**If mocking bypasses the core functionality being tested, DON'T mock it.**

---

## Task Instructions

### Step 1: Analyze Slow Tests
Given a list of slowest tests from project `{PROJECT_PATH}/before`:

```
26.94s call     tests/structural_sections/steel/steel_cross_sections/test_chs_profile.py::Test suite for CHSSteelProfile.::Test the plotting of the CHS profile shapes.
24.73s call     tests/structural_sections/steel/steel_cross_sections/test_rhs_profile.py::Test suite for RHSSteelProfile.::Test the plot method (ensure it runs without errors).
23.18s call     tests/structural_sections/steel/steel_cross_sections/test_i_profile.py::Test suite for ISteelProfile.::Test the plot method (ensure it runs without errors).
```

For each slow test:
1. **Read the test code** to understand what it's testing
2. **Trace dependencies**: Identify what the test calls
3. **Classify each dependency**:
   - External (network, DB, file I/O, subprocess, etc.) → Mockable
   - Internal logic (computation, algorithm, verification) → NOT mockable
4. **Analyze test purpose**: What verification logic must be preserved?

### Step 2: Evaluate Mockability

For each identified external dependency, answer:

#### A. Is it truly external?
- [ ] Does it involve I/O outside the process? (network, disk, DB)
- [ ] Does it call external services/APIs?
- [ ] Does it spawn subprocesses?

#### B. Will mocking preserve test effectiveness?
- [ ] Does the test verify the **result** of this dependency, or the **interaction** with it?
- [ ] If mocked, will the core verification logic still execute?
- [ ] Will statistical/mathematical correctness still be validated?

#### C. What is the cost-benefit?
- [ ] How much speedup will mocking provide? (estimate %)
- [ ] How much verification logic is lost? (estimate %)
- [ ] Is the tradeoff acceptable? (aim for <10% verification loss)


### Step 3: Implementation Guidelines

When implementing mocks:

#### Use pytest-mock (pytest fixture `mocker`) or unittest
```python
def test_example(mocker):
    # Mock at the correct boundary
    mock_requests = mocker.patch('module.requests.get')
    mock_requests.return_value.json.return_value = {'data': 'test'}
```

#### Mock at the correct layer:
- ✅ Mock at the **boundary** (where external call enters your code)
- ❌ Don't mock **internal methods** that wrap business logic

#### Preserve behavior:
- Mock should return **realistic data** that exercises the real code path
- Mock should maintain **same data types** and **structure** as real dependency
- Mock should allow **verification logic** to run unchanged

### Step 5: Validation Checklist

After applying mocks:

- [ ] All modified tests **pass**
- [ ] Test **assertions remain unchanged** (same verification logic)
- [ ] Test **coverage is preserved** (no code paths skipped)
- [ ] **No false positives** (test can still catch real bugs)
- [ ] **Documentation added** explaining what is mocked and why

---

## Expected Deliverables

### 1. Analysis Document
For each slow test, provide:
```markdown
## Test: test/path/to/test.py::TestClass::test_method

**Duration**: 78.95s

**What it tests**: [Brief description]

**Dependencies identified**:
- `library.compute_function()` - INTERNAL COMPUTATION - ❌ NOT MOCKABLE
  - Reason: Core algorithm is what's being tested
  - Verification logic: Checks algorithm output + validation logic
  - Impact if mocked: 90% of test effectiveness lost

- `requests.get(url)` - EXTERNAL API - ✅ MOCKABLE
  - Reason: External HTTP call, test doesn't verify network behavior
  - Verification logic: Only uses response data, not HTTP mechanics
  - Impact if mocked: 0% verification loss, ~30% speedup

**Decision**: Mock `requests.get()` only. DO NOT mock core computation.

**Expected speedup**: ~30% (78.95s → ~55s)
```

### 2. Modified Test Code
Only if mockable dependencies found:
- Copy project to `{PROJECT_PATH}/after_careful_mock/`
- Apply mocks to test files
- install mock related dependency in .venv 
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
## Mocking Summary

### Tests Analyzed: 5

### Tests Modified: 2
1. test_api_integration - Mocked requests.get() - 30% speedup ✅
2. test_database_query - Mocked psycopg2 - 45% speedup ✅

### Tests NOT Modified: 3
1. test_algorithm_computation - No external dependencies - ❌ NOT MOCKABLE
   - Rationale: Tests core algorithm computation + verification logic
   - Recommendation: Reduce iteration parameter (e.g., N: 20000 → 1000)

2. test_model_training - No external dependencies - ❌ NOT MOCKABLE
   - Rationale: Tests model training + verification logic
   - Recommendation: Reduce training parameters or sample size

3. test_statistical_validation - Testing the statistics itself - ❌ NOT MOCKABLE
   - Rationale: The slow computation IS what's being verified
   - Recommendation: Accept the speed, or use sampling/approximation

### Overall Result:
- Mockable tests: 2/5 (40%)
- Total speedup achieved: 25% average
- Test effectiveness: 100% preserved (no verification logic lost)
```

---

## Anti-Patterns to Avoid

### ❌ Don't Do This:
```python
# BAD: Mocking internal computation
def test_algorithm(mocker):
    mock_compute = mocker.patch('library.core_algorithm')
    mock_compute.return_value = [0.0]  # Bypasses verification!
```
**Why bad**: This bypasses the core algorithm and verification logic that the test is meant to validate.

### ✅ Do This Instead:
```python
# GOOD: Accept that this test is slow, or reduce iterations
def test_algorithm(self):
    params = self.create_params()
    result = run_algorithm(params)
    self.validate_result(result, iterations=1000)  # Reduced from 20000
```
**Why good**: Preserves test effectiveness while still getting reasonable speedup.

---

## Final Reminder

**It is perfectly acceptable to conclude that a slow test has NO mockable external dependencies.**

If analysis shows:
- All slowness comes from internal computation/logic
- Mocking would bypass core verification
- No external I/O is involved

**Then report**: "No external dependencies found suitable for mocking. Test speed is inherent to the verification logic being tested."

