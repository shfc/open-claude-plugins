#!/bin/bash
#
# postmortem-template.sh - Generate postmortem document template
#
# Usage:
#   postmortem-template.sh <commit-hash> [output-file]
#
# Arguments:
#   commit-hash    Git commit hash to generate template for
#   output-file    Optional output file path (default: stdout)
#
# Description:
#   Generates a postmortem document template with:
#   - YAML frontmatter with commit metadata
#   - Standard section structure
#   - Placeholder content
#
# Examples:
#   # Generate template to stdout
#   postmortem-template.sh abc123def456
#
#   # Generate template to file
#   postmortem-template.sh abc123def456 postmortem.md
#

set -euo pipefail

# Check arguments
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <commit-hash> [output-file]" >&2
    exit 1
fi

COMMIT_HASH="$1"
OUTPUT_FILE="${2:-}"

# Verify commit exists
if ! git rev-parse "$COMMIT_HASH" >/dev/null 2>&1; then
    echo "Error: Commit $COMMIT_HASH not found" >&2
    exit 1
fi

# Get commit information
COMMIT_DATE=$(git show -s --format=%ad --date=short "$COMMIT_HASH")
COMMIT_SUBJECT=$(git show -s --format=%s "$COMMIT_HASH")
FILES_CHANGED=$(git show --stat --format="" "$COMMIT_HASH" | wc -l | xargs)

# Extract brief title from commit subject (max 60 chars)
BRIEF_TITLE=$(echo "$COMMIT_SUBJECT" | head -c 60 | sed 's/[^a-zA-Z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

# Generate template
TEMPLATE=$(cat <<EOF
---
commit: $COMMIT_HASH
date: $COMMIT_DATE
severity: medium
tags: []
files_changed: $FILES_CHANGED
related_commits: []
---

# Postmortem: $COMMIT_SUBJECT

## Problem Summary

[Describe the bug or issue that required fixing. What was the observable symptom? What functionality was broken or degraded?]

## Root Cause Analysis

[Explain why this problem occurred. Go beyond the surface-level symptom to identify the underlying cause.]

**Root cause category**: [Select: Logic Error | Missing Validation | Race Condition | Architecture Flaw | Dependency Issue | Configuration Error | Other]

**Why it happened**:
- [Primary reason]
- [Contributing factors]
- [Missed edge cases or assumptions]

## Code Changes

[Describe what changes were made to fix the issue]

**Modified files**:
$(git show --stat --format="" "$COMMIT_HASH" | head -20)

**Key logic changes**:
- [Describe the main algorithmic or logical changes]
- [What was added, removed, or refactored]

**API/Interface changes**:
- [Note any changes to function signatures, API contracts, or data structures]
- [Impact on callers or dependencies]

## Risk Pattern

[What pattern should we watch for in future changes to avoid similar issues?]

**File/module risk**:
- Files: [List specific files that are prone to this issue]
- Modules: [List modules or components]

**Code pattern risk**:
- [Describe code structures or patterns that are vulnerable]
- [Example: "Accessing array elements without bounds checking"]
- [Example: "Database queries without transaction isolation"]

**Common mistake**:
- [What assumption or oversight led to this bug]
- [What might developers miss when working in this area]

## Prevention Strategy

[Focus on automation and systematic prevention, not manual processes]

### Automated Testing
- [ ] [Specific test case to add - describe input, expected behavior, edge cases]
- [ ] [Integration test scenario if applicable]
- [ ] [Performance test if relevant]
- [ ] [Recommend test framework or approach]

### AI Coding Context
- **When to load**: [Specify the trigger - e.g., "When modifying authentication flow", "Before editing database layer"]
- **What to load**:
  - [ ] [This postmortem document]
  - [ ] [Related postmortems: link to related_commits]
  - [ ] [Architecture docs: specify which files]
  - [ ] [API contracts: specify which interfaces]
- **Context strategy**: [Explain what AI should pay attention to when loaded]

### Automation Hooks
- **Pre-commit checks**:
  - [ ] [Linter rule to add]
  - [ ] [Static analysis check]
  - [ ] [Format validation]

- **CI/CD checks**:
  - [ ] [Build-time verification]
  - [ ] [Integration test requirement]
  - [ ] [Performance benchmark]

- **Claude Code hooks** (future):
  - [ ] [PreToolUse: warn when editing specific files]
  - [ ] [PostToolUse: validate generated code patterns]

### Code Review Checklist
- [ ] [Specific review item: e.g., "Verify bounds checking on array access"]
- [ ] [Second review item]
- [ ] [Third review item]

## Related Issues

**Similar commits**:
- [Link to related commits with similar issues]

**Potential problem areas**:
- [Files or modules that might have the same pattern]
- [Suggest running similar checks on these areas]

**Follow-up work**:
- [ ] [Any additional hardening or refactoring needed]
- [ ] [Documentation updates]

## Technical Context

**Affected components**:
- [Service/module/layer that was affected]

**Dependencies**:
- [External libraries, services, or systems involved]

**Testing challenges**:
- [Why this was hard to catch]
- [What made testing difficult]
- [How testing was improved]

**Additional notes**:
- [Any other context or observations]
- [Lessons learned]
- [Architectural considerations]

---

**Generated**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Commit**: $COMMIT_HASH
**Template version**: 1.0
EOF
)

# Output template
if [[ -n "$OUTPUT_FILE" ]]; then
    echo "$TEMPLATE" > "$OUTPUT_FILE"
else
    echo "$TEMPLATE"
fi

exit 0
