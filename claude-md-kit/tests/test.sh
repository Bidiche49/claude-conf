#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL="$MODULE_DIR/install.sh"
PASS=0
FAIL=0

# --- Helpers ---
setup() {
  TMPDIR=$(mktemp -d)
  export HOME="$TMPDIR/fakehome"
  mkdir -p "$HOME/.claude/commands"
}

teardown() {
  rm -rf "$TMPDIR"
  unset HOME
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

assert_file_exists() {
  local file=$1 test_name=$2
  if [ -f "$file" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (file not found: $file)"
    FAIL=$((FAIL + 1))
  fi
}

# --- Tests ---

test_syntax_valid() {
  set +e
  bash -n "$INSTALL" 2>&1
  rc=$?
  set -e
  assert_exit 0 $rc "install.sh syntax is valid (bash -n)"
}

test_install_creates_commands() {
  setup
  # Provide a fake 'claude' command so install.sh passes dependency check
  mkdir -p "$TMPDIR/bin"
  cat > "$TMPDIR/bin/claude" << 'FAKECLAUDE'
#!/bin/bash
exit 0
FAKECLAUDE
  chmod +x "$TMPDIR/bin/claude"
  export PATH="$TMPDIR/bin:$PATH"

  set +e
  bash "$INSTALL" > /dev/null 2>&1
  rc=$?
  set -e
  assert_exit 0 $rc "install.sh exits 0"
  assert_file_exists "$HOME/.claude/commands/claude-md-init.md" "claude-md-init.md created"
  assert_file_exists "$HOME/.claude/commands/claude-md-cleanup.md" "claude-md-cleanup.md created"
  assert_file_exists "$HOME/.claude/commands/claude-md-boost.md" "claude-md-boost.md created"
  teardown
}

test_idempotence() {
  setup
  mkdir -p "$TMPDIR/bin"
  cat > "$TMPDIR/bin/claude" << 'FAKECLAUDE'
#!/bin/bash
exit 0
FAKECLAUDE
  chmod +x "$TMPDIR/bin/claude"
  export PATH="$TMPDIR/bin:$PATH"

  # Run twice
  set +e
  bash "$INSTALL" > /dev/null 2>&1
  bash "$INSTALL" > /dev/null 2>&1
  rc=$?
  set -e
  assert_exit 0 $rc "second install exits 0"

  # Check that commands exist (not duplicated — just one file per command)
  local count
  count=$(find "$HOME/.claude/commands" -name "claude-md-init.md" -not -name "*.backup.*" | wc -l | tr -d ' ')
  if [ "$count" -eq 1 ]; then
    echo "  PASS: idempotence — no duplicate files"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: idempotence — expected 1 claude-md-init.md, found $count"
    FAIL=$((FAIL + 1))
  fi
  teardown
}

# --- Runner ---
echo "=== [claude-md-kit] Tests ==="
test_syntax_valid
test_install_creates_commands
test_idempotence
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
