#!/bin/bash
#
# commit-filter.sh - Universal git commit filtering utility
#
# Usage:
#   commit-filter.sh [options]
#
# Options:
#   --exclude-types "type1,type2,..."  Commit types to exclude (e.g., "feat,docs")
#   --include-keywords "word1,word2,..." Keywords to include (e.g., "fix,bug")
#   --since <date>                     Only commits after date (e.g., "2024-01-01", "6.months.ago")
#   --until <date>                     Only commits before date
#   --branch <name>                    Target branch (default: current branch)
#   --format <format>                  Output format: hash|full|json (default: full)
#   --output <file>                    Output file (default: stdout)
#   --merge-commits                    Include merge commits (default: exclude)
#   --help                             Show this help message
#
# Filtering Logic:
#   - If --include-keywords is set: Only commits containing these keywords
#   - If --include-keywords is not set: All commits except --exclude-types
#   - Merge commits are excluded by default unless --merge-commits is specified
#
# Examples:
#   # Get all fix commits from last 6 months
#   commit-filter.sh --include-keywords "fix,bug,hotfix" --since 6.months.ago
#
#   # Get all commits except feat/docs/chore
#   commit-filter.sh --exclude-types "feat,docs,chore"
#
#   # Get commits in JSON format
#   commit-filter.sh --include-keywords "fix" --format json --output /tmp/commits.json
#

set -euo pipefail

# Default values
EXCLUDE_TYPES=""
INCLUDE_KEYWORDS=""
SINCE=""
UNTIL=""
BRANCH=""
FORMAT="full"
OUTPUT=""
MERGE_COMMITS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --exclude-types)
            EXCLUDE_TYPES="$2"
            shift 2
            ;;
        --include-keywords)
            INCLUDE_KEYWORDS="$2"
            shift 2
            ;;
        --since)
            SINCE="$2"
            shift 2
            ;;
        --until)
            UNTIL="$2"
            shift 2
            ;;
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --merge-commits)
            MERGE_COMMITS=true
            shift
            ;;
        --help)
            grep "^#" "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

# Validate format
if [[ ! "$FORMAT" =~ ^(hash|full|json)$ ]]; then
    echo "Error: Invalid format '$FORMAT'. Must be: hash, full, or json" >&2
    exit 1
fi

# Build git log command
GIT_CMD="git log"

# Add branch/reference
if [[ -n "$BRANCH" ]]; then
    GIT_CMD="$GIT_CMD $BRANCH"
fi

# Add time range
if [[ -n "$SINCE" ]]; then
    GIT_CMD="$GIT_CMD --since='$SINCE'"
fi

if [[ -n "$UNTIL" ]]; then
    GIT_CMD="$GIT_CMD --until='$UNTIL'"
fi

# Exclude merge commits by default
if [[ "$MERGE_COMMITS" == false ]]; then
    GIT_CMD="$GIT_CMD --no-merges"
fi

# Set format based on output type
case "$FORMAT" in
    hash)
        GIT_CMD="$GIT_CMD --format=%H"
        ;;
    full)
        GIT_CMD="$GIT_CMD --format=%H|%an|%ae|%ad|%s"
        GIT_CMD="$GIT_CMD --date=iso"
        ;;
    json)
        # JSON format for structured output
        GIT_CMD="$GIT_CMD --format={\"hash\":\"%H\",\"author\":\"%an\",\"email\":\"%ae\",\"date\":\"%ad\",\"subject\":\"%s\",\"body\":\"%b\"}"
        GIT_CMD="$GIT_CMD --date=iso-strict"
        ;;
esac

# Execute git log and capture output
RAW_OUTPUT=$(eval "$GIT_CMD" 2>/dev/null || echo "")

if [[ -z "$RAW_OUTPUT" ]]; then
    # No commits found
    if [[ "$FORMAT" == "json" ]]; then
        echo "[]"
    fi
    exit 0
fi

# Filter commits based on include/exclude logic
FILTERED_OUTPUT=""

if [[ -n "$INCLUDE_KEYWORDS" ]]; then
    # Include mode: only commits with keywords
    IFS=',' read -ra KEYWORDS <<< "$INCLUDE_KEYWORDS"

    while IFS= read -r line; do
        # Check if line contains any keyword (case-insensitive)
        for keyword in "${KEYWORDS[@]}"; do
            keyword=$(echo "$keyword" | xargs) # trim whitespace
            if echo "$line" | grep -iq "$keyword"; then
                FILTERED_OUTPUT+="$line"$'\n'
                break
            fi
        done
    done <<< "$RAW_OUTPUT"
else
    # Exclude mode: exclude commits with certain types
    if [[ -n "$EXCLUDE_TYPES" ]]; then
        IFS=',' read -ra TYPES <<< "$EXCLUDE_TYPES"

        while IFS= read -r line; do
            # Extract commit subject (last field in full format, or subject in JSON)
            should_exclude=false

            for type in "${TYPES[@]}"; do
                type=$(echo "$type" | xargs) # trim whitespace
                # Check if commit subject starts with type: (conventional commits)
                if echo "$line" | grep -iE "(^|\{[^}]*\"subject\":\")[[:space:]]*${type}[:(]" > /dev/null; then
                    should_exclude=true
                    break
                fi
            done

            if [[ "$should_exclude" == false ]]; then
                FILTERED_OUTPUT+="$line"$'\n'
            fi
        done <<< "$RAW_OUTPUT"
    else
        # No filtering, use all output
        FILTERED_OUTPUT="$RAW_OUTPUT"
    fi
fi

# Remove trailing newline
FILTERED_OUTPUT=$(echo -n "$FILTERED_OUTPUT")

# Format output for JSON (wrap in array)
if [[ "$FORMAT" == "json" && -n "$FILTERED_OUTPUT" ]]; then
    # Remove empty lines and wrap in array
    FILTERED_OUTPUT=$(echo "$FILTERED_OUTPUT" | grep -v '^$' | sed '1s/^/[/; $!s/$/,/; $s/$/]/')
fi

# Output results
if [[ -n "$OUTPUT" ]]; then
    echo "$FILTERED_OUTPUT" > "$OUTPUT"
else
    echo "$FILTERED_OUTPUT"
fi

# Exit with success
exit 0
