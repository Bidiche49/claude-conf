---
name: code-index-bootstrap
description: Auto-bootstrap codebase indexing in any project. Detects the stack, dispatches to the native installer if supported (Dart in v0.1), or generates a stack-appropriate indexer with strict guardrails (official AST parser, format contract, auto-validation, refinement loop) for TypeScript, Python, Go, or Rust.
---

# /code-index-bootstrap

You are setting up `code-index` (claude-conf module) inside the user's current project. Your goal: install the right indexer + git hooks so `docs/.code-map/` regenerates automatically on every commit, with **measured token economy ≥ 50%** vs reading the source directly.

## Mission

1. **Detect the project stack** by scanning marker files in the project root.
2. **If a native stack setup exists** under `~/.claude/code-index/stacks/<stack>/_setup.sh` → delegate to it (fast path).
3. **Otherwise** → enter **generation mode** with the 4 non-negotiable guardrails defined below.
4. **Always** end with auto-validation: parse 5 source samples, confirm format conformance, measure token economy.

## Step 1 — Detect stack

Run `ls -la` in the project root and check, in this order:

| Marker | Stack |
|---|---|
| `pubspec.yaml` | `dart` |
| `package.json` | `js` (TypeScript inferred via `tsconfig.json` or `.ts` files) |
| `go.mod` | `go` |
| `Cargo.toml` | `rust` |
| `pyproject.toml` / `requirements.txt` / `setup.py` | `python` |

If multiple markers are present (e.g. monorepo with both Go and JS), **ask the user** which stack to index. Do not guess.

If none match, tell the user the project layout is unsupported and stop. Do not invent.

## Step 2 — Dispatch or generate

Check if a native installer exists:

```bash
ls ~/.claude/code-index/stacks/<detected-stack>/_setup.sh
```

### Case A — native installer present (Dart in v0.1)

Run it directly. Pass `--source` and `--out` only if the user requested non-default values.

```bash
bash ~/.claude/code-index/stacks/<stack>/_setup.sh
```

The script handles everything (copy indexer, install hooks, patch `.gitignore`, configure `git core.hooksPath`, run first index). Then jump to Step 4 (validation).

### Case B — generation mode

Only enter this branch if no native installer exists for the detected stack. Then **all 4 guardrails below are mandatory.**

## The 4 guardrails (non-negotiable in generation mode)

### Guardrail 1 — Strict template & format contract

Before writing a single line of code:

1. **Read the Dart reference implementation** at `~/.claude/code-index/stacks/dart/code_index.dart`. Understand the structure (CLI parsing, file discovery, AST walk, per-directory grouping, markdown rendering).
2. **Read the format samples** the Dart indexer produces — `~/.claude/code-index/stacks/dart/README.md` describes the format. The Dart `_renderIndexMd`, `_renderSymbolsMd`, `_renderDirMd` functions are the canonical contract.

The output **must** include exactly:

**`INDEX.md`** (light, ≤ 2K tokens for typical projects):
```markdown
# Code Index

Generated: <ISO timestamp>
Source: `<source-dir>/` — <N> files parsed, <M> failed, <ms>ms

## How to use this index (for Claude Code agents)

1. **First reflex** entering an unfamiliar zone: read the relevant `<dir>.md`...
2. **Then** use `Read offset=X limit=Y` targeted on specific symbols...
3. **To find a symbol globally**: `grep -n "ClassName\|methodName" <out>/SYMBOLS.md`.
4. **To find call sites in source**: `grep -rn "methodName" <source>/`.

## Directories

| Directory | Files | Lines | Outline file |
|---|---:|---:|---|
| `<src>/` | N | M | [`_root.md`](_root.md) |
| `<src>/foo/` | ... |

See [`SYMBOLS.md`](SYMBOLS.md) for the flat grep-friendly dump of every top-level symbol.
```

**`SYMBOLS.md`** (flat dump, grep-friendly):
```markdown
# Symbols (flat dump for grep)

Format: `<kind>  <name>  <path>:<line>`. One line per top-level declaration.
Use `grep -n "ClassName" <out>/SYMBOLS.md` to locate any symbol.

```
class        Foo                                      core/foo.ts:12
fn           bar                                      utils.ts:3
...
```
```

**`<dir>.md`** per source sub-directory (outlines):
```markdown
# <src>/<subdir>/

<N> files · <M> lines total

## <relative/path/file.ts> · <K> lines
imports: `…`, `…`

### class Foo extends Bar  ·  L12-89
- *fields:* `string id` L13 · `int age` L14
- *ctor:* `Foo(this.id, this.age)` L16
- *public:* `compute(int x)` L20 · `render()` L34
- *private:* `_helper()` L60
- *getters/setters:* `get description` L80
```

**Mandatory in every outline**:
- Classes/types with `extends`/`implements`/`with` when relevant
- Public AND private members (latter clearly marked)
- **Exact line numbers** (start-end for declarations, start for members)
- Imports (top of file, deduplicated, dropping standard-library noise)

If your generated indexer outputs a different shape → it does not satisfy guardrail 1. Iterate until it matches.

### Guardrail 2 — Official AST parser (no shortcuts)

| Stack | Required parser | Wrong choices (do NOT use) |
|---|---|---|
| TypeScript / JavaScript | **`ts-morph`** (TypeScript Compiler API wrapper) | regex, `acorn` alone, tree-sitter |
| Python | **`ast`** (stdlib) | regex, tree-sitter, `tokenize` |
| Go | **`go/parser` + `go/ast`** (stdlib) | regex, tree-sitter |
| Rust | **`syn`** crate | regex, tree-sitter |
| Java | **JavaParser** (Eclipse JDT alternative if needed) | regex, tree-sitter |
| Ruby | **`parser`** gem | regex |
| C# | **Roslyn** | regex |

If the user is on a stack not listed above, propose the official parser of that language and confirm with the user before generating. **Never** fall back to regex or tree-sitter "for speed". Tree-sitter is acceptable as a complement (e.g. for highlighting), never as the source of truth for symbol extraction.

Reasoning: official parsers track the language spec, handle edge cases (records, sealed, generics, async, etc.), and produce stable line/column information. Regex breaks on every refactor.

### Guardrail 3 — Stack-appropriate location

Where the generated indexer lives in the project depends on stack convention:

| Stack | Script path | Hook runner invocation |
|---|---|---|
| TypeScript / JavaScript | `tools/code_index.ts` (with tsx/ts-node) or `tools/code_index.js` | `npx tsx tools/code_index.ts` or `node tools/code_index.js` |
| Python | `tools/code_index.py` | `python tools/code_index.py` |
| Go | `tools/code_index/main.go` | `go run ./tools/code_index` |
| Rust | `tools/code_index/src/main.rs` (binary crate) | `cargo run --release --bin code_index --quiet` |

For each generated stack, you also write `.githooks/_run_code_index.sh` that:
- Honors `CODE_INDEX_HOOK_RUNNING` anti-loop env var (must read like the Dart shared one)
- Skips silently if the script is missing (so a clean clone before npm/pip install does not break commits)
- Caches a compiled artifact under `.dart_tool/`-equivalent (`node_modules/.cache/`, `__pycache__/`, `target/release/`, etc.) when applicable

Copy `~/.claude/code-index/shared/{post-commit,post-checkout,post-merge}` as-is into `.githooks/` (they are language-agnostic). Adapt only `_run_code_index.sh`.

### Guardrail 4 — Auto-validation + refinement loop

After writing the script and running it once, you MUST validate:

#### V1 — Format conformance (parse 5 generated outputs)

Pick 5 outputs deterministically:
- `INDEX.md`
- `SYMBOLS.md`
- 3 sub-directory outlines (the 3 largest by line count for representativity)

For each, verify:
- Required sections present (titles, "How to use" block in INDEX, symbol format in SYMBOLS, declaration sections in dir outlines)
- Markdown syntactically valid (no broken tables, no unclosed code blocks)
- Line numbers parseable (regex `L\d+(-\d+)?`)
- At least 3 different declaration kinds represented (class/fn/var/enum/interface/etc.)

If any check fails → loop to refinement (V3).

#### V2 — Sample symbol verification (5 source samples)

Pick 5 source files at random from the project. For each:
- Look up the file in the generated index
- Pick one declaration the index claims (e.g. `class FooBar` at line N)
- Use `Read` with `offset=N` `limit=10` on the source file
- Confirm the declaration is actually there at the announced line

If any line number is off by more than 1 → the parser is wrong (likely you used a non-official parser, or a wrong line tracking method). **Fix the script, do not patch the assertion.**

#### V3 — Token economy (≥ 50% saving on a representative scenario)

Pick a sub-directory with 3+ files. Compare:
- Without index: combined token count of `Read` on those 3 files (use `wc -c` / 4 as an estimate, or actually run a `Read`)
- With index: token count of the corresponding `<dir>.md`

Saving must be ≥ 50%. If less:
- Either your output is too verbose (over-rendering) → trim
- Or the source files are tiny (< 100 lines each) → the test isn't representative; pick a different sample

#### V4 — Refinement loop

If any of V1/V2/V3 fails:
1. **Identify the specific defect** (which assertion failed, which file, what was expected vs. what was emitted)
2. **Fix the indexer code** (not the validator)
3. **Re-run V1/V2/V3** entirely (not just the failed step — fixes can break passing checks)
4. **Loop max 3 times.** If still failing after 3 rounds, stop and report the persistent defect honestly. Do NOT lower the bar.

A "Solide" claim ("validation passed") only counts when V1/V2/V3 all pass cleanly in a single pass.

## Step 3 — Persist & wire up

After generation + validation succeed (or after Case A's native installer ran):

1. **Patch `.gitignore`** with the same block the Dart `_setup.sh` uses:
   ```
   # code-index (claude-conf) — generated artifacts
   docs/.code-map/
   ```
   plus any stack-specific compiled artifact path (`.dart_tool/code_index_bin`, `target/release/code_index`, `node_modules/.cache/code_index`, etc.).
   Use `grep -qF` to avoid duplicating the block.

2. **Configure `git core.hooksPath`** only if not already set to something else:
   ```bash
   if [ -z "$(git config core.hooksPath)" ] || [ "$(git config core.hooksPath)" = ".githooks" ]; then
       git config core.hooksPath .githooks
   fi
   ```
   If it's set to a different path, **warn the user** — do not overwrite.

3. **Make all hook files executable.**

## Step 4 — Final report to the user

Print a summary in this exact shape:

```
✓ code-index installed for <stack>
  Indexer       : <path/to/script>
  Output        : <path/to/.code-map>
  Hooks         : .githooks/ (post-commit, post-checkout, post-merge)
  Token economy : <X>% saving on <sample-dir> (<src tokens> → <out tokens>)

Next: Claude Code reads <out>/INDEX.md at session start to navigate this codebase efficiently.
```

If you ran in generation mode, also print a one-line caveat:
```
Generated for <stack> using <parser>. v0.2 of code-index will ship this stack natively — see claude-conf for updates.
```

## Hard rules (recap)

- **Never** use regex or tree-sitter as the source of truth for symbols.
- **Never** lower the validation bar to make a run pass.
- **Never** skip the refinement loop after a partial validation.
- **Never** invent a stack you cannot confidently parse — confirm with the user first.
- **Never** overwrite an existing `core.hooksPath` set by the user.
- **Always** match the format contract of guardrail 1 exactly. Claude Code will read these files in every future session; consistency across stacks matters more than originality.

## Anti-patterns to avoid

- **"It mostly works" without measuring** — measure economy with V3 or you're guessing.
- **Stuffing too much into outlines** — outlines must be short. If your `<dir>.md` is bigger than 5K tokens, you over-rendered. Trim signatures, drop noise (annotations, doc comments).
- **Skipping private members** — they matter for navigation. Mark them clearly but include them.
- **Adding TODO comments in the generated script** for "future improvements" — finish or omit.
- **Generating multi-file scripts** when one file suffices — match the Dart reference's monofile structure.
