#!/bin/bash
# Hook PostToolUse (matcher: "Edit|Write") — Remind to update API contract
# when a controller, route, or DTO file is modified.
# Generic: detects stack via file extension. Always exits 0 (reminder, never blocking).

set -e

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

# Only activate on Edit or Write
if [ "$tool_name" != "Edit" ] && [ "$tool_name" != "Write" ]; then
    exit 0
fi

# Locate API_CONTRACT.md — search multiple locations
contract_path=""
for candidate in \
    "$cwd/shared/API_CONTRACT.md" \
    "$cwd/../shared/API_CONTRACT.md" \
    "$cwd/API_CONTRACT.md"; do
    if [ -f "$candidate" ]; then
        contract_path="$candidate"
        break
    fi
done

# No contract found — not an API-contract project, stay silent
if [ -z "$contract_path" ]; then
    exit 0
fi

# Make the path relative for display
display_path="${contract_path#"$cwd/"}"

# Detect if the modified file affects the API contract
should_remind=false

case "$file_path" in
    # NestJS
    *.controller.ts|*.dto.ts) should_remind=true ;;
    # CakePHP / Laravel
    *Controller.php|*Route*.php) should_remind=true ;;
    # Express / Fastify
    */routes/*.ts|*/routes/*.js|*/router/*.ts|*/router/*.js) should_remind=true ;;
    # Django / FastAPI
    */routes/*.py|*views*.py) should_remind=true ;;
    # Go
    *_handler.go|*_router.go) should_remind=true ;;
    # Rust (Actix / Axum)
    */routes/*.rs) should_remind=true ;;
    # Rails
    *_controller.rb) should_remind=true ;;
esac

if [ "$should_remind" = true ]; then
    echo "[API-CONTRACT] You just modified a file that may affect the API contract. If the contract changed (new endpoint, changed field, removed route), update ${display_path} and add a Changelog entry."
fi

exit 0
