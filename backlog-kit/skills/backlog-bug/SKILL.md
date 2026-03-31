---
name: backlog-bug
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

4. **Check for external documentation needs**: If the bug involves a third-party library, API, or service (e.g. Stripe, Firebase, AWS SDK), note in the ticket that the relevant documentation should be consulted before starting the fix. Add a line in the description: `📖 Consulter: [doc URL or doc name]`.

5. **Identify affected files**: Based on the description and your knowledge of the codebase, determine which files are involved. If you can identify them, list the actual paths. If unsure, list the most likely candidates with a `(?)` marker. NEVER leave `(A determiner)` — always make your best assessment.

6. **Write specific acceptance criteria**: Describe the expected behavior AFTER the fix. Not "le bug est corrige" — describe what should happen concretely. Example: "La commande `install.sh` ne crash plus quand le dossier cible n'existe pas" instead of "Le bug est corrige".

7. **Write actionable test steps**: List the exact commands to run or manual steps to reproduce/verify. Reference the project's existing test commands when relevant (`bash tests/test.sh`, `bun test`, etc.).

8. **Create** `BACKLOG/BUGS/PENDING/BUG-XXX.md` using this format:

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
   [User's description, enriched with root cause analysis if possible]

   ## Fichiers concernes
   - `path/to/file.ext` — [why this file is involved]

   ## Criteres d'acceptation
   - [ ] [Specific expected behavior after fix]
   - [ ] Aucune regression introduite

   ## Tests de validation
   - [ ] [Exact command or manual verification step]
   ```

9. **Regenerate INDEX.md** — run the full `/backlog-status` logic (scan all tickets, rewrite INDEX.md entirely, display stats).

10. **Confirm** with the ticket ID and path.

## Important

- Do NOT start fixing the bug — just create the ticket.
