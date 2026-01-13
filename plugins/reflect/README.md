# Reflect Plugin for Claude Code

Enables Claude Code to learn from your sessions and continuously improve its skills based on your corrections and preferences.

## Features

- [x] **Session Analysis**: Automatically detects corrections, successes, and edge cases from conversation history
- [x] **Reflection Command**: Run `/reflect [skill-name]` to analyze any session
- [x] **Git Integration**: Automatically commits and pushes approved skill improvements
- [ ] **Auto-Reflection Hook**: Automatic session analysis on stop *(not yet implemented)*

## Installation

```bash
# Add marketplace
claude plugin add-marketplace shfc/open-claude-plugins

# Install plugin
claude plugin install reflect@open-claude-plugins

# Restart Claude Code
```

## Usage

### Basic Reflection

After working with a skill, run:

```bash
/reflect [skill-name]
```

Example:
```bash
/reflect frontend-design
```

Claude will:
1. Analyze the conversation for signals (corrections, successes, edge cases)
2. Propose specific changes to the skill
3. Ask for your approval
4. Apply changes and optionally commit to git