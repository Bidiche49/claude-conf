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

MODULES=("tab-titles" "handoff-kit" "supervisor" "closing" "comptable" "command-guard" "critical-thinking" "pre-commit-gate" "backlog-kit" "claude-md-kit" "setup-project" "api-contract" "scope-enforcer" "post-tool-use" "audit" "factorize")
DESCRIPTIONS=(
    "Smart terminal tab titles for Claude Code sessions"
    "Context monitoring, automatic backups, and session handoff"
    "CTO mode — investigate, delegate to workers, validate, never write code"
    "Freelance closing — mission analysis, scoping, quoting, CDC protection"
    "Expert-comptable / fiscaliste — optimisation FR, expatriation, patrimoine"
    "PreToolUse hook that validates every shell command before execution"
    "Anti-complacency rules — sparring partner mode for Claude Code"
    "Reminder to run /check before committing — with universal stack detection"
    "Universal ticketing system with automatic ID protection"
    "Three slash commands to generate, clean up, and optimize CLAUDE.md"
    "Project bootstrap for Claude Code — auto-detect stack, configure permissions"
    "API contract management — sync reminders for split frontend/backend projects"
    "PreToolUse hook — block writes outside worker scope"
    "PostToolUse hook — manifest of modified files and test failure detection"
    "Deep code audit — security, tests, architecture, performance"
    "Scan for duplication & factorization opportunities across the codebase"
)
DEPS=(
    "jq"
    "bun, jq"
    "none"
    "none"
    "none"
    "bun, jq"
    "none"
    "none"
    "none"
    "none"
    "none"
    "jq"
    "jq"
    "jq"
    "none"
    "none"
)

# ── Helpers ───────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

QUIET_MODE=0

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

    if [ "$QUIET_MODE" -eq 1 ]; then
        # Quiet mode: one line per module, suppress sub-installer output
        if (cd "$module_dir" && bash install.sh > /dev/null 2>&1); then
            track_module "$module"
            echo -e "  ${GREEN}✓${NC} ${module}"
        else
            echo -e "  ${RED}✗${NC} ${module} ${DIM}(failed)${NC}"
            return 1
        fi
    else
        # Verbose mode: full output from sub-installers
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}  Installing: ${module}${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        if (cd "$module_dir" && bash install.sh); then
            track_module "$module"
            echo ""
            echo -e "${GREEN}  ✓ ${module} installed successfully${NC}"
        else
            echo ""
            echo -e "${RED}  ✗ ${module} installation failed${NC}"
            return 1
        fi
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

install_shell_aliases() {
    # Install base shell aliases in .zshrc (or .bashrc)
    # These provide cc, ccd, ccupdate without requiring tab-titles
    # If tab-titles is installed later, it replaces this block with an enhanced version

    local ZSHRC="$HOME/.zshrc"
    local BASHRC="$HOME/.bashrc"
    local TARGET=""

    if [ -f "$ZSHRC" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
        TARGET="$ZSHRC"
    elif [ -f "$BASHRC" ]; then
        TARGET="$BASHRC"
    else
        TARGET="$ZSHRC"
    fi

    local MARKER="# ── Claude Code Aliases"
    local END_MARKER="# ── End Claude Code Aliases"

    # If tab-titles block already exists, skip — it has the enhanced versions
    if grep -q "# ── Claude Code Tab Titles" "$TARGET" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Shell aliases already managed by tab-titles"
        return 0
    fi

    # Remove existing base aliases block if present (idempotent update)
    if grep -q "$MARKER" "$TARGET" 2>/dev/null; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "/$MARKER/,/$END_MARKER/d" "$TARGET"
        else
            sed -i "/$MARKER/,/$END_MARKER/d" "$TARGET"
        fi
    fi

    cat >> "$TARGET" << 'ALIASES'

# ── Claude Code Aliases ─────────────────────────────────────────
# Base aliases installed by claude-conf (https://github.com/Bidiche49/claude-conf)
# Install tab-titles module for enhanced versions with smart terminal titles

# cc : session normale
cc() { command claude "$@"; }

# ccd : mode dangerously-skip-permissions
ccd() { command claude --dangerously-skip-permissions "$@"; }

# ccupdate : mise a jour complete claude-conf (pull + reinstall all + reload)
ccupdate() {
    local conf_dir
    conf_dir=$(cat "$HOME/.claude-conf-path" 2>/dev/null)
    if [ -z "$conf_dir" ] || [ ! -d "$conf_dir/.git" ]; then
        echo "claude-conf repo not found. Run install.sh first."
        return 1
    fi
    echo "Pulling latest..."
    git -C "$conf_dir" pull || return 1
    echo "Reinstalling all modules..."
    bash "$conf_dir/install.sh" --all
    echo "Reloading shell..."
    if [ -n "$ZSH_VERSION" ]; then
        source ~/.zshrc
    elif [ -n "$BASH_VERSION" ]; then
        source ~/.bashrc
    fi
    echo "Done."
}

alias claude=cc
# ── End Claude Code Aliases ─────────────────────────────────────
ALIASES
    echo -e "  ${GREEN}✓${NC} Shell aliases installed in $(basename "$TARGET") (cc, ccd, ccupdate)"
}

track_module() {
    local mod="$1"
    local file="$SCRIPT_DIR/.installed"
    if ! grep -q "^${mod}$" "$file" 2>/dev/null; then
        echo "$mod" >> "$file"
    fi
}

show_banner

# Always install the CLI and base aliases first
install_cli
install_shell_aliases

# Non-interactive mode: --all flag (quiet output)
if [ "$1" = "--all" ]; then
    QUIET_MODE=1
    echo -e "${BOLD}  Installing all modules...${NC}"
    echo ""

    success=0
    failed=0

    for module in "${MODULES[@]}"; do
        if install_module "$module"; then
            success=$((success + 1))
        else
            failed=$((failed + 1))
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
        success=$((success + 1))
    else
        failed=$((failed + 1))
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
