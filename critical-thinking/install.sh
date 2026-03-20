#!/bin/bash
# ── Claude Code Critical Thinking — Install Script ──────────────
# Injects anti-complacency rules into CLAUDE.md and patches supervisor
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
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
SUPERVISOR_LOCAL="$CLAUDE_DIR/commands/supervisor.md"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SNIPPET_FILE="$SCRIPT_DIR/claude-md/critical-thinking.md"

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │     ${RED}critical-thinking${NC}${BOLD} for Claude Code    │${NC}"
echo -e "${BOLD}  │   ${DIM}Anti-complacency — sparring partner mode${NC}${BOLD} │${NC}"
echo -e "${BOLD}  └─────────────────────────────────────────┘${NC}"
echo ""

# ── 1/4. Check dependencies ────────────────────────────────────

echo -e "${BLUE}[1/4]${NC} Checking dependencies..."

if ! command -v claude &>/dev/null; then
    echo -e "${RED}  ✗ Claude Code not found.${NC}"
    echo -e "    Install it first: ${DIM}npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi

echo -e "${GREEN}  ✓${NC} Claude Code available"

if [ ! -f "$SNIPPET_FILE" ]; then
    echo -e "${RED}  ✗ Source file not found: claude-md/critical-thinking.md${NC}"
    exit 1
fi

# ── 2/4. Inject into CLAUDE.md ──────────────────────────────────

echo -e "${BLUE}[2/4]${NC} Injecting into CLAUDE.md..."

mkdir -p "$CLAUDE_DIR"

if [ ! -f "$CLAUDE_MD" ]; then
    cp "$SNIPPET_FILE" "$CLAUDE_MD"
    echo -e "${GREEN}  ✓${NC} Created $CLAUDE_MD with critical-thinking rules"
elif grep -q '<!-- critical-thinking:start -->' "$CLAUDE_MD"; then
    echo -e "${YELLOW}  ! SKIP${NC} — critical-thinking markers already present in CLAUDE.md"
else
    echo "" >> "$CLAUDE_MD"
    cat "$SNIPPET_FILE" >> "$CLAUDE_MD"
    echo -e "${GREEN}  ✓${NC} Appended critical-thinking rules to CLAUDE.md"
fi

# ── 3/4. Fix "stagiaire" framing ───────────────────────────────

echo -e "${BLUE}[3/4]${NC} Fixing stagiaire framing..."

if [ -f "$CLAUDE_MD" ] && grep -q 'stagiaire qui reflechit' "$CLAUDE_MD"; then
    sed -i '' 's/Tu es un stagiaire qui reflechit et code comme un senior\./Tu es un associe technique. Tu as l'\''expertise pour identifier les bonnes solutions ET pour challenger les mauvaises. L'\''utilisateur reste le decisionnaire final, mais tu lui dois ton avis honnete, pas ta complaisance./' "$CLAUDE_MD"
    echo -e "${GREEN}  ✓${NC} Replaced stagiaire framing with associate framing"
else
    echo -e "${YELLOW}  ! WARNING${NC} — Stagiaire framing not found — may already be updated"
fi

# ── 4/4. Patch supervisor (local copy) ─────────────────────────

echo -e "${BLUE}[4/4]${NC} Patching supervisor..."

if [ -f "$SUPERVISOR_LOCAL" ]; then
    if grep -q '<!-- critical-thinking:start -->' "$SUPERVISOR_LOCAL"; then
        echo -e "${YELLOW}  ! SKIP${NC} — critical-thinking markers already present in supervisor"
    else
        # Extract POSTURE block from repo source
        REPO_SUPERVISOR="$SCRIPT_DIR/../supervisor/commands/supervisor.md"
        if [ -f "$REPO_SUPERVISOR" ]; then
            POSTURE_FILE=$(mktemp)
            sed -n '/<!-- critical-thinking:start -->/,/<!-- critical-thinking:end -->/p' "$REPO_SUPERVISOR" > "$POSTURE_FILE"
            # Insert posture block + separator before ## YOUR ROLE
            TEMP_FILE=$(mktemp)
            while IFS= read -r line || [ -n "$line" ]; do
                if [ "$line" = "## YOUR ROLE" ]; then
                    cat "$POSTURE_FILE"
                    echo ""
                    echo "---"
                    echo ""
                fi
                printf '%s\n' "$line"
            done < "$SUPERVISOR_LOCAL" > "$TEMP_FILE"
            mv "$TEMP_FILE" "$SUPERVISOR_LOCAL"
            rm -f "$POSTURE_FILE"
            echo -e "${GREEN}  ✓${NC} Injected POSTURE block into local supervisor"
        else
            echo -e "${YELLOW}  ! WARNING${NC} — Repo supervisor source not found, skipping patch"
        fi
    fi
else
    echo -e "${DIM}  ─ Supervisor not installed — skipping${NC}"
fi

# ── Done ────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── Installation complete ──${NC}"
echo ""
echo -e "  ${BOLD}What was installed:${NC}"
echo -e "    • Anti-complacency rules injected into ~/.claude/CLAUDE.md"
echo -e "    • Classification system (Solide/Discutable/Simplifie/Angle mort/Faux)"
echo -e "    • 5 anti-complacency reflexes"
echo -e "    • Stress-test questions by domain"
echo -e "    • CTO posture patch for supervisor (if installed)"
echo ""
echo -e "  ${BOLD}Works best with:${NC}"
echo -e "    ${DIM}supervisor${NC}  — CTO mode with POSTURE block"
echo ""
echo -e "  ${DIM}Restart Claude Code for the changes to take effect.${NC}"
echo ""
