#!/bin/bash
# Hook UserPromptSubmit - Injecte un rappel handoff si contexte > seuil
# NOTE: Ce hook lit le fichier ~/.claude/context-data/<session_id>.txt ecrit par le statusline.

set -e

# Lire l'input JSON du hook pour obtenir session_id et la question
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
user_prompt=$(echo "$input" | jq -r '.prompt // empty')

# Fichier de contexte par session
CONTEXT_FILE="$HOME/.claude/context-data/${session_id}.txt"

if [ -n "$session_id" ] && [ -f "$CONTEXT_FILE" ]; then
    used_percentage=$(cat "$CONTEXT_FILE" 2>/dev/null | cut -d'.' -f1)
else
    used_percentage=0
fi

# Fallback si valeur invalide
if ! [[ "$used_percentage" =~ ^[0-9]+$ ]]; then
    used_percentage=0
fi

# Seuils
WARN_THRESHOLD=65
CRITICAL_THRESHOLD=80

# Dossier pour les questions en attente
PENDING_DIR="$HOME/.claude/handoff-system/pending"
mkdir -p "$PENDING_DIR"

# Si contexte > seuil, injecter un rappel via texte brut (stdout)
if [ "$used_percentage" -ge "$CRITICAL_THRESHOLD" ]; then
    # Sauvegarder la question de l'utilisateur pour le handoff
    if [ -n "$user_prompt" ] && [ -n "$session_id" ]; then
        echo "$user_prompt" > "$PENDING_DIR/${session_id}.txt"
    fi
    echo "[SYSTEM-HANDOFF-CRITICAL] Contexte a ${used_percentage}%. STOP. Execute /handoff MAINTENANT avant de continuer. Ne reponds PAS a l'utilisateur avant d'avoir fait le handoff."
elif [ "$used_percentage" -ge "$WARN_THRESHOLD" ]; then
    echo "[SYSTEM-HANDOFF-WARNING] Contexte a ${used_percentage}%. Pense a faire /handoff bientot si la tache est longue."
fi

exit 0
