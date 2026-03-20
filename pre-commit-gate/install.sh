#!/bin/bash
# ── pre-commit-gate — Installer ─────────────────────────────────
# Installs the pre-commit-gate hook and /check command for Claude Code
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
HOOK_COMMAND="$HOOKS_DIR/pre-commit-gate.sh"

# ── Banner ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │       ${RED}pre-commit-gate${NC}${BOLD}                  │${NC}"
echo -e "${BOLD}  │   ${DIM}Reminder to /check before committing${NC}${BOLD}  │${NC}"
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

if [ ! -f "$SCRIPT_DIR/hooks/pre-commit-gate.sh" ]; then
    echo -e "${RED}  ✗ Source file not found: hooks/pre-commit-gate.sh${NC}"
    exit 1
fi

if [ -f "$HOOK_COMMAND" ]; then
    cp "$HOOK_COMMAND" "$HOOK_COMMAND.backup.$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}  !${NC} Existing hook backed up"
fi

cp "$SCRIPT_DIR/hooks/pre-commit-gate.sh" "$HOOK_COMMAND"
chmod +x "$HOOK_COMMAND"
echo -e "${GREEN}  ✓${NC} Hook installed in ${DIM}${HOOK_COMMAND}${NC}"

# ── 3. Install /check command ───────────────────────────────────

echo -e "${BLUE}[3/4]${NC} Installing /check command..."

mkdir -p "$COMMANDS_DIR"

if [ ! -f "$SCRIPT_DIR/commands/check.md" ]; then
    echo -e "${RED}  ✗ Source file not found: commands/check.md${NC}"
    exit 1
fi

if [ -f "$COMMANDS_DIR/check.md" ]; then
    cp "$COMMANDS_DIR/check.md" "$COMMANDS_DIR/check.md.backup.$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}  !${NC} Existing command backed up"
fi

cp "$SCRIPT_DIR/commands/check.md" "$COMMANDS_DIR/check.md"
echo -e "${GREEN}  ✓${NC} Command installed in ${DIM}${COMMANDS_DIR}/check.md${NC}"

# ── 4. Configure settings.json ──────────────────────────────────

echo -e "${BLUE}[4/4]${NC} Configuring Claude Code hook..."

mkdir -p "$(dirname "$SETTINGS_FILE")"

HOOK_ENTRY=$(cat <<JSONEOF
{
  "matcher": "Bash",
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
    # Backup existing settings
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d%H%M%S)"

    CURRENT=$(cat "$SETTINGS_FILE")
    HAS_PRE_TOOL_USE=$(echo "$CURRENT" | jq 'has("hooks") and (.hooks | has("PreToolUse"))' 2>/dev/null)

    if [ "$HAS_PRE_TOOL_USE" = "true" ]; then
        # Check if hook is already present
        ALREADY_INSTALLED=$(echo "$CURRENT" | jq --arg cmd "$HOOK_COMMAND" '
            .hooks.PreToolUse[]? |
            select(.hooks[]?.command == $cmd) |
            length > 0
        ' 2>/dev/null)

        if [ -n "$ALREADY_INSTALLED" ] && [ "$ALREADY_INSTALLED" != "false" ]; then
            echo -e "${YELLOW}  SKIP${NC} Hook already configured in settings.json"
        else
            UPDATED=$(echo "$CURRENT" | jq --argjson entry "$HOOK_ENTRY" '
                .hooks.PreToolUse += [$entry]
            ')
            echo "$UPDATED" > "$SETTINGS_FILE"
            echo -e "${GREEN}  ✓${NC} Hook added to existing PreToolUse array"
        fi
    else
        UPDATED=$(echo "$CURRENT" | jq --argjson entry "$HOOK_ENTRY" '
            .hooks = (.hooks // {}) |
            .hooks.PreToolUse = [$entry]
        ')
        echo "$UPDATED" > "$SETTINGS_FILE"
        echo -e "${GREEN}  ✓${NC} PreToolUse hook section created"
    fi
else
    jq -n --argjson entry "$HOOK_ENTRY" '{
        "hooks": {
            "PreToolUse": [$entry]
        }
    }' > "$SETTINGS_FILE"
    echo -e "${GREEN}  ✓${NC} Created ${DIM}${SETTINGS_FILE}${NC}"
fi

# ── Done ─────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}What it does:${NC}"
echo -e "    ${DIM}When Claude runs git commit, the hook reminds you to run /check first.${NC}"
echo -e "    ${DIM}/check detects your stack and runs lint + build + tests automatically.${NC}"
echo ""
echo -e "  ${BOLD}Usage:${NC}"
echo -e "    In any Claude Code session, type: ${BOLD}/check${NC}"
echo ""
echo -e "  ${BOLD}Works best with:${NC}"
echo -e "    ${DIM}command-guard${NC} — shell command validator for Claude Code"
echo ""
echo -e "  ${YELLOW}Restart Claude Code for changes to take effect.${NC}"
echo ""
