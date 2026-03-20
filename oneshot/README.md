# oneshot

Ultra-fast feature implementation — explore, code, test.

## How it works

- **EXPLORE** — Surgical codebase search with 1-2 parallel agents (5-10 min max)
- **CODE** — Implement immediately, following existing patterns
- **TEST** — Validate with your stack's linter and typecheck

## Supported stacks

| Config file | Lint | Typecheck/Build |
|---|---|---|
| package.json | lint script | typecheck/tsc script |
| pubspec.yaml | flutter analyze | flutter build |
| go.mod | go vet + golangci-lint | go build ./... |
| Cargo.toml | cargo clippy | cargo build |
| pyproject.toml | ruff check | mypy |
| composer.json | phpcs / phpstan | — |
| Makefile | make lint | make build |

## Install

```bash
bash install.sh
```

Then in any Claude Code session: `/oneshot <feature-description>`

## Dependencies

- [Claude Code](https://claude.com/claude-code)
