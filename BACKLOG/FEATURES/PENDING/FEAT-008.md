# FEAT-008: launch-worker — script de lancement worker avec config cc/ccd

**Type:** Feature
**Statut:** A faire
**Priorite:** Haute
**Complexite:** S
**Tags:** supervisor, ux
**Date creation:** 2026-03-21

---

## Description

Le flow supervisor→worker est actuellement 100% clipboard : copier le prompt, ouvrir un terminal, le coller. 5-6 étapes manuelles par worker.

Un script `launch-worker.sh` généré par le supervisor ouvrirait un nouveau terminal avec le prompt pré-chargé. L'user exécute le script (1 action), voit le worker travailler, peut intervenir, garde le contexte dédié 1M tokens.

Paramètre configurable one-time : `cc` (Claude Code normal) ou `ccd` (dangerously skip permissions).

## User Story

**En tant que** utilisateur du supervisor
**Je veux** lancer un worker en une seule action
**Afin de** réduire la friction sans perdre la visibilité ni le contexte dédié

## Design

### Configuration one-time

Fichier `~/.claude-conf/worker.conf` :
```bash
WORKER_COMMAND="ccd"  # ou "cc"
```

Settable via :
- `claude-conf config worker-command ccd`
- Ou manuellement dans le fichier

### Script généré par le supervisor

Le supervisor génère pour chaque worker :
```bash
#!/bin/bash
# .claude-sessions/launch/worker-BUG-003.sh
source ~/.claude-conf/worker.conf 2>/dev/null
CMD="${WORKER_COMMAND:-cc}"

$CMD --prompt-file .claude-sessions/prompts/BUG-003.md
```

Le prompt worker est écrit dans un fichier séparé (`.claude-sessions/prompts/BUG-003.md`) plutôt qu'inline dans le script.

### Flow complet

1. Le supervisor investigue et génère le prompt
2. Le supervisor écrit le prompt dans `.claude-sessions/prompts/TICKET-ID.md`
3. Le supervisor écrit le script de lancement dans `.claude-sessions/launch/worker-TICKET-ID.sh`
4. Le supervisor dit : "Lance avec `bash .claude-sessions/launch/worker-BUG-003.sh`"
5. L'user exécute dans un nouveau terminal
6. Le worker travaille avec contexte dédié 1M
7. L'user peut observer et intervenir
8. Le worker produit son rapport

### Cleanup

Les fichiers prompts et scripts sont nettoyés quand le supervisor valide et commite.

## Fichiers concernes

- `supervisor/commands/supervisor.md` — générer script + prompt file au lieu de texte à copier
- `bin/claude-conf` — commande `claude-conf config worker-command <cc|ccd>`
- `~/.claude-conf/worker.conf` — fichier de config

## Criteres d'acceptation

- [ ] Le supervisor génère un script exécutable par worker
- [ ] Le prompt est dans un fichier séparé référencé par le script
- [ ] La config `cc`/`ccd` est respectée
- [ ] Default à `cc` si pas de config
- [ ] Le script fonctionne sur macOS et Linux

## Tests de validation

- [ ] Configurer `ccd`, lancer le script, vérifier que c'est `ccd` qui s'exécute
- [ ] Sans config, vérifier que `cc` est utilisé par défaut
- [ ] Vérifier que le prompt file contient le bon contenu
