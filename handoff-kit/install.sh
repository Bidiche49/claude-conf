#!/bin/bash
set -e

# ============================================================
# Claude Code Handoff System - Installer
# ============================================================

CLAUDE_DIR="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================"
echo "  Claude Code Handoff System - Installation"
echo "============================================"
echo ""

# ── Prerequis ──────────────────────────────────────────────
if ! command -v bun &> /dev/null; then
    echo "[!] Bun n'est pas installe."
    echo "    Installe-le avec : curl -fsSL https://bun.sh/install | bash"
    echo "    Puis relance ce script."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "[!] jq n'est pas installe."
    echo "    Installe-le avec : brew install jq (macOS) ou sudo apt install jq (Linux)"
    exit 1
fi

echo "[1/6] Creation des dossiers..."
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/scripts"
mkdir -p "$CLAUDE_DIR/context-data"
mkdir -p "$CLAUDE_DIR/handoff-system/sessions"
mkdir -p "$CLAUDE_DIR/handoff-system/pending"

echo "[2/6] Installation des hooks..."
cp "$SCRIPT_DIR/hooks/context-monitor.sh" "$CLAUDE_DIR/hooks/context-monitor.sh"
cp "$SCRIPT_DIR/hooks/pre-compact-handoff.sh" "$CLAUDE_DIR/hooks/pre-compact-handoff.sh"
chmod +x "$CLAUDE_DIR/hooks/context-monitor.sh"
chmod +x "$CLAUDE_DIR/hooks/pre-compact-handoff.sh"

echo "[3/6] Installation de la commande /handoff..."
cp "$SCRIPT_DIR/commands/handoff.md" "$CLAUDE_DIR/commands/handoff.md"

echo "[4/6] Installation de la statusline..."
if [ -d "$CLAUDE_DIR/scripts/statusline" ]; then
    echo "  -> Backup de l'ancienne statusline..."
    mv "$CLAUDE_DIR/scripts/statusline" "$CLAUDE_DIR/scripts/statusline.backup.$(date +%Y%m%d%H%M%S)"
fi
cp -r "$SCRIPT_DIR/statusline" "$CLAUDE_DIR/scripts/statusline"

echo "[5/6] Installation des dependances statusline..."
cd "$CLAUDE_DIR/scripts/statusline"
bun install picocolors
cd "$SCRIPT_DIR"

echo "[6/6] Configuration de settings.json..."

SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Creer settings.json s'il n'existe pas
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

# Backup settings existant
cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d%H%M%S)"

# Merge hooks dans settings.json avec jq
# On ajoute nos hooks sans ecraser les hooks existants
TEMP_SETTINGS=$(mktemp)

jq '
# Ajouter le hook UserPromptSubmit pour context-monitor
.hooks.UserPromptSubmit = (
  (.hooks.UserPromptSubmit // [])
  | map(select(.hooks[0].command != "~/.claude/hooks/context-monitor.sh"))
  | . + [{
      "matcher": "",
      "hooks": [{"type": "command", "command": "~/.claude/hooks/context-monitor.sh"}]
    }]
)
# Ajouter le hook PreCompact pour pre-compact-handoff
| .hooks.PreCompact = (
  (.hooks.PreCompact // [])
  | map(select(.hooks[0].command != "~/.claude/hooks/pre-compact-handoff.sh"))
  | . + [{
      "matcher": "",
      "hooks": [{"type": "command", "command": "~/.claude/hooks/pre-compact-handoff.sh"}]
    }]
)
# Ajouter la statusline (remplace si existante)
| .statusLine = {
    "type": "command",
    "command": "bun ~/.claude/scripts/statusline/src/index.ts",
    "padding": 0
  }
' "$SETTINGS_FILE" > "$TEMP_SETTINGS"

if [ $? -eq 0 ]; then
    mv "$TEMP_SETTINGS" "$SETTINGS_FILE"
else
    echo "[!] Erreur lors du merge settings.json."
    echo "    Ta config originale est sauvegardee dans $SETTINGS_FILE.backup.*"
    rm -f "$TEMP_SETTINGS"
    exit 1
fi

echo ""
echo "============================================"
echo "  Installation terminee !"
echo "============================================"
echo ""
echo "Ce qui a ete installe :"
echo "  - Hooks : context-monitor.sh + pre-compact-handoff.sh"
echo "  - Commande : /handoff"
echo "  - Statusline : affichage contexte % en temps reel"
echo "  - Settings.json : hooks et statusline configures"
echo ""
echo "IMPORTANT : Ajoute les regles handoff dans ton CLAUDE.md"
echo "(voir README.md section 'Instructions CLAUDE.md')"
echo ""
echo "Relance Claude Code pour que les changements prennent effet."
echo ""
