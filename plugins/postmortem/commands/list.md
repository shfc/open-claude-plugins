---
name: postmortem:list
description: List and browse postmortem documents with filtering and search capabilities
allowed-tools: ["Read", "Bash", "Grep", "Glob"]
argument-hint: "[search-term] [--severity <level>] [--tag <tag>] [--since <date>] [--until <date>] [--limit <n>]"
---

# List Postmortem Documents

Browse, search, and filter postmortem documents in the database.

## Task

Perform these steps to list postmortem documents:

1. **Verify Postmortem Database Exists**:
   - Check if `.claude/postmortem/` directory exists
   - Check if it contains any `*.md` files
   - If not exists or empty:
     - Report: "Postmortem database not found or empty. Run `/postmortem:init` to initialize."
     - Stop execution

2. **Load Configuration**:
   - Check for `.claude/postmortem.local.md`
   - Parse `storage_dir` (default: `.claude/postmortem`)
   - Use configured storage directory

3. **Load Postmortem Index**:
   - Check if `index.json` exists in storage directory
   - If exists:
     - Read and parse index file
     - Use index for fast filtering
   - If not exists:
     - Scan directory for `*.md` files
     - Parse frontmatter from each file to build temporary index
     - Inform user: "Index not found. Consider running `/postmortem:update` to rebuild."

4. **Parse Arguments and Apply Filters**:

   **Search Term** (positional argument):
   - If provided (e.g., `/postmortem:list authentication`):
     - Search in: filename, commit subject, tags, problem summary
     - Case-insensitive matching
     - Match any field containing the search term

   **--severity <level>**:
   - Filter by severity: `critical`, `high`, `medium`, or `low`
   - Can specify multiple: `--severity critical,high`
   - Example: `/postmortem:list --severity critical`

   **--tag <tag>**:
   - Filter by tag
   - Can specify multiple: `--tag authentication --tag database`
   - Match if postmortem has ANY of the specified tags
   - Example: `/postmortem:list --tag race-condition`

   **--since <date>**:
   - Only show postmortems from commits after this date
   - Format: "YYYY-MM-DD" or relative like "1.week.ago", "2.months.ago"
   - Example: `/postmortem:list --since 2024-01-01`

   **--until <date>**:
   - Only show postmortems from commits before this date
   - Example: `/postmortem:list --until 2024-12-31`

   **--limit <n>**:
   - Limit results to first N postmortems
   - Default: 20 (to prevent overwhelming output)
   - Use `--limit 0` for no limit
   - Example: `/postmortem:list --limit 10`

5. **Filter Postmortems**:
   - Start with all postmortems from index/scan
   - Apply each filter in sequence:
     1. Search term filter
     2. Severity filter
     3. Tag filter
     4. Date range filters (since/until)
   - Sort results by date (newest first)
   - Apply limit

6. **Display Results**:

   **List Format** (default):
   ```
   Postmortem Database
   ===================

   Showing {displayed} of {total} postmortems
   [Filters applied: severity=high, tag=authentication]

   📋 Recent Postmortems:

   1. 🔴 CRITICAL - 2026-01-13
      File: 2026-01-13-abc123-token-validation-fix.md
      Commit: abc123 (5 files changed)
      Tags: authentication, validation, string-handling
      Problem: Token validation failed for password reset tokens

   2. 🟠 HIGH - 2026-01-12
      File: 2026-01-12-def456-race-condition-cache.md
      Commit: def456 (3 files changed)
      Tags: cache, race-condition, concurrency
      Problem: Race condition in cache invalidation causing stale data

   3. 🟡 MEDIUM - 2026-01-11
      File: 2026-01-11-ghi789-api-validation-missing.md
      Commit: ghi789 (2 files changed)
      Tags: api, validation, input-handling
      Problem: Missing input validation on API endpoint

   ...

   To view full postmortem: Read .claude/postmortem/<filename>
   To filter: /postmortem:list [search] [--severity X] [--tag Y]
   ```

   **Summary Statistics** (at end):
   ```
   Summary:
   --------
   Total postmortems: {total}
   Displayed: {displayed}

   By Severity:
   - Critical: {count} 🔴
   - High: {count} 🟠
   - Medium: {count} 🟡
   - Low: {count} 🟢

   Top Tags:
   - authentication: {count}
   - database: {count}
   - validation: {count}
   - race-condition: {count}
   - api: {count}
   ```

7. **Handle Special Cases**:

   **No matches**:
   ```
   No postmortems found matching your criteria.

   Filters applied:
   - Search: "authentication"
   - Severity: critical, high

   Try:
   - Broadening search terms
   - Removing some filters
   - Running `/postmortem:list` to see all postmortems
   ```

   **Large result set**:
   - If >20 matches and no --limit specified:
     - Show first 20
     - Inform: "Showing first 20 of {total} results. Use --limit to see more."

8. **Provide Helpful Tips**:
   - If database seems old (last_updated >1 month ago):
     - "💡 Tip: Database was last updated {date}. Run `/postmortem:update` for recent commits."
   - If user searches for common terms:
     - "💡 Tip: Use --tag for more precise filtering by tag."
   - If zero critical/high severity:
     - "✅ No critical or high severity postmortems in current view."

## Important Notes

- **FOR CLAUDE**: These instructions are for you, not the user
- Default to 20 results max (prevent overwhelming output)
- Use emoji indicators for severity (🔴🟠🟡🟢)
- Show enough context for each postmortem (one-line problem summary)
- Provide file paths so user can read full postmortems
- Include summary statistics for overview
- Make filter syntax clear in output

## Available Tools

- **Read**: Read index.json and postmortem files
- **Bash**: For date parsing if needed
- **Grep**: Search through postmortem content
- **Glob**: Find postmortem files in directory

## Example Usage

```
User: /postmortem:list
You: [Display all postmortems, newest first, limit 20]

User: /postmortem:list authentication
You: [Filter postmortems containing "authentication" in any field]

User: /postmortem:list --severity critical,high
You: [Show only critical and high severity postmortems]

User: /postmortem:list --tag race-condition --since 2024-01-01
You: [Show race-condition postmortems from 2024 onwards]

User: /postmortem:list --limit 5
You: [Show only 5 most recent postmortems]

User: /postmortem:list validation --severity medium --limit 10
You: [Search "validation", filter by medium severity, limit to 10 results]
```

## Output Format

**Per Postmortem Entry**:
```
{number}. {severity_emoji} {severity_level} - {date}
   File: {filename}
   Commit: {short_hash} ({files_changed} files changed)
   Tags: {tag1}, {tag2}, {tag3}
   Problem: {one_line_summary}
```

**Severity Emojis**:
- Critical: 🔴
- High: 🟠
- Medium: 🟡
- Low: 🟢

## Filtering Logic

**Search Term**:
- Match if ANY of these contain the term:
  - Filename
  - Commit subject (from frontmatter)
  - Tags array
  - First paragraph of Problem Summary

**Multiple Filters**:
- AND logic: Must satisfy ALL specified filters
- Example: `--severity high --tag auth` = high severity AND auth tag

**Tag Filter with Multiple Tags**:
- OR logic: Must have ANY of the specified tags
- Example: `--tag auth --tag database` = has auth OR database tag

## Tips

- Default limit of 20 keeps output manageable
- Newest first is most useful for recent issues
- Include problem summary line for quick scanning
- Show file path so user can read full postmortem
- Statistics give overview of database health
- Clear filter syntax in examples helps users refine searches
