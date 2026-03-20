#!/bin/bash
# Hook UserPromptSubmit — Met a jour le titre d'onglet + fenetre Terminal.app
# Detecte le mode (supervisor/worker/normal) et le projet courant
#
# Priorite: supervisor > ticket > normal

# Skip if module is disabled
grep -q "^tab-titles$" "$HOME/.claude-conf-disabled" 2>/dev/null && exit 0
# Titres:
#   🔴 SUP · projet       (mode supervisor)
#   🟢 BUG-101 · projet   (worker sur un ticket)
#   ⚡ CC · projet         (session normale)

# Lire l'input JSON
INPUT=$(cat)

# Extraire le prompt (jq disponible - utilise par context-monitor.sh)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# Nom du projet
PROJECT=$(basename "$PWD")

# Couleur unique par projet (hash du nom)
_dot() {
    local colors=("🟠" "🟡" "🔵" "🟣" "🟤" "🩷" "🩵" "🟧")
    local idx=$(( $(echo -n "$1" | cksum | cut -d' ' -f1) % 8 ))
    echo "${colors[$idx]}"
}

DOT=$(_dot "$PROJECT")

# Fichier d'etat par session Claude Code (PPID = PID de claude)
STATE_FILE="/tmp/cc-tab-${PPID}"

# --- Detection de changement de mode (PRIORITE : supervisor > ticket) ---

CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "CC")

if echo "$PROMPT" | grep -qi '/supervisor'; then
    echo "SUP" > "$STATE_FILE"
elif [ "$CURRENT_STATE" != "SUP" ] && [ -n "$PROMPT" ]; then
    # Detecter un ticket SEULEMENT si on n'est PAS en mode supervisor
    TICKET_MATCH=$(echo "$PROMPT" | grep -oE '(BUG|FEAT|IMP)-[0-9]+' | head -1)
    if [ -n "$TICKET_MATCH" ]; then
        CONTEXT=$(echo "$PROMPT" | sed "s/.*${TICKET_MATCH}[^a-zA-Z]*//" | head -1 | cut -c1-30 | sed 's/[[:space:]]*$//')
        if [ -n "$CONTEXT" ]; then
            echo "WORK:${TICKET_MATCH}:${CONTEXT}" > "$STATE_FILE"
        else
            echo "WORK:${TICKET_MATCH}" > "$STATE_FILE"
        fi
    fi
fi

# --- Lire l'etat courant ---

STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "CC")

# --- Construire le titre ---

case "$STATE" in
    SUP)
        TAB_TITLE="🔴 SUP"
        ;;
    WORK:*:*)
        TICKET=$(echo "$STATE" | cut -d: -f2)
        CTX=$(echo "$STATE" | cut -d: -f3-)
        TAB_TITLE="🟢 ${TICKET} ${CTX}"
        ;;
    WORK:*)
        TICKET="${STATE#WORK:}"
        TAB_TITLE="🟢 ${TICKET}"
        ;;
    *)
        TAB_TITLE="${DOT} CC"
        ;;
esac

# --- Appliquer le titre (OSC 1 = tab UNIQUEMENT, fenetre ne bouge jamais) ---
printf "\033]1;%s\007" "$TAB_TITLE" > /dev/tty 2>/dev/null

exit 0
