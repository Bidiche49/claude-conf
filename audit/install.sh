#!/bin/bash
# ── audit — Install Script ─────────────────────────────────────
# Installs the /audit skill for Claude Code
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

# ── Banner ────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │          ${GREEN}audit${NC}${BOLD} for Claude Code           │${NC}"
echo -e "${BOLD}  │   ${DIM}Deep code audit — security, tests,${NC}${BOLD}     │${NC}"
echo -e "${BOLD}  │   ${DIM}architecture, performance${NC}${BOLD}              │${NC}"
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
for legacy in audit; do
    rm -f "$LEGACY_DIR/$legacy.md" "$LEGACY_DIR/$legacy.md".backup.*
done

# ── 2/2. Install skill ───────────────────────────────────────────

echo -e "${BLUE}[2/2]${NC} Installing skill..."

src="$SCRIPT_DIR/skills/audit/SKILL.md"
dst="$SKILLS_DIR/audit/SKILL.md"

if [ ! -f "$src" ]; then
    echo -e "${RED}  ✗ Source not found: skills/audit/SKILL.md${NC}"
    exit 1
fi

mkdir -p "$SKILLS_DIR/audit"
cp "$src" "$dst"
echo -e "${GREEN}  ✓${NC} /audit skill installed"

# ── Done ──────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}Skill installed:${NC}"
echo -e "    /audit              — full code audit (all relevant axes)"
echo -e "    /audit security     — focused security audit"
echo -e "    /audit tests        — focused test coverage audit"
echo -e "    /audit architecture — focused architecture audit"
echo -e "    /audit performance  — focused performance audit"
echo ""
echo -e "  ${BOLD}Works best with:${NC}"
echo -e "    ${DIM}backlog${NC}        — auto-creates BUG/IMP tickets from findings"
echo -e "    ${DIM}setup-project${NC}  — /audit-conf for config audit"
echo ""
echo -e "  ${DIM}Restart Claude Code for the changes to take effect.${NC}"
echo ""
