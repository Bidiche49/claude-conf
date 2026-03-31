---
name: backlog-imp
description: Create an IMPROVEMENT ticket quickly
argument-hint: <improvement description>
---

Create a new IMPROVEMENT ticket in the backlog.

## Input

$ARGUMENTS

## Steps

1. **Check** that `BACKLOG/` exists. If not, tell the user to run `/backlog-init` first and stop.

2. **Calculate the next ID** by scanning files (NEVER read INDEX.md for the ID):
   - List all files in `BACKLOG/IMPROVEMENTS/PENDING/` and `BACKLOG/IMPROVEMENTS/DONE/`
   - Extract all numbers from `IMP-XXX.md` filenames
   - Next ID = max number found + 1 (or 001 if no files exist)
   - Format: `IMP-XXX` (zero-padded to 3 digits)

3. **Analyze** the description to determine:
   - Priorite (Critique / Haute / Moyenne / Basse)
   - Complexite (XS / S / M / L / XL)
   - Tags (free-form, relevant to the improvement)

4. **Check for external documentation needs**: If the improvement involves a third-party library, API, or service (e.g. migrating to a new SDK version, adopting a framework pattern), note in the ticket that the relevant documentation should be consulted before starting. Add a line in the description: `📖 Consulter: [doc URL or doc name]`.

5. **Identify affected files**: Based on the description and your knowledge of the codebase, determine which files will be modified. List actual paths. For uncertain candidates, add `(?)`. NEVER leave `(A determiner)`.

6. **Write specific acceptance criteria**: Describe the measurable improvement — what changes concretely? Performance gain, reduced complexity, better DX? Each criterion must be verifiable. Example: "Le hook s'execute en < 100ms au lieu de 500ms" instead of "C'est plus rapide".

7. **Write actionable test steps**: List the exact commands or scenarios to validate the improvement. Reference existing test infrastructure when applicable.

8. **Create** `BACKLOG/IMPROVEMENTS/PENDING/IMP-XXX.md` using this format:

   ```markdown
   # IMP-XXX: [Short title derived from description]

   **Type:** Improvement
   **Statut:** A faire
   **Priorite:** [determined]
   **Complexite:** [estimated]
   **Tags:** [relevant]
   **Depends on:** none
   **Blocked by:** —
   **Date creation:** [today YYYY-MM-DD]

   ---

   ## Description
   [User's description, enriched with current state vs desired state]

   ## Fichiers concernes
   - `path/to/file.ext` — [what changes in this file]

   ## Criteres d'acceptation
   - [ ] [Specific measurable improvement]

   ## Tests de validation
   - [ ] [Exact command or verification scenario]
   ```

9. **Regenerate INDEX.md** — run the full `/backlog-status` logic (scan all tickets, rewrite INDEX.md entirely, display stats).

10. **Confirm** with the ticket ID and path.

## Important

- Do NOT start implementing the improvement — just create the ticket.
