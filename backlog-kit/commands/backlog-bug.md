---
description: Create a BUG ticket quickly
argument-hint: <bug description>
---

Create a new BUG ticket in the backlog.

## Input

$ARGUMENTS

## Steps

1. **Check** that `BACKLOG/` exists. If not, tell the user to run `/backlog-init` first and stop.

2. **Calculate the next ID** by scanning files (NEVER read INDEX.md for the ID):
   - List all files in `BACKLOG/BUGS/PENDING/` and `BACKLOG/BUGS/DONE/`
   - Extract all numbers from `BUG-XXX.md` filenames
   - Next ID = max number found + 1 (or 001 if no files exist)
   - Format: `BUG-XXX` (zero-padded to 3 digits)

3. **Analyze** the description to determine:
   - Priorite (Critique / Haute / Moyenne / Basse)
   - Complexite (XS / S / M / L / XL)
   - Tags (free-form, relevant to the bug)

4. **Create** `BACKLOG/BUGS/PENDING/BUG-XXX.md` using this format:

   ```markdown
   # BUG-XXX: [Short title derived from description]

   **Type:** Bug
   **Statut:** A faire
   **Priorite:** [determined]
   **Complexite:** [estimated]
   **Tags:** [relevant]
   **Depends on:** none
   **Blocked by:** —
   **Date creation:** [today YYYY-MM-DD]

   ---

   ## Description
   [User's description, enriched if needed]

   ## Fichiers concernes
   - (A determiner)

   ## Criteres d'acceptation
   - [ ] Le bug est corrige
   - [ ] Aucune regression introduite

   ## Tests de validation
   - [ ] [Specific tests for this bug]
   ```

5. **Regenerate INDEX.md** — run the full `/backlog-status` logic (scan all tickets, rewrite INDEX.md entirely, display stats).

6. **Confirm** with the ticket ID and path.

## Important

- Do NOT start fixing the bug — just create the ticket.
