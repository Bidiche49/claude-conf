#!/usr/bin/env bash
# Tests for debug-forensic module
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SKILL_FILE="$ROOT_DIR/skills/debug-forensic/SKILL.md"
INSTALL_SCRIPT="$ROOT_DIR/install.sh"
FIXTURE_FILE="$SCRIPT_DIR/fixture-fake-conv.md"
PASS=0
FAIL=0

assert_pass() {
  echo "  PASS: $1"
  PASS=$((PASS + 1))
}

assert_fail() {
  echo "  FAIL: $1${2:+ ($2)}"
  FAIL=$((FAIL + 1))
}

# --- T1: install.sh syntax ---
test_install_syntax() {
  set +e
  bash -n "$INSTALL_SCRIPT" 2>/dev/null
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    assert_pass "install.sh syntax valid"
  else
    assert_fail "install.sh syntax valid" "bash -n returned $rc"
  fi
}

# --- T2: SKILL.md exists ---
test_skill_exists() {
  if [ -f "$SKILL_FILE" ]; then
    assert_pass "SKILL.md exists"
  else
    assert_fail "SKILL.md exists" "$SKILL_FILE not found"
  fi
}

# --- T3: frontmatter valid ---
test_frontmatter() {
  local first_line second_line
  first_line=$(head -1 "$SKILL_FILE")
  second_line=$(sed -n '2p' "$SKILL_FILE")
  if [ "$first_line" = "---" ] && [[ "$second_line" =~ ^name: ]]; then
    assert_pass "frontmatter starts with --- and name:"
  else
    assert_fail "frontmatter starts with --- and name:" "got '$first_line' / '$second_line'"
  fi

  if grep -q '^name: debug-forensic$' "$SKILL_FILE"; then
    assert_pass "frontmatter name = debug-forensic"
  else
    assert_fail "frontmatter name = debug-forensic"
  fi

  if grep -q '^description: ' "$SKILL_FILE"; then
    assert_pass "frontmatter has description"
  else
    assert_fail "frontmatter has description"
  fi
}

# --- T4: 7 sections present in template ---
test_seven_sections() {
  # The template specification lists exactly 7 sections (## 1. ROLE through ## 7. PREMIERE SORTIE)
  local sections=("1. ROLE" "2. MISSION" "3. GROUND-TRUTH DATA" "4. CODE PATHS" "5. CONTRAINTES" "6. ANTI-PATTERNS" "7. PREMIERE SORTIE")
  local missing=""
  for s in "${sections[@]}"; do
    if ! grep -q "### $s" "$SKILL_FILE"; then
      missing="$missing [$s]"
    fi
  done
  if [ -z "$missing" ]; then
    assert_pass "all 7 template sections referenced"
  else
    assert_fail "all 7 template sections referenced" "missing:$missing"
  fi
}

# --- T5: both modes documented ---
test_modes_documented() {
  if grep -q 'AUTO-EXTRACT' "$SKILL_FILE" && grep -q 'INTERVIEW' "$SKILL_FILE"; then
    assert_pass "both AUTO-EXTRACT and INTERVIEW modes documented"
  else
    assert_fail "both AUTO-EXTRACT and INTERVIEW modes documented"
  fi
}

# --- T6: arg overrides documented ---
test_arg_overrides() {
  if grep -q '\bnew\b' "$SKILL_FILE" && grep -q '\bhere\b' "$SKILL_FILE"; then
    assert_pass "new and here argument overrides documented"
  else
    assert_fail "new and here argument overrides documented"
  fi
}

# --- T7: 3 examples present ---
test_examples_count() {
  local count
  count=$(grep -c '^### Exemple ' "$SKILL_FILE" || true)
  if [ "$count" -ge 3 ]; then
    assert_pass "at least 3 examples present (found $count)"
  else
    assert_fail "at least 3 examples present" "found $count"
  fi
}

# --- T8: anti-patterns of the skill itself documented ---
test_skill_antipatterns() {
  if grep -qi 'Anti-patterns du skill' "$SKILL_FILE"; then
    assert_pass "skill self-anti-patterns documented"
  else
    assert_fail "skill self-anti-patterns documented"
  fi
}

# --- T9: STOP keyword in expected output ---
test_stop_keyword() {
  if grep -q 'STOP' "$SKILL_FILE"; then
    assert_pass "STOP keyword present (forensic discipline)"
  else
    assert_fail "STOP keyword present"
  fi
}

# --- T10: fixture exists for invocation simulation ---
test_fixture_exists() {
  if [ -f "$FIXTURE_FILE" ]; then
    assert_pass "fixture-fake-conv.md exists"
  else
    assert_fail "fixture-fake-conv.md exists" "$FIXTURE_FILE not found"
  fi
}

# --- T11: fixture contains the canonical signals (data, eliminations, files) ---
test_fixture_signals() {
  if grep -q 'D[0-9]' "$FIXTURE_FILE" 2>/dev/null && \
     grep -qi 'elimin' "$FIXTURE_FILE" 2>/dev/null; then
    assert_pass "fixture contains data points and eliminations (AUTO-EXTRACT trigger)"
  else
    assert_fail "fixture contains data points and eliminations"
  fi
}

# --- Runner ---
echo "=== [debug-forensic] Tests ==="
test_install_syntax
test_skill_exists
test_frontmatter
test_seven_sections
test_modes_documented
test_arg_overrides
test_examples_count
test_skill_antipatterns
test_stop_keyword
test_fixture_exists
test_fixture_signals
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
