---
name: setup-project
description: Bootstrap a project for Claude Code — auto-detect stack, configure permissions, generate commands
argument-hint: [optional project description]
disable-model-invocation: true
---

Bootstrap this project for Claude Code. Follow these 6 phases in order.

## Phase 1 — Detect Stack

Scan project root for config files and identify the stack:

| File | Stack | Permissions | Lint | Test |
|---|---|---|---|---|
| `pubspec.yaml` | Flutter/Dart | `Bash(flutter *)`, `Bash(dart *)` | `flutter analyze` | `flutter test` |
| `package.json` | Node/JS/TS | `Bash(npm *)`, `Bash(npx *)`, `Bash(node *)` | read scripts.lint | read scripts.test |
| `go.mod` | Go | `Bash(go *)` | `go vet`, `golangci-lint run` | `go test ./...` |
| `Cargo.toml` | Rust | `Bash(cargo *)` | `cargo clippy` | `cargo test` |
| `pyproject.toml` or `requirements.txt` | Python | `Bash(python *)`, `Bash(pip *)`, `Bash(pytest *)` | `ruff check` | `pytest` |
| `composer.json` | PHP | `Bash(composer *)`, `Bash(php *)` | `phpcs` or `phpstan` | `phpunit` |
| `Gemfile` | Ruby | `Bash(bundle *)`, `Bash(ruby *)`, `Bash(rails *)` | `rubocop` | `rspec` or `rails test` |
| `*.xcodeproj` or `Package.swift` | iOS/Swift | `Bash(xcodebuild *)`, `Bash(swift *)` | `swiftlint` | `xcodebuild test` |
| `Makefile` | Generic | `Bash(make *)` | `make lint` | `make test` |

Always add `Bash(git *)` for every stack.

For **Node/JS**: read `package.json` scripts to find the REAL command names (lint, test, typecheck, build). NEVER guess.
For **Makefile**: read actual targets. NEVER assume.

If multiple stacks detected (monorepo): list them and ask confirmation before proceeding.

Run `git log --oneline -10` for project context.

## Phase 2 — Configure Permissions

Target: `.claude/settings.json` in the PROJECT directory (NOT `~/.claude/settings.json`).

1. If `.claude/settings.json` exists, read existing `permissions.allow` array
2. Add permissions from the stack table above — do NOT overwrite existing entries
3. Merge cleanly: append only new entries
4. Show the user what was added

## Phase 3 — Git Commit Rules

Generate `.claude/git-commit-rules.md`:

1. Read `git log --oneline -20`
2. Detect: conventional commits? Language (FR/EN)? Scope prefix? Ticket references?
3. If convention detected → formalize it in the rules file
4. If no clear convention → propose conventional commits in the project's language
5. Present the rules and wait for validation before writing

## Phase 4 — Gitignore

1. If `.gitignore` exists and `.claude-sessions/` is not in it → add it
2. If `.gitignore` does not exist → do nothing (the project may have a reason)

## Phase 5 — Orchestrate Modules

1. If `BACKLOG/` does not exist → run `/backlog-init`
2. If `CLAUDE.md` does not exist → run `/claude-md-init` (pass detected stack as context)
3. If `CLAUDE.md` exists → suggest `/claude-md-boost` but do NOT run it automatically

## Phase 6 — Summary

Display:

```
SETUP COMPLETE — [project name]
══════════════════════════════
Stack         : [detected stack]
Permissions   : [list] (added to .claude/settings.json)
CLAUDE.md     : generated / already present (boost recommended)
BACKLOG/      : initialized / already present
Git rules     : .claude/git-commit-rules.md generated
.gitignore    : .claude-sessions/ added / already present / no .gitignore

Commands available:
  /start    — load session context
  /review   — auto-review before commit
  /check    — validation pipeline (lint + build + tests)
```