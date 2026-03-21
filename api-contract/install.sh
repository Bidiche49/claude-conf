#!/bin/bash
# ── api-contract — Installer ────────────────────────────────────
# Installs the api-contract hook and commands for Claude Code
#
# Usage: bash install.sh

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
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
HOOK_FILE="$HOOKS_DIR/api-contract-reminder.sh"

# ── Banner ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │       ${BLUE}api-contract${NC}${BOLD}                      │${NC}"
echo -e "${BOLD}  │   ${DIM}API contract management for split projects${NC}${BOLD} │${NC}"
echo -e "${BOLD}  └─────────────────────────────────────────┘${NC}"
echo ""

# ── 1. Check dependencies ───────────────────────────────────────

echo -e "${BLUE}[1/4]${NC} Checking dependencies..."

if ! command -v claude &>/dev/null; then
    echo -e "${RED}  ✗ Claude Code not found.${NC}"
    echo -e "    Install it first: ${DIM}npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓${NC} Claude Code available"

if ! command -v jq &>/dev/null; then
    echo -e "${RED}  ✗ jq not found.${NC}"
    echo -e "    Install it: ${DIM}brew install jq${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓${NC} jq available"

# ── 2. Install hook ─────────────────────────────────────────────

echo -e "${BLUE}[2/4]${NC} Installing hook..."

mkdir -p "$HOOKS_DIR"

if [ ! -f "$SCRIPT_DIR/hooks/api-contract-reminder.sh" ]; then
    echo -e "${RED}  ✗ Source file not found: hooks/api-contract-reminder.sh${NC}"
    exit 1
fi

if [ -f "$HOOK_FILE" ]; then
    cp "$HOOK_FILE" "$HOOK_FILE.backup.$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}  !${NC} Existing hook backed up"
fi

cp "$SCRIPT_DIR/hooks/api-contract-reminder.sh" "$HOOK_FILE"
chmod +x "$HOOK_FILE"
echo -e "${GREEN}  ✓${NC} Hook installed in ${DIM}${HOOK_FILE}${NC}"

# ── 3. Install commands ─────────────────────────────────────────

echo -e "${BLUE}[3/4]${NC} Installing commands..."

mkdir -p "$COMMANDS_DIR"

for cmd_file in api-contract-init.md api-contract-sync.md; do
    if [ ! -f "$SCRIPT_DIR/commands/$cmd_file" ]; then
        echo -e "${RED}  ✗ Source file not found: commands/$cmd_file${NC}"
        exit 1
    fi

    if [ -f "$COMMANDS_DIR/$cmd_file" ]; then
        cp "$COMMANDS_DIR/$cmd_file" "$COMMANDS_DIR/$cmd_file.backup.$(date +%Y%m%d%H%M%S)"
        echo -e "${YELLOW}  !${NC} Existing $cmd_file backed up"
    fi

    cp "$SCRIPT_DIR/commands/$cmd_file" "$COMMANDS_DIR/$cmd_file"
    echo -e "${GREEN}  ✓${NC} /${cmd_file%.md} installed"
done

# ── 4. Configure settings.json ──────────────────────────────────

echo -e "${BLUE}[4/4]${NC} Configuring Claude Code hook..."

mkdir -p "$(dirname "$SETTINGS_FILE")"

HOOK_ENTRY=$(cat <<JSONEOF
{
  "matcher": "Edit|Write",
  "hooks": [
    {
      "type": "command",
      "command": "$HOOK_FILE"
    }
  ]
}
JSONEOF
)

if [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d%H%M%S)"

    CURRENT=$(cat "$SETTINGS_FILE")
    HAS_POST_TOOL_USE=$(echo "$CURRENT" | jq 'has("hooks") and (.hooks | has("PostToolUse"))' 2>/dev/null)

    if [ "$HAS_POST_TOOL_USE" = "true" ]; then
        ALREADY_INSTALLED=$(echo "$CURRENT" | jq --arg cmd "$HOOK_FILE" '
            .hooks.PostToolUse[]? |
            select(.hooks[]?.command == $cmd) |
            length > 0
        ' 2>/dev/null)

        if [ -n "$ALREADY_INSTALLED" ] && [ "$ALREADY_INSTALLED" != "false" ]; then
            echo -e "${YELLOW}  SKIP${NC} Hook already configured in settings.json"
        else
            UPDATED=$(echo "$CURRENT" | jq --argjson entry "$HOOK_ENTRY" '
                .hooks.PostToolUse += [$entry]
            ')
            echo "$UPDATED" > "$SETTINGS_FILE"
            echo -e "${GREEN}  ✓${NC} Hook added to existing PostToolUse array"
        fi
    else
        UPDATED=$(echo "$CURRENT" | jq --argjson entry "$HOOK_ENTRY" '
            .hooks = (.hooks // {}) |
            .hooks.PostToolUse = ((.hooks.PostToolUse // []) + [$entry])
        ')
        echo "$UPDATED" > "$SETTINGS_FILE"
        echo -e "${GREEN}  ✓${NC} PostToolUse hook section created"
    fi
else
    jq -n --argjson entry "$HOOK_ENTRY" '{
        "hooks": {
            "PostToolUse": [$entry]
        }
    }' > "$SETTINGS_FILE"
    echo -e "${GREEN}  ✓${NC} Created ${DIM}${SETTINGS_FILE}${NC}"
fi

# ── Done ─────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}What it does:${NC}"
echo -e "    ${DIM}When Claude edits a controller, route, or DTO file, the hook reminds${NC}"
echo -e "    ${DIM}you to update API_CONTRACT.md and its Changelog.${NC}"
echo ""
echo -e "  ${BOLD}Commands:${NC}"
echo -e "    ${BOLD}/api-contract-init${NC}  — Generate API_CONTRACT.md from existing code"
echo -e "    ${BOLD}/api-contract-sync${NC}  — Check contract vs code for drift"
echo ""
echo -e "  ${BOLD}Supported stacks:${NC}"
echo -e "    ${DIM}NestJS, Express, Fastify, CakePHP, Laravel, Django, FastAPI, Go, Rust, Rails${NC}"
echo ""
echo -e "  ${YELLOW}Restart Claude Code for changes to take effect.${NC}"
echo ""
