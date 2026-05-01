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

## TypeScript / Next.js — first empirical measure (2026-05-01)

First real-world run of the `/code-index-bootstrap` skill on a non-Dart project. Site vitrine Next.js / TypeScript.

| Metric | Value |
|---|---|
| Source files (`.ts` + `.tsx`, excluding tests) | 53 |
| Sub-directories indexed | 22 |
| Generation time (cold) | ~150 ms |
| Parser used | `typescript` (TS Compiler API, native — already in devDeps) |
| Indexer location | `tools/code_index.mjs` (ESM, 0 new dependency) |

**Notable decision by the skill** (independent from the prompt): chose `typescript` (the TypeScript Compiler API directly) instead of `ts-morph`. Reasoning given: ts-morph is a wrapper, the underlying API is already installed in devDeps, no need to add 9 MB. **Pragmatic and right — kept as a pattern for future native stacks (use the lightest available official parser).**

### Token economy on this TS codebase

| Sub-directory | Source bytes | Code-map bytes | Saving |
|---|---:|---:|---:|
| `src/components/ui/` (13 files, 1192 lines) | 37 644 | 5 226 | **−86.1%** |
| `src/lib/` | 591 814 | 8 624 | **−98.5%** |

Both significantly above the ≥ 50% guardrail threshold.

### Skill validation walk-through

| Phase | Result |
|---|---|
| **V1** — format conformance | ✅ first pass (title, How-to-use block, `<kind> <name> path:line` format, declaration sections, valid markdown, ≥ 3 declaration kinds) |
| **V2** — sample symbol verification (5 randomly-picked declarations) | ✅ 5/5 line numbers exact (off=0). The official TS Compiler API reports precise lines. |
| **V3** — token economy | ✅ first pass (86% + 98%) |
| **V4** — refinement loop | Triggered for a cosmetic defect: multi-line signatures on functions with destructured parameters (e.g. `BeforeAfterSlider({\n  beforeSlug,\n  ...\n})`). Auto-detected post-V3, fixed with a `compactWs()` helper applied to param names + types. Re-validation confirmed no regression on V1/V2/V3. |

The defect was non-blocking (V3 passed before fix) but degraded readability. The skill did the right thing: pass the gate first, then improve in a quick-fix without lowering any standard.

### Caveat — single-project sample

These numbers come from one TS project (a relatively standard Next.js site vitrine). They do **not** generalize automatically to:
- NestJS / Angular projects (decorators not captured as metadata)
- Monorepos (single-source-dir walk insufficient)
- React Native (untested)
- Vue / Svelte / Solid (`.vue` / `.svelte` files not parsed by the TS Compiler API — would need a dedicated parser)

The skill remains the recommended entry-point for non-Dart stacks until at least 3-5 representative TS projects are indexed and the patterns generalize cleanly. **Native v0.2 status for TS is not premature-shipped on a sample of one.**

## Future benchmarks (multi-stack)

The `/code-index-bootstrap` skill (shipped) covers TS/Python/Go/Rust by generating a stack-equivalent indexer on first run, with **≥ 50% token reduction enforced** as a hard validation gate (Guardrail 4 in `skills/code-index-bootstrap/SKILL.md`).

Status of each stack:
- ✅ **TypeScript/Next.js** — measured 2026-05-01, see section above
- ⏳ **Python/FastAPI** (`ast` stdlib) — pending
- ⏳ **Go module** (`go/parser` stdlib) — pending
- ⏳ **Rust crate** (`syn` crate) — pending

For each, the reference is *not* "match Dart numbers" but "achieve ≥ 50% token reduction on a representative navigation scenario" — the auto-validation gate built into the bootstrap skill. If a generated indexer cannot pass that gate after 3 refinement rounds, the skill stops and reports honestly rather than lowering the bar.

A stack graduates from "generated on demand by the skill" to "native installer in `stacks/<name>/`" only after ≥ 3 representative projects have been indexed and the patterns generalize cleanly across them — never on a sample of one.
