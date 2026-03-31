---
name: backlog-feat
description: Create a FEATURE ticket quickly
argument-hint: <feature description>
---

Create a new FEATURE ticket in the backlog.

## Input

$ARGUMENTS

## Steps

1. **Check** that `BACKLOG/` exists. If not, tell the user to run `/backlog-init` first and stop.

2. **Calculate the next ID** by scanning files (NEVER read INDEX.md for the ID):
   - List all files in `BACKLOG/FEATURES/PENDING/` and `BACKLOG/FEATURES/DONE/`
   - Extract all numbers from `FEAT-XXX.md` filenames
   - Next ID = max number found + 1 (or 001 if no files exist)
   - Format: `FEAT-XXX` (zero-padded to 3 digits)

3. **Analyze** the description to determine:
   - Priorite (Critique / Haute / Moyenne / Basse)
   - Complexite (XS / S / M / L / XL)
   - Tags (free-form, relevant to the feature)

4. **Check for external documentation needs**: If the feature involves a third-party library, API, or service (e.g. Stripe, Firebase, AWS SDK, a specific framework), note in the ticket that the relevant documentation should be consulted before starting implementation. Add a line in the description: `📖 Consulter: [doc URL or doc name]`.

5. **Identify affected files**: Based on the description and your knowledge of the codebase, determine which files will need to be created or modified. List actual paths. For new files, indicate `(new)`. For uncertain candidates, add `(?)`. NEVER leave `(A determiner)`.

6. **Write specific acceptance criteria**: Describe the observable behavior the feature must produce. Each criterion should be independently verifiable. Example: "La commande `/foo` cree un fichier dans `~/.claude/commands/`" instead of "La feature marche".

7. **Write actionable test steps**: List the exact commands or scenarios to validate the feature works. Reference existing test infrastructure when applicable.

8. **Create** `BACKLOG/FEATURES/PENDING/FEAT-XXX.md` using this format:

   ```markdown
   # FEAT-XXX: [Short title derived from description]

   **Type:** Feature
   **Statut:** A faire
   **Priorite:** [determined]
   **Complexite:** [estimated]
   **Tags:** [relevant]
   **Depends on:** none
   **Blocked by:** —
   **Date creation:** [today YYYY-MM-DD]

   ---

   ## Description
   [User's description, enriched with context and design considerations]

   ## Fichiers concernes
   - `path/to/file.ext` — [create/modify, why]

   ## Criteres d'acceptation
   - [ ] [Specific observable behavior]

   ## Tests de validation
   - [ ] [Exact command or verification scenario]
   ```

9. **Regenerate INDEX.md** — run the full `/backlog-status` logic (scan all tickets, rewrite INDEX.md entirely, display stats).

10. **Confirm** with the ticket ID and path.

## Important

- Do NOT start implementing the feature — just create the ticket.
