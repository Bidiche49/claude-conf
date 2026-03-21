# api-contract

API contract management for split front/back projects. Keeps `API_CONTRACT.md` in sync between backend and frontend codebases.

## When to use

Any project where backend and frontend are in separate repos (or separate directories) and share an API contract. The contract acts as the source of truth for endpoint definitions.

## Components

### Hook: `api-contract-reminder.sh`

PostToolUse hook on `Edit|Write`. When Claude modifies a controller, route, or DTO file, it reminds you to update `API_CONTRACT.md` and add a Changelog entry.

The hook searches for `API_CONTRACT.md` in:
- `shared/API_CONTRACT.md`
- `../shared/API_CONTRACT.md`
- `API_CONTRACT.md` (project root)

If no contract file exists, the hook stays silent.

### Command: `/api-contract-init`

Scans existing routes and controllers to generate an initial `API_CONTRACT.md`. Extracts endpoints, methods, params, and response types from the real code — never fabricates.

### Command: `/api-contract-sync`

Compares `API_CONTRACT.md` against the current codebase. Reports:
- **MISSING** — endpoint in code but not in contract
- **REMOVED** — endpoint in contract but not in code
- **CHANGED** — endpoint exists in both but signatures differ

Does NOT modify the contract automatically.

## Supported stacks

| Stack | Files detected |
|---|---|
| NestJS | `*.controller.ts`, `*.dto.ts` |
| Express / Fastify | `routes/*.ts`, `router/*.ts` |
| CakePHP / Laravel | `*Controller.php`, `*Route*.php` |
| Django / FastAPI | `views*.py`, `routes/*.py` |
| Go | `*_handler.go`, `*_router.go` |
| Rust (Actix/Axum) | `routes/*.rs` |
| Rails | `*_controller.rb` |

## Generated contract format

```markdown
# API Contract — [Project Name]

## Global Conventions
- Base URL, Auth, Response format, Error format

## [Domain]
### [METHOD] [path]
Request / Response types, Auth, Notes

## Changelog
| Date | Change | Side |
```

## Install

```bash
bash install.sh
```

Installs the hook, both commands, and configures `settings.json` (PostToolUse `Edit|Write`). Idempotent — safe to run multiple times.

## Dependencies

- [Claude Code](https://claude.ai/claude-code)
- [jq](https://stedolan.github.io/jq/)
