#!/bin/bash

# Reflect command script
# Handles: on, off, status subcommands

# Detect the .claude directory based on script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"

# Use global Claude user directory for state (persists across plugin upgrades)
GLOBAL_CLAUDE_DIR="${HOME}/.claude"
STATE_FILE="$GLOBAL_CLAUDE_DIR/reflect-skill-state.json"
SKILLS_DIR="$CLAUDE_DIR/skills"

# Ensure global Claude directory exists
mkdir -p "$GLOBAL_CLAUDE_DIR"

# Get current timestamp in ISO format
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}
echo "$(date)" >> ~/.claude/reflect.log

# Enable auto-reflect
reflect_on() {
    local timestamp=$(get_timestamp)
    cat > "$STATE_FILE" << EOF
{
  "enabled": true,
  "updatedAt": "$timestamp"
}
EOF
    echo "Auto-reflect enabled. Sessions will be analyzed automatically when you stop."
    echo "State saved to: $STATE_FILE"
}

# Disable auto-reflect
reflect_off() {
    local timestamp=$(get_timestamp)
    cat > "$STATE_FILE" << EOF
{
  "enabled": false,
  "updatedAt": "$timestamp"
}
EOF
    echo "Auto-reflect disabled. Use \`/reflect\` manually to analyze sessions."
}

# Check auto-reflect status
reflect_status() {
    if [ -f "$STATE_FILE" ]; then
        local enabled=$(grep -o '"enabled": *[a-z]*' "$STATE_FILE" | grep -o 'true\|false')
        local updated=$(grep -o '"updatedAt": *"[^"]*"' "$STATE_FILE" | sed 's/"updatedAt": *"//' | sed 's/"$//')

        if [ "$enabled" = "true" ]; then
            echo "Auto-reflect is enabled. Last updated: $updated"
        else
            echo "Auto-reflect is disabled. Last updated: $updated"
        fi
    else
        echo "Auto-reflect is not configured. Run \`/reflect on\` to enable."
    fi

}

# Main command handler
case "$1" in
    on)
        reflect_on
        ;;
    off)
        reflect_off
        ;;
    status)
        reflect_status
        ;;
    *)
        # For empty args or skill name
        if [ -n "$1" ]; then
            # Skill name explicitly provided, always trigger
            echo "REFLECT_SKILL:$1"
        elif [ -f "$STATE_FILE" ]; then
            # No skill name, check if auto-reflect is enabled
            enabled=$(grep -o '"enabled": *[a-z]*' "$STATE_FILE" | grep -o 'true\|false')
            if [ "$enabled" = "true" ]; then
                # Auto-reflect is enabled - force Claude to run reflect skill
                # TODO: Implement the logic to trigger the reflect skill
                exit 0
            fi
        fi
        ;;
esac
