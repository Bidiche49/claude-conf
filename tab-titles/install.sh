#!/bin/bash
# ── Claude Code Tab Titles — Install Script ──────────────────────
# Installe les titres d'onglets intelligents pour Claude Code
# Compatible: macOS Terminal.app + zsh/oh-my-zsh
#
# Usage: bash install.sh

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}── Claude Code Tab Titles ──${NC}"
echo ""

# ── 1. Verifier les dependances ──────────────────────────────────

echo -e "${BLUE}[1/4]${NC} Verification des dependances..."

if ! command -v claude &>/dev/null; then
    echo -e "${RED}✗ Claude Code non trouve. Installe-le d'abord: npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo -e "${YELLOW}! jq non trouve. Installation via Homebrew...${NC}"
    if command -v brew &>/dev/null; then
        brew install jq
    else
        echo -e "${RED}✗ Homebrew requis pour installer jq. Installe jq manuellement.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓${NC} Claude Code + jq disponibles"

# ── 2. Installer le hook ─────────────────────────────────────────

echo -e "${BLUE}[2/4]${NC} Installation du hook tab-title.sh..."

HOOK_DIR="$HOME/.claude/hooks"
mkdir -p "$HOOK_DIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/hooks/tab-title.sh" "$HOOK_DIR/tab-title.sh"
chmod +x "$HOOK_DIR/tab-title.sh"

echo -e "${GREEN}✓${NC} Hook installe dans $HOOK_DIR/tab-title.sh"

# ── 3. Configurer settings.json ──────────────────────────────────

echo -e "${BLUE}[3/4]${NC} Configuration de Claude Code settings.json..."

SETTINGS_FILE="$HOME/.claude/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    if grep -q "tab-title.sh" "$SETTINGS_FILE"; then
        echo -e "${GREEN}✓${NC} Hook deja configure dans settings.json"
    else
        echo -e "${YELLOW}!${NC} settings.json existe deja."
        echo "  Ajoute manuellement ce bloc dans hooks.UserPromptSubmit :"
        echo ""
        echo '    {'
        echo '      "matcher": "",'
        echo '      "hooks": ['
        echo '        {'
        echo '          "type": "command",'
        echo '          "command": "~/.claude/hooks/tab-title.sh"'
        echo '        }'
        echo '      ]'
        echo '    }'
        echo ""
        echo "  Voir README.md section 'Configuration manuelle' pour details."
    fi
else
    cat > "$SETTINGS_FILE" << 'SETTINGS'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/tab-title.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS
    echo -e "${GREEN}✓${NC} settings.json cree avec le hook"
fi

# ── 4. Ajouter les aliases shell ─────────────────────────────────

echo -e "${BLUE}[4/4]${NC} Configuration des aliases shell..."

ZSHRC="$HOME/.zshrc"
MARKER="# ── Claude Code Tab Titles"

END_MARKER="# ── End Claude Code Tab Titles"

if grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
    echo -e "${YELLOW}!${NC} Updating existing tab-titles block in .zshrc..."
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "/$MARKER/,/$END_MARKER/d" "$ZSHRC"
    else
        sed -i "/$MARKER/,/$END_MARKER/d" "$ZSHRC"
    fi
fi

cat >> "$ZSHRC" << 'ALIASES'

# ── Claude Code Tab Titles ───────────────────────────────────────
# https://github.com/Bidiche49/claude-conf/tree/main/tab-titles

# Couleur unique par projet (cksum = meme resultat bash/zsh)
# Palette sans rouge ni vert (reserves pour SUP et WORKER)
_cc_dot() {
    [[ "$1" == "claude-conf" ]] && echo "⚙️" && return
    local colors=(🟠 🟡 🔵 🟣 🟤 ⚫)
    local idx=$(( $(echo -n "$1" | cksum | cut -d' ' -f1) % 6 + 1 ))
    echo "${colors[$idx]}"
}

_cc_set_tab() { printf "\033]1;%s\007" "$1"; }
_cc_set_win() { printf "\033]2;%s\007" "$1"; }

# Auto-check updates at Claude Code launch (once per day, non-blocking)
_cc_check_updates() { command -v claude-conf &>/dev/null && claude-conf check 2>/dev/null; }

# Check if tab-titles module is disabled
_cc_disabled() { grep -q "^tab-titles$" "$HOME/.claude-conf-disabled" 2>/dev/null; }

# cc : session normale (also aliased as 'claude')
cc() {
    _cc_check_updates
    if _cc_disabled; then command claude "$@"; return; fi
    local p=$(basename "$PWD") d=$(_cc_dot "$p")
    _cc_set_win "${d} ${p}"
    _cc_set_tab "${d} CC"
    CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1 command claude "$@"
}

# ccs : mode supervisor
ccs() {
    _cc_check_updates
    if _cc_disabled; then command claude "$@"; return; fi
    local p=$(basename "$PWD") d=$(_cc_dot "$p")
    _cc_set_win "${d} ${p}"
    _cc_set_tab "🔴 SUP"
    CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1 command claude "$@"
}

# ccd : mode dangerously-skip-permissions
ccd() {
    _cc_check_updates
    if _cc_disabled; then command claude --dangerously-skip-permissions "$@"; return; fi
    local p=$(basename "$PWD") d=$(_cc_dot "$p")
    _cc_set_win "${d} ${p}"
    _cc_set_tab "${d} CC"
    CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1 command claude --dangerously-skip-permissions "$@"
}

# ccw : mode worker sur un ticket
# Usage: ccw BUG-101
ccw() {
    _cc_check_updates
    if _cc_disabled; then command claude "$@"; return; fi
    local label="${1:-WORK}"
    shift 2>/dev/null
    local p=$(basename "$PWD") d=$(_cc_dot "$p")
    _cc_set_win "${d} ${p}"
    _cc_set_tab "🟢 ${label}"
    CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1 command claude "$@"
}

# 'claude' → 'cc' (tab titles always active)
alias claude=cc

# Titre intelligent pour shells normaux (non-Claude)
precmd_claude_conf() {
    printf "\033]1;%s\007" "$(basename "$PWD") — zsh"
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd precmd_claude_conf
# ── End Claude Code Tab Titles ───────────────────────────────────
ALIASES
echo -e "${GREEN}✓${NC} Tab-titles block installed in .zshrc"

# ── 5. oh-my-zsh auto-title ───────────────────────────────────────

if grep -q 'oh-my-zsh' "$ZSHRC" 2>/dev/null; then
    if grep -q '^# DISABLE_AUTO_TITLE="true"' "$ZSHRC" 2>/dev/null; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' 's/^# DISABLE_AUTO_TITLE="true"/DISABLE_AUTO_TITLE="true"/' "$ZSHRC"
        else
            sed -i 's/^# DISABLE_AUTO_TITLE="true"/DISABLE_AUTO_TITLE="true"/' "$ZSHRC"
        fi
        echo -e "${GREEN}✓${NC} oh-my-zsh DISABLE_AUTO_TITLE enabled (was commented out)"
    elif grep -q '^DISABLE_AUTO_TITLE="true"' "$ZSHRC" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} oh-my-zsh DISABLE_AUTO_TITLE already enabled"
    else
        echo -e "${YELLOW}!${NC} oh-my-zsh detected but DISABLE_AUTO_TITLE not found"
        echo "  Add ${YELLOW}DISABLE_AUTO_TITLE=\"true\"${NC} to your .zshrc (before source oh-my-zsh)"
    fi
fi

# ── Done ─────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}── Installation terminee ! ──${NC}"
echo ""
echo "Etapes manuelles requises (une seule fois) :"
echo "  Terminal.app → Reglages → Profils → onglet Tab :"
echo "    → Decocher 'Working directory or document'"
echo "    → Decocher 'Active process name'"
echo "    → Decocher 'Show activity indicator'"
echo "  Terminal.app → Reglages → Profils → onglet Window :"
echo "    → Decocher 'Working directory or document'"
echo "    → Decocher 'Active process name'"
echo "    → Garder 'Dimensions' coche"
echo ""
echo "Puis:"
echo "  source ~/.zshrc"
echo ""
echo "Commandes disponibles :"
echo "  cc           Session Claude Code normale"
echo "  ccs          Mode supervisor"
echo "  ccd          Mode skip-permissions"
echo "  ccw BUG-101  Mode worker sur un ticket"
echo ""
echo "Chaque projet obtient automatiquement un rond de couleur unique."
