---
name: backlog-status
description: Regenerate INDEX.md and display backlog statistics
---

Scan all tickets and regenerate INDEX.md from scratch. Then display stats.

## Steps

1. **Check** that `BACKLOG/` exists. If not, inform the user and stop.

2. **Scan all ticket files** in:
   - `BACKLOG/BUGS/PENDING/` and `BACKLOG/BUGS/DONE/`
   - `BACKLOG/FEATURES/PENDING/` and `BACKLOG/FEATURES/DONE/`
   - `BACKLOG/IMPROVEMENTS/PENDING/` and `BACKLOG/IMPROVEMENTS/DONE/`

3. **For each ticket file**, read and extract:
   - ID and title (from the `# TYPE-XXX: Title` heading)
   - Priorite (from the `**Priorite:**` field)
   - Statut: "A faire" if in PENDING/, "Fait" if in DONE/

4. **Rewrite `BACKLOG/INDEX.md` entirely** with this format:

   ```markdown
   # BACKLOG — [basename of project directory]

   ## FEATURES

   | ID | Titre | Statut | Priorite |
   |----|-------|--------|----------|
   | FEAT-001 | ... | A faire | Haute |

   **Prochain ID : FEAT-XXX**

   ## BUGS

   | ID | Titre | Statut | Priorite |
   |----|-------|--------|----------|

   **Prochain ID : BUG-XXX**

   ## IMPROVEMENTS

   | ID | Titre | Statut | Priorite |
   |----|-------|--------|----------|

   **Prochain ID : IMP-XXX**
   ```

   - Sort tickets by ID within each section
   - "Prochain ID" = max ID found + 1 (or 001 if no tickets). Zero-padded to 3 digits.
   - If a section has no tickets, leave the table empty (header only)

5. **Display stats** in the terminal:

   ```
   BACKLOG STATUS
   ══════════════
   BUGS:         X pending / X done
   FEATURES:     X pending / X done
   IMPROVEMENTS: X pending / X done
   ──────────────
   TOTAL:        X pending / X done
   ```
