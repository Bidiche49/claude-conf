#!/bin/bash
# ── explore — Install Script ────────────────────────────────────
# Installs the /explore skill for Claude Code
#
# Usage: bash install.sh

set -e

# ── Colors ────────────────────────────────────────────────────────

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

# ── Banner ────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │          ${BLUE}explore${NC}${BOLD} for Claude Code         │${NC}"
echo -e "${BOLD}  │   ${DIM}Structured parallel codebase exploration${NC}${BOLD}│${NC}"
echo -e "${BOLD}  └─────────────────────────────────────────┘${NC}"
echo ""

# ── 1/2. Check dependencies ──────────────────────────────────────

echo -e "${BLUE}[1/2]${NC} Checking dependencies..."

if ! command -v claude &>/dev/null; then
    echo -e "${RED}  ✗ Claude Code not found.${NC}"
    echo -e "    Install it first: ${DIM}npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓${NC} Claude Code available"

# ── Cleanup legacy commands ─────────────────────────────────────
LEGACY_DIR="$HOME/.claude/commands"
for legacy in explore; do
    rm -f "$LEGACY_DIR/$legacy.md" "$LEGACY_DIR/$legacy.md".backup.*
done

# ── 2/2. Install skill ───────────────────────────────────────────

echo -e "${BLUE}[2/2]${NC} Installing /explore skill..."

src="$SCRIPT_DIR/skills/explore/SKILL.md"
dst="$SKILLS_DIR/explore/SKILL.md"

if [ ! -f "$src" ]; then
    echo -e "${RED}  ✗ Source not found: skills/explore/SKILL.md${NC}"
    exit 1
fi

mkdir -p "$SKILLS_DIR/explore"
cp "$src" "$dst"
echo -e "${GREEN}  ✓${NC} Skill installed"

# ── Done ──────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}Skill installed:${NC}"
echo -e "    /explore <topic>  — deep parallel exploration of codebase, docs, and web"
echo ""
echo -e "  ${BOLD}Process:${NC}"
echo -e "    ${DIM}1. Plan   — break topic into 2-3 sub-questions${NC}"
echo -e "    ${DIM}2. Explore — parallel agents with focused queries${NC}"
echo -e "    ${DIM}3. Synthesize — structured report with file:line references${NC}"
echo ""
echo -e "  ${DIM}Restart Claude Code for the changes to take effect.${NC}"
echo ""
