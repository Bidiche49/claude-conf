# FEAT-010: Module setup-project — bootstrap projet intelligent avec detection stack

**Type:** Feature
**Statut:** Fait
**Priorite:** Haute
**Complexite:** M
**Tags:** module, onboarding, stack-detection
**Depends on:** none
**Blocked by:** —
**Date creation:** 2026-03-21

---

## Description

Creer un module `setup-project/` qui bootstrap un projet Claude Code en une commande. Detection automatique de la stack, configuration des permissions, generation des commandes projet, et orchestration des modules existants (backlog-init, claude-md-init).

L'intelligence du module c'est la detection stack : tu arrives sur un projet Flutter, il detecte Flutter, il configure les permissions Flutter, il genere un /start et /review adaptes Flutter, il lance claude-md-init et backlog-init. Zero config manuelle.

## User Story

**En tant que** utilisateur de Claude Code arrivant sur un nouveau projet
**Je veux** une seule commande qui configure tout automatiquement
**Afin de** commencer a travailler en 30 secondes au lieu de 15 minutes de setup manuel

## Livrable — Structure du module

```
setup-project/
├── README.md
├── install.sh
└── commands/
    ├── setup-project.md          ← Orchestrateur principal
    ├── start.md                  ← Debut de session (contexte)
    └── review.md                 ← Auto-review avant commit
```

## Detection stack — le coeur du module

Le setup detecte la stack en scannant les fichiers de config a la racine :

| Fichier detecte | Stack | Permissions auto | Lint | Test |
|---|---|---|---|---|
| `pubspec.yaml` | Flutter/Dart | `Bash(flutter *)`, `Bash(dart *)` | `flutter analyze` | `flutter test` |
| `package.json` | Node/JS/TS | `Bash(npm *)`, `Bash(npx *)`, `Bash(node *)` | lire scripts.lint | lire scripts.test |
| `go.mod` | Go | `Bash(go *)` | `go vet`, `golangci-lint run` | `go test ./...` |
| `Cargo.toml` | Rust | `Bash(cargo *)` | `cargo clippy` | `cargo test` |
| `pyproject.toml` ou `requirements.txt` | Python | `Bash(python *)`, `Bash(pip *)`, `Bash(pytest *)` | `ruff check` | `pytest` |
| `composer.json` | PHP | `Bash(composer *)`, `Bash(php *)` | `phpcs` ou `phpstan` | `phpunit` |
| `Gemfile` | Ruby | `Bash(bundle *)`, `Bash(ruby *)`, `Bash(rails *)` | `rubocop` | `rspec` ou `rails test` |
| `*.xcodeproj` ou `Package.swift` | iOS/Swift | `Bash(xcodebuild *)`, `Bash(swift *)` | `swiftlint` | `xcodebuild test` |
| `Makefile` | Generic | `Bash(make *)` | `make lint` | `make test` |

Toujours ajouter : `Bash(git *)` pour tout le monde.

Pour Node/JS : lire `package.json` scripts pour trouver les VRAIS noms (lint, test, typecheck, build). Ne pas deviner.

## Commande 1 : `/setup-project`

```markdown
---
description: Bootstrap a project for Claude Code — auto-detect stack, configure permissions, generate commands
argument-hint: [optional project description]
---
```

### Comportement

**Phase 1 — Detection**
1. Scanner les fichiers de config a la racine (tableau ci-dessus)
2. Detecter la stack principale
3. Si plusieurs stacks detectees (monorepo, split front/back) → lister et demander confirmation
4. Lire `package.json` / `Makefile` / etc. pour extraire les vraies commandes
5. `git log --oneline -10` pour contexte

**Phase 2 — Permissions** (`.claude/settings.json`)
1. Si `.claude/settings.json` existe → lire les permissions existantes
2. Ajouter les permissions de la stack detectee (tableau ci-dessus) SANS ecraser les existantes
3. Merge propre (meme pattern que les install.sh des modules)
4. Presenter les permissions ajoutees a l'utilisateur

**Phase 3 — Git commit rules** (`.claude/git-commit-rules.md`)
1. Analyser `git log --oneline -20` pour detecter la convention existante :
   - Conventional commits (feat/fix/chore) ?
   - Langue (FR/EN) ?
   - Prefixe scope (feat(ui): ...) ?
   - References tickets dans les messages ?
2. Si convention detectee → generer un `git-commit-rules.md` qui la formalise
3. Si pas de convention claire → proposer un standard (conventional commits, langue du projet)
4. Presenter et attendre validation

**Phase 4 — .gitignore**
1. Verifier si `.gitignore` existe
2. Si `.claude-sessions/` n'est pas dedans → l'ajouter
3. Si `.gitignore` n'existe pas → ne pas le creer (le projet a peut-etre une raison)

**Phase 5 — Orchestration modules**
1. Verifier si BACKLOG/ existe → si non, executer la logique de `/backlog-init`
2. Verifier si CLAUDE.md existe → si non, executer la logique de `/claude-md-init` (avec la stack detectee en contexte)
3. Si CLAUDE.md existe deja → proposer `/claude-md-boost` (ne pas l'executer automatiquement)

**Phase 6 — Resume**
Afficher un resume clair :
```
SETUP COMPLETE — [project name]
══════════════════════════════
Stack detectee : Flutter/Dart
Permissions    : flutter *, dart *, git * (ajoutees a settings.json)
CLAUDE.md      : genere / deja present (boost recommande)
BACKLOG/       : initialise / deja present
Git rules      : .claude/git-commit-rules.md genere
.gitignore     : .claude-sessions/ ajoute

Commandes disponibles :
  /start    — charger le contexte en debut de session
  /review   — auto-review avant commit
  /check    — pipeline validation (lint + build + tests)
```

## Commande 2 : `/start`

```markdown
---
description: Load session context — git state, backlog, last handoff
---
```

### Comportement

1. `git status` + `git log --oneline -10`
2. Scanner BACKLOG/ : compter pending/done par type
3. Verifier si `.claude-sessions/HANDOFF-*.md` existe → si oui, mentionner le plus recent (1 ligne : date + sujet). NE PAS le charger automatiquement.
4. Lire CLAUDE.md (le projet, pas le global)
5. Afficher un resume :

```
SESSION — [project name] ([stack])
═══════════════════════════════
Git    : branch [main], 3 ahead, 2 fichiers modifies
Backlog: 5 pending (2 bugs, 2 feat, 1 imp) / 42 done
Handoff: HANDOFF-2026-03-21-1430.md (FEAT-067 — voting UI)
         → Si tu veux reprendre, dis-le moi.

Pret. Qu'est-ce qu'on fait ?
```

**Regles :**
- JAMAIS charger le handoff automatiquement — juste mentionner
- JAMAIS proposer de travailler sur quelque chose — attendre l'utilisateur
- Le resume doit tenir en 5-6 lignes max

## Commande 3 : `/review`

```markdown
---
description: Auto-review changes before committing — stack-aware checklist
---
```

### Comportement

1. `git diff --stat` pour voir ce qui a change
2. `git diff` pour lire les changements
3. Detecter la stack (meme logique que setup-project)
4. Pour chaque fichier modifie, verifier :

**Checklist universelle (toute stack) :**
- [ ] Noms revelent l'intention
- [ ] Pas de code mort (commente, variables inutilisees)
- [ ] Pas de debug (print, console.log, debugPrint)
- [ ] Diff coherent (pas de changements hors scope)
- [ ] Pas de secrets/credentials dans le diff

**Checklist stack-specifique :**

| Stack | Verifications supplementaires |
|---|---|
| Flutter/Dart | Pas de `print()` (utiliser Logger), `[weak self]` n/a, Freezed genere a jour, imports barrel |
| iOS/Swift | `[weak self]` dans closures async, `deinit` present, pas de force unwrap dynamique |
| React/Next | Hooks deps arrays complets, pas de state mutation directe, server/client boundary |
| Node/Express | Error handling middleware, async/await (pas de callbacks), validation input |
| Go | Errors wrapped/returned (pas ignores), goroutines avec context, defer pour cleanup |
| Python | Type hints, async/await coherent, pas de bare except |
| Rust | Result/Option geres (pas de unwrap en prod), ownership clair |

5. Si problemes trouves → les lister avec fichier:ligne et correction proposee
6. Si tout OK → "Review OK — ready to commit" + `git diff --stat`

**Regle :** la review ne corrige PAS automatiquement. Elle liste les problemes. L'utilisateur decide.

## install.sh — Comportement

1. Check deps (claude)
2. Copier les 3 commandes vers `~/.claude/commands/` (backup si existant)
3. Banner + resume

Pas de hook, pas de settings.json global. Le `/setup-project` configure le settings.json du PROJET, pas le global.

## Criteres d'acceptation

- [ ] `bash install.sh` installe les 3 commandes
- [ ] `/setup-project` detecte correctement Flutter, Node, Go, Python (au minimum)
- [ ] `/setup-project` configure les permissions dans `.claude/settings.json` du projet
- [ ] `/setup-project` genere `git-commit-rules.md` adapte au projet
- [ ] `/setup-project` lance backlog-init si pas de BACKLOG/
- [ ] `/setup-project` lance claude-md-init si pas de CLAUDE.md
- [ ] `/start` affiche git + backlog + handoff en 5-6 lignes
- [ ] `/start` ne charge PAS le handoff automatiquement
- [ ] `/review` detecte la stack et applique la checklist adaptee
- [ ] `/review` ne corrige PAS automatiquement
- [ ] L'install est idempotente

## Fichiers concernes

### A creer
- `setup-project/README.md`
- `setup-project/install.sh`
- `setup-project/commands/setup-project.md`
- `setup-project/commands/start.md`
- `setup-project/commands/review.md`
