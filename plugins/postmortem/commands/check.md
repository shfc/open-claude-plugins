---
name: postmortem:check
description: Check current code changes or specific commit against postmortem database for regression risks
allowed-tools: ["Read", "Bash", "Grep", "Glob", "Task"]
argument-hint: "[commit-hash]"
---

# Check for Regression Risks

Analyze code changes against the postmortem database to identify potential risks of reintroducing previously fixed bugs.

## Task

Perform these steps to check code changes for risks:

1. **Verify Postmortem Database Exists**:
   - Check if `.claude/postmortem/` directory exists
   - Check if it contains any `*.md` files
   - If not exists or empty:
     - Report: "Postmortem database not found. Please run `/postmortem:init` first to initialize the database."
     - Stop execution

2. **Determine What to Analyze**:
   - If argument provided (commit hash):
     - Validate commit exists: `git rev-parse <commit-hash>`
     - If invalid, report error and stop
     - Target: This specific commit
   - If no argument:
     - Check for uncommitted changes: `git status --porcelain`
     - If no changes:
       - Report: "No uncommitted changes found. Specify a commit hash to check: `/postmortem:check <commit-hash>`"
       - Stop execution
     - Target: Working directory changes
   - Report what's being analyzed:
     - "Analyzing uncommitted changes in working directory..."
     - OR "Analyzing commit {hash}: {subject}..."

3. **Load Configuration**:
   - Check for `.claude/postmortem.local.md`
   - Parse `storage_dir` (default: `.claude/postmortem`)
   - Use configured storage directory

4. **Get Change Information**:
   - For uncommitted changes:
     ```bash
     git diff --stat  # Get summary
     git diff         # Get full diff
     ```
   - For specific commit:
     ```bash
     git show --stat <commit>   # Get summary
     git show <commit>          # Get full diff
     ```
   - Extract:
     - List of modified files
     - Number of lines changed
     - Diff content for analysis

5. **Launch risk-analyzer Agent**:
   - Use Task tool to launch the risk-analyzer agent
   - Pass:
     - What to analyze (uncommitted changes or commit hash)
     - Diff content
     - List of modified files
     - Postmortem database location
   - Agent will:
     - Load postmortem database
     - Calculate similarity scores
     - Generate risk report with recommendations
   - Wait for agent completion

6. **Present Results to User**:
   - Agent returns structured risk report
   - Display report with clear formatting
   - Ensure risk indicators are visible (🔴🟠🟡)
   - Highlight:
     - Critical and high risks prominently
     - Specific postmortems to review
     - Actionable recommendations
   - Include summary assessment

7. **Suggest Next Actions**:
   - If critical risks found:
     ```
     ⚠️  CRITICAL RISKS DETECTED

     Recommendation: Review the identified postmortems before proceeding.

     To view a specific postmortem:
     - Read file: .claude/postmortem/<filename>
     - Use `/postmortem:list` to browse all postmortems

     Consider:
     - Modifying your approach based on lessons learned
     - Adding tests mentioned in prevention strategies
     - Consulting with team if unsure
     ```
   - If high risks found:
     ```
     ⚠️  HIGH RISKS FOUND

     Recommendation: Carefully review the similar issues before committing.

     Suggested actions:
     - Review postmortems: [list files]
     - Run tests: [specific test commands if mentioned]
     - Double-check: [specific concerns from postmortems]
     ```
   - If only medium/low risks or no risks:
     ```
     ✅ No significant risks detected

     Your changes don't closely match any known problem patterns.
     Standard code review and testing recommended.
     ```

## Important Notes

- **FOR CLAUDE**: These instructions are for you, not the user
- Always provide context about what's being analyzed
- Make risk report easy to scan (use emoji indicators)
- Be specific about which postmortems are relevant
- Provide actionable recommendations, not just warnings
- If database is empty, suggest running `/postmortem:init`

## Available Tools

- **Bash**: Run git commands to get changes
- **Read**: Read postmortem database files
- **Grep/Glob**: Search through postmortems
- **Task**: Launch risk-analyzer agent

## Example Usage

```
User: /postmortem:check
You: "Analyzing uncommitted changes in working directory..."
[Launch risk-analyzer]
[Display results]

User: /postmortem:check abc123
You: "Analyzing commit abc123: Fix token validation..."
[Launch risk-analyzer]
[Display results]

User: /postmortem:check
[No changes]
You: "No uncommitted changes found. Specify a commit hash to check: `/postmortem:check <commit-hash>`"
```

## Output Format

Always structure output clearly:

```
Risk Analysis Report
====================

Analyzing: [uncommitted changes | commit abc123]
Postmortem Database: {count} documents loaded

Risk Findings:
--------------

[Agent's risk report here]

Summary:
--------
- Critical risks: {count} 🔴
- High risks: {count} 🟠
- Medium risks: {count} 🟡

Overall: [SAFE | REVIEW RECOMMENDED | CAUTION ADVISED | HIGH RISK]

Next Steps:
-----------
[Specific recommendations]
```

## Tips

- Default to uncommitted changes if no argument
- Make critical risks very visible
- Provide file paths for relevant postmortems
- Give specific test commands when available
- Keep report concise but actionable
- Focus on prevention, not just detection
