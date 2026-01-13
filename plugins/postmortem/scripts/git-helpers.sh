#!/bin/bash
#
# git-helpers.sh - Common git operations for postmortem plugin
#
# This script provides utility functions for git operations.
# Source this file to use the functions in other scripts.
#
# Usage:
#   source git-helpers.sh
#   get_commit_info <commit-hash>
#   get_commit_diff <commit-hash>
#   ...
#
# Or run directly:
#   git-helpers.sh <function-name> [args...]
#

set -euo pipefail

# Get full commit information in JSON format
# Usage: get_commit_info <commit-hash>
get_commit_info() {
    local commit="$1"

    if ! git rev-parse "$commit" >/dev/null 2>&1; then
        echo "{\"error\": \"Commit not found\"}" >&2
        return 1
    fi

    local hash=$(git rev-parse "$commit")
    local short_hash=$(git rev-parse --short "$commit")
    local author=$(git show -s --format=%an "$commit")
    local email=$(git show -s --format=%ae "$commit")
    local date=$(git show -s --format=%ad --date=iso-strict "$commit")
    local subject=$(git show -s --format=%s "$commit" | sed 's/"/\\"/g')
    local body=$(git show -s --format=%b "$commit" | sed 's/"/\\"/g' | tr '\n' ' ')
    local files_changed=$(git show --stat --format="" "$commit" | wc -l | xargs)

    cat <<EOF
{
  "hash": "$hash",
  "short_hash": "$short_hash",
  "author": "$author",
  "email": "$email",
  "date": "$date",
  "subject": "$subject",
  "body": "$body",
  "files_changed": $files_changed
}
EOF
}

# Get commit diff
# Usage: get_commit_diff <commit-hash> [--stat|--name-only|--full]
get_commit_diff() {
    local commit="$1"
    local mode="${2:---full}"

    if ! git rev-parse "$commit" >/dev/null 2>&1; then
        echo "Error: Commit not found" >&2
        return 1
    fi

    case "$mode" in
        --stat)
            git show --stat --format="" "$commit"
            ;;
        --name-only)
            git show --name-only --format="" "$commit"
            ;;
        --full)
            git show "$commit"
            ;;
        *)
            echo "Error: Invalid mode '$mode'. Use --stat, --name-only, or --full" >&2
            return 1
            ;;
    esac
}

# Get list of files changed in commit
# Usage: get_changed_files <commit-hash>
get_changed_files() {
    local commit="$1"

    if ! git rev-parse "$commit" >/dev/null 2>&1; then
        echo "Error: Commit not found" >&2
        return 1
    fi

    git show --name-only --format="" "$commit"
}

# Check if commit is a merge commit
# Usage: is_merge_commit <commit-hash>
# Returns: 0 if merge commit, 1 otherwise
is_merge_commit() {
    local commit="$1"

    if ! git rev-parse "$commit" >/dev/null 2>&1; then
        return 1
    fi

    local parents=$(git rev-parse "$commit^@" 2>/dev/null | wc -l)
    [[ $parents -gt 1 ]]
}

# Get merge commit conflict resolution
# Usage: get_merge_conflicts <commit-hash>
get_merge_conflicts() {
    local commit="$1"

    if ! is_merge_commit "$commit"; then
        echo "Error: Not a merge commit" >&2
        return 1
    fi

    # Show what was changed in the merge compared to first parent
    git show "$commit" --cc
}

# Get commit message components (type, scope, subject)
# Parses conventional commit format: type(scope): subject
# Usage: parse_commit_message <commit-hash>
parse_commit_message() {
    local commit="$1"
    local subject=$(git show -s --format=%s "$commit")

    # Try to match conventional commit format
    local pattern='^([a-z]+)(\(([^)]+)\))?:[[:space:]](.+)$'
    if [[ "$subject" =~ $pattern ]]; then
        local type="${BASH_REMATCH[1]}"
        local scope="${BASH_REMATCH[3]}"
        local message="${BASH_REMATCH[4]}"

        cat <<EOF
{
  "type": "$type",
  "scope": "$scope",
  "message": "$message",
  "raw": "$subject"
}
EOF
    else
        cat <<EOF
{
  "type": "",
  "scope": "",
  "message": "$subject",
  "raw": "$subject"
}
EOF
    fi
}

# Get commits between two refs
# Usage: get_commits_between <from-ref> <to-ref> [--format=json|hash|full]
get_commits_between() {
    local from="$1"
    local to="$2"
    local format="${3:---format=hash}"

    if ! git rev-parse "$from" >/dev/null 2>&1; then
        echo "Error: Invalid ref '$from'" >&2
        return 1
    fi

    if ! git rev-parse "$to" >/dev/null 2>&1; then
        echo "Error: Invalid ref '$to'" >&2
        return 1
    fi

    case "$format" in
        --format=hash)
            git log --format=%H "$from..$to"
            ;;
        --format=json)
            git log --format='{"hash":"%H","date":"%ad","subject":"%s"}' --date=iso-strict "$from..$to"
            ;;
        --format=full)
            git log "$from..$to"
            ;;
        *)
            echo "Error: Invalid format '$format'" >&2
            return 1
            ;;
    esac
}

# Get current branch name
# Usage: get_current_branch
get_current_branch() {
    git branch --show-current
}

# Get uncommitted changes
# Usage: get_uncommitted_changes [--stat|--name-only|--full]
get_uncommitted_changes() {
    local mode="${1:---full}"

    case "$mode" in
        --stat)
            git diff --stat
            ;;
        --name-only)
            git diff --name-only
            ;;
        --full)
            git diff
            ;;
        *)
            echo "Error: Invalid mode '$mode'" >&2
            return 1
            ;;
    esac
}

# Check if working directory is clean
# Usage: is_working_dir_clean
# Returns: 0 if clean, 1 if dirty
is_working_dir_clean() {
    [[ -z $(git status --porcelain) ]]
}

# Get file content at specific commit
# Usage: get_file_at_commit <commit-hash> <file-path>
get_file_at_commit() {
    local commit="$1"
    local file="$2"

    if ! git rev-parse "$commit" >/dev/null 2>&1; then
        echo "Error: Commit not found" >&2
        return 1
    fi

    git show "$commit:$file" 2>/dev/null || {
        echo "Error: File not found in commit" >&2
        return 1
    }
}

# Main: Allow running functions directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <function-name> [args...]" >&2
        echo "" >&2
        echo "Available functions:" >&2
        echo "  get_commit_info <commit>" >&2
        echo "  get_commit_diff <commit> [--stat|--name-only|--full]" >&2
        echo "  get_changed_files <commit>" >&2
        echo "  is_merge_commit <commit>" >&2
        echo "  get_merge_conflicts <commit>" >&2
        echo "  parse_commit_message <commit>" >&2
        echo "  get_commits_between <from> <to> [--format=json|hash|full]" >&2
        echo "  get_current_branch" >&2
        echo "  get_uncommitted_changes [--stat|--name-only|--full]" >&2
        echo "  is_working_dir_clean" >&2
        echo "  get_file_at_commit <commit> <file>" >&2
        exit 1
    fi

    FUNCTION="$1"
    shift

    if declare -f "$FUNCTION" > /dev/null; then
        "$FUNCTION" "$@"
    else
        echo "Error: Unknown function '$FUNCTION'" >&2
        exit 1
    fi
fi
