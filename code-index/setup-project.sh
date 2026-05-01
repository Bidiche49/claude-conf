#!/usr/bin/env bash
# ── code-index — per-project setup entry-point ───────────────────
# Detects the project stack (Dart, JS/TS, Python, Go, Rust) and dispatches
# to the appropriate stacks/<stack>/_setup.sh. For unsupported stacks,
# points the user toward /code-index-bootstrap in Claude Code.
#
# Usage:
#   bash ~/.claude/code-index/setup-project.sh                 # cwd, defaults
#   bash ~/.claude/code-index/setup-project.sh --source src    # custom source
#   bash ~/.claude/code-index/setup-project.sh --project /path # other dir
#
# Idempotent: re-running re-applies the stack setup with current templates.

set -e

# ── Colors ───────────────────────────────────────────────────────

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Paths ────────────────────────────────────────────────────────

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
STACKS_DIR="$SELF_DIR/stacks"

PROJECT_ROOT="$(pwd)"

# ── Parse args (passthrough to stack scripts) ────────────────────

# Capture --project and pull it out; the rest is forwarded.
STACK_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --project|--project-root)
            PROJECT_ROOT="$2"
            shift 2
            ;;
        -h|--help)
            cat <<EOF
code-index — per-project setup entry-point.

Usage:
  bash setup-project.sh [options]

Options:
  --project <dir>      Target project directory (default: cwd)
  --source <dir>       Source dir, forwarded to the stack setup (default: lib for Dart, src for JS/TS, etc.)
  --out <dir>          Output dir, forwarded (default: docs/.code-map)
  --yes, -y            Non-interactive mode, forwarded.
  -h, --help           Show this help.

The script detects your project stack by looking for marker files:
  pubspec.yaml         → dart  (supported in v0.1)
  package.json         → js/ts (chantier B — use /code-index-bootstrap in Claude Code)
  requirements.txt or
  pyproject.toml       → python (chantier B)
  go.mod               → go    (chantier B)
  Cargo.toml           → rust  (chantier B)
EOF
            exit 0
            ;;
        *)
            STACK_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ ! -d "$PROJECT_ROOT" ]; then
    echo -e "${RED}✗ Project directory not found: $PROJECT_ROOT${NC}" >&2
    exit 1
fi

cd "$PROJECT_ROOT"

# ── Banner ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │   ${BLUE}code-index${NC}${BOLD} — per-project setup        │${NC}"
echo -e "${BOLD}  │   ${DIM}auto-detect stack & install tooling${NC}${BOLD}    │${NC}"
echo -e "${BOLD}  └─────────────────────────────────────────┘${NC}"
echo ""
echo -e "  Project root : ${BOLD}$PROJECT_ROOT${NC}"
echo ""

# ── Detect stack ─────────────────────────────────────────────────

DETECTED_STACK=""
DETECTED_MARKER=""

if [ -f "pubspec.yaml" ]; then
    DETECTED_STACK="dart"
    DETECTED_MARKER="pubspec.yaml"
elif [ -f "package.json" ]; then
    DETECTED_STACK="js"
    DETECTED_MARKER="package.json"
elif [ -f "go.mod" ]; then
    DETECTED_STACK="go"
    DETECTED_MARKER="go.mod"
elif [ -f "Cargo.toml" ]; then
    DETECTED_STACK="rust"
    DETECTED_MARKER="Cargo.toml"
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
    DETECTED_STACK="python"
    if [ -f "pyproject.toml" ]; then
        DETECTED_MARKER="pyproject.toml"
    elif [ -f "requirements.txt" ]; then
        DETECTED_MARKER="requirements.txt"
    else
        DETECTED_MARKER="setup.py"
    fi
fi

if [ -z "$DETECTED_STACK" ]; then
    echo -e "${RED}  ✗ Could not detect stack.${NC}"
    echo -e "    No pubspec.yaml, package.json, go.mod, Cargo.toml, pyproject.toml,"
    echo -e "    requirements.txt, or setup.py found in $PROJECT_ROOT."
    echo ""
    echo -e "  ${DIM}If you have an unconventional layout, run the stack script directly:${NC}"
    echo -e "  ${DIM}  bash $STACKS_DIR/dart/_setup.sh${NC}"
    exit 1
fi

echo -e "  Detected     : ${GREEN}$DETECTED_STACK${NC} (via ${DIM}$DETECTED_MARKER${NC})"
echo ""

# ── Dispatch ─────────────────────────────────────────────────────

STACK_SETUP="$STACKS_DIR/$DETECTED_STACK/_setup.sh"

if [ -x "$STACK_SETUP" ]; then
    echo -e "${BLUE}→${NC} Running ${BOLD}$DETECTED_STACK${NC} stack setup..."
    echo ""
    PROJECT_ROOT="$PROJECT_ROOT" bash "$STACK_SETUP" "${STACK_ARGS[@]}"
    exit $?
fi

# ── Unsupported stack ────────────────────────────────────────────

echo -e "${YELLOW}  ! Stack '${BOLD}$DETECTED_STACK${NC}${YELLOW}' is not supported natively in v0.1.${NC}"
echo ""
echo -e "  ${BOLD}Two paths forward:${NC}"
echo ""
echo -e "  ${BOLD}1.${NC} Use Claude Code to bootstrap automatically:"
echo -e "       ${DIM}# in Claude Code session, from this project:${NC}"
echo -e "       ${BOLD}/code-index-bootstrap${NC}"
echo ""
echo -e "       The skill detects your stack, generates a parser using the"
echo -e "       official AST parser of the language (ts-morph, ast, go/parser, syn),"
echo -e "       and validates the output against a strict format contract."
echo ""
echo -e "  ${BOLD}2.${NC} Skip code-index for now and rely on CLAUDE.md + Glob/Grep."
echo ""
echo -e "  ${DIM}Track v0.2 multi-stack support in the claude-conf repo.${NC}"
echo ""
exit 0
