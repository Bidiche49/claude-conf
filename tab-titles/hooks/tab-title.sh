#!/bin/bash
# Hook UserPromptSubmit — Met a jour le titre d'onglet Terminal dynamiquement
# Detecte le mode (supervisor/worker/normal) et le projet courant
#
# Titres:
#   ⚡ CC · projet        (session normale)
#   🔴 SUP · projet       (mode supervisor)
#   🟢 BUG-101 · projet   (worker sur un ticket)

# Lire l'input JSON du hook
INPUT=$(cat)

# Extraire le prompt (requiert jq)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# Nom du projet = dernier dossier du PWD
PROJECT=$(basename "$PWD")

# Fichier d'etat par session Claude Code (PPID = PID de claude)
STATE_FILE="/tmp/cc-tab-${PPID}"

# --- Detection de changement de mode ---

if echo "$PROMPT" | grep -qi '/supervisor'; then
    echo "SUP" > "$STATE_FILE"
fi

# Detecter un ticket dans le prompt (BUG-XXX, FEAT-XXX, IMP-XXX)
TICKET_MATCH=$(echo "$PROMPT" | grep -oE '(BUG|FEAT|IMP)-[0-9]+' | head -1)
if [ -n "$TICKET_MATCH" ]; then
    CONTEXT=$(echo "$PROMPT" | sed "s/.*${TICKET_MATCH}[^a-zA-Z]*//" | head -1 | cut -c1-30 | sed 's/[[:space:]]*$//')
    if [ -n "$CONTEXT" ]; then
        echo "WORK:${TICKET_MATCH}:${CONTEXT}" > "$STATE_FILE"
    else
        echo "WORK:${TICKET_MATCH}" > "$STATE_FILE"
    fi
fi

# --- Lire l'etat courant ---

STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "CC")

# --- Construire le titre ---

case "$STATE" in
    SUP)
        TITLE="🔴 SUP · ${PROJECT}"
        ;;
    WORK:*:*)
        TICKET=$(echo "$STATE" | cut -d: -f2)
        CTX=$(echo "$STATE" | cut -d: -f3-)
        TITLE="🟢 ${TICKET} ${CTX} · ${PROJECT}"
        ;;
    WORK:*)
        TICKET="${STATE#WORK:}"
        TITLE="🟢 ${TICKET} · ${PROJECT}"
        ;;
    *)
        TITLE="⚡ CC · ${PROJECT}"
        ;;
esac

# --- Appliquer le titre ---
# OSC 1 = set tab title only
# Ecrire sur /dev/tty pour bypasser la capture stdout de Claude Code
printf "\033]1;%s\007" "$TITLE" > /dev/tty 2>/dev/null

exit 0
