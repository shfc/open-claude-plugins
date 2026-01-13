---
name: postmortem:update
description: Update postmortem database with recent fix commits since last update
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob", "Task"]
argument-hint: "[--since <date>]"
---

# Update Postmortem Database

Update the postmortem database by analyzing new fix commits since the last update or specified date.

## Task

Perform these steps to update the postmortem database:

1. **Verify Postmortem Database Exists**:
   - Check if `.claude/postmortem/` directory exists
   - Check if `index.json` exists
   - If not exists:
     - Report: "Postmortem database not initialized. Please run `/postmortem:init` first."
     - Stop execution

2. **Load Configuration**:
   - Check for `.claude/postmortem.local.md`
   - Parse YAML frontmatter for:
     - `storage_dir` (default: `.claude/postmortem`)
     - `commit_filter.exclude_types`
     - `commit_filter.include_keywords`
     - `postmortem.batch_size` (default: 20)
   - Use defaults if config not found

3. **Determine Time Range**:
   - Read `index.json` to get `last_commit` and `last_updated` timestamp
   - If `--since` argument provided:
     - Use provided date as start point
     - Report: "Analyzing commits since {date}..."
   - Else if `last_commit` exists in index:
     - Use commits after last_commit
     - Report: "Analyzing commits since last update ({last_updated})..."
   - Else:
     - Ask user: "How far back should I look for new commits? (e.g., '1.week.ago', '2024-01-01')"
     - Use user's response

4. **Filter New Commits**:
   - Build filter command:
     ```bash
     ${CLAUDE_PLUGIN_ROOT}/scripts/commit-filter.sh \
       [--include-keywords "..."] \
       [--exclude-types "..."] \
       --since "{start_point}" \
       --format json \
       --output /tmp/postmortem-new-commits.json
     ```
   - Execute and parse JSON output
   - If no new commits found:
     - Report: "No new fix commits found since last update. Database is up to date."
     - Stop execution
   - Report: "Found {count} new candidate commits"

5. **Show Sample and Confirm**:
   - Display first 3-5 commits:
     ```
     New commits to analyze:
     - abc123 (2026-01-13): Fix null pointer in auth
     - def456 (2026-01-12): Resolve race condition in cache
     - ghi789 (2026-01-11): Fix validation bug in API
     ...and {remaining} more
     ```
   - Ask: "Proceed with analyzing {count} commits?"
   - If user declines, stop

6. **Launch postmortem-generator Agent**:
   - Use Task tool to launch postmortem-generator agent
   - Pass list of new commit hashes
   - Agent will:
     - Process commits in batches
     - Generate new postmortem documents
     - Check for related existing postmortems
     - Update existing postmortems if new information found (per config)
     - Save to storage directory
   - Wait for agent completion

7. **Update Index**:
   - Read existing `index.json`
   - Add new postmortem entries
   - Update metadata:
     - `last_updated`: Current timestamp
     - `last_commit`: Latest commit hash analyzed
     - `total_postmortems`: Updated count
   - Write updated index back to file
   - Keep index sorted by date (newest first)

8. **Report Results**:
   - Display update summary:
     ```
     Postmortem Database Updated!

     New Commits Analyzed: {count}
     New Postmortems Generated: {count}
     Existing Postmortems Updated: {count}
     Skipped (not fixes): {count}

     Severity Distribution (new):
     - Critical: {count}
     - High: {count}
     - Medium: {count}
     - Low: {count}

     Total Postmortems: {total_count}
     Last Updated: {timestamp}
     Storage: {storage_dir}/

     Recently Added:
     - {filename1}: {brief description}
     - {filename2}: {brief description}
     - {filename3}: {brief description}

     Next steps:
     - Run `/postmortem:check` to analyze your current changes
     - Run `/postmortem:list --since 1.week.ago` to see recent postmortems
     ```

## Important Notes

- **FOR CLAUDE**: These instructions are for you, not the user
- Update is incremental - only analyze new commits since last update
- Per user's requirements: Can update existing postmortems if new analysis reveals more info
- Process in batches like init
- Maintain index integrity
- Report both new and updated postmortems

## Available Tools

- **Bash**: Run commit-filter.sh and git commands
- **Read**: Read existing index and config
- **Write**: Write new postmortems and update index
- **Grep/Glob**: Search existing postmortems
- **Task**: Launch postmortem-generator agent

## Example Usage

```
User: /postmortem:update
You: "I'll update the postmortem database with new commits..."
[Check last update from index]
[Filter commits since last update]
[Confirm and process]

User: /postmortem:update --since 1.week.ago
You: "Analyzing commits from the last week..."
[Override last update, use provided date]
[Filter and process]

User: /postmortem:update
[Database not initialized]
You: "Postmortem database not initialized. Please run `/postmortem:init` first."
```

## Updating Existing Postmortems

When analyzing commits, the postmortem-generator may discover that a new commit relates to an existing postmortem. In this case:

1. Check `related_commits` in existing postmortems
2. If new commit provides additional insights:
   - Update existing postmortem with new information
   - Add new commit to `related_commits` array
   - Update `last_updated` metadata
   - Report: "Updated existing postmortem: {filename}"
3. If new commit is distinct issue:
   - Create separate postmortem
   - Cross-reference in `related_commits` of both

## Tips

- Default behavior: Use last update from index as starting point
- `--since` allows manual override of date range
- Incremental updates keep database current without re-analyzing everything
- Index enables fast lookups and prevents duplicate analysis
- Report both quantity (counts) and quality (specific examples) in summary
- Highlight critical/high severity new postmortems
