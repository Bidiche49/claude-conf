#!/bin/bash
# command-guard wrapper — disabled check + pre-built bundle
# Saves startup time by using pre-built JS instead of TS source

# Skip if module is disabled
grep -q "^command-guard$" "$HOME/.claude-conf-disabled" 2>/dev/null && exit 0

# Forward stdin to the pre-built bundle (exec avoids extra subshell)
exec bun "$HOME/.claude/scripts/command-guard/dist/cli.js"
