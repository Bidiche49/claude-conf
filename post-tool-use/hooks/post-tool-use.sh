#!/bin/bash
# ── post-tool-use — PostToolUse hook ─────────────────────────────
# Two functions:
# 1. Manifest: logs every Write/Edit file path to a per-session manifest
# 2. Test failure detection: warns when a test command exits non-zero
#
# Input: JSON on stdin with tool_name, tool_input, tool_result, session_id
# Output: warning message on stdout (test failure) or silent exit 0

# Skip if module is disabled
grep -q "^post-tool-use$" "$HOME/.claude-conf-disabled" 2>/dev/null && exit 0

# Read stdin (hook JSON input)
INPUT=$(cat)

# Extract tool_name
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# ── A. Manifest (Write/Edit) ────────────────────────────────────

if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
    # Extract fields
    FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
    SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

    # No session = skip
    [ -z "$SESSION_ID" ] && exit 0
    [ -z "$FILE_PATH" ] && exit 0

    # Ensure manifest directory exists
    MANIFEST_DIR=".claude-sessions/manifests"
    mkdir -p "$MANIFEST_DIR"

    # Append entry — direct printf, no jq needed
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S")
    OP=$(printf '%s' "$TOOL_NAME" | tr '[:lower:]' '[:upper:]')
    printf '%s %s %s\n' "$TIMESTAMP" "$OP" "$FILE_PATH" >> "${MANIFEST_DIR}/${SESSION_ID}.txt"

    # Rotation: keep only the 35 most recent manifests
    # shellcheck disable=SC2012
    ls -t "${MANIFEST_DIR}"/*.txt 2>/dev/null | tail -n +36 | xargs rm -f 2>/dev/null

    exit 0
fi

# ── B. Test failure detection (Bash) ─────────────────────────────

if [ "$TOOL_NAME" = "Bash" ]; then
    # Extract command
    COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
    [ -z "$COMMAND" ] && exit 0

    # Check if command matches a test runner pattern
    if ! printf '%s' "$COMMAND" | grep -qE '(^|\s|/)(test|pytest|jest|vitest|bun test|flutter test|cargo test|go test|rspec|phpunit|make test)(\s|$|;|\|)'; then
        exit 0
    fi

    # Extract exit code — try both exitCode and exit_code
    EXIT_CODE=$(printf '%s' "$INPUT" | jq -r '.tool_result.exitCode // .tool_result.exit_code // empty' 2>/dev/null)
    [ -z "$EXIT_CODE" ] && exit 0

    # Non-zero = test failure
    if [ "$EXIT_CODE" != "0" ]; then
        echo "[TEST-FAILURE] Tests failed (exit code: ${EXIT_CODE}). Investigate before continuing."
    fi

    exit 0
fi

# ── C. All other tools — pass-through ────────────────────────────

exit 0
