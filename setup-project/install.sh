#!/bin/bash
# ── setup-project — Install Script ──────────────────────────────
# Installs the project bootstrap skills for Claude Code
#
# Usage: bash install.sh

set -e

# ── Colors ────────────────────────────────────────────────────────

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
HOOK_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"
HOOK_COMMAND="$HOOK_DIR/auto-start.sh"

# ── Banner ────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │       ${GREEN}setup-project${NC}${BOLD} for Claude Code      │${NC}"
echo -e "${BOLD}  │   ${DIM}Bootstrap any project in one command${NC}${BOLD}    │${NC}"
echo -e "${BOLD}  └─────────────────────────────────────────┘${NC}"
echo ""

# ── 1/3. Check dependencies ──────────────────────────────────────

echo -e "${BLUE}[1/3]${NC} Checking dependencies..."

if ! command -v claude &>/dev/null; then
    echo -e "${RED}  ✗ Claude Code not found.${NC}"
    echo -e "    Install it first: ${DIM}npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓${NC} Claude Code available"

# ── Cleanup legacy commands ─────────────────────────────────────
LEGACY_DIR="$HOME/.claude/commands"
for legacy in setup-project start review audit-conf; do
    rm -f "$LEGACY_DIR/$legacy.md" "$LEGACY_DIR/$legacy.md".backup.*
done

# ── 2/3. Install skills ──────────────────────────────────────────

echo -e "${BLUE}[2/3]${NC} Installing skills..."

installed_count=0
for skill_name in setup-project start review audit-conf; do
    src="$SCRIPT_DIR/skills/${skill_name}/SKILL.md"
    dst="$SKILLS_DIR/${skill_name}/SKILL.md"

    if [ ! -f "$src" ]; then
        echo -e "${RED}  ✗ Source not found: skills/${skill_name}/SKILL.md${NC}"
        exit 1
    fi

    mkdir -p "$SKILLS_DIR/${skill_name}"
    cp "$src" "$dst"
    installed_count=$((installed_count + 1))
done

echo -e "${GREEN}  ✓${NC} $installed_count skill(s) installed"

# ── 3/3. Install auto-start hook ──────────────────────────────────

echo -e "${BLUE}[3/3]${NC} Installing auto-start hook..."

if ! command -v jq &>/dev/null; then
    echo -e "${YELLOW}  ! jq not found — skipping hook install${NC}"
    echo -e "    ${DIM}Install jq (brew install jq) and re-run to enable auto-start reminder${NC}"
else
    mkdir -p "$HOOK_DIR"

    cp "$SCRIPT_DIR/hooks/auto-start.sh" "$HOOK_COMMAND"
    chmod +x "$HOOK_COMMAND"
    echo -e "${GREEN}  ✓${NC} Hook installed to ${DIM}${HOOK_COMMAND}${NC}"

    # Configure settings.json — add to UserPromptSubmit
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

    mkdir -p "$(dirname "$SETTINGS_FILE")"

    if [ -f "$SETTINGS_FILE" ]; then
        CURRENT=$(cat "$SETTINGS_FILE")

        HAS_HOOK=$(echo "$CURRENT" | jq 'has("hooks") and (.hooks | has("UserPromptSubmit"))' 2>/dev/null)

        if [ "$HAS_HOOK" = "true" ]; then
            ALREADY_INSTALLED=$(echo "$CURRENT" | jq --arg cmd "$HOOK_COMMAND" '
                [.hooks.UserPromptSubmit[]? | select(.hooks[]?.command == $cmd)] | length > 0
            ' 2>/dev/null)

            if [ "$ALREADY_INSTALLED" = "true" ]; then
                echo -e "${YELLOW}  SKIP${NC} Hook already configured in settings.json"
            else
                UPDATED=$(echo "$CURRENT" | jq \
                    --argjson entry "$HOOK_ENTRY" '
                    .hooks.UserPromptSubmit += [$entry]
                ')
                echo "$UPDATED" > "$SETTINGS_FILE"
                echo -e "${GREEN}  ✓${NC} Hook added to existing UserPromptSubmit array"
            fi
        else
            UPDATED=$(echo "$CURRENT" | jq \
                --argjson entry "$HOOK_ENTRY" '
                .hooks = (.hooks // {}) |
                .hooks.UserPromptSubmit = [$entry]
            ')
            echo "$UPDATED" > "$SETTINGS_FILE"
            echo -e "${GREEN}  ✓${NC} UserPromptSubmit hook section created"
        fi
    else
        jq -n \
            --argjson entry "$HOOK_ENTRY" '{
            "hooks": {
                "UserPromptSubmit": [$entry]
            }
        }' > "$SETTINGS_FILE"
        echo -e "${GREEN}  ✓${NC} Created ${DIM}${SETTINGS_FILE}${NC}"
    fi
fi

# ── Done ──────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}Skills installed:${NC}"
echo -e "    /setup-project  — bootstrap a project (stack detection, permissions, CLAUDE.md)"
echo -e "    /start          — load session context (git, backlog, handoff)"
echo -e "    /review         — auto-review changes before committing"
echo ""
echo -e "  ${BOLD}Hook installed:${NC}"
echo -e "    auto-start      — reminds to run /start on first message of each session"
echo ""
echo -e "  ${BOLD}Works best with:${NC}"
echo -e "    ${DIM}backlog${NC}        — ticketing system (/backlog-init, /backlog-bug, etc.)"
echo -e "    ${DIM}claude-md-kit${NC}  — CLAUDE.md management (/claude-md-init, /claude-md-boost)"
echo -e "    ${DIM}pre-commit-gate${NC} — validation pipeline (/check)"
echo -e "    ${DIM}handoff-kit${NC}    — session continuity (/handoff)"
echo ""
echo -e "  ${DIM}Restart Claude Code for the changes to take effect.${NC}"
echo ""
