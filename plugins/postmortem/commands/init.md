---
name: postmortem:init
description: Initialize postmortem database by analyzing historical fix commits from git history
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob", "Task"]
argument-hint: "[--since <date>] [--until <date>] [--branch <branch>]"
---

# Initialize Postmortem Database

Initialize the postmortem database by analyzing historical fix commits from git history and generating postmortem documents.

## Task

Perform these steps to initialize the postmortem database:

1. **Check Current State**:
   - Check if `.claude/postmortem/` directory already exists
   - If exists and contains files, ask user:
     - "Postmortem database already exists with {count} documents. Do you want to:"
     - Option 1: "Reinitialize (delete existing and start fresh)"
     - Option 2: "Update (add new commits since last update)"
     - Option 3: "Cancel"
   - If user chooses cancel, stop
   - If reinitialize, back up existing to `.claude/postmortem.backup-{timestamp}/`

2. **Load Configuration**:
   - Check for `.claude/postmortem.local.md` configuration file
   - If exists, parse YAML frontmatter to get:
     - `storage_dir` (default: `.claude/postmortem`)
     - `commit_filter.exclude_types` (default: feat,docs,chore,style,refactor,test,build,ci,perf)
     - `commit_filter.include_keywords` (if set, only analyze commits with these keywords)
     - `postmortem.batch_size` (default: 20)
   - If not exists, use defaults and inform user they can create config file

3. **Parse Arguments**:
   - `--since <date>`: Only analyze commits after this date (e.g., "6.months.ago", "2024-01-01")
   - `--until <date>`: Only analyze commits before this date
   - `--branch <branch>`: Target branch (default: current branch)
   - If no `--since` provided, ask user:
     - "How far back should I analyze git history?"
     - Options: "All history", "Last 6 months", "Last year", "Last 2 years", "Custom"

4. **Filter Commits**:
   - Use `${CLAUDE_PLUGIN_ROOT}/scripts/commit-filter.sh` to get candidate commits
   - Build command with parameters:
     ```bash
     ${CLAUDE_PLUGIN_ROOT}/scripts/commit-filter.sh \
       [--include-keywords "keyword1,keyword2"] \  # If configured
       [--exclude-types "type1,type2"] \           # If no include_keywords
       [--since "date"] \                           # If provided
       [--until "date"] \                           # If provided
       [--branch "branch"] \                        # If provided
       --format json \
       --output /tmp/postmortem-commits.json
     ```
   - Execute script and parse JSON output
   - Report: "Found {count} candidate commits to analyze"

5. **Confirm with User**:
   - Show sample of first 5 commits
   - Ask: "Ready to analyze {count} commits? This will generate postmortem documents."
   - If user declines, stop
   - Inform: "I'll process commits in batches of {batch_size}"

6. **Launch postmortem-generator Agent**:
   - Use Task tool to launch the postmortem-generator agent
   - Pass list of commit hashes to analyze
   - Agent will:
     - Process commits in batches
     - Confirm each is a fix commit
     - Generate postmortem documents
     - Save to storage directory
   - Wait for agent completion

7. **Create or Update Index**:
   - Create `index.json` in storage directory
   - Index structure:
     ```json
     {
       "version": "1.0",
       "last_updated": "2026-01-13T10:30:00Z",
       "last_commit": "abc123...",
       "total_postmortems": 42,
       "postmortems": [
         {
           "file": "2026-01-13-abc123-brief-title.md",
           "commit": "abc123...",
           "date": "2026-01-13",
           "severity": "medium",
           "tags": ["auth", "validation"],
           "files_changed": 5
         }
       ]
     }
     ```
   - Include metadata from all generated postmortems

8. **Report Results**:
   - Display summary:
     ```
     Postmortem Database Initialized!

     Analysis Summary:
     - Commits analyzed: {count}
     - Postmortems generated: {count}
     - Skipped (not fixes): {count}

     Severity Distribution:
     - Critical: {count}
     - High: {count}
     - Medium: {count}
     - Low: {count}

     Storage: {storage_dir}/
     Index: {storage_dir}/index.json

     Next steps:
     - Run `/postmortem:check` to analyze your current changes
     - Run `/postmortem:list` to browse generated postmortems
     - Run `/postmortem:update` after fixing new bugs
     ```

## Important Notes

- **FOR CLAUDE**: These instructions are for you, not the user
- Always ask for confirmation before analyzing large numbers of commits
- Process in batches to avoid overwhelming context
- Save progress incrementally (don't wait until all done to write files)
- If errors occur, report what was completed successfully
- Provide clear, actionable output to user

## Available Tools

- **Bash**: Run commit-filter.sh and git commands
- **Read**: Read configuration file and existing postmortems
- **Write**: Create postmortem documents and index file
- **Grep/Glob**: Search for existing files
- **Task**: Launch postmortem-generator agent

## Example Usage

```
User: /postmortem:init
You: "I'll initialize the postmortem database. Let me check your git history..."
[Follow steps above]

User: /postmortem:init --since 6.months.ago
You: "I'll analyze fix commits from the last 6 months..."
[Follow steps above with --since parameter]

User: /postmortem:init --branch main
You: "I'll analyze fix commits from the main branch..."
[Follow steps above with --branch parameter]
```

## Tips

- Default to last 6-12 months if user unsure about time range
- Batch size of 20 is good balance between speed and thoroughness
- Always create backup before reinitializing
- Index file enables fast searching later
- Report progress during long operations
