# code-index — Dart stack

Dart/Flutter implementation of the code-index module. Uses [`package:analyzer`](https://pub.dev/packages/analyzer) (the official Dart AST parser) to walk a source directory and emit per-directory markdown outlines under `docs/.code-map/`.

This is the **only natively supported stack in v0.1**. For TypeScript / Python / Go / Rust, the [`/code-index-bootstrap`](../../skills/code-index-bootstrap/) skill generates a stack-equivalent indexer on first use (with auto-validation against the same format contract).

## Files

| File | Role |
|------|------|
| `code_index.dart` | The indexer script. Copied to `tool/code_index.dart` in your project. |
| `_setup.sh` | Per-project installer. Called by `setup-project.sh` when a `pubspec.yaml` is detected, or runnable directly. |

## Manual usage

If you want to install only this stack without the rest of code-index:

```bash
bash ~/.claude/code-index/stacks/dart/_setup.sh --source lib --out docs/.code-map
```

## Requirements

- Dart SDK (any recent version supporting `package:analyzer ^7.0.0`)
- `package:analyzer` resolvable in your `pubspec.lock` (transitive or direct). Already present in any project using `freezed`, `build_runner`, `dart_style`, or `flutter_test`. Otherwise the setup will offer to add it via `dart pub add --dev analyzer`.

## What gets installed in your project

```
your-project/
├── tool/
│   └── code_index.dart          # the indexer (overwritable)
├── .githooks/
│   ├── _run_code_index.sh       # AOT runner with anti-loop guard
│   ├── post-commit              # regen after each commit
│   ├── post-checkout            # regen after branch switch
│   ├── post-merge               # regen after pull/merge
│   └── README.md                # docs for new clones
├── .gitignore                   # patched: docs/.code-map/, .dart_tool/code_index_bin
└── (git config core.hooksPath = .githooks)
```

After setup, `docs/.code-map/INDEX.md` is generated. From a fresh clone, anyone re-activates hooks with:

```bash
git config core.hooksPath .githooks && chmod +x .githooks/*
```

## CLI flags (code_index.dart)

| Flag | Default | Description |
|------|---------|-------------|
| `--source <dir>` | `lib` | Source directory to walk, relative to project root. |
| `--out <dir>` | `docs/.code-map` | Output directory. |
| `--root <dir>` | cwd | Project root (rarely needed). |
| `--files <f1> <f2> ...` | — | Incremental: only re-index these files. |
| `--exclude-suffix <s>` | `.g.dart`, `.freezed.dart` | Repeatable. First use replaces defaults. |
| `--exclude-prefix <s>` | `app_localizations` | Repeatable. First use replaces defaults. |
| `--no-default-excludes` | — | Drop all default exclusions. |
| `--quiet` | — | Suppress non-error output. |

## Output format

The indexer writes:
- `INDEX.md` — table of directories, workflow tips, ~1.5K tokens (read systematically at session start).
- `SYMBOLS.md` — flat grep-friendly dump of every top-level symbol.
- `<dir>.md` per source sub-directory — outlines with classes/methods/fields and line numbers.

Token economy on a real Flutter codebase (244 files, 62K LoC): **87-91% reduction** vs `Read`-ing the source directly. See [BENCHMARKS.md](../../BENCHMARKS.md).

## Performance

| Mode | Wall-clock |
|------|------------|
| `dart run tool/code_index.dart` (JIT) | ~6 s |
| AOT bootstrap (one-time, on first hook) | ~5.5 s |
| Hook after AOT bootstrap | **0.19 s** |
| Hook after editing code_index.dart | ~5.5 s (recompile) |

The hook runner caches an AOT binary at `.dart_tool/code_index_bin` and recompiles only when the source script is newer.
