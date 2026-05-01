#!/usr/bin/env bash
# ── code-index — Test suite ──────────────────────────────────────
# Runs:
#   1. shellcheck on every .sh
#   2. Dart fixture round-trip (5 stubs → assert outputs)
#   3. Idempotence test (run setup-project.sh twice in a temp git repo)
#   4. Skill /code-index-bootstrap structure (frontmatter, guardrails, refs)
#
# Usage: bash tests/test.sh [--quick]  (quick skips idempotence)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

QUICK=0
[[ "${1:-}" == "--quick" ]] && QUICK=1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURE_DIR="$SCRIPT_DIR/fixtures/dart_minimal"

PASS=0
FAIL=0

# ── helpers ─────────────────────────────────────────────────────

assert_pass() {
    PASS=$((PASS + 1))
    echo -e "    ${GREEN}✓${NC} $1"
}

assert_fail() {
    FAIL=$((FAIL + 1))
    echo -e "    ${RED}✗${NC} $1"
}

assert_contains() {
    local file="$1" needle="$2" desc="$3"
    if grep -qF "$needle" "$file"; then
        assert_pass "$desc"
    else
        assert_fail "$desc — '$needle' not found in $file"
    fi
}

assert_file_exists() {
    local file="$1" desc="$2"
    if [ -f "$file" ]; then
        assert_pass "$desc"
    else
        assert_fail "$desc — file missing: $file"
    fi
}

# ── 1. shellcheck ────────────────────────────────────────────────

echo ""
echo -e "${BOLD}[1/3] shellcheck${NC}"

if ! command -v shellcheck >/dev/null 2>&1; then
    echo -e "${YELLOW}    skipped (shellcheck not installed — brew install shellcheck)${NC}"
else
    SHELL_FILES=(
        "$MODULE_DIR/install.sh"
        "$MODULE_DIR/setup-project.sh"
        "$MODULE_DIR/stacks/dart/_setup.sh"
        "$MODULE_DIR/shared/_run_code_index.sh"
        "$MODULE_DIR/shared/post-commit"
        "$MODULE_DIR/shared/post-checkout"
        "$MODULE_DIR/shared/post-merge"
        "$SCRIPT_DIR/test.sh"
    )

    for f in "${SHELL_FILES[@]}"; do
        if [ ! -f "$f" ]; then
            assert_fail "shellcheck — file missing: $f"
            continue
        fi
        if shellcheck -x "$f" >/tmp/code_index_shellcheck.log 2>&1; then
            assert_pass "shellcheck $(basename "$f")"
        else
            assert_fail "shellcheck $(basename "$f"):"
            sed 's/^/        /' /tmp/code_index_shellcheck.log
        fi
    done
fi

# ── 2. Dart fixture round-trip ───────────────────────────────────

echo ""
echo -e "${BOLD}[2/3] Dart fixture round-trip${NC}"

if ! command -v dart >/dev/null 2>&1; then
    echo -e "${YELLOW}    skipped (dart not in PATH)${NC}"
else
    cd "$FIXTURE_DIR"

    echo -e "${DIM}    resolving fixture dependencies...${NC}"
    if ! dart pub get >/tmp/code_index_pubget.log 2>&1; then
        assert_fail "dart pub get on fixture"
        sed 's/^/        /' /tmp/code_index_pubget.log
    else
        assert_pass "dart pub get"

        OUT_DIR="$FIXTURE_DIR/.code-map-test"
        rm -rf "$OUT_DIR"

        # Copy the indexer into the fixture so `dart run` resolves imports
        # against the fixture's pubspec (mirrors what _setup.sh does).
        mkdir -p "$FIXTURE_DIR/tool"
        cp -f "$MODULE_DIR/stacks/dart/code_index.dart" "$FIXTURE_DIR/tool/code_index.dart"

        echo -e "${DIM}    running indexer on fixture...${NC}"
        if ! dart run tool/code_index.dart \
            --root "$FIXTURE_DIR" \
            --source lib \
            --out .code-map-test \
            --quiet 2>/tmp/code_index_run.log; then
            assert_fail "dart run code_index.dart"
            sed 's/^/        /' /tmp/code_index_run.log
        else
            assert_pass "dart run code_index.dart"

            # Output structure assertions
            assert_file_exists "$OUT_DIR/INDEX.md" "INDEX.md generated"
            assert_file_exists "$OUT_DIR/SYMBOLS.md" "SYMBOLS.md generated"
            assert_file_exists "$OUT_DIR/_root.md" "_root.md generated (lib/ at root)"

            # INDEX.md contents
            if [ -f "$OUT_DIR/INDEX.md" ]; then
                assert_contains "$OUT_DIR/INDEX.md" "# Code Index" "INDEX.md has title"
                assert_contains "$OUT_DIR/INDEX.md" "lib/" "INDEX.md mentions lib/"
                assert_contains "$OUT_DIR/INDEX.md" "5 |" "INDEX.md shows 5 files (count column)"
            fi

            # SYMBOLS.md contents — must mention every fixture symbol
            if [ -f "$OUT_DIR/SYMBOLS.md" ]; then
                assert_contains "$OUT_DIR/SYMBOLS.md" "SampleClass" "SYMBOLS.md mentions SampleClass"
                assert_contains "$OUT_DIR/SYMBOLS.md" "SampleMixin" "SYMBOLS.md mentions SampleMixin"
                assert_contains "$OUT_DIR/SYMBOLS.md" "SampleExtension" "SYMBOLS.md mentions SampleExtension"
                assert_contains "$OUT_DIR/SYMBOLS.md" "SampleEnum" "SYMBOLS.md mentions SampleEnum"
                assert_contains "$OUT_DIR/SYMBOLS.md" "sampleTopLevelFn" "SYMBOLS.md mentions sampleTopLevelFn"
                assert_contains "$OUT_DIR/SYMBOLS.md" "fixtureGreeting" "SYMBOLS.md mentions fixtureGreeting"
                assert_contains "$OUT_DIR/SYMBOLS.md" "class" "SYMBOLS.md tags 'class' kind"
                assert_contains "$OUT_DIR/SYMBOLS.md" "mixin" "SYMBOLS.md tags 'mixin' kind"
                assert_contains "$OUT_DIR/SYMBOLS.md" "extension" "SYMBOLS.md tags 'extension' kind"
                assert_contains "$OUT_DIR/SYMBOLS.md" "enum" "SYMBOLS.md tags 'enum' kind"
            fi

            # _root.md — outline detail per fixture file
            if [ -f "$OUT_DIR/_root.md" ]; then
                assert_contains "$OUT_DIR/_root.md" "class SampleClass" "outline contains class signature"
                assert_contains "$OUT_DIR/_root.md" "compute(int x)" "outline contains compute method"
                assert_contains "$OUT_DIR/_root.md" "_hidden()" "outline contains private method"
                assert_contains "$OUT_DIR/_root.md" "get description" "outline contains getter"
                assert_contains "$OUT_DIR/_root.md" "mixin SampleMixin" "outline contains mixin signature"
                assert_contains "$OUT_DIR/_root.md" "extension SampleExtension on String" "outline contains extension"
                assert_contains "$OUT_DIR/_root.md" "enum SampleEnum" "outline contains enum"
                assert_contains "$OUT_DIR/_root.md" "alpha, beta, gamma" "outline lists enum values"
                assert_contains "$OUT_DIR/_root.md" "sampleTopLevelFn" "outline contains top-level fn"
                assert_contains "$OUT_DIR/_root.md" "fixtureGreeting" "outline contains top-level var"

                # Line numbers should be present (format L<N>-<M>)
                if grep -qE 'L[0-9]+-[0-9]+' "$OUT_DIR/_root.md"; then
                    assert_pass "outline includes line numbers (L<N>-<M>)"
                else
                    assert_fail "outline missing line numbers"
                fi
            fi

            # Note: a token-economy assertion is intentionally skipped at this
            # scale. With 5 trivial stubs (5-12 lines each), the markdown
            # overhead (titles, separators, metadata) exceeds the reduction.
            # Real-world economy (87-91%) is documented in BENCHMARKS.md and
            # measured on a 244-file codebase, not a 5-stub fixture.

            # Cleanup
            rm -rf "$OUT_DIR"
            rm -rf "$FIXTURE_DIR/tool"
            rm -rf "$FIXTURE_DIR/.dart_tool"
            rm -f  "$FIXTURE_DIR/pubspec.lock"
        fi
    fi

    cd "$SCRIPT_DIR"
fi

# ── 3. Idempotence test (setup-project.sh runs cleanly twice) ────

echo ""
echo -e "${BOLD}[3/3] Idempotence (setup-project.sh × 2)${NC}"

if [ "$QUICK" -eq 1 ]; then
    echo -e "${DIM}    skipped (--quick)${NC}"
elif ! command -v dart >/dev/null 2>&1; then
    echo -e "${YELLOW}    skipped (dart not in PATH)${NC}"
elif ! command -v git >/dev/null 2>&1; then
    echo -e "${YELLOW}    skipped (git not in PATH)${NC}"
else
    TMP_PROJECT=$(mktemp -d -t code_index_idem.XXXXXX)
    trap 'rm -rf "$TMP_PROJECT"' EXIT

    echo -e "${DIM}    using temp project: $TMP_PROJECT${NC}"

    # Build a minimal Dart project with one source file.
    cd "$TMP_PROJECT"
    git init -q
    git -c user.email=test@test -c user.name=test commit --allow-empty -q -m "init"

    cat > pubspec.yaml <<EOF
name: idem_test
description: Idempotence test fixture
publish_to: none
environment:
  sdk: ^3.0.0
dependencies:
  analyzer: ^7.0.0
  path: ^1.8.0
EOF

    mkdir lib
    cat > lib/main.dart <<'EOF'
class IdemSample {
  IdemSample(this.value);
  final int value;
  int doubled() => value * 2;
}
EOF

    if ! dart pub get >/tmp/code_index_idem_pubget.log 2>&1; then
        assert_fail "dart pub get in temp project"
        sed 's/^/        /' /tmp/code_index_idem_pubget.log
    else
        # First setup
        if PROJECT_ROOT="$TMP_PROJECT" bash "$MODULE_DIR/setup-project.sh" --yes >/tmp/code_index_idem_run1.log 2>&1; then
            assert_pass "first setup-project.sh run"
        else
            assert_fail "first setup-project.sh run"
            sed 's/^/        /' /tmp/code_index_idem_run1.log
        fi

        # Snapshot key artifacts
        FIRST_HASH=$( {
            md5sum tool/code_index.dart 2>/dev/null || md5 tool/code_index.dart 2>/dev/null
            md5sum .githooks/_run_code_index.sh 2>/dev/null || md5 .githooks/_run_code_index.sh 2>/dev/null
        } | awk '{print $1}' | sort )

        # Second setup — should not fail nor duplicate gitignore patches
        if PROJECT_ROOT="$TMP_PROJECT" bash "$MODULE_DIR/setup-project.sh" --yes >/tmp/code_index_idem_run2.log 2>&1; then
            assert_pass "second setup-project.sh run (idempotent)"
        else
            assert_fail "second setup-project.sh run"
            sed 's/^/        /' /tmp/code_index_idem_run2.log
        fi

        SECOND_HASH=$( {
            md5sum tool/code_index.dart 2>/dev/null || md5 tool/code_index.dart 2>/dev/null
            md5sum .githooks/_run_code_index.sh 2>/dev/null || md5 .githooks/_run_code_index.sh 2>/dev/null
        } | awk '{print $1}' | sort )

        if [ "$FIRST_HASH" = "$SECOND_HASH" ]; then
            assert_pass "scripts unchanged across runs"
        else
            assert_fail "scripts differ between runs"
        fi

        # .gitignore must contain the patch block exactly once
        PATCH_COUNT=$(grep -cF "code-index (claude-conf)" .gitignore || true)
        if [ "$PATCH_COUNT" = "1" ]; then
            assert_pass ".gitignore patched exactly once"
        else
            assert_fail ".gitignore patch count = $PATCH_COUNT (expected 1)"
        fi

        # core.hooksPath must be .githooks
        HP=$(git config core.hooksPath)
        if [ "$HP" = ".githooks" ]; then
            assert_pass "git core.hooksPath = .githooks"
        else
            assert_fail "git core.hooksPath = '$HP' (expected .githooks)"
        fi

        # Index files must exist
        assert_file_exists "docs/.code-map/INDEX.md" "INDEX.md generated in temp project"
        assert_file_exists "docs/.code-map/SYMBOLS.md" "SYMBOLS.md generated in temp project"
    fi

    cd "$SCRIPT_DIR"
fi

# ── 4. Skill structure (chantier B) ──────────────────────────────

echo ""
echo -e "${BOLD}[4/4] Skill /code-index-bootstrap structure${NC}"

SKILL_FILE="$MODULE_DIR/skills/code-index-bootstrap/SKILL.md"

if [ ! -f "$SKILL_FILE" ]; then
    echo -e "${YELLOW}    skipped (skill not present — chantier B not yet shipped)${NC}"
else
    assert_file_exists "$SKILL_FILE" "SKILL.md present"

    # Frontmatter: must have name + description between --- markers at the very top.
    if head -1 "$SKILL_FILE" | grep -qE '^---$'; then
        assert_pass "SKILL.md starts with frontmatter delimiter"
    else
        assert_fail "SKILL.md missing opening '---'"
    fi

    if awk '/^---$/{c++} c==2{exit} END{exit !(c>=2)}' "$SKILL_FILE"; then
        assert_pass "SKILL.md frontmatter properly closed"
    else
        assert_fail "SKILL.md frontmatter not properly closed"
    fi

    FRONT=$(awk '/^---$/{c++; next} c==1{print}' "$SKILL_FILE")
    if echo "$FRONT" | grep -qE '^name: code-index-bootstrap$'; then
        assert_pass "frontmatter declares name=code-index-bootstrap"
    else
        assert_fail "frontmatter name field wrong or missing"
    fi
    if echo "$FRONT" | grep -qE '^description: '; then
        assert_pass "frontmatter has description"
    else
        assert_fail "frontmatter description missing"
    fi

    # Required content sections (acts as a contract — the prompt MUST
    # cover these or the guardrails are not actually enforced).
    REQUIRED_SECTIONS=(
        "Step 1 — Detect stack"
        "Step 2 — Dispatch or generate"
        "Guardrail 1 — Strict template"
        "Guardrail 2 — Official AST parser"
        "Guardrail 3 — Stack-appropriate location"
        "Guardrail 4 — Auto-validation"
        "refinement loop"
    )
    for section in "${REQUIRED_SECTIONS[@]}"; do
        if grep -qF "$section" "$SKILL_FILE"; then
            assert_pass "covers: $section"
        else
            assert_fail "missing section: $section"
        fi
    done

    # Each official parser must be named (guardrail 2 enforcement).
    REQUIRED_PARSERS=(
        "ts-morph"
        "\`ast\`"
        "go/parser"
        "\`syn\`"
    )
    for parser in "${REQUIRED_PARSERS[@]}"; do
        if grep -qF "$parser" "$SKILL_FILE"; then
            assert_pass "names parser: $parser"
        else
            assert_fail "missing parser mention: $parser"
        fi
    done

    # Wrong-choice section must explicitly forbid regex / tree-sitter as source of truth.
    if grep -qiE '(never|do NOT use).*regex' "$SKILL_FILE"; then
        assert_pass "forbids regex as source of truth"
    else
        assert_fail "does not forbid regex"
    fi
    if grep -qF "tree-sitter" "$SKILL_FILE"; then
        assert_pass "addresses tree-sitter (allowed only as complement)"
    else
        assert_fail "does not address tree-sitter trade-off"
    fi

    # Validation thresholds.
    if grep -qE '50%|≥ 50' "$SKILL_FILE"; then
        assert_pass "imposes ≥50% token economy threshold"
    else
        assert_fail "no token economy threshold"
    fi

    # File path references must point to actual paths the installer creates.
    # The tilde here is literal — we're grepping markdown text where ~/ is the
    # documented path, not an expansion target.
    # shellcheck disable=SC2088
    if grep -qF "~/.claude/code-index/stacks/dart/code_index.dart" "$SKILL_FILE"; then
        assert_pass "references Dart reference implementation path"
    else
        assert_fail "no reference to Dart canonical path"
    fi
    # shellcheck disable=SC2088
    if grep -qF "~/.claude/code-index/shared" "$SKILL_FILE"; then
        assert_pass "references shared hooks path"
    else
        assert_fail "no reference to shared hooks path"
    fi

    # Reasonable size bounds — too short = vague, too long = unfocused.
    LINE_COUNT=$(wc -l < "$SKILL_FILE")
    if [ "$LINE_COUNT" -ge 80 ] && [ "$LINE_COUNT" -le 400 ]; then
        assert_pass "SKILL.md size reasonable ($LINE_COUNT lines)"
    else
        assert_fail "SKILL.md size out of band ($LINE_COUNT lines, expected 80-400)"
    fi
fi

# ── Summary ──────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}─── Summary ───${NC}"
echo -e "  ${GREEN}passed: $PASS${NC}"
echo -e "  ${RED}failed: $FAIL${NC}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
