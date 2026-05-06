#!/bin/bash
# ── debug-forensic — Install Script ────────────────────────────────
# Installs the /debug-forensic skill for Claude Code
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
echo -e "${BOLD}  │      ${GREEN}debug-forensic${NC}${BOLD} for Claude Code     │${NC}"
echo -e "${BOLD}  │   ${DIM}Force forensic posture on debug${NC}${BOLD}        │${NC}"
echo -e "${BOLD}  │   ${DIM}sessions — data > 1 hypothesis > test${NC}${BOLD}  │${NC}"
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
for legacy in debug-forensic debug; do
    rm -f "$LEGACY_DIR/$legacy.md" "$LEGACY_DIR/$legacy.md".backup.*
done

# ── 2/2. Install skill ───────────────────────────────────────────

echo -e "${BLUE}[2/2]${NC} Installing skill..."

src="$SCRIPT_DIR/skills/debug-forensic/SKILL.md"
dst="$SKILLS_DIR/debug-forensic/SKILL.md"

if [ ! -f "$src" ]; then
    echo -e "${RED}  ✗ Source not found: skills/debug-forensic/SKILL.md${NC}"
    exit 1
fi

mkdir -p "$SKILLS_DIR/debug-forensic"
cp "$src" "$dst"
echo -e "${GREEN}  ✓${NC} /debug-forensic skill installed"

# ── Done ──────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}Skill installed:${NC}"
echo -e "    /debug-forensic         — auto-detect mode (extract or interview)"
echo -e "    /debug-forensic new     — force INTERVIEW mode (fresh bug)"
echo -e "    /debug-forensic here    — keep recadrage in current conv"
echo ""
echo -e "  ${BOLD}When to use:${NC}"
echo -e "    ${DIM}• Long debug session is drifting into speculation${NC}"
echo -e "    ${DIM}• Context is saturated, need to migrate to a fresh conv${NC}"
echo -e "    ${DIM}• Want to force a strict 'data → 1 hypothesis → 1 test → STOP' posture${NC}"
echo ""
echo -e "  ${DIM}Restart Claude Code for the changes to take effect.${NC}"
echo ""
