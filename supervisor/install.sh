#!/bin/bash
# ── Claude Code Supervisor — Install Script ──────────────────────
# Installs the /supervisor skill for Claude Code
#
# Usage: bash install.sh

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │       ${RED}supervisor${NC}${BOLD} for Claude Code        │${NC}"
echo -e "${BOLD}  │   ${DIM}CTO mode — investigate, delegate, ship${NC}${BOLD}  │${NC}"
echo -e "${BOLD}  └─────────────────────────────────────────┘${NC}"
echo ""

# ── 1. Check dependencies ────────────────────────────────────────

echo -e "${BLUE}[1/2]${NC} Checking dependencies..."

if ! command -v claude &>/dev/null; then
    echo -e "${RED}  ✗ Claude Code not found.${NC}"
    echo -e "    Install it first: ${DIM}npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi

echo -e "${GREEN}  ✓${NC} Claude Code available"

# ── Cleanup legacy commands ─────────────────────────────────────
LEGACY_DIR="$HOME/.claude/commands"
for legacy in supervisor; do
    rm -f "$LEGACY_DIR/$legacy.md" "$LEGACY_DIR/$legacy.md".backup.*
done

# ── 2. Install the skill ──────────────────────────────────────────

echo -e "${BLUE}[2/2]${NC} Installing /supervisor skill..."

src="$SCRIPT_DIR/skills/supervisor/SKILL.md"
dst="$SKILLS_DIR/supervisor/SKILL.md"

if [ ! -f "$src" ]; then
    echo -e "${RED}  ✗ Source file not found: skills/supervisor/SKILL.md${NC}"
    exit 1
fi

mkdir -p "$SKILLS_DIR/supervisor"
cp "$src" "$dst"

echo -e "${GREEN}  ✓${NC} Skill installed in $SKILLS_DIR/supervisor/SKILL.md"

# ── Done ──────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}Usage:${NC}"
echo -e "    In any Claude Code session, type: ${BOLD}/supervisor${NC}"
echo ""
echo -e "  ${BOLD}What it does:${NC}"
echo -e "    Switches Claude into CTO mode. It will investigate problems,"
echo -e "    create tickets, generate worker prompts, and validate reports"
echo -e "    — but ${BOLD}never write code${NC}."
echo ""
echo -e "  ${BOLD}Works best with:${NC}"
echo -e "    ${DIM}tab-titles${NC}  — distinct tab titles for supervisor vs worker sessions"
echo -e "    ${DIM}handoff-kit${NC} — context monitoring to avoid losing progress"
echo ""
echo -e "  ${DIM}Restart Claude Code for the skill to become available.${NC}"
echo ""
