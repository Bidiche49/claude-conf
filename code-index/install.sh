#!/usr/bin/env bash
# ── code-index — Module installer ────────────────────────────────
# Copies the code-index toolkit into ~/.claude/code-index/ so it can be
# invoked from any project via:
#   bash ~/.claude/code-index/setup-project.sh
#
# Optionally installs the /code-index-bootstrap skill (chantier B), if
# present at skills/code-index-bootstrap/SKILL.md.
#
# Usage: bash install.sh

set -e

# ── Colors ───────────────────────────────────────────────────────

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Paths ────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
INSTALL_DIR="$CLAUDE_DIR/code-index"
SKILLS_DIR="$CLAUDE_DIR/skills"

# ── Banner ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │       ${BLUE}code-index${NC}${BOLD} for Claude Code         │${NC}"
echo -e "${BOLD}  │   ${DIM}auto-indexed codebase navigation${NC}${BOLD}      │${NC}"
echo -e "${BOLD}  └─────────────────────────────────────────┘${NC}"
echo ""

# ── 1. Check dependencies ────────────────────────────────────────

echo -e "${BLUE}[1/3]${NC} Checking dependencies..."

if ! command -v claude &>/dev/null; then
    echo -e "${YELLOW}  ! Claude Code CLI not found.${NC}"
    echo -e "    The shell entry-point (${DIM}setup-project.sh${NC}) works without it,"
    echo -e "    but the ${DIM}/code-index-bootstrap${NC} skill needs Claude Code installed."
    echo -e "    Install: ${DIM}npm install -g @anthropic-ai/claude-code${NC}"
else
    echo -e "${GREEN}  ✓${NC} Claude Code available"
fi

# git is needed for hooks but only at per-project setup time, not here.

# ── 2. Install templates under ~/.claude/code-index/ ─────────────

echo -e "${BLUE}[2/3]${NC} Installing templates to $INSTALL_DIR ..."

mkdir -p "$INSTALL_DIR"

# Copy stacks/ and shared/ (everything users need to set up a project).
# Use -R for recursive, -f to overwrite — idempotent.
cp -Rf "$SCRIPT_DIR/stacks"   "$INSTALL_DIR/stacks"
cp -Rf "$SCRIPT_DIR/shared"   "$INSTALL_DIR/shared"
cp -f  "$SCRIPT_DIR/setup-project.sh" "$INSTALL_DIR/setup-project.sh"

# Optional reference docs (don't fail if absent during dev).
[ -f "$SCRIPT_DIR/README.md"     ] && cp -f "$SCRIPT_DIR/README.md"     "$INSTALL_DIR/README.md"
[ -f "$SCRIPT_DIR/BENCHMARKS.md" ] && cp -f "$SCRIPT_DIR/BENCHMARKS.md" "$INSTALL_DIR/BENCHMARKS.md"

# Re-apply executable bits (cp preserves mode but better safe).
chmod +x "$INSTALL_DIR/setup-project.sh"
find "$INSTALL_DIR/stacks" -type f -name '_setup.sh' -exec chmod +x {} \;
find "$INSTALL_DIR/shared" -type f \( -name 'post-*' -o -name '_run_code_index.sh' \) -exec chmod +x {} \;

echo -e "${GREEN}  ✓${NC} stacks/, shared/, setup-project.sh installed"

# ── 3. Install skill if present ──────────────────────────────────

echo -e "${BLUE}[3/3]${NC} Checking for /code-index-bootstrap skill..."

SKILL_SRC="$SCRIPT_DIR/skills/code-index-bootstrap/SKILL.md"
SKILL_DST_DIR="$SKILLS_DIR/code-index-bootstrap"

if [ -f "$SKILL_SRC" ]; then
    mkdir -p "$SKILL_DST_DIR"
    cp -f "$SKILL_SRC" "$SKILL_DST_DIR/SKILL.md"
    echo -e "${GREEN}  ✓${NC} /code-index-bootstrap skill installed"
else
    echo -e "${DIM}  · skill not yet shipped (chantier B WIP); shell entry-point still works${NC}"
fi

# ── Done ─────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}Per-project usage:${NC}"
echo -e "    cd your-project/"
echo -e "    ${BOLD}bash ~/.claude/code-index/setup-project.sh${NC}"
echo ""
if [ -f "$SKILL_SRC" ]; then
    echo -e "  ${BOLD}Or in Claude Code:${NC}"
    echo -e "    ${BOLD}/code-index-bootstrap${NC}"
    echo ""
fi
echo -e "  ${DIM}Currently supported natively: Dart/Flutter (other stacks via /code-index-bootstrap).${NC}"
echo ""
