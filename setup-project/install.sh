#!/bin/bash
# ── setup-project — Install Script ──────────────────────────────
# Installs the project bootstrap commands for Claude Code
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
COMMANDS_DIR="$HOME/.claude/commands"

# ── Banner ────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │       ${GREEN}setup-project${NC}${BOLD} for Claude Code      │${NC}"
echo -e "${BOLD}  │   ${DIM}Bootstrap any project in one command${NC}${BOLD}    │${NC}"
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

# ── 2/2. Install commands ────────────────────────────────────────

echo -e "${BLUE}[2/2]${NC} Installing commands..."

mkdir -p "$COMMANDS_DIR"

installed_count=0
for cmd in setup-project start review; do
    src="$SCRIPT_DIR/commands/${cmd}.md"
    dst="$COMMANDS_DIR/${cmd}.md"

    if [ ! -f "$src" ]; then
        echo -e "${RED}  ✗ Source not found: commands/${cmd}.md${NC}"
        exit 1
    fi

    if [ -f "$dst" ]; then
        cp "$dst" "${dst}.bak"
        echo -e "${YELLOW}  ↑${NC} Backed up existing ${cmd}.md"
    fi

    cp "$src" "$dst"
    installed_count=$((installed_count + 1))
done

echo -e "${GREEN}  ✓${NC} $installed_count command(s) installed"

# ── Done ──────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}Commands installed:${NC}"
echo -e "    /setup-project  — bootstrap a project (stack detection, permissions, CLAUDE.md)"
echo -e "    /start          — load session context (git, backlog, handoff)"
echo -e "    /review         — auto-review changes before committing"
echo ""
echo -e "  ${BOLD}Works best with:${NC}"
echo -e "    ${DIM}backlog${NC}        — ticketing system (/backlog-init, /backlog-bug, etc.)"
echo -e "    ${DIM}claude-md-kit${NC}  — CLAUDE.md management (/claude-md-init, /claude-md-boost)"
echo -e "    ${DIM}pre-commit-gate${NC} — validation pipeline (/check)"
echo -e "    ${DIM}handoff-kit${NC}    — session continuity (/handoff)"
echo ""
echo -e "  ${DIM}Restart Claude Code for the changes to take effect.${NC}"
echo ""
