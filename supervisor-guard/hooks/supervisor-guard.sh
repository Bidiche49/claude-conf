#!/bin/bash
set -e
# ── supervisor-guard — PreToolUse hook ────────────────────────────
# Blocks Write/Edit/Bash-write operations on files outside the supervisor
# whitelist when supervisor mode is active (marker file exists).
#
# The supervisor creates a marker at startup:
#   .claude-sessions/supervisor-active/{session_id}
#
# Whitelisted paths (supervisor can write to):
#   - BACKLOG/**
#   - .claude-sessions/**
#   - **/INDEX.md
#   - /tmp/** and /dev/** (Bash redirects only)
#
# Exit codes:
#   0 — allowed (pass-through)
#   2 — blocked (file outside supervisor whitelist)

# Skip if module is disabled
grep -q "^supervisor-guard$" "$HOME/.claude-conf-disabled" 2>/dev/null && exit 0

# Read stdin (hook JSON input)
INPUT=$(cat)

# Extract tool_name — enforce on Write, Edit, and Bash
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || true

case "$TOOL_NAME" in
    Write|Edit|Bash) ;;
    *) exit 0 ;;
esac

# Extract session_id — no session = pass-through
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null) || true
[ -z "$SESSION_ID" ] && exit 0

# Check supervisor marker — primary mechanism (set by supervisor-detect.sh hook)
MARKER=".claude-sessions/supervisor-active/${SESSION_ID}"
# Fallback: env var from launch script
if [ ! -f "$MARKER" ]; then
    [ "${CC_SUPERVISOR_SESSION:-}" = "1" ] || exit 0
fi

# Returns 0 if path is whitelisted, 1 if not
_is_whitelisted() {
    local path="${1#./}"
    case "$path" in
        BACKLOG/*|*/BACKLOG/*) return 0 ;;
        .claude-sessions/*) return 0 ;;
        */INDEX.md|INDEX.md) return 0 ;;
        /tmp/*|/dev/*) return 0 ;;
        *) return 1 ;;
    esac
}

# Emit block JSON and exit 2
_block() {
    local target="$1"
    cat <<BLOCKEOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"block","permissionDecisionReason":"Supervisor mode active — you cannot write source code. Generate a worker prompt instead. Attempted: ${target}"}}
BLOCKEOF
    exit 2
}

case "$TOOL_NAME" in
    Write|Edit)
        # Extract target file path from tool_input
        FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || true
        [ -z "$FILE_PATH" ] && exit 0

        # Normalize: strip leading ./ if present
        FILE_PATH="${FILE_PATH#./}"

        if _is_whitelisted "$FILE_PATH"; then
            exit 0
        fi
        _block "$FILE_PATH"
        ;;

    Bash)
        # Extract the command string
        COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || true
        [ -z "$COMMAND" ] && exit 0

        BLOCKED_TARGET=""

        # --- Redirect detection: > or >> not preceded by 2 or & ---
        # Extract targets from redirections
        redirect_targets=$(echo "$COMMAND" | grep -oE '(^|[^2&])>{1,2}\s*["'"'"']?[^ "'"'"';|&]+' | sed -E "s/^.*>+[[:space:]]*[\"']?//; s/[\"']$//" || true)

        # --- Command detection: tee, sed -i, cp, mv ---
        tee_targets=$(echo "$COMMAND" | grep -oE '\btee\s+(-[a-zA-Z]+\s+)*["'"'"']?[^ "'"'"';|&]+' | sed -E "s/^tee\s+(-[a-zA-Z]+\s+)*[\"']?//; s/[\"']$//" || true)
        sedi_targets=$(echo "$COMMAND" | grep -oE '\bsed\s+-i[^ ]*\s+[^ ]+\s+["'"'"']?[^ "'"'"';|&]+' | sed -E "s/^sed\s+-i[^ ]*\s+[^ ]+\s+[\"']?//; s/[\"']$//" || true)
        cp_targets=$(echo "$COMMAND" | grep -oE '\bcp\s+[^ ]+\s+["'"'"']?[^ "'"'"';|&]+' | sed -E "s/^cp\s+[^ ]+\s+[\"']?//; s/[\"']$//" || true)
        mv_targets=$(echo "$COMMAND" | grep -oE '\bmv\s+[^ ]+\s+["'"'"']?[^ "'"'"';|&]+' | sed -E "s/^mv\s+[^ ]+\s+[\"']?//; s/[\"']$//" || true)

        # Combine all targets
        all_targets=$(printf '%s\n' "$redirect_targets" "$tee_targets" "$sedi_targets" "$cp_targets" "$mv_targets" | sed '/^$/d')

        # No write targets detected → allow
        [ -z "$all_targets" ] && exit 0

        # Check each target against whitelist
        while IFS= read -r target; do
            [ -z "$target" ] && continue
            # Strip quotes that may remain
            target="${target%\"}"
            target="${target%\'}"
            target="${target#\"}"
            target="${target#\'}"
            target="${target#./}"
            if ! _is_whitelisted "$target"; then
                BLOCKED_TARGET="$target"
                break
            fi
        done <<< "$all_targets"

        if [ -n "$BLOCKED_TARGET" ]; then
            _block "$BLOCKED_TARGET"
        fi
        exit 0
        ;;
esac
