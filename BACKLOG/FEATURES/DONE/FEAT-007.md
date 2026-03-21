# FEAT-007: PostToolUse hook — manifest fichiers modifiés + détection tests fail

**Type:** Feature
**Statut:** A faire
**Priorite:** Haute
**Complexite:** S
**Tags:** supervisor, security
**Date creation:** 2026-03-21

---

## Description

Le hook PostToolUse n'est pas utilisé actuellement. Deux usages à implémenter :

1. **Manifest automatique** : après chaque Write/Edit, logger le path dans un manifest par session. Le supervisor compare le manifest au rapport worker pour détecter les divergences.

2. **Détection échec tests** : après chaque Bash contenant `test`/`check`/`pytest`/etc., si exit code ≠ 0, injecter un signal pour que le worker investigue avant de continuer.

## User Story

**En tant que** superviseur
**Je veux** une source de vérité mécanique sur les fichiers modifiés par chaque worker
**Afin de** comparer le déclaratif (rapport) au factuel (manifest) pendant la review

## Design

### Manifest par session

```
.claude-sessions/manifests/{session_id}.txt
```

Format : une ligne par opération, append-only :
```
2026-03-21T14:32:00 WRITE src/cli.ts
2026-03-21T14:32:15 EDIT src/lib/validator.ts
2026-03-21T14:33:00 EDIT src/lib/validator.ts
```

### Rotation

En fin de script, garder les 35 derniers manifests :
```bash
ls -t .claude-sessions/manifests/*.txt 2>/dev/null | tail -n +36 | xargs rm -f
```

### Détection tests

Si l'outil est `Bash` et que la commande matche `test|check|pytest|jest|vitest|bun test|flutter test` et que le exit code ≠ 0 :
```json
{"decision": "warn", "message": "Tests en échec. Investigue avant de continuer."}
```

### Session_id dans le format rapport worker

Le rapport worker doit inclure une ligne `Session: {session_id}` pour que le supervisor
sache quel manifest lire. Ajouter cette ligne dans le bloc rapport de supervisor.md :
```markdown
### Session
- **Session ID :** [session_id de cette conversation]
```

### Intégration supervisor

Le supervisor ajoute à sa validation :
1. Lire le session_id dans le rapport worker
2. Lire le manifest correspondant (`.claude-sessions/manifests/{session_id}.txt`)
3. Comparer avec la section "Fichiers modifiés" du rapport
4. Signaler toute divergence

## Fichiers concernes

- `post-tool-use/hooks/post-tool-use.sh` — nouveau hook
- `post-tool-use/install.sh` — installer dans settings.json
- `supervisor/commands/supervisor.md` — étape de validation manifest vs rapport

## Criteres d'acceptation

- [ ] Chaque Write/Edit est loggé dans le manifest session
- [ ] Les manifests sont rotés à 35 fichiers max
- [ ] Les échecs de test injectent un warning
- [ ] Le hook est rapide (< 50ms)
- [ ] Sans manifest existant, le hook le crée
- [ ] Le supervisor sait lire et comparer le manifest

## Tests de validation

- [ ] Faire 3 edits, vérifier que le manifest contient 3 lignes
- [ ] Lancer un test qui fail, vérifier le warning
- [ ] Accumuler 40 manifests, vérifier qu'il en reste 35
