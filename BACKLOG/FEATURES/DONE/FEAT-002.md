# FEAT-002: Module pre-commit-gate — rappel /check avant commit + commande /check generique

**Type:** Feature
**Statut:** Fait
**Priorite:** Haute
**Complexite:** S
**Scope:** both
**Tags:** hooks, commands, quality
**Date creation:** 2026-03-20

---

## Description

Creer un module `pre-commit-gate/` qui installe :
1. Un hook PreToolUse qui detecte `git commit` et rappelle de lancer `/check`
2. Une commande `/check` generique stack-agnostic qui detecte la stack et lance le pipeline de validation adapte

Les deux sont bundles ensemble car le hook depend de la commande.

## User Story

**En tant que** utilisateur de Claude Code
**Je veux** etre rappele de valider mon code avant chaque commit, et avoir une commande universelle pour le faire
**Afin de** ne jamais committer du code qui ne passe pas le lint/build/tests

## Livrable — Structure du module

```
pre-commit-gate/
├── README.md
├── install.sh
├── hooks/
│   └── pre-commit-gate.sh
└── commands/
    └── check.md
```

## Contenu du hook (`hooks/pre-commit-gate.sh`)

Reprendre le hook existant de `~/.claude/hooks/pre-commit-gate.sh` avec ces adaptations :
- Supprimer la reference specifique a Lunera.xcodeproj (c'est un projet perso)
- Garder la detection generique : package.json, pubspec.yaml, composer.json, xcodeproj, go.mod, Cargo.toml, pyproject.toml, Makefile
- Le message doit dire : "Run /check before committing" (pas de reference a des commandes specifiques)
- exit 0 toujours (rappel, pas bloquant)

Detection des stacks :
| Fichier detecte | Stack |
|---|---|
| `package.json` | Node/JS/TS |
| `pubspec.yaml` | Flutter/Dart |
| `composer.json` | PHP/Laravel |
| `*.xcodeproj` ou `Package.swift` | iOS/Swift |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pyproject.toml` ou `requirements.txt` | Python |
| `Gemfile` | Ruby |
| `Makefile` | Generic make |
| fallback | "assure-toi que les tests passent" |

## Contenu de la commande `/check`

```markdown
---
description: Run the full validation pipeline (lint + build + tests) for the detected stack
---

Detecte la stack du projet et lance le pipeline de validation complet.

## Detection de la stack

Cherche ces fichiers a la racine du projet (ou dans le cwd) :

| Fichier | Stack | Pipeline |
|---|---|---|
| `package.json` | Node/TS | Lire scripts dans package.json → lancer lint, typecheck, build, test dans cet ordre |
| `pubspec.yaml` | Flutter | `flutter analyze` → `flutter test` |
| `composer.json` | PHP | `composer lint` ou `phpcs` → `phpunit` |
| `*.xcodeproj` ou `Package.swift` | Swift | `swiftlint` → `xcodebuild test` |
| `go.mod` | Go | `go vet` → `golangci-lint run` → `go test ./...` |
| `Cargo.toml` | Rust | `cargo clippy` → `cargo test` |
| `pyproject.toml` | Python | `ruff check` → `mypy` → `pytest` |
| `Gemfile` | Ruby | `rubocop` → `rspec` ou `rails test` |
| `Makefile` | Generic | Chercher `make lint`, `make test`, `make check` |

## Regles d'execution

1. Detecter la stack
2. Lire le fichier de config (package.json scripts, Makefile targets, etc.) pour trouver les VRAIES commandes du projet
3. Lancer dans l'ordre : lint → build (si applicable) → tests
4. **Arreter a la premiere erreur** — corriger, puis relancer l'etape echouee
5. Si tout passe : afficher "Ready to commit" + `git diff --stat`
6. Si une commande n'existe pas (ex: pas de script "lint" dans package.json) → skip avec warning
```

## install.sh — Comportement attendu

Suivre le pattern de `supervisor/install.sh` et `command-guard/install.sh` :

1. Check dependencies (claude, jq)
2. Copier `hooks/pre-commit-gate.sh` → `~/.claude/hooks/pre-commit-gate.sh`
3. Copier `commands/check.md` → `~/.claude/commands/check.md`
4. Configurer le hook dans `~/.claude/settings.json` :
   - Event: `PreToolUse`
   - Matcher: `Bash`
   - Command: `~/.claude/hooks/pre-commit-gate.sh`
   - Idempotent (ne pas dupliquer si deja present)
5. Banner + resume

Pattern settings.json : s'inspirer de `command-guard/install.sh` qui fait deja du merge jq sur PreToolUse.

## Criteres d'acceptation

- [ ] `bash install.sh` installe hook + commande
- [ ] Le hook se declenche sur `git commit` et rappelle /check
- [ ] Le hook ne se declenche PAS sur d'autres commandes git
- [ ] `/check` detecte la stack et lance le bon pipeline
- [ ] L'install est idempotente
- [ ] Le style install.sh est coherent avec les autres modules

## Fichiers concernes

### A creer
- `pre-commit-gate/README.md`
- `pre-commit-gate/install.sh`
- `pre-commit-gate/hooks/pre-commit-gate.sh`
- `pre-commit-gate/commands/check.md`
