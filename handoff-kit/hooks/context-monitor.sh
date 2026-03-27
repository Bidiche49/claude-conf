#!/bin/bash
# Hook UserPromptSubmit - Injecte un rappel handoff si contexte > seuil
# NOTE: Ce hook lit le fichier ~/.claude/context-data/<session_id>.txt ecrit par le statusline.

set -e

# Lire l'input JSON du hook pour obtenir session_id
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')

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

# Seuil
WARN_THRESHOLD=65

# Si contexte > seuil, injecter un rappel via texte brut (stdout)
# IMPORTANT: Le message ne doit PAS declencher le handoff automatiquement.
# Il doit UNIQUEMENT informer l'utilisateur, pas donner une instruction a Claude.
if [ "$used_percentage" -ge "$WARN_THRESHOLD" ]; then
    echo "[SYSTEM] Context usage: ${used_percentage}%. Mention briefly to the user: 'Context at ${used_percentage}% — /handoff is available when you want to save progress.' Do NOT run /handoff automatically. Continue working normally."
fi

exit 0
