# Benchmarks

Reference numbers for `code-index` v0.1 on a real Flutter codebase.

## Carnage App (Flutter party game) — 2026-05-01

| Metric | Value |
|---|---|
| Source files (Dart, excluding generated) | 244 |
| Total lines (Dart, source only) | 62 627 |
| Median lines / file | 144 |
| p90 lines / file | 596 |
| p99 lines / file | 2 161 |
| Max lines / file | 3 004 |
| Files > 1000 lines | 12 |

## Index generation performance

| Mode | Wall-clock |
|---|---|
| `dart run tool/code_index.dart` (JIT, full repo) | ~6 s |
| `dart compile exe` (one-time AOT bootstrap) | ~5.5 s |
| Hook with AOT binary (full repo) | **0.19 s** |
| Hook after editing `code_index.dart` (recompile + run) | ~5.5 s |

After bootstrap, the per-commit overhead is **0.19 s** — imperceptible.

The compile step happens automatically on the first hook run (or whenever `tool/code_index.dart` is edited). The compiled binary lives at `.dart_tool/code_index_bin` and is `.gitignore`d.

## Output size (full repo)

| File | Tokens | Role |
|---|---:|---|
| `INDEX.md` (light: dirs only) | ~1 500 | Read at session start |
| `SYMBOLS.md` (flat dump) | ~11 300 | Grep-only, never read fully |
| `<dir>.md` × 45 | 200-3000 each | Read on demand for the relevant zone |

A typical outline (`presentation_providers_game_play.md`, 3 files / 2837 lines) weighs **~2 100 tokens** vs 26 000 tokens for the underlying source — **−91%** for the same level of structural understanding.

## Token economy on representative tasks

### Scenario A — comprehend a 3-file module

Goal: understand the structure of `lib/presentation/providers/game_play/` (3 files: notifier, provider, state).

| Approach | Tokens | Reads |
|---|---:|---|
| Without index: `Read` full of all 3 files | 26 024 | 3 full reads |
| With index: `Read presentation_providers_game_play.md` | 2 098 | 1 read |
| **Saving** | **−23 926 (−91%)** | −2 reads |

### Scenario B — read one specific method

Goal: read the `transitionToPhase()` method inside a 2566-line notifier.

| Approach | Tokens | Reads |
|---|---:|---|
| Without index: `Read` full notifier, scroll to the right line | 23 524 | 1 full read |
| With index: `Read` outline + `Read offset=1135 limit=105` targeted | 3 145 | 2 targeted reads |
| **Saving** | **−20 379 (−87%)** | same count, but no full read |

### Scenario C — find a symbol globally

Goal: locate every class named `*Service`.

| Approach | Behaviour |
|---|---|
| Without index: `grep -rn "class.*Service" lib/` | Works — slight noise from string matches |
| With index: `grep -n "class .*Service" docs/.code-map/SYMBOLS.md` | Faster, zero noise (top-level decls only), gives line + file |

In practice both work well; the index slightly accelerates symbol lookups but its main value is on scenarios A and B.

## Verification of accuracy

Line numbers in the index were spot-checked against the source on 5 representative files. **0 dérive** observed: every `L<N>` annotation matched the actual line in `Read` output.

The indexer uses the official Dart `package:analyzer` AST, so the precision matches what the Dart Analyzer / IDE reports.

## When the ROI is marginal

Numbers above assume:
- Project size between 100 and 5000 source files
- You run Claude Code regularly on the project (≥ 1 session/week)
- Sessions involve onboarding into a zone you didn't read recently

If your project is smaller, or you mostly do focused single-file edits, the index won't hurt but won't pay for itself either. CLAUDE.md hierarchical + Glob/Grep stays optimal in that regime.

## Future benchmarks (multi-stack)

The `/code-index-bootstrap` skill (shipped) covers TS/Python/Go/Rust by generating a stack-equivalent indexer on first run, with **≥ 50% token reduction enforced** as a hard validation gate (Guardrail 4 in `skills/code-index-bootstrap/SKILL.md`).

This section will collect measurements as the skill is exercised on real projects:
- A TypeScript/React project (`ts-morph`)
- A Python/FastAPI project (`ast`)
- A Go module (`go/parser`)
- A Rust crate (`syn`)

For each, the reference is *not* "match Dart numbers" but "achieve ≥ 50% token reduction on a representative navigation scenario" — the auto-validation gate built into the bootstrap skill. If a generated indexer cannot pass that gate after 3 refinement rounds, the skill stops and reports honestly rather than lowering the bar.
