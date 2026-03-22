#!/bin/bash
# ── command-guard — Installer ────────────────────────────────────
# Installs the command-guard hook for Claude Code
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
INSTALL_DIR="$HOME/.claude/scripts/command-guard"
SETTINGS_FILE="$HOME/.claude/settings.json"
HOOK_COMMAND="$HOME/.claude/hooks/command-guard-wrapper.sh"

# ── Banner ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │         ${RED}command-guard${NC}${BOLD}                   │${NC}"
echo -e "${BOLD}  │   ${DIM}Shell command validator for Claude Code${NC}${BOLD} │${NC}"
echo -e "${BOLD}  └─────────────────────────────────────────┘${NC}"
echo ""

# ── Check dependencies ───────────────────────────────────────────

echo -e "  ${BOLD}Checking dependencies...${NC}"
echo ""

if ! command -v bun &> /dev/null; then
    echo -e "  ${RED}Error: Bun is not installed.${NC}"
    echo -e "  ${DIM}Install it with: curl -fsSL https://bun.sh/install | bash${NC}"
    echo ""
    exit 1
fi

BUN_VERSION=$(bun --version 2>/dev/null)
echo -e "  ${GREEN}OK${NC} bun ${DIM}v${BUN_VERSION}${NC}"

if ! command -v jq &> /dev/null; then
    echo -e "  ${RED}Error: jq is not installed.${NC}"
    echo -e "  ${DIM}Install it with: brew install jq${NC}"
    echo ""
    exit 1
fi

JQ_VERSION=$(jq --version 2>/dev/null)
echo -e "  ${GREEN}OK${NC} jq ${DIM}${JQ_VERSION}${NC}"
echo ""

# ── Copy source files ────────────────────────────────────────────

echo -e "  ${BOLD}Installing command-guard...${NC}"
echo ""

# Create directories
mkdir -p "$INSTALL_DIR/src/lib"
mkdir -p "$INSTALL_DIR/src/__tests__"
mkdir -p "$INSTALL_DIR/data"

# Copy source files
cp "$SCRIPT_DIR/src/cli.ts" "$INSTALL_DIR/src/cli.ts"
cp "$SCRIPT_DIR/src/lib/validator.ts" "$INSTALL_DIR/src/lib/validator.ts"
cp "$SCRIPT_DIR/src/lib/types.ts" "$INSTALL_DIR/src/lib/types.ts"
cp "$SCRIPT_DIR/src/__tests__/validator.test.ts" "$INSTALL_DIR/src/__tests__/validator.test.ts"
cp "$SCRIPT_DIR/package.json" "$INSTALL_DIR/package.json"
cp "$SCRIPT_DIR/tsconfig.json" "$INSTALL_DIR/tsconfig.json"

echo -e "  ${GREEN}OK${NC} Source files copied to ${DIM}${INSTALL_DIR}${NC}"

# ── Pre-build for faster hook execution ─────────────────────

echo ""
echo -e "  ${BOLD}Building optimized bundle...${NC}"
mkdir -p "$INSTALL_DIR/dist"
(cd "$INSTALL_DIR" && bun build src/cli.ts --outfile dist/cli.js --target bun)
echo -e "  ${GREEN}OK${NC} Bundle built ${DIM}(dist/cli.js)${NC}"

# ── Install wrapper script ──────────────────────────────────

mkdir -p "$HOME/.claude/hooks"
cp "$SCRIPT_DIR/hooks/command-guard-wrapper.sh" "$HOME/.claude/hooks/command-guard-wrapper.sh"
chmod +x "$HOME/.claude/hooks/command-guard-wrapper.sh"
echo -e "  ${GREEN}OK${NC} Wrapper installed ${DIM}($HOME/.claude/hooks/command-guard-wrapper.sh)${NC}"

# ── Create data directory ────────────────────────────────────────

touch "$INSTALL_DIR/data/.gitkeep"
echo -e "  ${GREEN}OK${NC} Data directory ready ${DIM}(security logs go here)${NC}"

# ── Configure Claude Code hook ───────────────────────────────────

echo ""
echo -e "  ${BOLD}Configuring Claude Code hook...${NC}"
echo ""

# Create settings directory if needed
mkdir -p "$(dirname "$SETTINGS_FILE")"

# Build the hook entry
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
    # File exists — merge the hook
    CURRENT=$(cat "$SETTINGS_FILE")

    # Check if PreToolUse array exists
    HAS_PRE_TOOL_USE=$(echo "$CURRENT" | jq 'has("hooks") and (.hooks | has("PreToolUse"))' 2>/dev/null)

    if [ "$HAS_PRE_TOOL_USE" = "true" ]; then
        # Check if command-guard hook is already present
        ALREADY_INSTALLED=$(echo "$CURRENT" | jq --arg cmd "$HOOK_COMMAND" '
            .hooks.PreToolUse[]? |
            select(.hooks[]?.command == $cmd) |
            length > 0
        ' 2>/dev/null)

        if [ -n "$ALREADY_INSTALLED" ] && [ "$ALREADY_INSTALLED" != "false" ]; then
            echo -e "  ${YELLOW}SKIP${NC} Hook already configured in settings.json"
        else
            # Append to existing PreToolUse array
            UPDATED=$(echo "$CURRENT" | jq --argjson entry "$HOOK_ENTRY" '
                .hooks.PreToolUse += [$entry]
            ')
            echo "$UPDATED" > "$SETTINGS_FILE"
            echo -e "  ${GREEN}OK${NC} Hook added to existing PreToolUse array"
        fi
    else
        # Add hooks.PreToolUse section
        UPDATED=$(echo "$CURRENT" | jq --argjson entry "$HOOK_ENTRY" '
            .hooks = (.hooks // {}) |
            .hooks.PreToolUse = [$entry]
        ')
        echo "$UPDATED" > "$SETTINGS_FILE"
        echo -e "  ${GREEN}OK${NC} PreToolUse hook section created"
    fi
else
    # No settings file — create one
    jq -n --argjson entry "$HOOK_ENTRY" '{
        "hooks": {
            "PreToolUse": [$entry]
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
echo -e "  ${BOLD}Installed to:${NC}  ${DIM}${INSTALL_DIR}${NC}"
echo -e "  ${BOLD}Settings:${NC}      ${DIM}${SETTINGS_FILE}${NC}"
echo -e "  ${BOLD}Logs:${NC}          ${DIM}${INSTALL_DIR}/data/security.log${NC}"
echo ""
echo -e "  ${BOLD}What happens now:${NC}"
echo -e "  ${DIM}Every Bash command in Claude Code is validated before execution.${NC}"
echo -e "  ${DIM}Destructive commands (rm -rf) are blocked. Dangerous commands${NC}"
echo -e "  ${DIM}(sudo, chmod, kill...) require confirmation.${NC}"
echo ""
echo -e "  ${BOLD}Run tests:${NC}"
echo -e "  ${DIM}cd ${INSTALL_DIR} && bun test${NC}"
echo ""
echo -e "  ${BOLD}Add custom DENY rules:${NC}"
echo -e "  ${DIM}Edit ${INSTALL_DIR}/src/lib/validator.ts${NC}"
echo -e "  ${DIM}Add a new method + call it in validate(). Example:${NC}"
echo ""
echo -e "  ${DIM}  containsMyRule(command: string): boolean {${NC}"
echo -e "  ${DIM}    return /\\bgh\\s+repo\\s+delete\\b/i.test(command);${NC}"
echo -e "  ${DIM}  }${NC}"
echo ""
echo -e "  ${YELLOW}Restart Claude Code for changes to take effect.${NC}"
echo ""
