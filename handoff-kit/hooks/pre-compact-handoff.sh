#!/bin/bash
# Hook PreCompact - Handoff automatique avant compactage
# Se declenche AUTOMATIQUEMENT quand le contexte est plein

set -e

# Lire l'input JSON du hook
input=$(cat)

# Extraire les informations
session_id=$(echo "$input" | jq -r '.session_id')
transcript_path=$(echo "$input" | jq -r '.transcript_path')
trigger=$(echo "$input" | jq -r '.trigger')
cwd=$(echo "$input" | jq -r '.cwd // empty')

# Timestamp pour le nom de fichier
timestamp=$(date +%Y%m%d-%H%M%S)

# Determiner le nom du projet
if [ -n "$cwd" ]; then
    project_name=$(basename "$cwd")
else
    project_name="unknown"
fi

# Dossiers de sauvegarde
global_backup_dir="$HOME/.claude/handoff-system/sessions"
local_backup_dir="$cwd/.claude-sessions"

# Creer les dossiers si necessaire
mkdir -p "$global_backup_dir"
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
    mkdir -p "$local_backup_dir"
fi

# Nom du fichier de backup
backup_name="AUTOBACKUP-${project_name}-${timestamp}"

# Copier le transcript JSON (sauvegarde brute)
if [ -f "$transcript_path" ]; then
    cp "$transcript_path" "$global_backup_dir/${backup_name}.json"

    if [ -n "$cwd" ] && [ -d "$cwd" ]; then
        cp "$transcript_path" "$local_backup_dir/${backup_name}.json"
    fi
fi

# Generer un fichier de resume basique
cat > "$global_backup_dir/${backup_name}.md" << EOF
# Auto-Backup Session - $timestamp

**Projet:** $project_name
**Session ID:** $session_id
**Trigger:** $trigger (auto = contexte plein, manual = /compact)
**Date:** $(date '+%Y-%m-%d %H:%M:%S')

---

## Fichiers sauvegardes

- Transcript JSON: \`${backup_name}.json\`
- Ce fichier: \`${backup_name}.md\`

## Pour reprendre

1. Ouvrir une nouvelle conversation Claude Code dans le meme projet
2. Demander a Claude de lire le transcript:

\`\`\`
Lis le fichier ~/.claude/handoff-system/sessions/${backup_name}.json
et resume-moi ce qui a ete fait. Genere un prompt de continuation.
\`\`\`

## Note

Ce backup a ete cree AUTOMATIQUEMENT par le hook PreCompact.
Pour des sauvegardes plus propres avec prompt de continuation optimise,
utiliser la commande \`/handoff\` AVANT que le contexte soit plein.

---

*Systeme de handoff automatique - ~/.claude/hooks/pre-compact-handoff.sh*
EOF

# Copie locale aussi
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
    cp "$global_backup_dir/${backup_name}.md" "$local_backup_dir/${backup_name}.md"
fi

# Log l'evenement
echo "[$(date '+%Y-%m-%d %H:%M:%S')] PreCompact triggered ($trigger) - Saved: $backup_name" >> "$HOME/.claude/handoff-system/handoff.log"

# Retourner un message pour Claude (sera affiche dans la conversation)
cat << EOF
{
  "result": "HANDOFF AUTO: Session sauvegardee dans ~/.claude/handoff-system/sessions/${backup_name}.md\n\nSi tu veux un prompt de continuation propre, tape /handoff maintenant AVANT de continuer."
}
EOF
