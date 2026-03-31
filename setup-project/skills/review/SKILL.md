---
name: review
description: Auto-review changes before committing — stack-aware checklist
---

Review all staged and unstaged changes before commit. Follow these steps:

## Step 1 — Read Changes

Run `git diff --stat` and `git diff` to see what changed. If there are staged changes, also run `git diff --cached`.

## Step 2 — Detect Stack

Check project root for: `package.json`, `pubspec.yaml`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `composer.json`, `Gemfile`, `*.xcodeproj`, `Package.swift`, `Makefile`.

## Step 3 — Universal Checklist (all stacks)

For every modified file, verify:

- [ ] Names reveal intent (variables, functions, classes)
- [ ] No dead code (commented-out code, unused variables)
- [ ] No debug statements (print, console.log, debugPrint, pp, var_dump)
- [ ] Diff is coherent — no out-of-scope changes
- [ ] No secrets or credentials in the diff

## Step 4 — Stack-Specific Checklist

| Stack | Additional checks |
|---|---|
| Flutter/Dart | No `print()` (use Logger), Freezed generated files up to date, barrel imports |
| iOS/Swift | `[weak self]` in async closures, `deinit` present where needed, no dynamic force unwrap |
| React/Next | Hooks deps arrays complete, no direct state mutation, server/client boundary respected |
| Node/Express | Error handling middleware, async/await (no raw callbacks), input validation |
| Go | Errors wrapped/returned (not ignored), goroutines with context, defer for cleanup |
| Python | Type hints on functions, async/await coherent, no bare `except:` |
| Rust | Result/Option handled (no `unwrap()` in prod code), ownership clear |

## Step 5 — Report

- If problems found → list each with `file:line` and a suggested fix
- If all clear → print `Review OK — ready to commit` and show `git diff --stat`

## Rules — NON-NEGOTIABLE

- The review LISTS problems — it does NOT auto-fix. The user decides.
- Review ALL changed files, not just the first few.
- Be specific: file, line number, what's wrong, what to do instead.