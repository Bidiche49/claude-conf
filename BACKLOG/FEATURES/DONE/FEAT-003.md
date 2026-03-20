# FEAT-003: Module oneshot — implementation rapide stack-agnostic

**Type:** Feature
**Statut:** Fait
**Priorite:** Basse
**Complexite:** XS
**Scope:** both
**Tags:** commands, workflow
**Date creation:** 2026-03-20

---

## Description

Creer un module `oneshot/` qui installe la commande `/oneshot` — un mode "explore → code → test" rapide qui skip le planning et va droit a l'implementation. La version actuelle est orientee JS/npm, il faut la rendre stack-agnostic.

## User Story

**En tant que** dev senior utilisant Claude Code
**Je veux** un mode "go fast" qui explore minimalement, code immediatement, et valide avec les outils de ma stack
**Afin de** implementer des features claires sans que Claude sur-reflechisse

## Livrable — Structure du module

```
oneshot/
├── README.md
├── install.sh
└── commands/
    └── oneshot.md
```

## Contenu de la commande `/oneshot`

Reprendre la commande existante avec ces modifications :

**Phase EXPLORE** — inchange (deja stack-agnostic)

**Phase CODE** — remplacer les references npm par du generique :
- "Run autoformatting scripts when done" → "Run the project's formatter if available"
- "Fix reasonable linter warnings" → "Fix linter warnings using the project's linter"

**Phase TEST** — rendre stack-agnostic :
Remplacer les references `npm run lint && npm run typecheck` et `npm test` par :

```
3. **TEST** (validate quality):
   - Detect the project stack from config files (package.json, pubspec.yaml, go.mod, Cargo.toml, pyproject.toml, composer.json, Makefile)
   - Run the stack's lint command, then typecheck/build if available
   - If checks fail: fix errors immediately and re-run
   - Stay in scope — don't run full test suite unless requested
   - For major changes only: run relevant tests with the appropriate test runner

   Stack detection:
   | File | Lint | Typecheck/Build |
   |---|---|---|
   | package.json | read "lint" script → run | read "typecheck"/"tsc" script → run |
   | pubspec.yaml | flutter analyze | flutter build (skip if slow) |
   | go.mod | go vet && golangci-lint run | go build ./... |
   | Cargo.toml | cargo clippy | cargo build |
   | pyproject.toml | ruff check | mypy |
   | composer.json | phpcs or phpstan | — |
   | Makefile | make lint | make build |
```

**Rules** — remplacer `MINIMAL TESTS: Lint + typecheck only` par `MINIMAL TESTS: Stack linter + typecheck only (unless user requests more)`

## install.sh — Comportement attendu

Simple, meme pattern que `supervisor/install.sh` :
1. Check dependencies (claude)
2. Copier `commands/oneshot.md` → `~/.claude/commands/oneshot.md`
3. Banner + resume

Pas de hook, pas de settings.json a modifier. Juste une commande.

## Criteres d'acceptation

- [ ] `bash install.sh` installe la commande
- [ ] `/oneshot implement X` fonctionne sur un projet Node
- [ ] `/oneshot implement X` fonctionne sur un projet non-Node (detection stack)
- [ ] Aucune reference a npm/node dans le prompt (stack-agnostic)
- [ ] L'install est idempotente

## Fichiers concernes

### A creer
- `oneshot/README.md`
- `oneshot/install.sh`
- `oneshot/commands/oneshot.md`
