#!/bin/bash
# ── Claude Code OneShot — Install Script ─────────────────────────
# Installs the /oneshot slash command for Claude Code
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
COMMANDS_DIR="$CLAUDE_DIR/commands"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │         ${RED}oneshot${NC}${BOLD} for Claude Code          │${NC}"
echo -e "${BOLD}  │   ${DIM}Explore → Code → Test — ship fast${NC}${BOLD}      │${NC}"
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

# ── 2. Install the command ────────────────────────────────────────

echo -e "${BLUE}[2/2]${NC} Installing /oneshot command..."

mkdir -p "$COMMANDS_DIR"

if [ ! -f "$SCRIPT_DIR/commands/oneshot.md" ]; then
    echo -e "${RED}  ✗ Source file not found: commands/oneshot.md${NC}"
    exit 1
fi

# Backup existing command if present
if [ -f "$COMMANDS_DIR/oneshot.md" ]; then
    cp "$COMMANDS_DIR/oneshot.md" "$COMMANDS_DIR/oneshot.md.backup.$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}  !${NC} Existing command backed up"
fi

cp "$SCRIPT_DIR/commands/oneshot.md" "$COMMANDS_DIR/oneshot.md"

echo -e "${GREEN}  ✓${NC} Command installed in $COMMANDS_DIR/oneshot.md"

# ── Done ──────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}Usage:${NC}"
echo -e "    In any Claude Code session, type: ${BOLD}/oneshot <feature-description>${NC}"
echo ""
echo -e "  ${BOLD}What it does:${NC}"
echo -e "    Ultra-fast feature implementation. Explores minimally,"
echo -e "    codes immediately, validates with your stack's linter/typecheck."
echo -e "    No planning phase — ${BOLD}ship fast, iterate later${NC}."
echo ""
echo -e "  ${BOLD}Supported stacks:${NC}"
echo -e "    ${DIM}Node/JS${NC} (package.json)  ${DIM}Flutter/Dart${NC} (pubspec.yaml)"
echo -e "    ${DIM}Go${NC} (go.mod)             ${DIM}Rust${NC} (Cargo.toml)"
echo -e "    ${DIM}Python${NC} (pyproject.toml)  ${DIM}PHP${NC} (composer.json)"
echo -e "    ${DIM}Make${NC} (Makefile)"
echo ""
echo -e "  ${DIM}Restart Claude Code for the command to become available.${NC}"
echo ""
