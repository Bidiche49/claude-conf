#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$(dirname "$SCRIPT_DIR")"
HOOK="$MODULE_DIR/hooks/api-contract-reminder.sh"
PASS=0
FAIL=0

# --- Helpers ---
setup() {
  TMPDIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TMPDIR"
}

assert_exit() {
  local expected=$1 actual=$2 test_name=$3
  if [ "$actual" -eq "$expected" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (expected exit $expected, got $actual)"
    FAIL=$((FAIL + 1))
  fi
}

assert_output_contains() {
  local expected=$1 output=$2 test_name=$3
  if echo "$output" | grep -q "$expected"; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (output missing: $expected)"
    FAIL=$((FAIL + 1))
  fi
}

assert_output_empty() {
  local output=$1 test_name=$2
  if [ -z "$output" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (expected empty output, got: $output)"
    FAIL=$((FAIL + 1))
  fi
}

# --- Tests ---

test_controller_ts_with_contract_shows_reminder() {
  setup
  echo "# API Contract" > "$TMPDIR/API_CONTRACT.md"
  local input='{"tool_name": "Edit", "tool_input": {"file_path": "src/users.controller.ts"}, "cwd": "'"$TMPDIR"'"}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "controller.ts edit exits 0"
  assert_output_contains "API-CONTRACT" "$output" "controller.ts edit shows reminder"
  teardown
}

test_utils_ts_no_reminder() {
  setup
  echo "# API Contract" > "$TMPDIR/API_CONTRACT.md"
  local input='{"tool_name": "Edit", "tool_input": {"file_path": "src/utils.ts"}, "cwd": "'"$TMPDIR"'"}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "utils.ts edit exits 0"
  assert_output_empty "$output" "utils.ts edit produces no output"
  teardown
}

test_read_tool_ignored() {
  setup
  echo "# API Contract" > "$TMPDIR/API_CONTRACT.md"
  local input='{"tool_name": "Read", "tool_input": {"file_path": "src/users.controller.ts"}, "cwd": "'"$TMPDIR"'"}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "Read tool exits 0"
  assert_output_empty "$output" "Read tool produces no output"
  teardown
}

test_no_contract_file_silent() {
  setup
  local input='{"tool_name": "Edit", "tool_input": {"file_path": "src/users.controller.ts"}, "cwd": "'"$TMPDIR"'"}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "no contract file exits 0"
  assert_output_empty "$output" "no contract file produces no output"
  teardown
}

test_laravel_controller_shows_reminder() {
  setup
  echo "# API Contract" > "$TMPDIR/API_CONTRACT.md"
  local input='{"tool_name": "Edit", "tool_input": {"file_path": "app/Http/Controllers/UserController.php"}, "cwd": "'"$TMPDIR"'"}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "Laravel controller exits 0"
  assert_output_contains "API-CONTRACT" "$output" "Laravel controller shows reminder"
  teardown
}

test_express_routes_shows_reminder() {
  setup
  echo "# API Contract" > "$TMPDIR/API_CONTRACT.md"
  local input='{"tool_name": "Edit", "tool_input": {"file_path": "src/routes/users.ts"}, "cwd": "'"$TMPDIR"'"}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "Express routes exits 0"
  assert_output_contains "API-CONTRACT" "$output" "Express routes shows reminder"
  teardown
}

# --- Runner ---
echo "=== [api-contract] Tests ==="
test_controller_ts_with_contract_shows_reminder
test_utils_ts_no_reminder
test_read_tool_ignored
test_no_contract_file_silent
test_laravel_controller_shows_reminder
test_express_routes_shows_reminder
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
