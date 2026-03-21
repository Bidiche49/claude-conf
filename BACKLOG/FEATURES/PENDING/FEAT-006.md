# FEAT-006: scope-enforcer — hook PreToolUse pour bloquer écriture hors scope worker

**Type:** Feature
**Statut:** A faire
**Priorite:** Haute
**Complexite:** M
**Tags:** security, supervisor
**Date creation:** 2026-03-21

---

## Description

Le supervisor déclare un scope strict par worker (liste de fichiers autorisés) mais cette contrainte est purement comportementale — rien n'empêche techniquement le worker de modifier un fichier hors scope.

Un hook PreToolUse sur Write/Edit qui compare le fichier cible à une liste autorisée transforme cette promesse en garantie technique.

## User Story

**En tant que** superviseur
**Je veux** que les workers soient mécaniquement bloqués s'ils tentent d'écrire hors scope
**Afin de** garantir zéro conflit fichier en exécution parallèle

## Design

### Fichier de scope

Le supervisor écrit avant chaque worker :
```json
// .claude-sessions/worker-scope/{session_id}.json
{
  "allowed_files": ["src/cli.ts", "src/lib/validator.ts"],
  "forbidden_files": ["src/types.ts"],
  "worker_ticket": "BUG-003",
  "created_by_supervisor": "session_abc123"
}
```

### Hook PreToolUse

Script shell qui :
1. Détecte si un fichier de scope existe pour la session courante
2. Si oui, vérifie que le fichier cible est dans `allowed_files`
3. Si hors scope → exit 2 avec message explicite ("fichier hors scope, contactez le supervisor")
4. Si pas de fichier de scope → laisse passer (mode normal, pas de supervisor actif)

### Intégration supervisor

Le prompt worker du supervisor doit :
1. Écrire le fichier de scope AVANT de générer le prompt worker
2. Inclure dans le prompt : "Un hook bloque les écritures hors scope. Si tu as besoin de toucher un fichier non listé, note-le dans le rapport."

### Boy scout integration

Le rapport worker ajoute une section :
```markdown
### Tests manquants (boy scout)
- `path/to/file.ext` — pas de test pour [fonctionnalité]. Suggestion : [type de test]
```

Le supervisor crée des tickets IMP pour chaque entrée.

## Fichiers concernes

- `scope-enforcer/hooks/scope-check.sh` — nouveau hook PreToolUse
- `scope-enforcer/install.sh` — installer le hook dans settings.json
- `supervisor/commands/supervisor.md` — ajouter l'écriture du fichier scope + section rapport boy scout

## Criteres d'acceptation

- [ ] Un worker ne peut pas écrire dans un fichier non listé dans son scope
- [ ] Sans fichier de scope, le hook est transparent (pass-through)
- [ ] Le message de blocage est clair et actionnable
- [ ] Le format rapport worker inclut la section tests manquants
- [ ] Le supervisor documente comment écrire le fichier de scope

## Tests de validation

- [ ] Créer un scope avec 2 fichiers autorisés, tenter d'écrire un 3ème → bloqué
- [ ] Sans fichier de scope → écriture libre
- [ ] Vérifier que le hook ne ralentit pas l'UX (< 50ms)
