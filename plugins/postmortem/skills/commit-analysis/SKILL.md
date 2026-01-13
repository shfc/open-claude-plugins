---
name: Commit Analysis
description: This skill should be used when the user asks to "analyze commits", "identify fix patterns", "detect code issues from commits", "git commit analysis", "parse commit history", or needs guidance on analyzing git commits to extract problem patterns and generate postmortem insights.
version: 0.1.0
---

# Commit Analysis for Problem Pattern Detection

This skill provides techniques for analyzing git commits to identify bug fix patterns, extract root causes, and detect similar issues in code changes.

## Purpose

Commit analysis transforms raw git history into actionable insights by:

- Identifying which commits represent bug fixes vs. features
- Extracting problem patterns from fix commits
- Understanding root causes from code changes
- Detecting similar patterns in new code changes
- Building knowledge bases from historical fixes

## Commit Identification Strategy

### Two-Stage Filtering

Use a two-stage approach to identify fix-related commits:

**Stage 1: Shell-based filtering**
- Fast, deterministic filtering using commit message patterns
- Excludes obvious non-fix commits (feat, docs, chore, style, refactor, test, build, ci, perf)
- Includes commits with fix-related keywords if configured

**Stage 2: AI analysis**
- Analyze commit messages and diffs to confirm actual fixes
- Distinguish between bug fixes, workarounds, and refactorings
- Identify root cause from changes made

### Conventional Commit Pattern Recognition

Parse conventional commit format: `type(scope): subject`

**Common fix types**:
- `fix:` - Bug fixes
- `bugfix:` - Explicit bug fixes
- `hotfix:` - Urgent production fixes
- `patch:` - Small fixes
- `revert:` - Reverting broken changes
- `security:` - Security fixes

**Exclude types** (not fixes):
- `feat:` - New features
- `docs:` - Documentation
- `chore:` - Maintenance tasks
- `style:` - Formatting, no logic change
- `refactor:` - Code restructuring, no behavior change
- `test:` - Test additions
- `build:` - Build system changes
- `ci:` - CI/CD configuration
- `perf:` - Performance improvements (not fixes)

### Keyword-Based Detection

When commit messages don't follow conventional format, look for keywords:

**Strong fix indicators**:
- fix, fixes, fixed, fixing
- bug, bugfix
- issue, resolve, resolves, resolved
- hotfix, patch
- crash, error, failure
- broken, break

**Context-dependent indicators**:
- handle, prevent (may indicate defensive coding, not necessarily fixing existing bug)
- improve, update (could be enhancement or fix)
- correct, adjust (likely fixes)

**AI analysis needed**: When keywords are ambiguous, examine the diff to determine if it's fixing existing broken behavior or adding new functionality.

## Commit Diff Analysis

### Structure of Analysis

For each commit identified as potential fix, analyze:

1. **Files changed**: Which modules/components affected
2. **Code patterns**: What types of changes made
3. **Logic changes**: What behavior was modified
4. **Test changes**: What test coverage was added

### Identifying Root Cause from Diff

#### Added Validation or Bounds Checking

**Pattern**: New `if` statements, assertions, or checks added

```diff
+ if (index < 0 || index >= array.length) {
+     throw new Error("Index out of bounds");
+ }
  return array[index];
```

**Root cause**: Missing input validation or boundary check

#### Fixed Null/Undefined Handling

**Pattern**: Added null checks, optional chaining, or default values

```diff
- const name = user.profile.name;
+ const name = user?.profile?.name ?? "Unknown";
```

**Root cause**: Null pointer/undefined access

#### Corrected Logic or Algorithm

**Pattern**: Changed comparison operators, loop conditions, or calculations

```diff
- if (count > threshold) {
+ if (count >= threshold) {
```

**Root cause**: Logic error, off-by-one error

#### Added Synchronization or Locking

**Pattern**: Added mutexes, locks, or atomic operations

```diff
+ mutex.lock();
  shared_resource.update();
+ mutex.unlock();
```

**Root cause**: Race condition or concurrency issue

#### Fixed Error Handling

**Pattern**: Added try-catch, error checking, or improved error propagation

```diff
  try {
      perform_operation();
+ } catch (SpecificError e) {
+     handle_error(e);
+     throw new UserFriendlyError("Operation failed");
  }
```

**Root cause**: Missing or inadequate error handling

#### Corrected API Usage

**Pattern**: Changed function calls, parameter order, or API contracts

```diff
- api.call(data, callback, options);
+ api.call(data, options, callback);
```

**Root cause**: API misuse or misunderstanding

#### Fixed Resource Management

**Pattern**: Added resource cleanup, close operations, or lifecycle management

```diff
  const file = open(path);
  process(file);
+ file.close();
```

**Root cause**: Resource leak

## Pattern Detection

### Common Problem Patterns

Identify recurring patterns across fix commits:

#### 1. Input Validation Issues
**Symptoms**:
- Added bounds checking
- Added type validation
- Added format verification

**Pattern signature**:
```python
# Check for additions like:
if not validate_input(x):
    raise ValueError()
```

#### 2. Null/None Safety Issues
**Symptoms**:
- Added null checks
- Added default values
- Changed to safe navigation

**Pattern signature**:
```python
# Check for changes like:
obj?.property  # Optional chaining
value ?? default  # Nullish coalescing
```

#### 3. Race Conditions
**Symptoms**:
- Added locks or mutexes
- Changed to atomic operations
- Added synchronization

**Pattern signature**:
```python
# Check for additions like:
with lock:
    shared_state.update()
```

#### 4. Off-by-One Errors
**Symptoms**:
- Changed `<` to `<=` or vice versa
- Changed `+1` to `+0` or vice versa
- Changed loop bounds

**Pattern signature**:
```diff
- for i in range(len(array)):
+ for i in range(len(array) - 1):
```

#### 5. Error Handling Gaps
**Symptoms**:
- Added try-catch blocks
- Added error checking after operations
- Improved error messages

**Pattern signature**:
```python
# Check for additions like:
try:
    operation()
except Exception as e:
    handle_error(e)
```

## Merge Commit Analysis

Merge commits require special handling to identify conflict resolutions.

### Detecting Merge-Related Fixes

**Indicators of conflict resolution issues**:
- Merge commit contains logic changes (not just combining changes)
- Subsequent fix commit shortly after merge
- Fix affects files that were merged

### Analyzing Merge Conflicts

Use git tools to examine merge conflict resolution:

```bash
# Show what was changed in merge compared to parents
git show <merge-commit> --cc

# See which files had conflicts
git show <merge-commit> --name-only
```

**Look for**:
- Logic that combines both parents incorrectly
- Missing code from one parent
- Incorrect conflict resolution choices
- Broken integrations between merged features

## Similarity Detection

### Comparing Code Changes

To detect if new changes match known problem patterns:

#### File Path Similarity
- **Exact match**: Same file modified = High risk
- **Same directory**: Related files = Medium risk
- **Same module**: Same component = Low-medium risk
- **Different area**: Unrelated = Low risk

#### Code Structure Similarity
Analyze AST (Abstract Syntax Tree) or code patterns:
- Same function names or signatures
- Similar variable names
- Similar control flow structures
- Same API usage patterns

#### Keyword Similarity
Extract keywords from postmortem and compare with new changes:
- Technical terms (array, index, token, validation)
- Operation verbs (check, validate, parse, handle)
- Problem indicators (null, race, leak, overflow)

### Risk Scoring

Combine similarity metrics:

```python
risk_score = (
    file_similarity * 0.4 +
    pattern_similarity * 0.3 +
    keyword_similarity * 0.3
)

if risk_score > 0.8:
    risk_level = "critical"
elif risk_score > 0.6:
    risk_level = "high"
elif risk_score > 0.4:
    risk_level = "medium"
else:
    risk_level = "low"
```

## Batch Analysis Strategy

For analyzing many commits (during initialization):

### Batch Size
- Process 10-20 commits per batch
- Prevents context overflow
- Allows for comprehensive analysis of each commit

### Batch Processing Steps

1. **Extract commit metadata**: Use `commit-filter.sh` to get candidate commits
2. **Batch commits**: Group into batches of 10-20
3. **Analyze each batch**:
   - For each commit: Get diff, message, files changed
   - Determine if it's a fix (AI analysis)
   - If fix: Extract problem pattern, root cause
   - Generate postmortem draft
4. **Save results**: Write postmortem documents
5. **Update index**: Maintain searchable index

### Incremental Updates

For ongoing updates:
- Track last analyzed commit hash in index
- Only analyze commits since last update
- Merge or update existing postmortems if new information found

## Git Helper Utilities

Use provided scripts for common operations:

### Get Commit Info
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/git-helpers.sh get_commit_info <commit-hash>
```

Returns JSON with commit metadata.

### Get Commit Diff
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/git-helpers.sh get_commit_diff <commit-hash> --full
```

Options: `--stat`, `--name-only`, `--full`

### Filter Commits
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/commit-filter.sh \
  --include-keywords "fix,bug,hotfix" \
  --since 6.months.ago \
  --format json
```

Returns filtered commit list.

## Analysis Workflow

### For Postmortem Generation

1. **Identify commit**: Get commit hash from user or filter output
2. **Gather information**:
   ```bash
   info=$(git-helpers.sh get_commit_info $commit)
   diff=$(git-helpers.sh get_commit_diff $commit --full)
   ```
3. **Analyze diff**: Identify pattern from changes (see "Identifying Root Cause from Diff")
4. **Determine severity**: Based on impact and scope
5. **Extract tags**: From commit message, files, and patterns
6. **Generate postmortem**: Use template and fill sections
7. **Validate**: Ensure all sections complete and actionable

### For Risk Analysis

1. **Get current changes**:
   ```bash
   git diff  # For uncommitted changes
   git show <commit>  # For specific commit
   ```
2. **Load postmortem index**: Read all existing postmortems
3. **Calculate similarity**:
   - File path matching
   - Code pattern matching
   - Keyword matching
4. **Score risk**: Combine similarity metrics
5. **Report findings**: List matching postmortems with risk levels

## Common Analysis Mistakes

### Mistake 1: Confusing Refactoring with Fixes
Not every code change is a fix. Refactoring improves structure without changing behavior.

**Fix indicators**:
- Adds validation that was missing
- Changes logic that was incorrect
- Handles errors that were unhandled

**Refactoring indicators**:
- Renames for clarity
- Extracts functions
- Improves structure without logic changes

### Mistake 2: Missing Root Cause
Don't stop at surface symptom.

**Surface**: "Added null check"
**Root cause**: "Function assumed input was always non-null because it was only called from one location, but new caller can pass null"

### Mistake 3: Overmatching
Not every change to authentication code is the same issue.

**Be specific**: Match specific patterns, not just file paths.

### Mistake 4: Ignoring Test Changes
Test additions reveal what edge cases were missed.

**Analyze tests**: They document the bug better than the fix sometimes.

## Additional Resources

### Reference Files

For detailed pattern detection techniques:
- **`references/pattern-detection.md`** - Comprehensive pattern library
- **`references/diff-analysis.md`** - Advanced diff analysis techniques

### Scripts

Utility scripts for commit analysis:
- **`${CLAUDE_PLUGIN_ROOT}/scripts/commit-filter.sh`** - Universal commit filtering
- **`${CLAUDE_PLUGIN_ROOT}/scripts/git-helpers.sh`** - Git operation utilities

## Key Principles

1. **Two-stage filtering**: Shell first (fast), then AI (accurate)
2. **Root cause focus**: Go beyond surface changes to understand why
3. **Pattern recognition**: Look for recurring structures across fixes
4. **Similarity metrics**: Combine multiple signals for risk detection
5. **Batch processing**: Handle large histories efficiently
6. **Incremental updates**: Only analyze new commits

Apply these techniques to transform git history into actionable knowledge for preventing code regression.
