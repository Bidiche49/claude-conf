#!/bin/bash
# ── claude-conf — Root Installer ─────────────────────────────────
# Interactive module installer for claude-conf toolkit
#
# Usage:
#   bash install.sh          Interactive mode (pick modules)
#   bash install.sh --all    Install all modules

set -e

# ── Colors ────────────────────────────────────────────────────────

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Banner ────────────────────────────────────────────────────────

show_banner() {
    echo ""
    echo -e "${BOLD}  ┌─────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}  │           ${BLUE}claude-conf${NC}${BOLD}                    │${NC}"
    echo -e "${BOLD}  │   ${DIM}Modular toolkit for Claude Code${NC}${BOLD}        │${NC}"
    echo -e "${BOLD}  └─────────────────────────────────────────┘${NC}"
    echo ""
}

# ── Module definitions ────────────────────────────────────────────

MODULES=("tab-titles" "handoff-kit" "supervisor" "command-guard")
DESCRIPTIONS=(
    "Smart terminal tab titles for Claude Code sessions"
    "Context monitoring, automatic backups, and session handoff"
    "CTO mode — investigate, delegate to workers, validate, never write code"
    "PreToolUse hook that validates every shell command before execution"
)
DEPS=(
    "jq"
    "bun, jq"
    "none"
    "bun, jq"
)

# ── Helpers ───────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

install_module() {
    local module="$1"
    local module_dir="$SCRIPT_DIR/$module"

    if [ ! -d "$module_dir" ]; then
        echo -e "${RED}  Error: module directory not found: $module_dir${NC}"
        return 1
    fi

    if [ ! -f "$module_dir/install.sh" ]; then
        echo -e "${RED}  Error: install.sh not found in $module_dir${NC}"
        return 1
    fi

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Installing: ${module}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    (cd "$module_dir" && bash install.sh)

    if [ $? -eq 0 ]; then
        track_module "$module"
        echo ""
        echo -e "${GREEN}  ✓ ${module} installed successfully${NC}"
    else
        echo ""
        echo -e "${RED}  ✗ ${module} installation failed${NC}"
        return 1
    fi
}

show_modules() {
    echo -e "${BOLD}  Available modules:${NC}"
    echo ""
    for i in "${!MODULES[@]}"; do
        local num=$((i + 1))
        echo -e "    ${BOLD}${num})${NC} ${GREEN}${MODULES[$i]}${NC}"
        echo -e "       ${DESCRIPTIONS[$i]}"
        echo -e "       ${DIM}Dependencies: ${DEPS[$i]}${NC}"
        echo ""
    done
}

# ── Main ──────────────────────────────────────────────────────────

install_cli() {
    # Install the claude-conf CLI to PATH
    local bin_dir="$HOME/bin"
    mkdir -p "$bin_dir"
    cp "$SCRIPT_DIR/bin/claude-conf" "$bin_dir/claude-conf"
    chmod +x "$bin_dir/claude-conf"

    # Save repo path for the CLI to find
    echo "$SCRIPT_DIR" > "$HOME/.claude-conf-path"

    # Track installed modules
    touch "$SCRIPT_DIR/.installed"
}

track_module() {
    local mod="$1"
    local file="$SCRIPT_DIR/.installed"
    if ! grep -q "^${mod}$" "$file" 2>/dev/null; then
        echo "$mod" >> "$file"
    fi
}

show_banner

# Always install the CLI first
install_cli

# Non-interactive mode: --all flag
if [ "$1" = "--all" ]; then
    echo -e "${BOLD}  Installing all modules...${NC}"

    success=0
    failed=0

    for module in "${MODULES[@]}"; do
        if install_module "$module"; then
            ((success++))
        else
            ((failed++))
        fi
    done

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Installation complete${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}Installed: ${success}${NC}  ${RED}Failed: ${failed}${NC}"
    echo ""
    exit 0
fi

# Interactive mode
show_modules

echo -e "  ${BOLD}Options:${NC}"
echo -e "    ${DIM}Enter module numbers separated by spaces (e.g. 1 2)${NC}"
echo -e "    ${DIM}Type 'all' to install everything${NC}"
echo -e "    ${DIM}Type 'q' to quit${NC}"
echo ""
echo -ne "  ${BOLD}Your choice: ${NC}"
read -r choice

if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
    echo ""
    echo -e "  ${DIM}Nothing installed. Goodbye.${NC}"
    echo ""
    exit 0
fi

# Determine which modules to install
selected=()

if [ "$choice" = "all" ] || [ "$choice" = "ALL" ]; then
    selected=("${MODULES[@]}")
else
    for num in $choice; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#MODULES[@]}" ]; then
            local_idx=$((num - 1))
            selected+=("${MODULES[$local_idx]}")
        else
            echo -e "${YELLOW}  Warning: ignoring invalid selection '$num'${NC}"
        fi
    done
fi

if [ ${#selected[@]} -eq 0 ]; then
    echo ""
    echo -e "  ${YELLOW}No valid modules selected. Nothing to install.${NC}"
    echo ""
    exit 0
fi

echo ""
echo -e "  ${BOLD}Will install:${NC} ${selected[*]}"

success=0
failed=0

for module in "${selected[@]}"; do
    if install_module "$module"; then
        ((success++))
    else
        ((failed++))
    fi
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Installation complete${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${GREEN}Installed: ${success}${NC}  ${RED}Failed: ${failed}${NC}"
echo ""

if [ $failed -eq 0 ]; then
    echo -e "  ${DIM}Restart Claude Code for changes to take effect.${NC}"
    echo ""
fi
