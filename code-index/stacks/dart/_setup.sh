#!/usr/bin/env bash
# ── code-index / dart stack — per-project setup ──────────────────
# Installs tool/code_index.dart, .githooks/*, configures git, runs first index.
#
# Called by setup-project.sh after stack detection. Can also be invoked directly:
#   bash ~/.claude/code-index/stacks/dart/_setup.sh [--source <dir>] [--out <dir>]
#
# Idempotent: re-running overwrites the script and hooks but preserves
# tool/code_index.dart customizations only if the file is identical (cp -f).

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

# Resolve the directory that holds this script + the templates.
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

# When installed: SELF_DIR == ~/.claude/code-index/stacks/dart
# When invoked from repo: SELF_DIR == claude-conf/code-index/stacks/dart
TEMPLATE_DIR="$SELF_DIR"
SHARED_DIR="$(cd "$SELF_DIR/../../shared" && pwd)"

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"

# ── Defaults (overridable via flags) ─────────────────────────────

SOURCE_DIR="lib"
OUT_DIR="docs/.code-map"
NON_INTERACTIVE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source) SOURCE_DIR="$2"; shift 2 ;;
        --out)    OUT_DIR="$2"; shift 2 ;;
        --yes|-y) NON_INTERACTIVE=1; shift ;;
        --project-root) PROJECT_ROOT="$2"; shift 2 ;;
        -h|--help)
            cat <<EOF
Dart code-index — per-project setup.

Usage: bash _setup.sh [options]

Options:
  --source <dir>       Source directory to index (default: lib)
  --out <dir>          Output dir for the index (default: docs/.code-map)
  --project-root <dir> Project root (default: cwd)
  --yes, -y            Non-interactive mode (auto-confirm pubspec hint)
  -h, --help           Show this help
EOF
            exit 0
            ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
done

cd "$PROJECT_ROOT"

# ── Banner ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │   ${BLUE}code-index${NC}${BOLD} / ${BOLD}dart stack${NC}${BOLD}                │${NC}"
echo -e "${BOLD}  │   ${DIM}per-project setup${NC}${BOLD}                     │${NC}"
echo -e "${BOLD}  └─────────────────────────────────────────┘${NC}"
echo ""
echo -e "  Project    : ${BOLD}$PROJECT_ROOT${NC}"
echo -e "  Source dir : ${BOLD}$SOURCE_DIR${NC}"
echo -e "  Output dir : ${BOLD}$OUT_DIR${NC}"
echo ""

# ── 1. Sanity checks ─────────────────────────────────────────────

echo -e "${BLUE}[1/7]${NC} Checking project layout..."

if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}  ✗ No pubspec.yaml in $PROJECT_ROOT${NC}"
    echo -e "    This installer is for Dart/Flutter projects."
    exit 1
fi
echo -e "${GREEN}  ✓${NC} pubspec.yaml found"

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${YELLOW}  ! Source dir '$SOURCE_DIR' does not exist yet.${NC}"
    echo -e "    The index will be empty until you add Dart files there."
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo -e "${RED}  ✗ Not a git repository.${NC}"
    echo -e "    code-index hooks need git. Run ${DIM}git init${NC} first."
    exit 1
fi
echo -e "${GREEN}  ✓${NC} git repository detected"

if ! command -v dart >/dev/null 2>&1; then
    echo -e "${RED}  ✗ 'dart' command not found in PATH.${NC}"
    echo -e "    Install Dart: ${DIM}https://dart.dev/get-dart${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓${NC} dart in PATH ($(dart --version 2>&1 | head -1))"

# ── 2. Install code_index.dart ───────────────────────────────────

echo -e "${BLUE}[2/7]${NC} Installing tool/code_index.dart..."

mkdir -p tool
cp -f "$TEMPLATE_DIR/code_index.dart" tool/code_index.dart
echo -e "${GREEN}  ✓${NC} tool/code_index.dart"

# ── 3. Install hooks ─────────────────────────────────────────────

echo -e "${BLUE}[3/7]${NC} Installing .githooks/..."

mkdir -p .githooks
cp -f "$SHARED_DIR/_run_code_index.sh" .githooks/_run_code_index.sh
cp -f "$SHARED_DIR/post-commit"        .githooks/post-commit
cp -f "$SHARED_DIR/post-checkout"      .githooks/post-checkout
cp -f "$SHARED_DIR/post-merge"         .githooks/post-merge
cp -f "$SHARED_DIR/README.md"          .githooks/README.md
chmod +x .githooks/_run_code_index.sh .githooks/post-commit .githooks/post-checkout .githooks/post-merge
echo -e "${GREEN}  ✓${NC} 4 hooks + README installed under .githooks/"

# ── 4. Patch .gitignore ──────────────────────────────────────────

echo -e "${BLUE}[4/7]${NC} Patching .gitignore..."

touch .gitignore

PATCH_BLOCK_HEADER="# code-index (claude-conf) — generated artifacts"
PATCH_LINES=(
    "$OUT_DIR/"
    ".dart_tool/code_index_bin"
)

if grep -qF "$PATCH_BLOCK_HEADER" .gitignore; then
    echo -e "${DIM}  · already patched${NC}"
else
    {
        echo ""
        echo "$PATCH_BLOCK_HEADER"
        for line in "${PATCH_LINES[@]}"; do
            echo "$line"
        done
    } >> .gitignore
    echo -e "${GREEN}  ✓${NC} added: $OUT_DIR/, .dart_tool/code_index_bin"
fi

# ── 5. Configure git hooksPath ───────────────────────────────────

echo -e "${BLUE}[5/7]${NC} Configuring git hooksPath..."

CURRENT_HOOKS_PATH="$(git config core.hooksPath || true)"
if [ "$CURRENT_HOOKS_PATH" = ".githooks" ]; then
    echo -e "${DIM}  · already set to .githooks${NC}"
elif [ -n "$CURRENT_HOOKS_PATH" ] && [ "$CURRENT_HOOKS_PATH" != ".githooks" ]; then
    echo -e "${YELLOW}  ! core.hooksPath is currently set to '$CURRENT_HOOKS_PATH'.${NC}"
    echo -e "    Skipping override to avoid breaking your existing hooks."
    echo -e "    To enable code-index hooks, manually run: ${DIM}git config core.hooksPath .githooks${NC}"
else
    git config core.hooksPath .githooks
    echo -e "${GREEN}  ✓${NC} core.hooksPath = .githooks"
fi

# ── 6. Check analyzer dependency ─────────────────────────────────

echo -e "${BLUE}[6/7]${NC} Checking analyzer availability..."

ANALYZER_AVAILABLE=0
if [ -f pubspec.lock ] && grep -q '^  analyzer:' pubspec.lock; then
    ANALYZER_AVAILABLE=1
fi

if [ "$ANALYZER_AVAILABLE" -eq 1 ]; then
    echo -e "${GREEN}  ✓${NC} analyzer resolved (transitive or direct dep)"
else
    echo -e "${YELLOW}  ! analyzer not found in pubspec.lock${NC}"
    echo -e "    code_index.dart needs ${BOLD}package:analyzer${NC} (>= 7.0.0)."
    echo -e "    Add it to dev_dependencies:"
    echo ""
    echo -e "${DIM}      dev_dependencies:${NC}"
    echo -e "${DIM}        analyzer: ^7.0.0${NC}"
    echo ""

    if [ "$NON_INTERACTIVE" -eq 1 ]; then
        echo -e "${DIM}  · non-interactive mode: skipping pubspec edit${NC}"
    else
        read -rp "  Add it now via 'dart pub add --dev analyzer' ? [y/N] " reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            if dart pub add --dev analyzer; then
                echo -e "${GREEN}  ✓${NC} analyzer added"
                ANALYZER_AVAILABLE=1
            else
                echo -e "${RED}  ✗ 'dart pub add' failed. Add manually and re-run.${NC}"
            fi
        fi
    fi
fi

# ── 7. First index run ───────────────────────────────────────────

echo -e "${BLUE}[7/7]${NC} Running first index..."

if [ "$ANALYZER_AVAILABLE" -eq 0 ]; then
    echo -e "${YELLOW}  · skipped (analyzer missing). Run later: ${DIM}dart run tool/code_index.dart${NC}"
else
    if dart run tool/code_index.dart --source "$SOURCE_DIR" --out "$OUT_DIR" --quiet 2>/dev/null; then
        FILE_COUNT=$(find "$OUT_DIR" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${GREEN}  ✓${NC} index generated under $OUT_DIR/ ($FILE_COUNT markdown files)"
    else
        echo -e "${YELLOW}  ! first run failed — try manually: ${DIM}dart run tool/code_index.dart${NC}"
    fi
fi

# ── Done ─────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ── code-index / dart ready ──${NC}"
echo ""
echo -e "  ${BOLD}Index location:${NC}    $OUT_DIR/"
echo -e "  ${BOLD}Source script:${NC}     tool/code_index.dart"
echo -e "  ${BOLD}Hooks:${NC}             .githooks/ (auto-runs on commit/checkout/merge)"
echo ""
echo -e "  ${DIM}Manual regen:${NC}       dart run tool/code_index.dart"
echo -e "  ${DIM}Disable hooks:${NC}      git config --unset core.hooksPath"
echo ""
echo -e "  ${BOLD}Next step:${NC} have Claude Code read ${DIM}$OUT_DIR/INDEX.md${NC} at session start."
echo ""
