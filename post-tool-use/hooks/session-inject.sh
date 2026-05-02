#!/bin/bash
# ── post-tool-use:session-inject — SessionStart hook ──────────────
# Injects the worker's session_id + manifest path as additionalContext
# at session start. The worker then knows its manifest deterministically
# and never needs `ls -t` (which races with parallel workers and the
# supervisor's own manifest writes).
#
# Only fires when the launch script set CC_WORKER_TICKET. Normal,
# supervisor, and unrelated sessions get a silent pass-through.
#
# Input:  JSON on stdin (session_id, source, ...)
# Output: hookSpecificOutput.additionalContext (worker only)

# Skip if module is disabled
grep -q "^post-tool-use$" "$HOME/.claude-conf-disabled" 2>/dev/null && exit 0

# Only inject for worker sessions
[ -z "${CC_WORKER_TICKET:-}" ] && exit 0

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$SESSION_ID" ] && exit 0

# Skip resume/compact — the worker already saw the context once
SOURCE=$(printf '%s' "$INPUT" | jq -r '.source // empty' 2>/dev/null)
[ "$SOURCE" = "resume" ] && exit 0
[ "$SOURCE" = "compact" ] && exit 0

MANIFEST_PATH=".claude-sessions/manifests/${SESSION_ID}.txt"

CONTEXT="[WORKER SESSION CONTEXT — injected by post-tool-use:session-inject]
Ticket: ${CC_WORKER_TICKET}
Session ID: ${SESSION_ID}
Your manifest path: ${MANIFEST_PATH}

When you write the \"Manifest:\" field in your final report, use the
EXACT path above. Do NOT run \`ls -t .claude-sessions/manifests/\` —
that path races with parallel workers and the supervisor's own writes,
and consistently returns the wrong file."

jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'

exit 0
