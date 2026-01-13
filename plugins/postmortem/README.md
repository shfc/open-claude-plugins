# Postmortem Plugin

AI-powered postmortem analysis plugin for Claude Code that learns from historical fix commits to prevent code regression.

## Overview

As codebases grow, AI-assisted coding (Vibe Coding) can become fragile - fixing bug A may reintroduce bug B, or implementing feature A may introduce bug C. This plugin implements a systematic postmortem workflow inspired by traditional software engineering practices to break this cycle.

**Core concept**: Build a knowledge base of postmortem documents from historical fix commits, then use this knowledge to prevent similar issues in future code changes.

## Features

### V1 Core Features

- **`/postmortem:setup`** - Create project configuration file from template
- **`/postmortem:init`** - Initialize postmortem database from git history
- **`/postmortem:check`** - Check current changes against postmortem patterns
- **`/postmortem:update`** - Update postmortem database with recent fixes
- **`/postmortem:list`** - List and browse postmortem documents
- **Intelligent analysis** - AI-powered commit filtering and pattern detection
- **Risk assessment** - Automatic similarity matching and risk scoring
- **Structured documentation** - Standardized postmortem format in Markdown

### Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  1. Onboarding: Analyze historical fix commits              │
│     /postmortem:init                                         │
│     → Generates initial postmortem knowledge base           │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  2. Prevention: Check changes before committing             │
│     /postmortem:check                                        │
│     → Warns if changes match known problem patterns         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  3. Learning: Update knowledge base after fixes             │
│     /postmortem:update                                       │
│     → Continuously learns from new fix commits              │
└─────────────────────────────────────────────────────────────┘
```

## Installation

### Prerequisites

- Claude Code CLI
- Git repository

### Install Plugin

1. Add the open-claude-plugins marketplace:
   ```bash
   claude plugin add-marketplace shfc/open-claude-plugins
   ```

2. Install the postmortem plugin:
   ```bash
   claude plugin install postmortem@open-claude-plugins
   ```

3. Restart Claude Code to load the plugin

4. (Optional) Create project configuration:
   ```bash
   /postmortem:setup
   ```

   Then customize settings in `.claude/postmortem.local.md`

## Configuration

The plugin uses `.claude/postmortem.local.md` for project-specific settings.

### Key Settings

| Setting | Description | Default |
|---------|-------------|---------|
| `storage_dir` | Postmortem storage location | `.claude/postmortem` |
| `commit_filter.exclude_types` | Commit types to exclude | `feat, docs, chore, style, refactor, test, build, ci, perf` |
| `commit_filter.include_keywords` | If set, only analyze commits with these keywords | Not set |
| `postmortem.min_severity` | Minimum severity to generate | `low` |
| `postmortem.batch_size` | Commits per batch | `20` |

### Filtering Logic

- **If `include_keywords` is set**: Only analyze commits containing these keywords, then AI determines if it's a fix
- **If `include_keywords` is not set**: Exclude commits with `exclude_types`, then AI analyzes remaining commits

### Severity Levels (Reference)

| Level | Description | Examples |
|-------|-------------|----------|
| **Critical** | System crash, data loss, security breach | Null pointer causing service crash, SQL injection vulnerability |
| **High** | Core functionality broken, widespread impact | Authentication failure, database connection error |
| **Medium** | Feature broken, workaround available | Form validation issue, API timeout |
| **Low** | Minor issue, edge case, cosmetic problem | UI alignment, rare edge case |

## Usage

### Create Project Configuration

(Optional) Create a project-specific configuration file:

```bash
/postmortem:setup
```

This will:
1. Find the plugin installation directory
2. Copy the configuration template to `.claude/postmortem.local.md`
3. Provide guidance on customization

After creation, edit `.claude/postmortem.local.md` to customize:
- Storage directory location
- Commit filtering rules (exclude/include types)
- Minimum severity level
- Batch size for analysis

**Note**: The plugin works with default settings if no configuration file is created.

### Initialize Postmortem Database

First-time setup to analyze historical commits:

```bash
/postmortem:init
```

This will:
1. Scan git history for fix-related commits
2. Analyze commits in batches (configurable)
3. Generate postmortem documents in `.claude/postmortem/`
4. Create search index for fast lookup

**Options**:
- Time range: Specify `--since 6.months.ago` or `--until 2024-01-01`
- Branch: Specify `--branch main` (default: current branch)

### Check Changes for Risks

Before committing, check if your changes might trigger known issues:

```bash
/postmortem:check
```

This will:
1. Analyze uncommitted changes (or specified commits)
2. Compare against postmortem database
3. Report matching patterns and risk levels
4. Suggest prevention strategies

**Risk levels**:
- 🔴 **Critical**: Exact same file + highly similar pattern
- 🟠 **High**: Same file or very similar code structure
- 🟡 **Medium**: Same module, related files
- 🟢 **Low**: Distant match or no match

### Update Postmortem Database

After fixing bugs, update the knowledge base:

```bash
/postmortem:update
```

This will:
1. Find new fix commits since last update
2. Generate postmortem documents for new fixes
3. Update existing postmortems if new information found
4. Refresh search index

**Incremental**: Only analyzes commits since last update.

### List Postmortem Documents

Browse and search postmortem database:

```bash
/postmortem:list
```

**Options**:
- Search: `/postmortem:list authentication`
- Filter by severity: `/postmortem:list --severity high`
- Filter by date: `/postmortem:list --since 2024-01-01`
- Filter by tags: `/postmortem:list --tag race-condition`

## Postmortem Document Structure

Each postmortem document follows this structure:

```markdown
---
commit: abc123def456
date: 2026-01-13
severity: medium
tags: [authentication, database, race-condition]
files_changed: 5
related_commits: [def456, ghi789]
---

# Postmortem: [Brief Title]

## Problem Summary
What was the bug/issue that required fixing?

## Root Cause Analysis
Why did this problem occur?

## Code Changes
What changes were made to fix the issue?

## Risk Pattern
What pattern should we watch for in future changes?

## Prevention Strategy
How to avoid similar issues in the future?
- Automated testing recommendations
- AI coding context to load (which files, when)
- Suggested hooks for automation
- Code review checklist items

## Related Issues
Links to related commits and potential areas with same pattern

## Technical Context
Affected modules, dependencies, testing challenges
```

### Prevention Strategy Focus

The `Prevention Strategy` section emphasizes **automation without human intervention**:

- **Automated testing**: Specific test cases to add
- **AI coding context**: Which files/docs AI should load, at what stage
- **Hooks**: Pre-commit, pre-push, or Claude Code hooks
- **CI/CD checks**: Linting, static analysis, integration tests

## Specialized Agents

The plugin includes specialized agents for autonomous analysis:

### postmortem-generator

Generates professional postmortem documents from fix commits.

**Triggers**: `/postmortem:init`, `/postmortem:update`, or "generate postmortem"

**Capabilities**:
- Analyzes commit messages, diffs, and context
- Identifies root causes vs. surface symptoms
- Structures findings in standard format
- Assigns severity levels
- Generates actionable prevention strategies

### risk-analyzer

Analyzes code changes for regression risks.

**Triggers**: `/postmortem:check`, or "is this change safe", "check for risks"

**Capabilities**:
- Compares changes against postmortem patterns
- Evaluates similarity (file paths, code structure, keywords)
- Scores risk levels with justification
- Recommends preventive actions
- Highlights relevant postmortem documents

## Skills

The plugin provides specialized knowledge through skills:

### postmortem-writing

Best practices for writing effective postmortem documents.

**Triggers**: "how to write postmortem", "postmortem best practices"

**Includes**:
- Document structure and section guidelines
- Root cause analysis techniques
- Good/bad examples
- Severity classification guide
- Tagging conventions

### commit-analysis

Techniques for analyzing git commits and detecting patterns.

**Triggers**: "analyze commits", "identify fix patterns", "git commit analysis"

**Includes**:
- Commit message pattern recognition
- Diff analysis techniques
- Common problem pattern detection
- Similarity detection methods
- Git history analysis tips

## Roadmap

### Phase 2 - Automation (Future)

- **Pre-commit hooks**: Automatic risk check before commits
- **Post-commit hooks**: Auto-update postmortem after fix commits
- **Pre-push hooks**: Block high-risk pushes with warnings
- **Claude Code hooks**: Integrate with Write/Edit tool events

### Phase 3 - Analytics (Future)

- **`/postmortem:stats`**: Statistical analysis
  - Most common problem types
  - High-risk files/modules
  - Severity distribution over time
  - Tag frequency analysis
  - Prevention strategy effectiveness

## Contributing

Contributions welcome! Please:

1. Follow blameless postmortem principles
2. Write postmortem documents in English
3. Focus on learning and prevention, not blame
4. Emphasize automation in prevention strategies