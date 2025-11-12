# Summary: Mock Misuse Strategy Added to Prompt Template

## What Was Learned

From analyzing **ERT PR #11206**, I learned about a critical mock optimization strategy that was missing from the original prompt template: **identifying and fixing misused mocks**.

---

## The Key Insight

### Problem Pattern

A test had mocking code but was still taking 120 seconds:

```python
# Test code:
monkeypatch.setattr(Job, "DEFAULT_FILE_VERIFICATION_TIMEOUT", 0)
run_test()  # Still takes 120 seconds! 😱
```

### Root Cause

The mock wasn't working because the source code used the constant as a **default parameter**:

```python
# Source code (BEFORE - broken):
class Job:
    DEFAULT_FILE_VERIFICATION_TIMEOUT = 120

    async def _verify_checksum(
        self,
        checksum_lock: asyncio.Lock,
        timeout: int = DEFAULT_FILE_VERIFICATION_TIMEOUT,  # ❌ Evaluated at definition time
    ):
        # Sleeps for 120 seconds even when mock sets it to 0
        await asyncio.sleep(timeout)
```

**Why it fails**: Python evaluates default parameters **once** when the function is defined, not when it's called. By the time the test mocks the constant, it's too late—the function already has `120` baked in.

### The Fix

Change the source code to use `None` as the default and evaluate the constant at call time:

```python
# Source code (AFTER - fixed):
class Job:
    DEFAULT_FILE_VERIFICATION_TIMEOUT = 120

    async def _verify_checksum(
        self,
        checksum_lock: asyncio.Lock,
        timeout: int | None = None,  # ✅ Use None
    ):
        if timeout is None:
            timeout = self.DEFAULT_FILE_VERIFICATION_TIMEOUT  # ✅ Evaluated at call time

        await asyncio.sleep(timeout)  # Now mock works!
```

### Result

- **Before**: 120 seconds
- **After**: 1.5 seconds
- **Speedup**: **80x** 🚀

---

## What Was Added to the Prompt Template

### 1. New Step 2: "Check for Mock Misuse"

Added a comprehensive section with:

#### Red Flags to Identify Mock Misuse:
- Test has mocks but is still slow
- Test duration matches a timeout constant (e.g., 120s test with `TIMEOUT = 120`)
- Mocking class constants used as default parameters

#### Common Patterns and Fixes:

**Pattern 1: Default Parameter Issue** (most common)
```python
# ❌ BROKEN:
def method(self, timeout=TIMEOUT):
    time.sleep(timeout)

# ✅ FIXED:
def method(self, timeout=None):
    if timeout is None:
        timeout = self.TIMEOUT
    time.sleep(timeout)
```

**Pattern 2: Wrong Mock Target**
```python
# ❌ BROKEN:
@patch('bar.some_function')  # Patching where it's defined

# ✅ FIXED:
@patch('foo.some_function')  # Patching where it's used
```

**Pattern 3: Mock Applied Too Late**
```python
# ❌ BROKEN:
obj = MyClass()  # Created first
monkeypatch.setattr(MyClass, "TIMEOUT", 0)  # Too late!

# ✅ FIXED:
monkeypatch.setattr(MyClass, "TIMEOUT", 0)  # Mock first
obj = MyClass()  # Created after mock
```

### 2. Detection Strategy

Added checklist for investigating mock misuse:
- [ ] Does test have mocking code?
- [ ] Is test still slow despite mocks?
- [ ] Does test duration match timeout constant?
- [ ] Search codebase for mocked constant in default parameters
- [ ] Add debug logging to verify mock is applied

### 3. Updated Analysis Template

Added "Mock misuse check" section to the analysis document template:
```markdown
**Mock misuse check**:
- [ ] Test has existing mocks: [YES/NO]
- [ ] If YES, do mocks appear to work?
- [ ] Are mocked constants used as default parameters?
```

### 4. Updated Summary Report Template

Added new category for fixed mock misuse:
```markdown
### Tests with Mock Misuse Fixed: 1
1. test_connection_errors - Fixed DEFAULT_FILE_VERIFICATION_TIMEOUT mock - 80x speedup ✅
   - Problem: Mock not working due to default parameter evaluation
   - Fix: Changed source code to use timeout=None with conditional evaluation
   - Result: 120s → 1.5s
```

### 5. Special Section: "Mock Misuse - The Hidden Goldmine"

Added comprehensive section explaining:
- Why checking for mock misuse should be **priority #1**
- Real example from ERT PR #11206
- Detection strategy
- Why one fixed mock beats ten new mocks

### 6. Updated Final Reminder

Changed from 2 possible outcomes to 3:

1. **Mock Misuse Found** (Best case!) - 10x-100x speedup potential
2. **External Dependencies Found** (Good case) - 30-50% speedup potential
3. **No Mockable Dependencies** (Acceptable outcome) - Document why

---

## Why This Matters

### The Original Prompt Was Incomplete

The original prompt focused on:
- ✅ Identifying external dependencies to mock
- ✅ Avoiding mocking internal logic
- ❌ **MISSING**: Checking if existing mocks are broken

### The Real-World Impact

In the ERT project analysis:
- 4 tests analyzed (146.43s total)
- 0 tests found with mockable external dependencies (all integration tests)
- **But if I had checked for mock misuse first**, I would have found:
  - Test with broken mock taking 120s
  - 80x speedup opportunity (120s → 1.5s)
  - Simple fix with massive impact

### Key Lesson

**Always check for broken mocks before adding new ones!**

One fixed mock (80x speedup) >> Ten new mocks (30% speedup each)

---

## How to Use the Updated Prompt

### New Workflow

1. **Step 1**: Analyze slow tests (as before)
2. **Step 2**: **NEW!** Check for mock misuse first
   - Look for existing mocks
   - Check if test duration matches constants
   - Search for default parameter issues
3. **Step 3**: Evaluate mockability (as before)
4. **Step 4**: Implement fixes or new mocks
5. **Step 5**: Validate results

### Priority Order

1. 🥇 **First**: Fix broken mocks (10x-100x potential)
2. 🥈 **Second**: Add new mocks for external dependencies (30-50% potential)
3. 🥉 **Third**: Configuration tuning for integration tests (20-40% potential)

---

## Files Updated

1. **`prompt_template_mock_speedup.md`** - Main prompt template
   - Added Step 2: Check for Mock Misuse
   - Added detection patterns and fixes
   - Updated deliverables templates
   - Added special section on mock misuse

2. **`versions/ert_11206/MOCK_MISUSE_ANALYSIS.md`** - Detailed case study
   - Explains the problem in depth
   - Shows before/after code
   - Provides detection strategy
   - Lists common patterns

3. **`versions/ert_11206/FINAL_SUMMARY.md`** - Already existed
   - Documents that no mocking was applied
   - Explains why tests weren't suitable for mocking
   - Provides alternative recommendations

---

## Testing the Updated Prompt

To validate the updated prompt works, test it on projects where:

1. **Mock misuse exists** (like ERT PR #11206)
   - Should detect broken mock
   - Should identify default parameter issue
   - Should fix source code
   - Should achieve 10x-100x speedup

2. **External dependencies exist**
   - Should identify mockable dependencies
   - Should add appropriate mocks
   - Should achieve 30-50% speedup

3. **Integration tests only**
   - Should recognize no mocking appropriate
   - Should suggest configuration tuning
   - Should preserve test effectiveness

---

## Summary

**What changed**: Added comprehensive mock misuse detection and fixing strategy to the prompt template

**Why it matters**: One fixed mock can provide more speedup than adding many new mocks

**Key insight**: Default parameter evaluation timing is a common Python gotcha that breaks mocks

**Impact**: The updated prompt now handles 3 scenarios instead of 2:
1. ✅ Mock misuse (NEW!)
2. ✅ External dependencies (existing)
3. ✅ Integration tests (existing)

**Bottom line**: Always investigate **why existing mocks might be broken** before trying to add new ones. The biggest optimization opportunities are often hiding in plain sight! 🚀
