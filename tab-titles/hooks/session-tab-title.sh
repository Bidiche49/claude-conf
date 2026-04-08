#!/bin/bash
# Hook SessionStart — Re-applies tab/window title after Claude Code startup
# On resume/compact: reads persisted state file to restore the correct title
# On startup: uses CC_TAB_TITLE/CC_WIN_TITLE env vars from launcher functions

# Skip if module is disabled
grep -q "^tab-titles$" "$HOME/.claude-conf-disabled" 2>/dev/null && exit 0

# Read JSON stdin
INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
SOURCE=$(echo "$INPUT" | jq -r '.source // empty' 2>/dev/null)

# Couleur unique par projet (hash du nom) — same logic as tab-title.sh
_dot() {
    if [ "$1" = "claude-conf" ]; then echo "⚙️"; return; fi
    local colors=("🟠" "🟡" "🔵" "🟣" "🟤" "⚫")
    local idx=$(( $(echo -n "$1" | cksum | cut -d' ' -f1) % 6 ))
    echo "${colors[$idx]}"
}

if [ "$SOURCE" = "resume" ] || [ "$SOURCE" = "compact" ]; then
    # Restore title from persisted state file
    PROJECT_ROOT=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)
    PROJECT=$(basename "$PWD")
    DOT=$(_dot "$PROJECT")

    STATE=""
    if [ -n "$SESSION_ID" ] && [ -n "$PROJECT_ROOT" ]; then
        STATE_FILE="${PROJECT_ROOT}/.claude-sessions/tab-state/${SESSION_ID}"
        if [ -f "$STATE_FILE" ]; then
            STATE=$(cat "$STATE_FILE")
        fi
    fi

    if [ -n "$STATE" ]; then
        case "$STATE" in
            SUP)
                TAB_TITLE="🔴 SUP"
                ;;
            BIZ)
                TAB_TITLE="⚪ BIZ"
                ;;
            WORK:*:*)
                TICKET=$(echo "$STATE" | cut -d: -f2)
                CTX=$(echo "$STATE" | cut -d: -f3-)
                TAB_TITLE="🟢 ${TICKET} ${CTX}"
                ;;
            WORK:*)
                TICKET="${STATE#WORK:}"
                TAB_TITLE="🟢 ${TICKET}"
                ;;
            *)
                TAB_TITLE="${DOT} CC"
                ;;
        esac

        printf "\033]1;%s\007" "$TAB_TITLE" > /dev/tty 2>/dev/null
        printf "\033]2;%s %s\007" "$DOT" "$PROJECT" > /dev/tty 2>/dev/null

        # Prevent Claude Code from overwriting the restored title
        if [ -n "$CLAUDE_ENV_FILE" ]; then
            echo 'export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1' >> "$CLAUDE_ENV_FILE"
        fi
    fi
else
    # Startup — re-apply titles from env vars (set by cc/ccd/ccs/ccw functions)
    if [ -n "$CC_TAB_TITLE" ]; then
        printf "\033]1;%s\007" "$CC_TAB_TITLE" > /dev/tty 2>/dev/null
    fi

    if [ -n "$CC_WIN_TITLE" ]; then
        printf "\033]2;%s\007" "$CC_WIN_TITLE" > /dev/tty 2>/dev/null
    fi
fi

exit 0
