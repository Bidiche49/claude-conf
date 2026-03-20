#!/bin/bash
# Hook PreToolUse (matcher: "Bash") — Reminder to run /check before git commit
# Generic hook: detects stack via project files, always exits 0 (reminder, never blocking)

set -e

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only activate on git commit
if ! echo "$command" | grep -qE '^\s*git\s+commit'; then
    exit 0
fi

cwd=$(echo "$input" | jq -r '.cwd // empty')

# Detect stack via project files
stack=""
if [ -f "$cwd/package.json" ]; then
    stack="Node/JS/TS"
elif [ -f "$cwd/pubspec.yaml" ]; then
    stack="Flutter/Dart"
elif [ -f "$cwd/composer.json" ]; then
    stack="PHP/Laravel"
elif ls "$cwd"/*.xcodeproj 1>/dev/null 2>&1 || [ -f "$cwd/Package.swift" ]; then
    stack="iOS/Swift"
elif [ -f "$cwd/go.mod" ]; then
    stack="Go"
elif [ -f "$cwd/Cargo.toml" ]; then
    stack="Rust"
elif [ -f "$cwd/pyproject.toml" ] || [ -f "$cwd/requirements.txt" ]; then
    stack="Python"
elif [ -f "$cwd/Gemfile" ]; then
    stack="Ruby"
elif [ -f "$cwd/Makefile" ]; then
    stack="Make"
fi

if [ -n "$stack" ]; then
    echo "REMINDER: Run /check before committing — it validates lint, build, and tests for your stack ($stack)."
else
    echo "REMINDER: Before committing, make sure tests pass and code is clean."
fi

exit 0
