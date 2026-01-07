# Reflect Plugin for Claude Code

Enables Claude Code to learn from your sessions and continuously improve its skills based on your corrections and preferences.

## Features

- [x] **Session Analysis**: Automatically detects corrections, successes, and edge cases from conversation history
- [x] **Reflection Command**: Run `/reflect [skill-name]` to analyze any session
- [x] **Git Integration**: Automatically commits and pushes approved skill improvements
- [ ] **Auto-Reflection Hook**: Automatic session analysis on stop *(not yet implemented)*

## Installation

### Option 1: Fork and Customize (Recommended)

This approach gives you full control to modify the plugin for your needs.

1. **Fork this repository on GitHub**, then clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/open-claude-plugins.git
   cd open-claude-plugins
   ```

2. **Customize the plugin** (optional):
   - Edit `plugins/reflect/skills/reflect/SKILL.md` to adjust the reflection logic

3. **Register your fork as a marketplace in Claude Code:**
   ```bash
   /plugin marketplace add YOUR_USERNAME/open-claude-plugins
   ```

4. **Install the reflect plugin:**
   ```bash
   /plugin install reflect@open-claude-plugins
   ```

### Option 2: Install Directly from This Repository

If you want to use the plugin as-is without customization:

1. **Register this repository as a marketplace:**
   ```bash
   /plugin marketplace add shfc/open-claude-plugins
   ```

2. **Install the reflect plugin:**
   ```bash
   /plugin install reflect@open-claude-plugins
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