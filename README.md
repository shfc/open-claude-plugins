# Open Claude Plugins

A curated collection of plugins that extend Claude Code with new commands, skills, hooks, and capabilities.

## Available Plugins

- **[reflect](./plugins/reflect/README.md)** - Learn from sessions and improve skills based on corrections and preferences
- **[postmortem](./plugins/postmortem/README.md)** - Prevent code regression by learning from historical fix commits

## Installation

```bash
# Add marketplace
claude plugin add-marketplace shfc/open-claude-plugins

# Install plugins
claude plugin install reflect@open-claude-plugins
claude plugin install postmortem@open-claude-plugins

# Restart Claude Code
```