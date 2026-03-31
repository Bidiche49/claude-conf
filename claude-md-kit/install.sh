#!/bin/bash
# ── Claude MD Kit — Install Script ───────────────────────────────
# Installs /claude-md-init, /claude-md-cleanup, /claude-md-boost
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

COMMANDS=("claude-md-init" "claude-md-cleanup" "claude-md-boost")

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │       ${BLUE}claude-md-kit${NC}${BOLD} for Claude Code     │${NC}"
echo -e "${BOLD}  │   ${DIM}init, cleanup, boost your CLAUDE.md${NC}${BOLD}    │${NC}"
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
for legacy in claude-md-init claude-md-cleanup claude-md-boost; do
    rm -f "$LEGACY_DIR/$legacy.md" "$LEGACY_DIR/$legacy.md".backup.*
done

# ── 2. Install skills ────────────────────────────────────────────

echo -e "${BLUE}[2/2]${NC} Installing skills..."

for cmd in "${COMMANDS[@]}"; do
    src="$SCRIPT_DIR/skills/${cmd}/SKILL.md"
    dst="$SKILLS_DIR/${cmd}/SKILL.md"

    if [ ! -f "$src" ]; then
        echo -e "${RED}  ✗ Source file not found: skills/${cmd}/SKILL.md${NC}"
        exit 1
    fi

    mkdir -p "$SKILLS_DIR/${cmd}"
    cp "$src" "$dst"
    echo -e "${GREEN}  ✓${NC} /${cmd} skill installed"
done

# ── Done ─────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}Skills installed:${NC}"
echo -e "    ${BOLD}/claude-md-init${NC}     Generate a CLAUDE.md from scratch"
echo -e "    ${BOLD}/claude-md-cleanup${NC}  Remove duplicates with global config"
echo -e "    ${BOLD}/claude-md-boost${NC}    Optimize with prompt engineering + stack best practices"
echo ""
echo -e "  ${DIM}Restart Claude Code for skills to become available.${NC}"
echo ""
