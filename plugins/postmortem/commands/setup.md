---
name: postmortem:setup
description: Create project configuration file from template
allowed-tools: ["Read", "Write", "Bash", "Glob"]
argument-hint: ""
---

# Create Project Configuration

This command creates a project-specific configuration file for the postmortem plugin.

## Implementation

1. Use `${CLAUDE_PLUGIN_ROOT}` to get the plugin directory
2. Read the template file from `${CLAUDE_PLUGIN_ROOT}/.claude/postmortem.local.md.template`
3. Create `.claude/postmortem.local.md` in the current project
4. Inform the user about the created file and next steps

## Steps

```bash
# Use Claude Code's plugin root environment variable
TEMPLATE_PATH="${CLAUDE_PLUGIN_ROOT}/.claude/postmortem.local.md.template"

if [ ! -f "$TEMPLATE_PATH" ]; then
  echo "Error: Template file not found at $TEMPLATE_PATH"
  echo "Plugin root: ${CLAUDE_PLUGIN_ROOT}"
  exit 1
fi

# Create .claude directory if it doesn't exist
mkdir -p .claude

# Check if config already exists
if [ -f .claude/postmortem.local.md ]; then
  echo "Configuration file already exists at .claude/postmortem.local.md"
  echo "Do you want to overwrite it? (The existing file will be backed up)"
  # Ask user for confirmation via AskUserQuestion tool
  exit 0
fi

# Copy template to project
cp "$TEMPLATE_PATH" .claude/postmortem.local.md

echo "✓ Created project configuration at .claude/postmortem.local.md"
echo ""
echo "Next steps:"
echo "1. Edit .claude/postmortem.local.md to customize settings"
echo "2. Run /postmortem:init to initialize the postmortem database"
```

## User Interaction

If the configuration file already exists:
1. Use the `AskUserQuestion` tool to ask if they want to overwrite
2. If yes, backup the existing file to `.claude/postmortem.local.md.backup`
3. Copy the template

## Output

The command should output:
- Success message with the file path
- Brief description of key settings to customize
- Suggested next steps
