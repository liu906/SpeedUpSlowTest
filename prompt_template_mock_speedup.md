PROJECT_PATH=patientMatcher_262

here is my sudo pwd in case you need: 19970321
# Prompt: Mock-Based Test Speedup

## Task Overview
Analyze slow tests and apply mocking **only to external dependencies** to speed up test execution **without harming test effectiveness**, or **identify and fix misuse of existing mocking** that prevents it from working correctly.

## Critical Principles

### ✅ DO Mock (External Dependencies Only):
- **Network calls** (HTTP requests, API calls)
- **Database access** (SQL queries, ORM operations)
- **File I/O** (reading/writing large files or log files, especially from disk/network)
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
Given a list of slowest tests from project `{PROJECT_PATH}/before` with "venv/" :

```
11.70s call     tests/cli/test_add.py::test_cli_add_demo_data
3.01s call     tests/match/test_GT_matching.py::test_genotype_matching
2.34s call     tests/match/test_matching_handler.py::test_internal_matching
1.63s call     tests/server/test_server_responses.py::test_match_ensembl_patient
1.63s call     tests/server/test_server_responses.py::test_match_hgnc_symbol_patient

```

For each slow test:
1. **Read the test code** to understand what it's testing
2. **Check for existing mocks**: Look for `monkeypatch.setattr()`, `@patch()`, `@mock.patch()`, etc.
3. **Trace dependencies**: Identify what the test calls
4. **Classify each dependency**:
   - External (network, DB, file I/O, subprocess, etc.) → Mockable
   - Internal logic (computation, algorithm, verification) → NOT mockable
5. **Analyze test purpose**: What verification logic must be preserved?
6. **Identify mock misuse**: If mocks exist but test is still slow, investigate why

### Step 2: Check for Mock Misuse (IMPORTANT!)

**Before adding new mocks, check if existing mocks are broken!**

#### 🚩 Red Flags Indicating Mock Misuse:

1. **Test has mocks but is still slow**
   ```python
   # Test has this but still takes 120 seconds:
   monkeypatch.setattr(Job, "DEFAULT_FILE_VERIFICATION_TIMEOUT", 0)
   ```
   → The mock might not be working!

2. **Mocking class constants used as default parameters**
   ```python
   # In source code:
   class Job:
       TIMEOUT = 120
       def method(self, timeout=TIMEOUT):  # ❌ Evaluated at definition time!
           time.sleep(timeout)
   ```
   → Mock won't affect this because Python evaluates default parameters once at function definition

3. **Test duration matches a timeout constant**
   - Test takes exactly 120 seconds
   - Code has `DEFAULT_TIMEOUT = 120`
   - Test mocks the timeout but it doesn't work
   → Classic mock misuse

#### ✅ How to Detect Mock Misuse:

```python
# Add debug logging to verify mock is working:
def test_something(monkeypatch):
    monkeypatch.setattr(Job, "TIMEOUT", 0)
    print(f"Mocked value: {Job.TIMEOUT}")  # Should print 0

    result = run_test()  # If this still takes 120s, mock isn't being used
```

#### 🔧 Common Mock Misuse Patterns and Fixes:

**Pattern 1: Default Parameter Issue** (Most Common)

```python
# ❌ BROKEN - Mock won't work:
class Job:
    TIMEOUT = 120

    def verify(self, timeout=TIMEOUT):  # Evaluated at definition time
        for _ in range(timeout):
            time.sleep(1)

# Test mocks it but doesn't work:
monkeypatch.setattr(Job, "TIMEOUT", 0)  # ❌ Too late!

# ✅ FIXED - Mock works:
class Job:
    TIMEOUT = 120

    def verify(self, timeout=None):  # Use None as default
        if timeout is None:
            timeout = self.TIMEOUT  # Evaluated at call time
        for _ in range(timeout):
            time.sleep(1)

# Now the mock works:
monkeypatch.setattr(Job, "TIMEOUT", 0)  # ✅ Works!
```

**Pattern 2: Wrong Mock Target**

```python
# In module foo.py
from bar import some_function

def my_method():
    return some_function()

# ❌ BROKEN:
@patch('bar.some_function')  # Wrong! Mock where it's defined
def test_my_method(mock_func):
    my_method()  # Calls real function

# ✅ FIXED:
@patch('foo.some_function')  # Correct! Mock where it's used
def test_my_method(mock_func):
    my_method()  # Calls mock
```

**Pattern 3: Mock Applied Too Late**

```python
# ❌ BROKEN:
obj = MyClass()  # Object created with real timeout
monkeypatch.setattr(MyClass, "TIMEOUT", 0)  # Too late!
obj.do_work()  # Uses original timeout

# ✅ FIXED:
monkeypatch.setattr(MyClass, "TIMEOUT", 0)  # Mock first
obj = MyClass()  # Object uses mocked timeout
obj.do_work()  # Uses mock
```

#### 📋 Mock Misuse Checklist:

When you find a slow test with existing mocks:

- [ ] Does the test have `monkeypatch.setattr()` or `@patch()`?
- [ ] Is the test still slow despite the mocks?
- [ ] Does the test duration match a timeout/retry constant?
- [ ] Search codebase: Is the mocked constant used as a default parameter?
- [ ] Add debug logging: Is the mock actually being applied?
- [ ] Trace execution: Is the mocked value actually used in the slow path?

**If YES to multiple questions above → Mock misuse likely! Fix the mock instead of adding new ones.**

### Step 3: Evaluate Mockability (for new mocks)

**IMPORTANT: This task is ONLY about true mocking using `unittest.mock`, `pytest-mock`, `monkeypatch`, etc. Do NOT:**
- ❌ Change timeout values (e.g., `timeout=3` → `timeout=0.1`)
- ❌ Reduce iteration counts or parameters
- ❌ Optimize fixture initialization times
- ❌ Suggest any other speedup techniques

**If a test is not mockable, mark it as "NOT MOCKABLE" and skip it. Do nothing else.**

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

#### D. Final Decision:
- [ ] **MOCKABLE** - Proceed with implementing true mocks (using `@patch`, `mocker.patch`, `monkeypatch.setattr`, etc.)
- [ ] **NOT MOCKABLE** - Skip this test, do not modify it in any way


### Step 4: Implementation Guidelines

**CRITICAL: Only implement TRUE mocking - replacing external dependencies with mock objects.**

When implementing mocks or fixing mock misuse:

#### Use pytest-mock (pytest fixture `mocker`) or unittest.mock
```python
def test_example(mocker):
    # TRUE MOCKING: Replace the external dependency with a mock object
    mock_requests = mocker.patch('module.requests.get')
    mock_requests.return_value.json.return_value = {'data': 'test'}

    # This is TRUE mocking - no real HTTP request is made
```

**Examples of what is NOT mocking:**
```python
# ❌ NOT MOCKING - This is just parameter optimization
await backend.put(put_value, timeout=0.1)  # Reduced from timeout=3

# ❌ NOT MOCKING - This is just reducing iterations
validate_result(result, iterations=1000)  # Reduced from 20000

# ❌ NOT MOCKING - This is just optimizing delays
time.sleep(0.1)  # Reduced from 2
```

#### Mock at the correct layer:
- ✅ Mock at the **boundary** (where external call enters your code)
- ❌ Don't mock **internal methods** that wrap business logic

#### Preserve behavior:
- Mock should return **realistic data** that exercises the real code path
- Mock should maintain **same data types** and **structure** as real dependency
- Mock should allow **verification logic** to run unchanged

#### Fixing mock misuse in source code:

If you identify that a mock isn't working due to default parameter evaluation:

```python
# Fix the source code (not just the test)
# Change from:
def method(self, timeout=self.TIMEOUT):
    # implementation

# To:
def method(self, timeout=None):
    if timeout is None:
        timeout = self.TIMEOUT
    # implementation
```

Then verify the mock now works:
```python
@pytest.mark.timeout(10)  # Add safety net
def test_something(monkeypatch):
    monkeypatch.setattr(Job, "TIMEOUT", 0)
    result = run_test()  # Should now be fast!
```

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

**Mock misuse check**:
- [ ] Test has existing mocks: [YES/NO]
- [ ] If YES, do mocks appear to work? [Check if test duration matches timeout constants]
- [ ] Are mocked constants used as default parameters? [Search source code]

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

**For tests with mock misuse**:
```markdown
## Test: tests/ui_tests/cli/test_cli.py::test_that_connection_errors_do_not_effect_final_result

**Duration**: 120.00s (exact timeout value!)

**What it tests**: Verifies ensemble experiments handle ZMQ connection errors gracefully

**Mock misuse identified**: ✅ YES - Mock exists but doesn't work!

**Existing mock**:
```python
monkeypatch.setattr(Job, "DEFAULT_FILE_VERIFICATION_TIMEOUT", 0)
```

**Why mock fails**:
- Source code uses `DEFAULT_FILE_VERIFICATION_TIMEOUT` as default parameter
- Python evaluates default parameters at function definition time, not call time
- Mock is applied in test, but function already has hardcoded value

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
# Change to:
async def _verify_checksum(
    self,
    checksum_lock: asyncio.Lock,
    timeout: int | None = None,  # ✅ Use None
):
    if timeout is None:
        timeout = self.DEFAULT_FILE_VERIFICATION_TIMEOUT  # ✅ Evaluated at call time
    # ... now mock works!
```

**Expected speedup**: ~80x (120s → 1.5s) 🚀

**Decision**: Fix source code to make mock work properly, add `@pytest.mark.timeout(10)` as safety net
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

### Tests with Mock Misuse Fixed: 1
1. test_connection_errors - Fixed DEFAULT_FILE_VERIFICATION_TIMEOUT mock - 80x speedup ✅
   - Problem: Mock not working due to default parameter evaluation
   - Fix: Changed source code to use `timeout=None` with conditional evaluation
   - Result: 120s → 1.5s

### Tests Modified with New Mocks: 2
1. test_api_integration - Mocked requests.get() - 30% speedup ✅
2. test_database_query - Mocked psycopg2 - 45% speedup ✅

### Tests NOT Modified: 2
1. test_algorithm_computation - No external dependencies - ❌ NOT MOCKABLE
   - Rationale: Tests core algorithm computation + verification logic
   - Recommendation: Reduce iteration parameter (e.g., N: 20000 → 1000)

2. test_model_training - No external dependencies - ❌ NOT MOCKABLE
   - Rationale: Tests model training + verification logic
   - Recommendation: Reduce training parameters or sample size

### Overall Result:
- Mock misuse fixed: 1/5 (20%) - **Biggest impact!**
- Mockable tests: 2/5 (40%)
- Total speedup achieved: ~45% average
- Test effectiveness: 100% preserved (no verification logic lost)

### Key Lesson:
**Always check for broken mocks before adding new ones!** Fixing one misused mock (120s → 1.5s) provided more speedup than adding multiple new mocks.
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

## Special Case: Mock Misuse - The Hidden Goldmine

### The Most Impactful Optimization

**Before assuming a test needs new mocks, check if existing mocks are broken!**

#### Real Example: ERT PR #11206

A test took 120 seconds despite having this mock:
```python
monkeypatch.setattr(Job, "DEFAULT_FILE_VERIFICATION_TIMEOUT", 0)
```

**Investigation revealed**:
- Test duration: 120s (exactly matching the DEFAULT_FILE_VERIFICATION_TIMEOUT constant)
- Mock was present but not working
- Root cause: Python default parameter evaluation timing

**The Fix**:
Changed source code from:
```python
def _verify_checksum(self, timeout=DEFAULT_FILE_VERIFICATION_TIMEOUT):
```

To:
```python
def _verify_checksum(self, timeout=None):
    if timeout is None:
        timeout = self.DEFAULT_FILE_VERIFICATION_TIMEOUT
```

**Result**: 120s → 1.5s (**80x speedup!** 🚀)

### Why This Matters

- **One broken mock fix** provided more speedup than adding 10 new mocks
- The mock was already there, just not working
- No test effectiveness was lost
- Simple code change with massive impact

### Detection Strategy

1. **Look for the pattern**:
   - Test has mocking code ✓
   - Test is still slow ✓
   - Test duration matches a timeout constant ✓
   → Likely mock misuse!

2. **Search for default parameters**:
   ```bash
   grep -r "def.*timeout.*=.*TIMEOUT" src/
   ```

3. **Add debug logging**:
   ```python
   print(f"Mocked value: {Job.TIMEOUT}")  # Should be 0, but prints 120?
   ```

4. **Fix the source code** (not just the test)

### When to Suspect Mock Misuse

- ✅ Test has `monkeypatch.setattr()` or `@patch()`
- ✅ Test is still slow (matches timeout/retry constant)
- ✅ No obvious reason why mock wouldn't work
- ✅ Test was supposed to be fast but regressed

**Priority**: Always investigate mock misuse **before** adding new mocks!

---

## Final Reminder

### CRITICAL: Only True Mocking Allowed

**DO NOT suggest or implement:**
- ❌ Timeout value changes
- ❌ Parameter reductions
- ❌ Fixture optimization
- ❌ Any other speedup techniques

**ONLY use true mocking: `@patch`, `mocker.patch`, `monkeypatch.setattr`, etc.**

### Three Possible Outcomes

1. **Mock Misuse Found** (Best case!)
   - Fix the broken mock by modifying source code
   - Potential for 10x-100x speedup
   - Report: "Mock was present but not working due to [reason]. Fixed [source code location]."

2. **External Dependencies Found and Mockable** (Good case)
   - Add TRUE mocks using `@patch`, `mocker`, or `monkeypatch`
   - Replace external calls with mock objects
   - Potential for 30-90% speedup
   - Report: "Mocked [dependency] using [mock framework] successfully."

3. **No Mockable Dependencies** (Common outcome - SKIP THE TEST)
   - Test verifies core logic that cannot be mocked
   - External dependencies are integral to what's being tested
   - **DO NOT modify the test in any way**
   - Report: "Test is NOT MOCKABLE. Core verification logic would be bypassed by mocking. Test skipped - no changes made."

**Remember**:
- Fixing one broken mock is often more valuable than adding ten new ones!
- If a test cannot be safely mocked, **skip it** - do not try alternative optimizations

