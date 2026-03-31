---
name: audit-conf
description: Audit project config against latest claude-conf — fix drift, clean duplicates, optimize CLAUDE.md
---

Audit this project's Claude Code configuration against the latest global config.
Fix drift, remove duplicates, regenerate caches, and optimize.

## Step 1 — Project CLAUDE.md

Read `.claude/CLAUDE.md` or `CLAUDE.md` at project root.

**If it exists:**

1. Read `~/.claude/CLAUDE.md` (global config)
2. Compare section by section. Remove from project CLAUDE.md anything that is
   **identical or near-identical** to the global config:
   - Mindset engineering rules → in global, remove from project
   - Critical-thinking / anti-complacency → in global, remove from project
   - Backlog system rules → in global, remove from project
   - Handoff rules → in global, remove from project
3. Check for **obsolete references**:
   - `/oneshot` → removed module, delete any mention
   - `[SYSTEM-HANDOFF-CRITICAL]` → removed behavior, delete any mention
   - `WORKER_COMMAND` → renamed to `WORKER_MODE`, update if found
   - Old commit rules referencing "Co-Authored-By: Claude" → should not exist
4. Check that **stack-specific rules** are present and accurate:
   - Build/lint/test commands match actual project config files
   - Framework conventions match actual code patterns
   - If rules reference files that don't exist → flag
5. Run `/claude-md-boost` if the CLAUDE.md is thin or generic

**If it doesn't exist:**
- Run `/claude-md-init` to generate one

**Show the diff** of any changes before proceeding.

## Step 2 — BACKLOG

**If `BACKLOG/` exists:**

1. Run `/backlog-status` to regenerate INDEX.md from ticket files
2. Check for orphan tickets:
   - Files without proper `# TYPE-XXX: Title` heading → flag
   - Duplicate IDs across PENDING and DONE → flag
3. Check that tickets in DONE/ have `**Statut:** Fait` in their content
4. Report: "X pending / X done, INDEX.md regenerated"

**If `BACKLOG/` doesn't exist:**
- Skip (not all projects need a backlog)

## Step 3 — Local settings

Read `.claude/settings.local.json` if it exists.

Check:
1. **Permissions** — are they appropriate for this project's stack?
   - Missing common permissions for the detected stack → suggest
   - Overly broad permissions (`Bash(*)`) → flag
2. **Hooks** — any obsolete hook references?
   - `bun .../src/cli.ts` (old command-guard) → should be wrapper
   - Any hook pointing to files that don't exist → flag
3. If no local settings exist → OK (global settings apply)

## Step 4 — .gitignore

Check that these are ignored (either in project `.gitignore` or `~/.gitignore_global`):
- `.claude-sessions/`
- `.claude/` (if not needed in repo)

Run: `git check-ignore .claude-sessions/test 2>/dev/null` to verify.

## Step 5 — Summary

Display:

```
AUDIT — [project name]
═══════════════════════
CLAUDE.md    : [OK / created / cleaned (N duplicates removed) / boosted]
BACKLOG      : [OK (X pending / X done) / regenerated / initialized / not present]
Settings     : [OK / issues found: (list)]
.gitignore   : [OK / needs .claude-sessions/]

Actions performed:
- [list of what was done]

Manual actions needed:
- [list of what requires user decision]
```

## Rules — NON-NEGOTIABLE

- **DO NOT COMMIT** — show summary and wait for user validation
- **Show diffs** before modifying CLAUDE.md — the user must approve
- **Be conservative** — never remove a project rule unless you confirmed it exists
  in the global config. When in doubt, keep it.
- **Never touch source code** — this is a config audit, not a refactoring
- This audit should take < 2 minutes. If something is complex, flag it and move on.