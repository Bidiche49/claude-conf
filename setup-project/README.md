# setup-project

Bootstrap any project for Claude Code in one command — auto-detect stack, configure permissions, generate session tools.

## Commands

| Command | Description |
|---|---|
| `/setup-project` | Full project bootstrap — detect stack, configure `.claude/settings.json`, generate git rules, init BACKLOG & CLAUDE.md |
| `/start` | Load session context — git state, backlog stats, last handoff mention |
| `/review` | Auto-review changes before committing — universal + stack-specific checklist |

## Supported Stacks

- **Flutter/Dart** — `pubspec.yaml`
- **Node/JS/TS** — `package.json`
- **Go** — `go.mod`
- **Rust** — `Cargo.toml`
- **Python** — `pyproject.toml` / `requirements.txt`
- **PHP** — `composer.json`
- **Ruby** — `Gemfile`
- **iOS/Swift** — `*.xcodeproj` / `Package.swift`
- **Generic** — `Makefile`

## Example Output

```
SETUP COMPLETE — my-app
══════════════════════════════
Stack         : Flutter/Dart
Permissions   : flutter *, dart *, git * (added to .claude/settings.json)
CLAUDE.md     : generated
BACKLOG/      : initialized
Git rules     : .claude/git-commit-rules.md generated
.gitignore    : .claude-sessions/ added

Commands available:
  /start    — load session context
  /review   — auto-review before commit
  /check    — validation pipeline (lint + build + tests)
```

## Install

```bash
bash install.sh
```

## Dependencies

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## Works Best With

- **backlog** — ticketing system (`/backlog-init`, `/backlog-bug`, `/backlog-feat`, `/backlog-imp`)
- **claude-md-kit** — CLAUDE.md management (`/claude-md-init`, `/claude-md-boost`, `/claude-md-cleanup`)
- **pre-commit-gate** — validation pipeline (`/check`)
- **handoff-kit** — session continuity (`/handoff`)
- **supervisor** — CTO mode for planning and delegation
