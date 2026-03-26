---
description: Deep code audit — security, tests, architecture, performance, stack-specific checks
argument-hint: [security|tests|architecture|performance|ux|costs|<custom>]
---

Run a structured code audit on this project. Adapts to the detected stack.

## Step 1 — Context & scope

1. Read `CLAUDE.md` (project root or `.claude/`). If none exists:
   - Tell the user: "No CLAUDE.md found. Run `/audit-conf` first to generate one, then re-run `/audit`."
   - Stop.

2. From CLAUDE.md, extract:
   - **Stack** (languages, frameworks, DB, infra)
   - **Build/test commands**
   - **Project conventions**

3. Determine audit scope:
   - If `$ARGUMENTS` is provided → audit ONLY that axis
   - If no argument → auto-detect relevant axes (see Step 2)

## Step 2 — Detect relevant axes

Based on the stack and project structure, select which axes to audit.

**Always included (any stack):**
- **Tests** — coverage gaps, weak assertions, missing edge cases, fragile tests
- **Security** — secrets in code, injection risks, input validation, dependency vulnerabilities
- **Architecture** — layering violations, DRY, coupling, pattern consistency
- **Error handling** — silent failures, broad exceptions, unhelpful error messages

**Include if detected:**
- **Performance** — if DB/ORM present: N+1 queries, missing indexes, unbounded queries. If async: race conditions.
- **Data integrity** — if ETL/pipeline/import code present
- **UX** — if frontend framework detected (Streamlit, Flutter, React, etc.)
- **API costs** — if LLM/SaaS API calls detected (OpenAI, Anthropic, Stripe, etc.)
- **Deployment** — if Docker, CI/CD, systemd, Caddy files present

Present the selected axes to the user:
```
AUDIT PLAN — [project name]
Stack: [detected stack]
Axes: [list of selected axes]
Estimated: [2-4] review agents

Proceed? [Y/n]
```

Wait for confirmation before launching agents.

## Step 3 — Exploration phase

Launch **1 agent** (subagent_type: `Explore`, thoroughness: "very thorough"):

**Mission:** Map the codebase for the audit. For each selected axis, identify which files
are relevant. Produce a structured map:

```
AUDIT MAP
├── Tests: [list of test files + source files with no test coverage]
├── Security: [auth files, route handlers, config files, env handling]
├── Architecture: [core modules, services, models, entry points]
├── Error handling: [same files as architecture + API clients]
├── Performance: [DB queries, ORM models, async code, batch operations]
├── [other axes]: [relevant files]
```

This map is the INPUT for the review agents. No file should be audited blindly.

## Step 4 — Review phase

Launch **2-4 agents** in parallel (subagent_type: `feature-dev:code-reviewer`).

Split the axes across agents to minimize file overlap:

| Agent | Axes | Focus |
|-------|------|-------|
| Reviewer 1 | Security + Error handling | Auth, routes, input handling, config, API clients |
| Reviewer 2 | Tests + Robustness | Test files, source files with gaps, edge cases |
| Reviewer 3 | Architecture + Performance | Core logic, services, models, DB queries |
| Reviewer 4 | Stack-specific (if applicable) | UX, data integrity, API costs, deployment |

**Skip Reviewer 4** if no stack-specific axes were selected.
**Merge Reviewers 1+2** if the project has < 20 source files (small project).

Each agent receives:
1. The audit map (their relevant files ONLY)
2. The CLAUDE.md stack conventions
3. Clear instructions:

```
You are auditing [project name] ([stack]).
Your axes: [list].
Files to review: [list from audit map].

For each finding, report:
- **Severity**: CRITICAL / HIGH / MEDIUM / LOW
- **Category**: BUG / SECURITY / ROBUSTNESS / PERFORMANCE / COST / UX / ARCHITECTURE
- **File:line**: exact location
- **Description**: what's wrong (1-2 sentences)
- **Evidence**: the problematic code snippet
- **Suggestion**: how to fix it (1-2 sentences)

CRITICAL/HIGH findings MUST include evidence (code snippet).
Do NOT report style issues or nitpicks — only real problems.
Do NOT report issues that the project's linter/analyzer would already catch.
```

## Step 5 — CTO consolidation

After all agents return, act as CTO. For each finding:

**CRITICAL/HIGH findings:**
- Read the actual file at the reported line
- Verify the finding is real (not a false positive, not already handled elsewhere)
- If false positive → reject with 1-line justification
- If confirmed → keep, classify

**MEDIUM/LOW findings:**
- Accept as-is (no re-verification — trust the reviewer for lower severity)
- Still classify

**Feature suggestions** (things that aren't bugs but could be better):
- Separate into a "Feature suggestions" section
- Do NOT create tickets — present for discussion

## Step 6 — Create tickets

For each confirmed finding:

| Category | Ticket type | Auto-create? |
|----------|------------|--------------|
| BUG / SECURITY (CRITICAL/HIGH) | BUG | Yes |
| BUG / SECURITY (MEDIUM/LOW) | BUG | Yes |
| ROBUSTNESS / ARCHITECTURE / PERFORMANCE | IMP | Yes |
| COST / UX | IMP | Yes |
| Feature suggestion | — | No (discussion) |

**Respect project conventions:**
- If `BACKLOG/` exists → create tickets there (scan existing IDs, anti-conflict)
- If no `BACKLOG/` → skip ticket creation, just present findings in report
- Use `/backlog-bug` and `/backlog-imp` patterns for ticket format

## Step 7 — Report

Generate the report and save to `audit-reports/YYYY-MM-DD_HH-MM.md`.

**The filename MUST include the hour and minute** (e.g., `2026-03-26_14-30.md`).
Use `date +%Y-%m-%d_%H-%M` to generate it. Never use date-only filenames — multiple audits per day would collide.

```markdown
# Audit Report — [project name]
**Date:** [timestamp]
**Stack:** [detected stack]
**Axes audited:** [list]
**Agents used:** [count]

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | X |
| HIGH     | X |
| MEDIUM   | X |
| LOW      | X |

| Category | Count |
|----------|-------|
| BUG      | X |
| SECURITY | X |
| ...      | X |

## CRITICAL & HIGH findings

### [FINDING-1] [Category] — [short title]
- **Severity:** CRITICAL
- **File:** `path/to/file:line`
- **Ticket:** BUG-XXX (created)
- **Description:** ...
- **Evidence:** ```code snippet```
- **Suggestion:** ...
- **Verified:** ✅ confirmed by CTO review

### [FINDING-2] ...

## MEDIUM & LOW findings

| # | Severity | Category | File | Description | Ticket |
|---|----------|----------|------|-------------|--------|
| 1 | MEDIUM | ... | ... | ... | IMP-XXX |
| 2 | LOW | ... | ... | ... | IMP-XXX |

## Rejected findings (false positives)

| # | Original finding | Rejection reason |
|---|-----------------|-----------------|
| 1 | ... | ... |

## Feature suggestions (for discussion)

- [Suggestion 1 — description + rationale]
- [Suggestion 2]

## Recommended treatment order

1. [TICKET-ID] (SEVERITY) — [why first: impact, quick win, dependency]
2. [TICKET-ID] (SEVERITY) — [reason]
3. ...

Group quick wins (XS complexity) that can be batched together.

## Tickets created

| ID | Type | Title | Severity |
|----|------|-------|----------|
| BUG-XXX | BUG | ... | CRITICAL |
| IMP-XXX | IMP | ... | MEDIUM |
```

Create the `audit-reports/` directory if it doesn't exist.

Also display a summary in the conversation:

```
AUDIT COMPLETE — [project name]
═══════════════════════════════
Findings: X critical, X high, X medium, X low
Rejected: X false positives
Tickets created: X BUG, X IMP
Feature suggestions: X (for discussion)

Full report: audit-reports/[filename].md
```

## Step 8 — .gitignore

After saving the report, check that `audit-reports/` is in `.gitignore`.
If not, add it (audit reports contain security findings — never commit them).

## Rules — NON-NEGOTIABLE

- **Read CLAUDE.md first** — never audit without understanding the project
- **Wait for user confirmation** after presenting the audit plan (Step 2)
- **Never modify source code** — this is an audit, not a fix
- **Never skip CTO verification for CRITICAL/HIGH** — every serious finding must be re-checked
- **Never create FEAT tickets** — features are discussions, not unilateral decisions
- **Always save the report** — findings must persist beyond the conversation
- **Respect existing BACKLOG conventions** — scan IDs, use proper format
- **Audit reports contain sensitive data** — ensure they're gitignored
