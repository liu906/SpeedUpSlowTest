# Prompt Template: Mock-Based Test Speedup (Short Version)

## Task
Given slow tests, apply mocking **only to external dependencies** to speed up execution **without harming test effectiveness**.

---

## Critical Rules

### ✅ MOCK These (External Dependencies):
- Network calls (HTTP, API)
- Database access (SQL, ORM)
- File I/O (disk reads/writes)
- Subprocess calls (shell commands)
- External services (cloud APIs, third-party)

### ❌ NEVER MOCK These (Internal Logic):
- Core algorithms/computations (numerical methods, statistical calculations, model training)
- Verification logic (validation checks, assertions, statistical tests)
- Business logic under test
- Mathematical operations (library computations being tested)

### 🎯 Golden Rule:
**If mocking bypasses what the test is verifying, DON'T mock it.**

---

## Instructions

### Given Input:
```
Project: {PROJECT_PATH}
Slow tests:
  78.95s  test/module/test_file.py::TestClass::test_method_1
  20.26s  test/module/test_file.py::TestClass::test_method_2
  13.45s  test/other/test_file.py::TestClass::test_method_3
```

### For Each Test:

1. **Read the test code** - understand what it verifies
2. **Identify dependencies** - what does it call?
3. **Classify each**:
   - External I/O? → Mockable ✅
   - Internal computation/logic? → NOT mockable ❌
4. **Decision criteria**:
   - Will mocking preserve verification logic? (aim for 0-10% loss)
   - Is speedup worthwhile? (aim for >20% improvement)

---

## Decision Examples

| Dependency | Mock? | Why |
|------------|-------|-----|
| `requests.get()` | ✅ YES | External HTTP - not what's being tested |
| `library.compute_algorithm()` | ❌ NO | Core algorithm being verified |
| `library.train_model()` | ❌ NO | Model training being tested |
| Test validates algorithm verification logic | ❌ NO | Testing the verification itself |
| `subprocess.run(['external_cmd'])` | ✅ YES | External subprocess |
| `database_client.connect()` | ✅ YES | External database |
| Large iteration loops (N=100000) | ❌ NO | Computation being verified - reduce N instead |

---

## Deliverables

### 1. Analysis (for each test):
```markdown
## Test: test/path/test.py::TestClass::test_method
**Duration**: 78.95s

**What it tests**: [1-2 sentence description]

**Dependencies**:
- `dependency_1` - [EXTERNAL/INTERNAL] - [✅ MOCKABLE / ❌ NOT MOCKABLE]
  - Reason: [why mockable or not]
  - Verification impact: [what's preserved/lost]

**Decision**: [Mock X only / No mockable dependencies found]
**Expected speedup**: [X%] or [None - recommend reduce N/sample size]
```

### 2. Implementation (if mockable found):
- Copy to `{PROJECT_PATH}_after_mock/`
- Apply mocks using pytest-mock
- Add comments explaining what/why mocked

### 3. Validation:
```bash
pytest path/to/test.py::test_name --durations=0
```
- Before: Xs
- After: Ys
- Status: PASS ✅
- Verification preserved: YES ✅

### 4. Summary:
```markdown
## Summary
**Tests analyzed**: X
**Tests modified**: Y (with external dependencies)
**Tests NOT modified**: Z (no external dependencies OR would harm verification)

**Not modified reasons**:
- test_name_1: Internal computation only - recommend reduce iteration count
- test_name_2: Testing verification logic itself - no speedup possible

**Overall**: Y% speedup, 100% verification preserved
```

---

## Important Notes

✅ **It's OK to conclude**: "No external dependencies to mock"

✅ **Alternative recommendations** when nothing to mock:
- Reduce iteration counts (N parameter)
- Reduce sample sizes
- Mark as `@pytest.mark.slow`
- Run only in nightly builds

❌ **Don't force mocking** - Mocking internal logic destroys test value

---

## Quick Example

### BAD ❌:
```python
# Mocking core computation being tested
def test_algorithm(mocker):
    mocker.patch('library.core_algorithm')  # Bypasses what we're testing!
```

### GOOD ✅:
```python
# Accept it's slow OR reduce iterations
def test_algorithm(self):
    result = run_algorithm(params)
    self.verify_result(result, iterations=1000)  # Reduced from 20000
```
