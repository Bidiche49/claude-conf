#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$(dirname "$SCRIPT_DIR")"
HOOK="$MODULE_DIR/hooks/pre-commit-gate.sh"
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

test_git_commit_shows_reminder() {
  setup
  local input='{"tool_input": {"command": "git commit -m '\''test'\''"}, "cwd": "'"$TMPDIR"'"}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "git commit exits 0"
  assert_output_contains "REMINDER" "$output" "git commit shows reminder"
  teardown
}

test_git_push_no_output() {
  setup
  local input='{"tool_input": {"command": "git push origin main"}, "cwd": "'"$TMPDIR"'"}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "git push exits 0"
  assert_output_empty "$output" "git push produces no output"
  teardown
}

test_ls_no_output() {
  setup
  local input='{"tool_input": {"command": "ls -la"}, "cwd": "'"$TMPDIR"'"}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "ls exits 0"
  assert_output_empty "$output" "ls produces no output"
  teardown
}

test_node_stack_detected() {
  setup
  touch "$TMPDIR/package.json"
  local input='{"tool_input": {"command": "git commit -m '\''feat'\''"}, "cwd": "'"$TMPDIR"'"}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "node stack exits 0"
  assert_output_contains "Node" "$output" "detects Node stack"
  teardown
}

test_flutter_stack_detected() {
  setup
  touch "$TMPDIR/pubspec.yaml"
  local input='{"tool_input": {"command": "git commit -m '\''feat'\''"}, "cwd": "'"$TMPDIR"'"}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "flutter stack exits 0"
  assert_output_contains "Flutter" "$output" "detects Flutter stack"
  teardown
}

test_no_stack_generic_reminder() {
  setup
  local input='{"tool_input": {"command": "git commit -m '\''fix'\''"}, "cwd": "'"$TMPDIR"'"}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "no stack exits 0"
  assert_output_contains "tests pass" "$output" "shows generic reminder without stack"
  teardown
}

# --- Runner ---
echo "=== [pre-commit-gate] Tests ==="
test_git_commit_shows_reminder
test_git_push_no_output
test_ls_no_output
test_node_stack_detected
test_flutter_stack_detected
test_no_stack_generic_reminder
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
