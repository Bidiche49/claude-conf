---
name: check
description: Run the full validation pipeline (lint + build + tests) for the detected stack
---

Detect the project stack and run the full validation pipeline.

## Stack detection

Check these files at project root:

| File | Stack | Pipeline |
|---|---|---|
| `package.json` | Node/TS | Read `scripts` in package.json. Run lint, typecheck, build, test (in that order, using the actual script names found) |
| `pubspec.yaml` | Flutter | `flutter analyze` then `flutter test` |
| `composer.json` | PHP | `composer lint` or `phpcs` then `phpunit` |
| `*.xcodeproj` or `Package.swift` | Swift | `swiftlint` then `xcodebuild test` |
| `go.mod` | Go | `go vet` then `golangci-lint run` then `go test ./...` |
| `Cargo.toml` | Rust | `cargo clippy` then `cargo test` |
| `pyproject.toml` | Python | `ruff check` then `mypy` then `pytest` |
| `Gemfile` | Ruby | `rubocop` then `rspec` or `rails test` |
| `Makefile` | Generic | Look for targets: `make lint`, `make test`, `make check` |

## Rules

1. Detect the stack from the table above
2. **Read the config file** (package.json scripts, Makefile targets, pyproject.toml, etc.) to find the real commands — never guess
3. Run in order: lint, build (if applicable), tests
4. **Stop on first error** — fix the issue, then re-run the failed step
5. If a command doesn't exist (e.g. no "lint" script in package.json), skip it with a warning
6. When everything passes: print "Ready to commit" and run `git diff --stat`
