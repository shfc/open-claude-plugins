---
name: Postmortem Writing
description: This skill should be used when the user asks to "write postmortem", "create postmortem document", "document code issue", "postmortem best practices", "postmortem format", or needs guidance on structuring and writing effective postmortem documentation for code fixes.
version: 0.1.0
---

# Postmortem Writing for Code Issues

This skill provides guidance for writing effective postmortem documents that learn from code fixes and prevent future regressions.

## Purpose

Postmortem documents serve as a knowledge base for preventing code regression in AI-assisted development. Each postmortem analyzes a bug fix to extract:

- What went wrong and why
- How it was fixed
- What patterns to watch for
- How to prevent similar issues systematically

**Blameless principle**: Focus on learning and prevention, not blame. Never include author attribution.

## Document Structure

Postmortem documents follow a standard structure with YAML frontmatter and markdown sections.

### YAML Frontmatter

Required metadata fields:

```yaml
---
commit: abc123def456           # Full commit hash
date: 2026-01-13              # Commit date (YYYY-MM-DD)
severity: medium              # low, medium, high, critical
tags: [authentication, race-condition]  # Descriptive tags
files_changed: 5              # Number of files modified
related_commits: []           # Related fix commits (hashes)
---
```

**Severity levels**:
- **critical**: System crash, data loss, security breach
- **high**: Core functionality broken, widespread impact
- **medium**: Feature broken, workaround available
- **low**: Minor issue, edge case, cosmetic problem

**Tags**: Use descriptive, searchable tags for categorization:
- Component/module names: `authentication`, `database`, `api`
- Problem types: `race-condition`, `null-pointer`, `memory-leak`
- Technologies: `postgres`, `redis`, `react`
- Patterns: `boundary-check`, `input-validation`, `error-handling`

### Markdown Sections

Each postmortem includes these sections in order:

#### 1. Title

Format: `# Postmortem: [Brief Description]`

Use imperative form and be specific:
- Good: `Fix null pointer in user authentication flow`
- Good: `Resolve race condition in cache invalidation`
- Avoid: `Bug fix`
- Avoid: `Update code`

#### 2. Problem Summary

Describe the observable symptom and broken functionality.

**What to include**:
- What was the user-visible problem?
- What functionality was broken or degraded?
- Under what conditions did it occur?

**Keep it concise**: 2-3 sentences maximum.

**Example**:
```markdown
## Problem Summary

Users were unable to log in after password reset. The authentication
service returned a 500 error when validating reset tokens. This affected
all users who attempted password reset between 2026-01-10 and 2026-01-12.
```

#### 3. Root Cause Analysis

Explain WHY the problem occurred, not just what was wrong.

**Structure**:
```markdown
## Root Cause Analysis

**Root cause category**: [Logic Error | Missing Validation | Race Condition |
Architecture Flaw | Dependency Issue | Configuration Error | Other]

**Why it happened**:
- [Primary reason - dig deep, not surface]
- [Contributing factors]
- [Missed edge cases or incorrect assumptions]
```

**Go beyond surface symptoms**: Identify the underlying cause, not just the immediate trigger.

**Good analysis**:
```markdown
**Root cause category**: Logic Error

**Why it happened**:
- Token validation logic assumed tokens were always 32 characters
- Password reset flow generates 64-character tokens
- No length validation on token input
- Original implementation only supported session tokens (32 chars)
```

**Poor analysis**:
```markdown
**Why it happened**:
- The code had a bug
- Token check failed
```

#### 4. Code Changes

Describe what was modified to fix the issue.

**Structure**:
```markdown
## Code Changes

**Modified files**:
[List files with change summary]

**Key logic changes**:
- [Describe algorithmic or logical changes]
- [What was added, removed, or refactored]

**API/Interface changes**:
- [Function signature changes]
- [Data structure modifications]
- [Impact on callers or dependencies]
```

**Be specific**: Mention actual file names, function names, and logic changes.

**Example**:
```markdown
## Code Changes

**Modified files**:
- `src/auth/token_validator.py`: Updated validation logic
- `tests/auth/test_token_validation.py`: Added test cases

**Key logic changes**:
- Removed hardcoded 32-character length check
- Added flexible token length validation (16-128 chars)
- Improved error messages to distinguish token types

**API/Interface changes**:
- `validate_token()` now accepts optional `token_type` parameter
- Return value includes token type for better error handling
```

#### 5. Risk Pattern

Identify patterns to watch for in future changes.

**Structure**:
```markdown
## Risk Pattern

**File/module risk**:
- Files: [Specific files prone to similar issues]
- Modules: [Components or services]

**Code pattern risk**:
- [Vulnerable code structures or patterns]
- [Common mistakes in this area]

**Common mistake**:
- [What assumption led to this bug]
- [What developers might miss]
```

**Make it actionable**: Describe patterns that can be detected in code changes.

**Example**:
```markdown
## Risk Pattern

**File/module risk**:
- Files: `src/auth/*.py`, especially token handling
- Modules: Authentication service, session management

**Code pattern risk**:
- Fixed-length string assumptions without validation
- Token handling without type checking
- String operations assuming specific formats

**Common mistake**:
- Assuming all tokens have the same format
- Not validating token length before operations
- Forgetting that token formats evolve over time
```

#### 6. Prevention Strategy

Focus on automation and systematic prevention.

**Critical**: This section should emphasize **automation without human intervention**, not manual processes.

**Structure**:
```markdown
## Prevention Strategy

### Automated Testing
- [ ] [Specific test case with input/expected behavior]
- [ ] [Integration test scenario]
- [ ] [Recommend test framework]

### AI Coding Context
- **When to load**: [Specific trigger for loading this postmortem]
- **What to load**:
  - [ ] [This postmortem document]
  - [ ] [Related postmortems]
  - [ ] [Architecture docs]
- **Context strategy**: [What AI should pay attention to]

### Automation Hooks
- **Pre-commit checks**: [Linter rules, static analysis]
- **CI/CD checks**: [Build-time validation]
- **Claude Code hooks** (future): [PreToolUse/PostToolUse recommendations]

### Code Review Checklist
- [ ] [Specific review item]
- [ ] [Second item]
```

**Automated Testing**:
- Describe specific test cases to add
- Include edge cases and boundary conditions
- Recommend test types (unit, integration, property-based)

**AI Coding Context**:
- Specify WHEN to load context (what triggers it)
- List WHAT context to load (files, docs, postmortems)
- Explain HOW AI should use the context

**Example**:
```markdown
### Automated Testing
- [ ] Test tokens of various lengths: 16, 32, 64, 128 characters
- [ ] Test invalid token formats (empty, too short, too long)
- [ ] Test mixed token types in same session
- [ ] Property-based testing: generate random valid tokens

### AI Coding Context
- **When to load**: When modifying `src/auth/*.py` or token-related code
- **What to load**:
  - [ ] This postmortem (token length assumptions)
  - [ ] `docs/auth/token-formats.md` (token specifications)
  - [ ] Related postmortem: `2026-01-05-xyz789-session-token-expiry.md`
- **Context strategy**: Verify no fixed-length assumptions in new code. Check all string operations for token length validation.

### Automation Hooks
- **Pre-commit checks**:
  - [ ] Linter rule: Flag hardcoded length checks on token strings
  - [ ] Static analysis: Detect string operations without length validation
- **CI/CD checks**:
  - [ ] Run token validation test suite on all auth changes
  - [ ] Property-based tests must pass
```

#### 7. Related Issues

Connect to related problems and areas.

**Structure**:
```markdown
## Related Issues

**Similar commits**:
- [Commit hash]: [Brief description]

**Potential problem areas**:
- [Files or modules that might have same pattern]

**Follow-up work**:
- [ ] [Additional hardening needed]
- [ ] [Documentation updates]
```

#### 8. Technical Context

Provide technical background for understanding the issue.

**Structure**:
```markdown
## Technical Context

**Affected components**:
- [Service/module/layer affected]

**Dependencies**:
- [External libraries, services, systems]

**Testing challenges**:
- [Why this was hard to catch]
- [How testing was improved]

**Additional notes**:
- [Other relevant context]
```

## Writing Guidelines

### Use Clear, Technical Language

Write for developers who will read this months or years later.

**Good**:
```markdown
The authentication service validated tokens using a fixed-length
comparison, assuming all tokens were 32 characters. When password
reset tokens (64 characters) were introduced, the validation logic
failed silently.
```

**Bad**:
```markdown
There was a problem with the token thing. The code didn't work right
for some tokens.
```

### Focus on "Why", Not Just "What"

Explain reasoning and assumptions, not just symptoms.

**Good**:
```markdown
The original implementation assumed all tokens came from the session
service, which always generates 32-character tokens. The password reset
service was added later and generates longer tokens for security, but
the validation logic was never updated.
```

**Bad**:
```markdown
The token was the wrong length and failed validation.
```

### Be Specific About Prevention

Provide actionable, automatable prevention strategies.

**Good**:
```markdown
### Automated Testing
- [ ] Add property-based test: generate tokens of length 16-128, verify all validate correctly
- [ ] Add integration test: complete password reset flow with token validation
- [ ] Test framework: Use hypothesis for property-based testing
```

**Bad**:
```markdown
### Prevention
- Write tests
- Be careful with tokens
- Review code carefully
```

### Use Imperative Form

Write instructions, not descriptions.

**Good**: "Add test cases for token length validation"
**Bad**: "We should add test cases" or "You should add test cases"

## Severity Assessment

Assign severity based on impact and scope.

### Critical
- System crash or unavailability
- Data loss or corruption
- Security breach or vulnerability
- Complete feature failure affecting all users

**Example**: Database connection leak causing service crash

### High
- Core functionality broken for many users
- Data inconsistency (but not loss)
- Performance degradation (>10x slower)
- Authentication or authorization failure

**Example**: Users unable to log in after password reset

### Medium
- Feature broken for some users
- Workaround available
- Minor data inconsistency
- Performance degradation (2-10x slower)

**Example**: Export function fails for files >10MB

### Low
- Edge case or rare condition
- Minor UI issue
- Cosmetic problem
- Only affects specific configurations

**Example**: Button alignment off by 2px on mobile

## Tag Selection

Use consistent, searchable tags.

### Component Tags
Technical components affected: `authentication`, `database`, `api`, `frontend`, `cache`

### Problem Type Tags
Nature of the issue: `race-condition`, `null-pointer`, `memory-leak`, `deadlock`, `off-by-one`

### Technology Tags
Specific technologies: `postgres`, `redis`, `react`, `python`, `docker`

### Pattern Tags
Code patterns: `boundary-check`, `input-validation`, `error-handling`, `concurrency`, `resource-management`

**Example tag set**:
```yaml
tags: [authentication, password-reset, input-validation, string-handling]
```

## Common Mistakes to Avoid

### Mistake 1: Blame or Attribution
❌ Don't identify who wrote the buggy code
❌ Don't criticize individuals or decisions
✅ Focus on what happened and how to prevent it

### Mistake 2: Surface-Level Analysis
❌ "The bug was in line 42"
❌ "The code was wrong"
✅ Explain why the code was written that way
✅ Identify assumptions that proved incorrect

### Mistake 3: Vague Prevention
❌ "Write better tests"
❌ "Be more careful"
✅ Specific test cases to add
✅ Concrete automation strategies

### Mistake 4: Manual Prevention Focus
❌ "Developers should remember to check token length"
❌ "Reviewers should watch for this pattern"
✅ Linter rules to catch the pattern
✅ Tests that fail if pattern recurs

## Additional Resources

### Reference Files

For detailed best practices and advanced techniques:
- **`references/best-practices.md`** - Comprehensive postmortem writing guide
- **`references/severity-guide.md`** - Detailed severity classification

### Example Files

Complete postmortem examples:
- **`examples/sample-postmortem.md`** - Full annotated example
- **`examples/good-vs-bad.md`** - Good and bad examples compared

## Template Usage

Generate initial postmortem template using:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/postmortem-template.sh <commit-hash> output.md
```

This creates a structured template with commit metadata populated. Fill in the analysis and prevention sections.

## Key Principles

1. **Blameless**: Focus on learning, not blame
2. **Root cause**: Go beyond symptoms to understand why
3. **Actionable**: Prevention strategies must be specific and automatable
4. **Searchable**: Use clear tags and structure for future discovery
5. **Complete**: Include all context needed to understand the issue
6. **English**: Write all content in English for consistency

Follow these guidelines to create postmortem documents that effectively prevent regression and build a valuable knowledge base for AI-assisted development.
