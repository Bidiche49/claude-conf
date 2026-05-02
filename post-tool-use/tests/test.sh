#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$(dirname "$SCRIPT_DIR")"
HOOK_PTU="$MODULE_DIR/hooks/post-tool-use.sh"
HOOK_INJECT="$MODULE_DIR/hooks/session-inject.sh"
INSTALL="$MODULE_DIR/install.sh"
PASS=0
FAIL=0

# --- Helpers ---
setup() {
  TMPDIR=$(mktemp -d)
  ORIG_HOME="$HOME"
  ORIG_PWD="$PWD"
  HOME="$TMPDIR"
  cd "$TMPDIR"
}

teardown() {
  HOME="$ORIG_HOME"
  cd "$ORIG_PWD"
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
  if echo "$output" | grep -q -- "$expected"; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (output missing: $expected)"
    echo "    actual output: $output"
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

# --- Syntax tests ---

test_syntax_post_tool_use() {
  set +e
  bash -n "$HOOK_PTU" 2>/dev/null
  rc=$?
  set -e
  assert_exit 0 $rc "post-tool-use.sh syntax valid"
}

test_syntax_session_inject() {
  set +e
  bash -n "$HOOK_INJECT" 2>/dev/null
  rc=$?
  set -e
  assert_exit 0 $rc "session-inject.sh syntax valid"
}

test_syntax_install() {
  set +e
  bash -n "$INSTALL" 2>/dev/null
  rc=$?
  set -e
  assert_exit 0 $rc "install.sh syntax valid"
}

# --- session-inject behavioural tests ---

test_inject_silent_without_ticket_env() {
  setup
  local input='{"session_id":"abc-123","source":"startup"}'
  set +e
  output=$(echo "$input" | env -u CC_WORKER_TICKET bash "$HOOK_INJECT" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "no CC_WORKER_TICKET → exit 0"
  assert_output_empty "$output" "no CC_WORKER_TICKET → empty output"
  teardown
}

test_inject_silent_when_module_disabled() {
  setup
  echo "post-tool-use" > "$HOME/.claude-conf-disabled"
  local input='{"session_id":"abc-123","source":"startup"}'
  set +e
  output=$(echo "$input" | CC_WORKER_TICKET="BUG-001" bash "$HOOK_INJECT" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "module disabled → exit 0"
  assert_output_empty "$output" "module disabled → empty output"
  teardown
}

test_inject_silent_without_session_id() {
  setup
  local input='{"source":"startup"}'
  set +e
  output=$(echo "$input" | CC_WORKER_TICKET="BUG-001" bash "$HOOK_INJECT" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "missing session_id → exit 0"
  assert_output_empty "$output" "missing session_id → empty output"
  teardown
}

test_inject_silent_on_resume() {
  setup
  local input='{"session_id":"abc-123","source":"resume"}'
  set +e
  output=$(echo "$input" | CC_WORKER_TICKET="BUG-001" bash "$HOOK_INJECT" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "source=resume → exit 0"
  assert_output_empty "$output" "source=resume → empty output"
  teardown
}

test_inject_silent_on_compact() {
  setup
  local input='{"session_id":"abc-123","source":"compact"}'
  set +e
  output=$(echo "$input" | CC_WORKER_TICKET="BUG-001" bash "$HOOK_INJECT" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "source=compact → exit 0"
  assert_output_empty "$output" "source=compact → empty output"
  teardown
}

test_inject_emits_context_for_worker() {
  setup
  local input='{"session_id":"f6d1e037-81db-4de3-b52b-d57c17dcb972","source":"startup"}'
  set +e
  output=$(echo "$input" | CC_WORKER_TICKET="BUG-042" bash "$HOOK_INJECT" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "worker session → exit 0"
  assert_output_contains "SessionStart" "$output" "output contains hookEventName SessionStart"
  assert_output_contains "additionalContext" "$output" "output contains additionalContext"
  assert_output_contains "BUG-042" "$output" "output contains ticket id"
  assert_output_contains "f6d1e037-81db-4de3-b52b-d57c17dcb972" "$output" "output contains session_id"
  assert_output_contains ".claude-sessions/manifests/f6d1e037-81db-4de3-b52b-d57c17dcb972.txt" "$output" "output contains exact manifest path"
  # Verify it's valid JSON
  set +e
  echo "$output" | jq -e . >/dev/null 2>&1
  jq_rc=$?
  set -e
  assert_exit 0 $jq_rc "output is valid JSON"
  teardown
}

# --- Run ---

echo "Running post-tool-use tests..."
echo ""

test_syntax_post_tool_use
test_syntax_session_inject
test_syntax_install
test_inject_silent_without_ticket_env
test_inject_silent_when_module_disabled
test_inject_silent_without_session_id
test_inject_silent_on_resume
test_inject_silent_on_compact
test_inject_emits_context_for_worker

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
