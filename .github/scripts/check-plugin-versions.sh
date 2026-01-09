#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the base branch (default to main)
BASE_BRANCH="${1:-main}"

echo "Checking plugin version changes against base branch: ${BASE_BRANCH}"

# Get list of changed files
CHANGED_FILES=$(git diff --name-only origin/${BASE_BRANCH}...HEAD)

if [ -z "$CHANGED_FILES" ]; then
    echo -e "${GREEN}No files changed. Skipping version check.${NC}"
    exit 0
fi

# Track validation status
VALIDATION_FAILED=0
PLUGINS_CHECKED=0

# Find all plugins
for PLUGIN_DIR in plugins/*/; do
    [ -d "$PLUGIN_DIR" ] || continue

    PLUGIN_NAME=$(basename "$PLUGIN_DIR")
    PLUGIN_CONFIG="${PLUGIN_DIR}.claude-plugin/plugin.json"

    # Check if plugin.json exists
    if [ ! -f "$PLUGIN_CONFIG" ]; then
        echo -e "${YELLOW}Warning: Plugin ${PLUGIN_NAME} has no plugin.json at ${PLUGIN_CONFIG}${NC}"
        continue
    fi

    # Check if any files in this plugin directory were changed (excluding README.md)
    PLUGIN_CHANGES=$(echo "$CHANGED_FILES" | grep "^${PLUGIN_DIR}" | grep -v "README.md" || true)

    if [ -z "$PLUGIN_CHANGES" ]; then
        # No relevant changes in this plugin
        continue
    fi

    echo -e "\n${YELLOW}Plugin ${PLUGIN_NAME} has changes:${NC}"
    echo "$PLUGIN_CHANGES" | sed 's/^/  - /'

    PLUGINS_CHECKED=$((PLUGINS_CHECKED + 1))

    # Check if plugin.json was modified
    PLUGIN_CONFIG_CHANGED=$(echo "$CHANGED_FILES" | grep "^${PLUGIN_CONFIG}$" || true)

    if [ -z "$PLUGIN_CONFIG_CHANGED" ]; then
        echo -e "${RED}ERROR: Plugin ${PLUGIN_NAME} has code changes but plugin.json was not modified${NC}"
        VALIDATION_FAILED=1
        continue
    fi

    # Check if version field was changed
    VERSION_CHANGED=$(git diff origin/${BASE_BRANCH}...HEAD -- "$PLUGIN_CONFIG" | grep '"version"' || true)

    if [ -z "$VERSION_CHANGED" ]; then
        echo -e "${RED}ERROR: Plugin ${PLUGIN_NAME} plugin.json was modified but version field was not changed${NC}"
        VALIDATION_FAILED=1
        continue
    fi

    # Extract old and new versions
    OLD_VERSION=$(git show origin/${BASE_BRANCH}:"${PLUGIN_CONFIG}" | grep '"version"' | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    NEW_VERSION=$(cat "$PLUGIN_CONFIG" | grep '"version"' | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

    echo -e "  Version change: ${OLD_VERSION} → ${NEW_VERSION}"

    # Validate version format (basic semver check)
    if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'; then
        echo -e "${RED}ERROR: Plugin ${PLUGIN_NAME} has invalid version format: ${NEW_VERSION}${NC}"
        echo -e "       Expected semantic versioning format: MAJOR.MINOR.PATCH"
        VALIDATION_FAILED=1
        continue
    fi

    # Check if version actually increased (optional strict check)
    if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
        echo -e "${RED}ERROR: Plugin ${PLUGIN_NAME} version was not bumped (still ${OLD_VERSION})${NC}"
        VALIDATION_FAILED=1
        continue
    fi

    echo -e "${GREEN}✓ Plugin ${PLUGIN_NAME} version check passed${NC}"
done

echo -e "\n========================================="
if [ $PLUGINS_CHECKED -eq 0 ]; then
    echo -e "${GREEN}No plugins with code changes found. Check passed.${NC}"
    exit 0
fi

if [ $VALIDATION_FAILED -eq 1 ]; then
    echo -e "${RED}Version validation FAILED${NC}"
    echo -e "\nPlease ensure that:"
    echo -e "  1. Every plugin with code changes (excluding README.md) has an updated version in .claude-plugin/plugin.json"
    echo -e "  2. The version follows semantic versioning format (e.g., 1.0.0)"
    echo -e "  3. The version number is actually incremented"
    exit 1
else
    echo -e "${GREEN}All version checks passed!${NC}"
    exit 0
fi
