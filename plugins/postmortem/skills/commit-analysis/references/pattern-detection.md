# Pattern Detection Reference

Comprehensive library of problem patterns detectable from commit diffs and how to identify them.

## Pattern Categories

### 1. Memory Safety Issues

#### Null Pointer / Undefined Access
**Symptoms in diff**:
```diff
- obj.property
+ obj?.property ?? defaultValue

- array[index]
+ array?.[index]

- func(obj.data)
+ if (obj && obj.data) func(obj.data)
```

**Detection logic**:
- Added `?.` optional chaining
- Added `??` nullish coalescing
- Added `if (x != null)` or `if (x)` checks before access
- Added default values

**Root cause keywords**: null, undefined, None, nil, nullable

---

#### Buffer Overflow / Array Out of Bounds
**Symptoms in diff**:
```diff
- return array[index]
+ if (index >= 0 && index < array.length) return array[index]

- memcpy(dest, src, size)
+ if (size <= dest_capacity) memcpy(dest, src, size)
```

**Detection logic**:
- Added bounds checking (`index < length`)
- Added size validation before operations
- Changed array access to checked versions

**Root cause keywords**: overflow, bounds, index, out of range

---

#### Memory Leak
**Symptoms in diff**:
```diff
  resource = allocate()
  use(resource)
+ free(resource)

  file = open(path)
  read(file)
+ file.close()
```

**Detection logic**:
- Added `free()`, `close()`, `dispose()`, `cleanup()`
- Added `with` statements or RAII patterns
- Added destructors or finalizers

**Root cause keywords**: leak, memory, resource, cleanup, close

---

### 2. Concurrency Issues

#### Race Condition
**Symptoms in diff**:
```diff
+ lock.acquire()
  shared_state.update()
+ lock.release()

- value = counter++
+ value = atomic_increment(counter)

- if check: modify()
+ with lock: if check: modify()
```

**Detection logic**:
- Added locks, mutexes, or semaphores
- Changed to atomic operations
- Added synchronization primitives
- Wrapped check-then-act in critical section

**Root cause keywords**: race, concurrent, thread, atomic, lock, mutex

---

#### Deadlock
**Symptoms in diff**:
```diff
- lock_a.acquire(); lock_b.acquire()
+ lock_a.acquire(); lock_b.acquire()  # Always in same order now

+ timeout added to lock acquisition
```

**Detection logic**:
- Reordered lock acquisition
- Added timeout or try_lock
- Removed nested locking

**Root cause keywords**: deadlock, livelock, hang, stuck

---

### 3. Logic Errors

#### Off-by-One Error
**Symptoms in diff**:
```diff
- for i in range(n):
+ for i in range(n + 1):

- if (x > threshold):
+ if (x >= threshold):

- array[len - 1]
+ array[len]
```

**Detection logic**:
- Changed `<` to `<=` or vice versa
- Changed `+1` to `+0` in array indexing
- Changed loop range boundaries
- Changed string slicing ranges

**Root cause keywords**: off-by-one, boundary, edge case, fencepost

---

#### Wrong Operator or Condition
**Symptoms in diff**:
```diff
- if (a && b):
+ if (a || b):

- result = a + b
+ result = a * b

- while (count > 0):
+ while (count != 0):
```

**Detection logic**:
- Changed logical operators (`&&` ↔ `||`)
- Changed arithmetic operators
- Changed comparison operators
- Negated conditions (`!`)

**Root cause keywords**: logic error, wrong operator, incorrect condition

---

#### Missing Case / Incomplete Condition
**Symptoms in diff**:
```diff
  if (type == A): handle_a()
  elif (type == B): handle_b()
+ elif (type == C): handle_c()
+ else: handle_default()
```

**Detection logic**:
- Added new case to if-elif chain
- Added else clause
- Added switch case
- Added enum variant handling

**Root cause keywords**: missing case, incomplete, unhandled

---

### 4. Input Validation Issues

#### Missing Validation
**Symptoms in diff**:
```diff
+ if not validate_email(email):
+     raise ValueError("Invalid email")

+ if len(password) < 8:
+     return error("Password too short")

+ if file_size > MAX_SIZE:
+     return error("File too large")
```

**Detection logic**:
- Added validation function calls
- Added format/length/range checks
- Added type checking
- Added sanitization

**Root cause keywords**: validation, invalid, malformed, bad input

---

#### Injection Vulnerabilities
**Symptoms in diff** (example of UNSAFE code being fixed):
```diff
- # UNSAFE: String interpolation with user input
- query = f"SELECT * FROM users WHERE name = '{name}'"
+ # SAFE: Parameterized query
+ query = "SELECT * FROM users WHERE name = ?"
+ cursor.execute(query, (name,))

- # UNSAFE: Direct command execution
- result = subprocess.call(f"ls {user_path}", shell=True)
+ # SAFE: Command with argument list
+ result = subprocess.run(["ls", user_path], check=True)
```

**Detection logic**:
- Changed string interpolation to parameterized queries
- Changed shell execution to argument lists
- Added input escaping or sanitization

**Root cause keywords**: injection, SQL, command, escape, sanitize

**Note**: The "UNSAFE" examples above show vulnerable code that should be fixed, not code to use.

---

### 5. Error Handling Issues

#### Unhandled Exception
**Symptoms in diff**:
```diff
+ try:
      risky_operation()
+ except SpecificError as e:
+     handle_error(e)

  result = may_fail()
+ if result.is_error():
+     return error_response()
```

**Detection logic**:
- Added try-catch blocks
- Added error checking after operations
- Added error return handling
- Changed from panic to graceful error

**Root cause keywords**: exception, error, unhandled, crash

---

#### Swallowed Exception
**Symptoms in diff**:
```diff
  try:
      operation()
  except:
-     pass
+     log.error("Operation failed")
+     raise
```

**Detection logic**:
- Changed empty exception handler to logging + re-raise
- Added specific exception handling
- Added error reporting

**Root cause keywords**: silent failure, swallowed, ignored error

---

### 6. API Misuse

#### Incorrect Parameter Order
**Symptoms in diff**:
```diff
- api.call(timeout, data, callback)
+ api.call(data, callback, timeout)
```

**Detection logic**:
- Changed order of function arguments
- Usually involves callbacks, options, or flags

**Root cause keywords**: parameter order, argument, API misuse

---

#### Incorrect API Usage
**Symptoms in diff**:
```diff
- file.read()  # Doesn't return data
+ data = file.read()  # Returns data

- async_func()  # Doesn't wait
+ await async_func()  # Waits for completion
```

**Detection logic**:
- Added `await` for async functions
- Added return value usage
- Changed synchronous to async call
- Added required configuration

**Root cause keywords**: API misuse, incorrect usage, async, await

---

### 7. State Management Issues

#### Uninitialized Variable
**Symptoms in diff**:
```diff
+ result = None  # Initialize before use
  if condition:
      result = compute()
  return result
```

**Detection logic**:
- Added initialization before conditional assignment
- Added default value

**Root cause keywords**: uninitialized, not defined, undefined

---

#### State Inconsistency
**Symptoms in diff**:
```diff
  update_a()
+ update_b()  # Keep state consistent

+ if a_changed: update_related_state()
```

**Detection logic**:
- Added synchronization between related state
- Added consistency checks
- Added state validation

**Root cause keywords**: inconsistent, out of sync, state mismatch

---

### 8. Resource Management

#### Resource Leak
**Symptoms in diff**:
```diff
  resource = acquire()
  use(resource)
+ finally:
+     release(resource)

- file = open(path)
+ with open(path) as file:
```

**Detection logic**:
- Added `finally` blocks
- Changed to `with` statement (context manager)
- Added explicit cleanup

**Root cause keywords**: leak, resource, cleanup, close

---

### 9. Type Issues

#### Type Mismatch
**Symptoms in diff**:
```diff
- result = int_value + string_value
+ result = int_value + int(string_value)

- func(string_arg)  # Function expects number
+ func(float(string_arg))
```

**Detection logic**:
- Added type conversions
- Added type checking before operations
- Changed type annotations

**Root cause keywords**: type error, type mismatch, conversion

---

### 10. Configuration Issues

#### Missing Configuration
**Symptoms in diff**:
```diff
+ config.set_timeout(30)  # Was using default
+ config.enable_retry(true)
```

**Detection logic**:
- Added configuration calls
- Added environment variable reads
- Added default value overrides

**Root cause keywords**: configuration, config, setting, default

---

## Pattern Matching Algorithm

### Step 1: Identify Changed Lines
Extract added lines (+ lines) from diff:
```python
added_lines = [line for line in diff if line.startswith('+')]
```

### Step 2: Classify Changes
For each added line, check for pattern indicators:

```python
patterns = []

if "if" in line and ("!=" in line or "is not None" in line):
    patterns.append("null_check_added")

if "try:" in line:
    patterns.append("exception_handling_added")

if "lock" in line or "mutex" in line:
    patterns.append("synchronization_added")

# ... more pattern checks
```

### Step 3: Analyze Context
Look at surrounding lines to confirm pattern:

```python
if "null_check_added" in patterns:
    # Look for what's being protected
    next_lines = get_next_lines(line_num, 3)
    if any("." in nl or "[" in nl for nl in next_lines):
        confirm_pattern("null_pointer_fix")
```

### Step 4: Extract Root Cause
Based on detected patterns:

```python
root_cause_map = {
    "null_check_added": "Missing null/undefined validation",
    "bounds_check_added": "Missing array bounds checking",
    "lock_added": "Race condition or concurrent access issue",
    "try_catch_added": "Unhandled exception",
    # ...
}
```

## Similarity Scoring

### File-Based Similarity
```python
def file_similarity(file1, file2):
    if file1 == file2:
        return 1.0  # Exact match
    elif os.path.dirname(file1) == os.path.dirname(file2):
        return 0.7  # Same directory
    elif file1.split('/')[0:2] == file2.split('/')[0:2]:
        return 0.4  # Same module
    else:
        return 0.1  # Different area
```

### Pattern-Based Similarity
```python
def pattern_similarity(postmortem_patterns, change_patterns):
    common = set(postmortem_patterns) & set(change_patterns)
    union = set(postmortem_patterns) | set(change_patterns)

    if not union:
        return 0.0

    return len(common) / len(union)  # Jaccard similarity
```

### Keyword-Based Similarity
```python
def keyword_similarity(postmortem_keywords, change_text):
    change_keywords = extract_keywords(change_text)
    common = set(postmortem_keywords) & set(change_keywords)

    if not postmortem_keywords:
        return 0.0

    return len(common) / len(postmortem_keywords)
```

### Combined Risk Score
```python
def calculate_risk_score(postmortem, new_change):
    file_sim = file_similarity(
        postmortem.files,
        new_change.files
    )

    pattern_sim = pattern_similarity(
        postmortem.patterns,
        detect_patterns(new_change.diff)
    )

    keyword_sim = keyword_similarity(
        postmortem.keywords,
        new_change.diff + new_change.message
    )

    # Weighted combination
    score = (
        file_sim * 0.4 +
        pattern_sim * 0.3 +
        keyword_sim * 0.3
    )

    return score
```

## Advanced Techniques

### AST-Based Pattern Detection

For deeper analysis, parse code into AST:

```python
import ast

def detect_ast_patterns(code):
    tree = ast.parse(code)
    patterns = []

    for node in ast.walk(tree):
        # Detect null checks
        if isinstance(node, ast.If):
            if isinstance(node.test, ast.Compare):
                if any(isinstance(op, ast.IsNot) for op in node.test.ops):
                    patterns.append("null_check")

        # Detect try-except
        if isinstance(node, ast.Try):
            patterns.append("exception_handling")

        # Detect loops with bounds
        if isinstance(node, ast.For):
            patterns.append("iteration")

    return patterns
```

### Semantic Analysis

Understand what the code does, not just patterns:

```python
def semantic_analysis(diff):
    analysis = {
        "adds_validation": False,
        "fixes_logic": False,
        "improves_error_handling": False,
        "adds_synchronization": False
    }

    # Check if validation added
    if "validate" in diff or "check" in diff:
        if "if" in diff and ("raise" in diff or "return" in diff):
            analysis["adds_validation"] = True

    # Check if logic fixed
    if any(op in diff for op in ["<=", ">=", "!=", "=="]):
        analysis["fixes_logic"] = True

    # ... more semantic checks

    return analysis
```

## Machine Learning Approach (Future)

For even more accurate pattern detection:

### Feature Extraction
```python
features = [
    file_path_tokens,
    diff_added_lines_count,
    diff_removed_lines_count,
    keywords_in_message,
    patterns_detected,
    complexity_metrics,
    # ...
]
```

### Training
Train classifier on labeled commits (fix vs. not fix, pattern type).

### Prediction
```python
is_fix, pattern_type = model.predict(features)
```

---

This reference provides a comprehensive library for detecting problem patterns from git commits. Use these patterns to build postmortem knowledge bases and detect similar issues in new code changes.
