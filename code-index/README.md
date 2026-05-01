# code-index

> Auto-indexed codebase navigation for Claude Code. **v0.1 — Dart/Flutter natively supported. Other stacks (TypeScript, Python, Go, Rust) via `/code-index-bootstrap` slash command in Claude Code.**

A claude-conf module that generates per-directory markdown outlines of your codebase, so Claude Code can navigate to the right file and the right line **without reading full source files**. Measured on a real Flutter codebase: **87-91% token reduction** on common navigation tasks.

---

## Why?

Claude Code is excellent with Glob/Grep, but on a non-trivial project it still has two pain points:

1. **Reading a large file to find one method costs thousands of tokens.** A 2000-line Dart file ≈ 18K tokens, even if you only care about 30 lines.
2. **Reconstructing a flow across files** (provider → service → repo) means several full reads — 10-25K tokens of context spent on orientation, before any real work happens.

`code-index` solves both by emitting a markdown outline per directory:

```
docs/.code-map/
├── INDEX.md                                      # 1.5K tokens — table of dirs, workflow tips
├── SYMBOLS.md                                    # grep-friendly dump of every symbol
└── presentation_providers_game_play.md           # 2K tokens — outlines all 3 files in that dir
```

Each outline lists classes, methods, fields, line numbers. Claude Code reads `INDEX.md` first, then the relevant `<dir>.md`, then `Read offset=X limit=Y` on the actual source — paying ~10% of the tokens it used to.

The index is **regenerated automatically** by git hooks (post-commit/checkout/merge) and **never committed** — it's `.gitignore`d like any generated artifact.

## Installation

```bash
cd claude-conf/code-index
bash install.sh
```

This copies the toolkit into `~/.claude/code-index/` (and the `/code-index-bootstrap` skill into `~/.claude/skills/`, once chantier B ships).

## Per-project setup (Dart/Flutter)

From any Dart/Flutter project:

```bash
cd your-flutter-project/
bash ~/.claude/code-index/setup-project.sh
```

The script:
1. Detects `pubspec.yaml` → Dart stack
2. Installs `tool/code_index.dart` (the indexer, ~640 LOC, no external deps beyond `package:analyzer` which Flutter projects already have transitively)
3. Installs 4 git hooks under `.githooks/` (auto-regen on commit/checkout/merge)
4. Patches `.gitignore` (the index is generated, not tracked)
5. Configures `git config core.hooksPath .githooks`
6. Runs the first index

After that, every commit silently regenerates the affected outlines (~0.2s after one-time AOT bootstrap).

For other stacks, see [§ Multi-stack support](#multi-stack-support).

## Token economy (measured)

Benchmark on Carnage App (244 Dart files, 62K LoC). See [BENCHMARKS.md](BENCHMARKS.md).

| Scenario | Without index | With index | Saving |
|---|---:|---:|---:|
| Comprehend a 3-file module | 26K tokens, 3 reads | 2K tokens, 1 read | **−91%** |
| Read one specific method (in a 2566-line file) | 23K tokens, 1 full read | 3K tokens, 2 targeted reads | **−87%** |

These numbers reflect a typical onboarding-into-a-zone workflow. On pure file lookups, the index is neutral or slightly positive (depending on your habits with Glob).

## Multi-stack support

**v0.1 supports Dart natively.** For TypeScript, Python, Go, Rust, run `/code-index-bootstrap` inside a Claude Code session. The skill detects your stack, generates an indexer using the **official AST parser** of the language (`ts-morph` for TS, `ast` for Python, `go/parser` for Go, `syn` for Rust — never regex, never tree-sitter as a shortcut), validates the output against the same markdown contract Dart uses, and loops until economy ≥ 50% on a representative sample (refinement gate, max 3 rounds).

The skill enforces 4 non-negotiable guardrails: strict format contract (same as Dart), official parser only, stack-appropriate file layout (`tools/` for TS/Python, `tools/code_index/` binary for Go/Rust), and post-generation auto-validation against 5 source samples. See [`skills/code-index-bootstrap/SKILL.md`](skills/code-index-bootstrap/SKILL.md) for the full contract.

## What lives in your project after setup

```
your-project/
├── tool/
│   └── code_index.dart              # the indexer (overwritten on re-setup)
├── .githooks/
│   ├── _run_code_index.sh           # AOT runner with anti-loop guard
│   ├── post-commit, post-checkout, post-merge
│   └── README.md                    # docs for new clones
├── .gitignore                       # patched: docs/.code-map/, .dart_tool/code_index_bin
└── (git config core.hooksPath = .githooks)
```

Nothing else is committed. The `docs/.code-map/` artifacts are produced locally on each clone after the one-time `git config core.hooksPath .githooks && chmod +x .githooks/*`.

## Scope (v0.1) — honest disclosure

**What this module does well:**
- Auto-maintained, AST-faithful index of a Dart codebase
- Markdown outlines with exact line numbers (not approximations)
- Sub-second hooks after AOT bootstrap (0.19s on Carnage)
- Zero external runtime dependencies (no Python venv, no MCP server)

**What this module deliberately does *not* do:**
- No PageRank-style importance ranking (use directory size as a heuristic; future work: integrate with [RepoMapper](https://github.com/pdavis68/RepoMapper) for a hybrid)
- No call-graph (Grep covers this in practice; the index complements rather than replaces grep)
- No multi-stack ahead-of-time install in v0.1: TS/Python/Go/Rust go through the `/code-index-bootstrap` skill the first time you run it on a project (one-shot generation + validation, then identical to native after that).
- No Cartographer-style narrative ("module purpose" or "design intent" — that's CLAUDE.md's job)

**When to skip this module:**
- Project < 100 source files: Glob/Grep are already optimal, ROI is marginal
- You don't run Claude Code regularly on the project
- You're in a stack that's not yet supported and can't wait for chantier B

## Files

```
code-index/
├── README.md             # this file
├── BENCHMARKS.md         # measured numbers from Carnage
├── install.sh            # → ~/.claude/code-index/ + ~/.claude/skills/code-index-bootstrap/
├── setup-project.sh      # shell entry-point: detect stack, dispatch
├── stacks/
│   └── dart/
│       ├── code_index.dart   # the indexer
│       ├── _setup.sh         # per-project Dart installer
│       └── README.md
├── shared/
│   ├── post-commit, post-checkout, post-merge
│   ├── _run_code_index.sh    # AOT runner with CODE_INDEX_HOOK_RUNNING anti-loop
│   └── README.md             # → copied to .githooks/README.md in target project
├── skills/
│   └── code-index-bootstrap/
│       └── SKILL.md          # /code-index-bootstrap prompt with 4 guardrails
└── tests/
    └── test.sh               # shellcheck + Dart fixture + idempotence + skill structure
```

## License

[MIT](../LICENSE) — part of [claude-conf](https://github.com/Bidiche49/claude-conf).

---

# Français

> Indexation automatique du code pour Claude Code. **v0.1 — Dart/Flutter supporté nativement. Autres stacks (TS/Python/Go/Rust) via la slash command `/code-index-bootstrap` dans Claude Code.**

Module claude-conf qui génère des outlines markdown par dossier de votre codebase, pour que Claude Code accède au bon fichier et à la bonne ligne **sans lire les sources entières**. Mesure réelle sur Flutter : **87-91% de tokens en moins** sur les tâches de navigation courantes.

## Pourquoi ?

Claude Code excelle avec Glob/Grep, mais sur un projet non trivial deux pains restent :
1. **Lire un gros fichier pour une méthode coûte des milliers de tokens** (ex : un fichier Dart de 2000 lignes ≈ 18K tokens, même si vous ne voulez que 30 lignes).
2. **Reconstruire un flow cross-fichiers** (provider → service → repo) demande plusieurs reads complets — 10-25K tokens d'orientation avant tout travail réel.

`code-index` règle les deux en émettant un outline markdown par dossier (~2K tokens par dossier au lieu de ~25K). Régénéré auto par git hooks. Jamais committé (ignoré comme tout artefact généré).

## Installation et usage

```bash
# Setup machine, une fois :
cd claude-conf/code-index && bash install.sh

# Par projet :
cd mon-projet-flutter/
bash ~/.claude/code-index/setup-project.sh
```

Pour les stacks non-Dart (TS/Python/Go/Rust), utiliser `/code-index-bootstrap` dans Claude Code. Le skill détecte la stack, génère un indexer avec le parser officiel du langage, et valide automatiquement le résultat (économie ≥ 50% obligatoire, loop de raffinement max 3 rounds si validation partielle).

Voir la version anglaise ci-dessus pour les détails (économie de tokens mesurée, scope honnête, fichiers installés).

## Licence

[MIT](../LICENSE) — module de [claude-conf](https://github.com/Bidiche49/claude-conf).
