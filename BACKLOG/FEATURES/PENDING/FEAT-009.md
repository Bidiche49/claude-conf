# FEAT-009: supervisor-guard — hook PreToolUse pour bloquer Write/Edit en mode supervisor

**Type:** Feature
**Statut:** A faire
**Priorite:** Haute
**Complexite:** S
**Tags:** security, supervisor
**Date creation:** 2026-03-21

---

## Description

La règle "TU NE TOUCHES JAMAIS AU CODE" du supervisor est purement comportementale — rien n'empêche techniquement le supervisor d'utiliser Write/Edit sur du code source. Un hook PreToolUse doit bloquer mécaniquement ces opérations quand le mode supervisor est actif.

Même pattern que FEAT-006 (scope-enforcer pour workers) mais inversé : au lieu d'une whitelist de fichiers, c'est une whitelist de répertoires autorisés.

## User Story

**En tant que** utilisateur du mode supervisor
**Je veux** que le supervisor soit mécaniquement bloqué s'il tente d'écrire du code
**Afin de** garantir la séparation des rôles supervisor/worker

## Design

### Détection du mode supervisor

Le hook vérifie si un fichier marqueur existe :
```
.claude-sessions/supervisor-active/{session_id}
```

Ce fichier est créé par le supervisor au démarrage (ajout dans supervisor.md startup sequence) et supprimé à la fin de session.

### Whitelist supervisor

Le supervisor peut UNIQUEMENT écrire dans :
- `BACKLOG/**` (tickets)
- `.claude-sessions/**` (handoff, manifests, prompts, scope files)
- `INDEX.md`

Tout autre Write/Edit → exit 2 avec message : "Mode supervisor actif. Génère un prompt worker pour cette modification."

### Sans marqueur

Si pas de fichier `supervisor-active`, le hook est transparent (pass-through). Les sessions normales et workers ne sont pas affectées.

## Fichiers concernes

- `supervisor-guard/hooks/supervisor-guard.sh` — nouveau hook PreToolUse
- `supervisor-guard/install.sh` — installer le hook dans settings.json
- `supervisor/commands/supervisor.md` — créer le marqueur au startup, le supprimer à la fin

## Depends on

- FEAT-006 (scope-enforcer) — même pattern, partager la logique si possible

## Criteres d'acceptation

- [ ] En mode supervisor, Write/Edit sur du code source est bloqué
- [ ] En mode supervisor, Write/Edit sur BACKLOG/ et .claude-sessions/ passe
- [ ] Sans mode supervisor, aucun blocage
- [ ] Le message de blocage est clair et actionnable
- [ ] Le marqueur est créé au startup et nettoyé proprement

## Tests de validation

- [ ] Activer le mode supervisor, tenter un Write sur src/file.ts → bloqué
- [ ] Activer le mode supervisor, écrire un ticket BACKLOG → autorisé
- [ ] Session normale, Write sur src/file.ts → autorisé
