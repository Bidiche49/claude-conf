#!/bin/bash
# ── post-tool-use — Installer ────────────────────────────────────
# Installs the post-tool-use PostToolUse hook for Claude Code
#
# Usage:
#   bash install.sh

set -e

# ── Colors ───────────────────────────────────────────────────────

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Paths ────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"
HOOK_COMMAND="$HOOK_DIR/post-tool-use.sh"
SESSION_INJECT_COMMAND="$HOOK_DIR/post-tool-use-session-inject.sh"

# ── Banner ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │         ${BLUE}post-tool-use${NC}${BOLD}                   │${NC}"
echo -e "${BOLD}  │   ${DIM}Manifest & test-failure detection hook${NC}${BOLD}  │${NC}"
echo -e "${BOLD}  └─────────────────────────────────────────┘${NC}"
echo ""

# ── Check dependencies ───────────────────────────────────────────

echo -e "  ${BOLD}Checking dependencies...${NC}"
echo ""

if ! command -v jq &> /dev/null; then
    echo -e "  ${RED}Error: jq is not installed.${NC}"
    echo -e "  ${DIM}Install it with: brew install jq${NC}"
    echo ""
    exit 1
fi

JQ_VERSION=$(jq --version 2>/dev/null)
echo -e "  ${GREEN}OK${NC} jq ${DIM}${JQ_VERSION}${NC}"
echo ""

# ── Install hook script ─────────────────────────────────────────

echo -e "  ${BOLD}Installing post-tool-use hook...${NC}"
echo ""

mkdir -p "$HOOK_DIR"

cp "$SCRIPT_DIR/hooks/post-tool-use.sh" "$HOOK_COMMAND"
chmod +x "$HOOK_COMMAND"

echo -e "  ${GREEN}OK${NC} Hook installed to ${DIM}${HOOK_COMMAND}${NC}"

cp "$SCRIPT_DIR/hooks/session-inject.sh" "$SESSION_INJECT_COMMAND"
chmod +x "$SESSION_INJECT_COMMAND"

echo -e "  ${GREEN}OK${NC} Hook installed to ${DIM}${SESSION_INJECT_COMMAND}${NC}"

# ── Create manifest directory ────────────────────────────────────

mkdir -p ".claude-sessions/manifests"
echo -e "  ${GREEN}OK${NC} Manifest directory ready ${DIM}(.claude-sessions/manifests/)${NC}"

# ── Configure Claude Code hook ───────────────────────────────────

echo ""
echo -e "  ${BOLD}Configuring Claude Code hook...${NC}"
echo ""

mkdir -p "$(dirname "$SETTINGS_FILE")"

# Hook entry — matches all tools (PostToolUse fires after every tool)
HOOK_ENTRY=$(cat <<JSONEOF
{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "command": "$HOOK_COMMAND"
    }
  ]
}
JSONEOF
)

if [ -f "$SETTINGS_FILE" ]; then
    CURRENT=$(cat "$SETTINGS_FILE")

    HAS_POST_TOOL_USE=$(echo "$CURRENT" | jq 'has("hooks") and (.hooks | has("PostToolUse"))' 2>/dev/null)

    if [ "$HAS_POST_TOOL_USE" = "true" ]; then
        # Check if post-tool-use hook is already present
        ALREADY_INSTALLED=$(echo "$CURRENT" | jq --arg cmd "$HOOK_COMMAND" '
            [.hooks.PostToolUse[]? | select(.hooks[]?.command == $cmd)] | length > 0
        ' 2>/dev/null)

        if [ "$ALREADY_INSTALLED" = "true" ]; then
            echo -e "  ${YELLOW}SKIP${NC} Hook already configured in settings.json"
        else
            # Append to existing PostToolUse array
            UPDATED=$(echo "$CURRENT" | jq \
                --argjson entry "$HOOK_ENTRY" '
                .hooks.PostToolUse += [$entry]
            ')
            echo "$UPDATED" > "$SETTINGS_FILE"
            echo -e "  ${GREEN}OK${NC} Hook added to existing PostToolUse array"
        fi
    else
        # Add hooks.PostToolUse section
        UPDATED=$(echo "$CURRENT" | jq \
            --argjson entry "$HOOK_ENTRY" '
            .hooks = (.hooks // {}) |
            .hooks.PostToolUse = [$entry]
        ')
        echo "$UPDATED" > "$SETTINGS_FILE"
        echo -e "  ${GREEN}OK${NC} PostToolUse hook section created"
    fi
else
    # No settings file — create one
    jq -n \
        --argjson entry "$HOOK_ENTRY" '{
        "hooks": {
            "PostToolUse": [$entry]
        }
    }' > "$SETTINGS_FILE"
    echo -e "  ${GREEN}OK${NC} Created ${DIM}${SETTINGS_FILE}${NC}"
fi

# ── Configure SessionStart hook (worker session-id injection) ────

SESSION_HOOK_ENTRY=$(cat <<JSONEOF
{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "command": "$SESSION_INJECT_COMMAND"
    }
  ]
}
JSONEOF
)

CURRENT=$(cat "$SETTINGS_FILE")
HAS_SESSION_START=$(echo "$CURRENT" | jq 'has("hooks") and (.hooks | has("SessionStart"))' 2>/dev/null)

if [ "$HAS_SESSION_START" = "true" ]; then
    ALREADY_INSTALLED=$(echo "$CURRENT" | jq --arg cmd "$SESSION_INJECT_COMMAND" '
        [.hooks.SessionStart[]? | select(.hooks[]?.command == $cmd)] | length > 0
    ' 2>/dev/null)

    if [ "$ALREADY_INSTALLED" = "true" ]; then
        echo -e "  ${YELLOW}SKIP${NC} session-inject already configured in settings.json"
    else
        UPDATED=$(echo "$CURRENT" | jq \
            --argjson entry "$SESSION_HOOK_ENTRY" '
            .hooks.SessionStart += [$entry]
        ')
        echo "$UPDATED" > "$SETTINGS_FILE"
        echo -e "  ${GREEN}OK${NC} session-inject added to existing SessionStart array"
    fi
else
    UPDATED=$(echo "$CURRENT" | jq \
        --argjson entry "$SESSION_HOOK_ENTRY" '
        .hooks = (.hooks // {}) |
        .hooks.SessionStart = [$entry]
    ')
    echo "$UPDATED" > "$SETTINGS_FILE"
    echo -e "  ${GREEN}OK${NC} SessionStart hook section created"
fi

# ── Summary ──────────────────────────────────────────────────────

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Installation complete${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}Installed to:${NC}     ${DIM}${HOOK_COMMAND}${NC}"
echo -e "  ${BOLD}Settings:${NC}         ${DIM}${SETTINGS_FILE}${NC}"
echo -e "  ${BOLD}Manifest dir:${NC}     ${DIM}.claude-sessions/manifests/${NC}"
echo ""
echo -e "  ${BOLD}What happens now:${NC}"
echo -e "  ${DIM}After every Write/Edit, the file path is logged to a session manifest.${NC}"
echo -e "  ${DIM}After every Bash test command that fails, a warning is emitted.${NC}"
echo -e "  ${DIM}At SessionStart, worker sessions (CC_WORKER_TICKET set) get their${NC}"
echo -e "  ${DIM}session_id and manifest path injected — no more guessing via ls -t.${NC}"
echo -e "  ${DIM}The supervisor uses manifests to verify worker reports.${NC}"
echo ""
echo -e "  ${BOLD}Disable:${NC}"
echo -e "  ${DIM}echo 'post-tool-use' >> ~/.claude-conf-disabled${NC}"
echo ""
echo -e "  ${YELLOW}Restart Claude Code for changes to take effect.${NC}"
echo ""
