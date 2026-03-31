---
name: factorize
description: Scan the project for duplication and factorization opportunities
argument-hint: [path/to/dir | --dry-run | --scope <small|medium|large>]
---

Scan the codebase to detect duplicated code, repeated patterns, and factorization opportunities. Unlike `/simplify` (which refines recently changed code), this command performs a **project-wide** analysis.

**Modes:**
- `/factorize` — full scan, all source files
- `/factorize src/services` — scoped to a specific directory
- `/factorize --dry-run` — report only, no code changes
- `/factorize --scope small` — override auto-detected project size

## Step 1 — Context

1. Read `CLAUDE.md` to understand:
   - Stack (language, framework, conventions)
   - Project structure (where source lives, what's generated/vendored)
   - Naming conventions and existing abstractions

2. Detect project size:
   - Count source files (exclude tests, config, generated, vendor, node_modules)
   - **Small** (< 30 files): 1 analysis agent
   - **Medium** (30-100 files): 2 agents (split by directory)
   - **Large** (> 100 files): 3 agents (split by layer/concern)

3. Present the plan:
   ```
   FACTORIZE — [project name]
   Stack: [detected]
   Scope: [full / directory]
   Size: [X source files] → [small/medium/large]
   Agents: [1-3]
   Mode: [analysis + refactor / dry-run (report only)]

   Proceed? [Y/n]
   ```

## Step 2 — Detection phase

Launch agents in parallel (subagent_type: `feature-dev:code-explorer`).

Each agent receives its assigned files and this mission:

```
You are analyzing [project name] ([stack]) for factorization opportunities.
Your assigned files: [list].

Scan for these patterns:

1. **DUPLICATED CODE** — identical or near-identical blocks (>5 lines) that appear in 2+ files.
   Report: both locations, the duplicated block, and a suggested shared function/module name.

2. **REPEATED PATTERNS** — same logical pattern implemented differently across files
   (e.g., 3 different ways to validate input, 4 similar API call wrappers).
   Report: all occurrences, the common pattern, and a suggested unified approach.

3. **MISSED ABSTRACTIONS** — operations that could benefit from a shared utility
   (e.g., repeated string transformations, common data reshaping, recurring error handling).
   Report: occurrences and suggested abstraction.

4. **COPY-PASTE DRIFT** — code that was clearly copied then modified slightly,
   creating divergence that will cause bugs (one copy gets fixed, others don't).
   Report: all copies, the differences, and which version is likely "correct".

For each finding, report:
- **Type**: DUPLICATION / PATTERN / ABSTRACTION / DRIFT
- **Impact**: HIGH (>3 occurrences or >20 lines each) / MEDIUM (2-3 occurrences) / LOW (minor)
- **Locations**: file:line for each occurrence
- **Code snippets**: the duplicated/similar blocks (abbreviated if >15 lines)
- **Suggestion**: concrete refactoring approach (function name, module location, signature)

Do NOT report:
- Similar test setup code (tests are allowed to be repetitive for readability)
- Framework boilerplate that cannot be abstracted (e.g., route definitions)
- Config files or generated code
- Differences that are intentional (check comments, commit messages)
```

## Step 3 — Consolidation

After agents return, act as the senior architect:

1. **Merge overlapping findings** — if two agents found the same duplication from different files, merge into one finding.

2. **Rank by ROI** — for each finding, estimate:
   - **Effort**: how many files need to change, is it a simple extract-function or a design change?
   - **Benefit**: how much duplication is eliminated, what's the maintenance risk if left as-is?
   - **Risk**: could this refactoring break things? Is it well-covered by tests?

3. **Filter out low-ROI noise** — if the effort exceeds the benefit (e.g., extracting a 3-line helper used twice), drop it with a 1-line justification.

4. **Group into refactoring units** — things that should be done together because they touch the same files or create the same abstraction.

## Step 4 — Report (always)

Generate and save to `factorize-reports/YYYY-MM-DD_HH-MM.md`:

```markdown
# Factorize Report — [project name]
**Date:** [timestamp]
**Stack:** [detected]
**Scope:** [full / directory path]
**Files analyzed:** [count]
**Agents used:** [count]

## Summary

| Type | HIGH | MEDIUM | LOW | Total |
|------|------|--------|-----|-------|
| Duplication | X | X | X | X |
| Repeated pattern | X | X | X | X |
| Missed abstraction | X | X | X | X |
| Copy-paste drift | X | X | X | X |

**Estimated impact:** ~[X] lines of code can be eliminated or consolidated.

## HIGH impact findings

### [F-1] [Type] — [short title]
- **Impact:** HIGH
- **Locations:**
  - `file1.ext:L10-L25`
  - `file2.ext:L42-L57`
  - `file3.ext:L8-L23`
- **Duplicated block:**
  ```[lang]
  [code snippet]
  ```
- **Suggestion:** Extract to `[module/function name]` in `[suggested path]`
- **Effort:** [XS/S/M] — [brief justification]
- **Risk:** [low/medium — test coverage status]

## MEDIUM impact findings

| # | Type | Title | Locations | Suggestion | Effort |
|---|------|-------|-----------|------------|--------|
| 1 | ... | ... | file1, file2 | ... | S |

## LOW impact findings (informational)

[Brief list — no action expected unless convenient]

## Rejected findings

| # | Finding | Reason |
|---|---------|--------|
| 1 | ... | Intentional difference / framework constraint / ROI too low |

## Recommended refactoring plan

### Wave 1 — Quick wins (XS-S effort, high impact)
1. [F-X] Extract `[function]` from [files] → [target module]
2. [F-Y] Unify [pattern] across [files]

### Wave 2 — Medium effort
3. [F-Z] Create shared [abstraction] for [concern]

### Wave 3 — Large refactoring (discuss first)
4. [F-W] Restructure [area] — requires design decision
```

Create `factorize-reports/` if it doesn't exist.
Add `factorize-reports/` to `.gitignore` if not already present.

## Step 5 — Apply (unless --dry-run)

If NOT in dry-run mode, ask:

```
[X] findings ready to apply.
Recommended approach:
  Wave 1: [X] quick wins ([list of F-IDs])
  Wave 2: [X] medium refactors
  Wave 3: [X] need discussion first

Apply Wave 1 now? [Y/n/all]
```

- **Y** → apply Wave 1 only, then ask for Wave 2
- **all** → apply Waves 1 + 2 (never auto-apply Wave 3)
- **n** → stop, report is saved

For each applied refactoring:
1. Create the shared function/module
2. Replace all occurrences with calls to the shared version
3. Run the project's test command (from CLAUDE.md) after each wave
4. If tests fail → revert the wave, report which refactoring caused the failure

## Step 6 — Tickets

For findings NOT applied (Wave 3, or if user chose dry-run):
- If `BACKLOG/` exists → create IMP tickets (scan IDs, anti-conflict)
- Use the standard ticket format with the factorize finding details
- Reference the report: `See factorize-reports/[filename].md, finding F-X`

## Rules — NON-NEGOTIABLE

- **Read CLAUDE.md first** — respect project conventions for where shared code lives
- **Wait for user confirmation** after the plan (Step 1) AND before applying (Step 5)
- **Never auto-apply Wave 3** — large refactorings need human decision
- **Run tests after each wave** — revert if broken
- **Never refactor test code** — tests can be repetitive, that's fine
- **Never create FEAT tickets** — factorization is improvement, not new features
- **Reports contain code snippets** — gitignore them
- **Dry-run is the safe default** — if user seems unsure, suggest --dry-run first
