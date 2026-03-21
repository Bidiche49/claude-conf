#!/bin/bash
# ── backlog — Install Script ─────────────────────────────────────
# Installs the backlog ticketing system for Claude Code
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
CLAUDE_DIR="$HOME/.claude"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
HOOKS_DIR="$CLAUDE_DIR/hooks"
COMMANDS_DIR="$CLAUDE_DIR/commands"
TEMPLATES_DIR="$CLAUDE_DIR/templates/backlog"
SNIPPET_FILE="$SCRIPT_DIR/claude-md/backlog.md"
HOOK_FILE="$SCRIPT_DIR/hooks/backlog-guard.sh"

sed_inplace() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# ── Banner ────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │          ${RED}backlog${NC}${BOLD} for Claude Code         │${NC}"
echo -e "${BOLD}  │   ${DIM}Universal ticketing with ID protection${NC}${BOLD}  │${NC}"
echo -e "${BOLD}  └─────────────────────────────────────────┘${NC}"
echo ""

# ── 1/5. Check dependencies ──────────────────────────────────────

echo -e "${BLUE}[1/5]${NC} Checking dependencies..."

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

if [ ! -f "$SNIPPET_FILE" ]; then
    echo -e "${RED}  ✗ Source file not found: claude-md/backlog.md${NC}"
    exit 1
fi

if [ ! -f "$HOOK_FILE" ]; then
    echo -e "${RED}  ✗ Source file not found: hooks/backlog-guard.sh${NC}"
    exit 1
fi

# ── 2/5. Install hook ────────────────────────────────────────────

echo -e "${BLUE}[2/5]${NC} Installing backlog-guard hook..."

mkdir -p "$HOOKS_DIR"
cp "$HOOK_FILE" "$HOOKS_DIR/backlog-guard.sh"
chmod +x "$HOOKS_DIR/backlog-guard.sh"
echo -e "${GREEN}  ✓${NC} Hook copied to $HOOKS_DIR/backlog-guard.sh"

# Configure hook in settings.json
HOOK_COMMAND="bash $HOOKS_DIR/backlog-guard.sh"

HOOK_ENTRY=$(cat <<JSONEOF
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

mkdir -p "$(dirname "$SETTINGS_FILE")"

if [ -f "$SETTINGS_FILE" ]; then
    CURRENT=$(cat "$SETTINGS_FILE")
    HAS_PRE_TOOL_USE=$(echo "$CURRENT" | jq 'has("hooks") and (.hooks | has("PreToolUse"))' 2>/dev/null)

    if [ "$HAS_PRE_TOOL_USE" = "true" ]; then
        ALREADY_INSTALLED=$(echo "$CURRENT" | jq --arg cmd "$HOOK_COMMAND" '
            .hooks.PreToolUse[]? |
            select(.hooks[]?.command == $cmd) |
            length > 0
        ' 2>/dev/null)

        if [ -n "$ALREADY_INSTALLED" ] && [ "$ALREADY_INSTALLED" != "false" ]; then
            echo -e "${YELLOW}  ↑${NC} Hook already configured in settings.json"
        else
            UPDATED=$(echo "$CURRENT" | jq --argjson entry "$HOOK_ENTRY" '
                .hooks.PreToolUse += [$entry]
            ')
            echo "$UPDATED" > "$SETTINGS_FILE"
            echo -e "${GREEN}  ✓${NC} Hook added to PreToolUse array"
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

# ── 3/5. Install commands ────────────────────────────────────────

echo -e "${BLUE}[3/5]${NC} Installing commands..."

mkdir -p "$COMMANDS_DIR"

installed_count=0
for cmd in backlog-init backlog-bug backlog-feat backlog-imp backlog-status; do
    if [ -f "$SCRIPT_DIR/commands/${cmd}.md" ]; then
        cp "$SCRIPT_DIR/commands/${cmd}.md" "$COMMANDS_DIR/${cmd}.md"
        installed_count=$((installed_count + 1))
    fi
done

if [ "$installed_count" -gt 0 ]; then
    echo -e "${GREEN}  ✓${NC} $installed_count command(s) installed"
else
    echo -e "${YELLOW}  !${NC} No command files found yet (will be installed later)"
fi

# ── 4/5. Install template ────────────────────────────────────────

echo -e "${BLUE}[4/5]${NC} Installing ticket template..."

mkdir -p "$TEMPLATES_DIR"
cp "$SCRIPT_DIR/templates/ticket.md" "$TEMPLATES_DIR/ticket.md"
echo -e "${GREEN}  ✓${NC} Template installed to $TEMPLATES_DIR/ticket.md"

# ── 5/5. Inject CLAUDE.md ────────────────────────────────────────

echo -e "${BLUE}[5/5]${NC} Injecting into CLAUDE.md..."

mkdir -p "$CLAUDE_DIR"

# Step A: Remove old backlog block if present
if [ -f "$CLAUDE_MD" ] && grep -q '## SYSTEME DE TICKETING UNIVERSEL (BACKLOG)' "$CLAUDE_MD"; then
    # Delete from "## SYSTEME DE TICKETING UNIVERSEL" up to (and including) the "---" line
    # that precedes "## REGLES GENERALES"
    TEMP_FILE=$(mktemp)
    awk '
        /^## SYSTEME DE TICKETING UNIVERSEL \(BACKLOG\)/ { skip=1; next }
        skip && /^---$/ {
            # Buffer the --- line, peek ahead to see if next section is REGLES GENERALES
            pending_sep=1; next
        }
        skip && pending_sep {
            # If we hit REGLES GENERALES (or empty line before it), stop skipping
            if (/^## REGLES GENERALES/ || /^$/) {
                if (/^## REGLES GENERALES/) {
                    skip=0; pending_sep=0
                    print $0; next
                }
                # Empty line between --- and ## REGLES GENERALES — keep skipping
                next
            }
            # The --- was inside the block (e.g., template), continue skipping
            pending_sep=0; next
        }
        !skip { print }
    ' "$CLAUDE_MD" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$CLAUDE_MD"
    echo -e "${YELLOW}  !${NC} Removed old backlog block from CLAUDE.md"
fi

# Step B: Inject new snippet between markers
if [ ! -f "$CLAUDE_MD" ]; then
    cp "$SNIPPET_FILE" "$CLAUDE_MD"
    echo -e "${GREEN}  ✓${NC} Created $CLAUDE_MD with backlog snippet"
elif grep -q '<!-- backlog:start -->' "$CLAUDE_MD"; then
    # Update: remove old content between markers, reinject fresh
    sed_inplace '/<!-- backlog:start -->/,/<!-- backlog:end -->/d' "$CLAUDE_MD"
    # Remove trailing empty lines left by deletion
    while [[ -s "$CLAUDE_MD" ]] && [[ "$(tail -c 1 "$CLAUDE_MD")" == "" ]] && [[ "$(tail -n 1 "$CLAUDE_MD")" == "" ]]; do
        sed_inplace '$ d' "$CLAUDE_MD"
    done
    echo "" >> "$CLAUDE_MD"
    cat "$SNIPPET_FILE" >> "$CLAUDE_MD"
    echo -e "${BLUE}  ↑ UPDATED${NC} backlog snippet in CLAUDE.md"
else
    echo "" >> "$CLAUDE_MD"
    cat "$SNIPPET_FILE" >> "$CLAUDE_MD"
    echo -e "${GREEN}  ✓${NC} Appended backlog snippet to CLAUDE.md"
fi

# ── Done ──────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}What was installed:${NC}"
echo -e "    • backlog-guard hook (PreToolUse Write) — blocks duplicate IDs"
echo -e "    • Ticket template in ~/.claude/templates/backlog/"
echo -e "    • Backlog conventions injected into ~/.claude/CLAUDE.md"
if [ "$installed_count" -gt 0 ]; then
echo -e "    • $installed_count slash commands (/backlog-init, /backlog-bug, etc.)"
fi
echo ""
echo -e "  ${BOLD}Works best with:${NC}"
echo -e "    ${DIM}supervisor${NC}  — CTO mode for ticket planning and delegation"
echo ""
echo -e "  ${DIM}Restart Claude Code for the changes to take effect.${NC}"
echo ""
