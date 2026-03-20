# pre-commit-gate

Reminder to run `/check` before committing — with a universal validation command.

## What it does

1. **Hook (PreToolUse → Bash):** Detects `git commit` and reminds you to run `/check` first
2. **Command `/check`:** Detects your project stack and runs the full lint + build + tests pipeline

The hook never blocks — it's a reminder only (always exits 0).

## Supported stacks

| Detected file | Stack |
|---|---|
| `package.json` | Node/JS/TS |
| `pubspec.yaml` | Flutter/Dart |
| `composer.json` | PHP/Laravel |
| `*.xcodeproj` / `Package.swift` | iOS/Swift |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pyproject.toml` / `requirements.txt` | Python |
| `Gemfile` | Ruby |
| `Makefile` | Generic make |

## Install

```bash
bash install.sh
```

## Dependencies

- `claude` (Claude Code CLI)
- `jq`

## Works best with

- **command-guard** — shell command validator for Claude Code
