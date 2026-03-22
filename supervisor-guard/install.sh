#!/bin/bash
# ── supervisor-guard — Installer ─────────────────────────────────
# Installs the supervisor-guard PreToolUse hook for Claude Code
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
HOOK_COMMAND="$HOOK_DIR/supervisor-guard.sh"

# ── Banner ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │         ${BLUE}supervisor-guard${NC}${BOLD}                    │${NC}"
echo -e "${BOLD}  │   ${DIM}Supervisor write guard for Claude Code${NC}${BOLD}     │${NC}"
echo -e "${BOLD}  └─────────────────────────────────────────────┘${NC}"
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

echo -e "  ${BOLD}Installing supervisor-guard...${NC}"
echo ""

mkdir -p "$HOOK_DIR"

cp "$SCRIPT_DIR/hooks/supervisor-guard.sh" "$HOOK_COMMAND"
chmod +x "$HOOK_COMMAND"

echo -e "  ${GREEN}OK${NC} Hook installed to ${DIM}${HOOK_COMMAND}${NC}"

# ── Create marker directory ──────────────────────────────────────

mkdir -p ".claude-sessions/supervisor-active"
echo -e "  ${GREEN}OK${NC} Marker directory ready ${DIM}(.claude-sessions/supervisor-active/)${NC}"

# ── Configure Claude Code hook ───────────────────────────────────

echo ""
echo -e "  ${BOLD}Configuring Claude Code hook...${NC}"
echo ""

mkdir -p "$(dirname "$SETTINGS_FILE")"

# Hook entry — matches Write and Edit tools
HOOK_ENTRY_WRITE=$(cat <<JSONEOF
{
  "matcher": "Write",
  "hooks": [
    {
      "type": "command",
      "command": "$HOOK_COMMAND"
    }
  ]
}
JSONEOF
)

HOOK_ENTRY_EDIT=$(cat <<JSONEOF
{
  "matcher": "Edit",
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

    HAS_PRE_TOOL_USE=$(echo "$CURRENT" | jq 'has("hooks") and (.hooks | has("PreToolUse"))' 2>/dev/null)

    if [ "$HAS_PRE_TOOL_USE" = "true" ]; then
        # Check if supervisor-guard hook is already present
        ALREADY_INSTALLED=$(echo "$CURRENT" | jq --arg cmd "$HOOK_COMMAND" '
            [.hooks.PreToolUse[]? | select(.hooks[]?.command == $cmd)] | length > 0
        ' 2>/dev/null)

        if [ "$ALREADY_INSTALLED" = "true" ]; then
            echo -e "  ${YELLOW}SKIP${NC} Hook already configured in settings.json"
        else
            # Append both matchers to existing PreToolUse array
            UPDATED=$(echo "$CURRENT" | jq \
                --argjson write "$HOOK_ENTRY_WRITE" \
                --argjson edit "$HOOK_ENTRY_EDIT" '
                .hooks.PreToolUse += [$write, $edit]
            ')
            echo "$UPDATED" > "$SETTINGS_FILE"
            echo -e "  ${GREEN}OK${NC} Hook added to existing PreToolUse array (Write + Edit matchers)"
        fi
    else
        # Add hooks.PreToolUse section
        UPDATED=$(echo "$CURRENT" | jq \
            --argjson write "$HOOK_ENTRY_WRITE" \
            --argjson edit "$HOOK_ENTRY_EDIT" '
            .hooks = (.hooks // {}) |
            .hooks.PreToolUse = [$write, $edit]
        ')
        echo "$UPDATED" > "$SETTINGS_FILE"
        echo -e "  ${GREEN}OK${NC} PreToolUse hook section created"
    fi
else
    # No settings file — create one
    jq -n \
        --argjson write "$HOOK_ENTRY_WRITE" \
        --argjson edit "$HOOK_ENTRY_EDIT" '{
        "hooks": {
            "PreToolUse": [$write, $edit]
        }
    }' > "$SETTINGS_FILE"
    echo -e "  ${GREEN}OK${NC} Created ${DIM}${SETTINGS_FILE}${NC}"
fi

# ── Summary ──────────────────────────────────────────────────────

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Installation complete${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}Installed to:${NC}  ${DIM}${HOOK_COMMAND}${NC}"
echo -e "  ${BOLD}Settings:${NC}      ${DIM}${SETTINGS_FILE}${NC}"
echo -e "  ${BOLD}Marker dir:${NC}    ${DIM}.claude-sessions/supervisor-active/${NC}"
echo ""
echo -e "  ${BOLD}What happens now:${NC}"
echo -e "  ${DIM}When a supervisor session creates its marker file,${NC}"
echo -e "  ${DIM}the hook blocks any Write/Edit on files outside the whitelist.${NC}"
echo -e "  ${DIM}Without a marker, the hook is fully transparent.${NC}"
echo ""
echo -e "  ${BOLD}Whitelist:${NC}"
echo -e "  ${DIM}  BACKLOG/**${NC}"
echo -e "  ${DIM}  .claude-sessions/**${NC}"
echo -e "  ${DIM}  **/INDEX.md${NC}"
echo ""
echo -e "  ${BOLD}Disable:${NC}"
echo -e "  ${DIM}echo 'supervisor-guard' >> ~/.claude-conf-disabled${NC}"
echo ""
echo -e "  ${YELLOW}Restart Claude Code for changes to take effect.${NC}"
echo ""
