#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$(dirname "$SCRIPT_DIR")"
HOOK="$MODULE_DIR/hooks/backlog-guard.sh"
PASS=0
FAIL=0

# --- Helpers ---
setup() {
  TMPDIR=$(mktemp -d)
  # Create a full BACKLOG structure
  mkdir -p "$TMPDIR/BACKLOG/BUGS/PENDING"
  mkdir -p "$TMPDIR/BACKLOG/BUGS/DONE"
  mkdir -p "$TMPDIR/BACKLOG/FEATURES/PENDING"
  mkdir -p "$TMPDIR/BACKLOG/FEATURES/DONE"
  mkdir -p "$TMPDIR/BACKLOG/IMPROVEMENTS/PENDING"
  mkdir -p "$TMPDIR/BACKLOG/IMPROVEMENTS/DONE"
  # Pre-populate with some tickets
  echo "# BUG-001" > "$TMPDIR/BACKLOG/BUGS/PENDING/BUG-001.md"
  echo "# FEAT-001" > "$TMPDIR/BACKLOG/FEATURES/DONE/FEAT-001.md"
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

test_non_backlog_write_ignored() {
  setup
  local input='{"tool_input": {"file_path": "/tmp/some/other/file.md"}}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "non-BACKLOG write exits 0"
  assert_output_empty "$output" "non-BACKLOG write produces no output"
  teardown
}

test_index_md_ignored() {
  setup
  local input='{"tool_input": {"file_path": "'"$TMPDIR"'/BACKLOG/INDEX.md"}}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "INDEX.md write exits 0"
  assert_output_empty "$output" "INDEX.md write produces no output"
  teardown
}

test_duplicate_bug_blocked() {
  setup
  local input='{"tool_input": {"file_path": "'"$TMPDIR"'/BACKLOG/BUGS/PENDING/BUG-001.md"}}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 2 $rc "duplicate BUG-001 exits 2"
  assert_output_contains "BLOCKED" "$output" "duplicate BUG-001 says BLOCKED"
  teardown
}

test_new_bug_allowed() {
  setup
  local input='{"tool_input": {"file_path": "'"$TMPDIR"'/BACKLOG/BUGS/PENDING/BUG-002.md"}}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 0 $rc "new BUG-002 exits 0"
  assert_output_empty "$output" "new BUG-002 produces no output"
  teardown
}

test_done_ticket_also_blocked() {
  setup
  local input='{"tool_input": {"file_path": "'"$TMPDIR"'/BACKLOG/FEATURES/PENDING/FEAT-001.md"}}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 2 $rc "FEAT-001 in DONE still blocks exits 2"
  assert_output_contains "BLOCKED" "$output" "FEAT-001 in DONE says BLOCKED"
  teardown
}

test_blocked_shows_next_id() {
  setup
  local input='{"tool_input": {"file_path": "'"$TMPDIR"'/BACKLOG/BUGS/PENDING/BUG-001.md"}}'
  set +e
  output=$(echo "$input" | bash "$HOOK" 2>&1)
  rc=$?
  set -e
  assert_exit 2 $rc "blocked output exits 2"
  assert_output_contains "BUG-002" "$output" "blocked output suggests next ID BUG-002"
  teardown
}

# --- Runner ---
echo "=== [backlog-kit] Tests ==="
test_non_backlog_write_ignored
test_index_md_ignored
test_duplicate_bug_blocked
test_new_bug_allowed
test_done_ticket_also_blocked
test_blocked_shows_next_id
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
