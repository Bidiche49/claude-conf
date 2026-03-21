---
description: Load session context — git state, backlog, last handoff
---

Load the current session context and display a brief summary. Follow these steps:

1. Run `git status` and `git log --oneline -10`
2. Scan `BACKLOG/` — count pending and done tickets by type (bugs, features, improvements)
3. Check if `.claude-sessions/HANDOFF-*.md` exists — if yes, mention the most recent one (date + subject, 1 line). **NEVER load the handoff automatically — just mention it exists.**
4. Read the project's `CLAUDE.md` (not the global one)

Display a summary in this format:

```
SESSION — [project name] ([stack])
═══════════════════════════════
Git    : branch [name], [N] ahead, [N] modified files
Backlog: [N] pending ([breakdown]) / [N] done
Handoff: [filename] ([subject])
         → To resume, just ask.

Ready. What are we working on?
```

## Rules — NON-NEGOTIABLE

- NEVER load the handoff automatically — just mention it exists
- NEVER propose what to work on — wait for the user
- Summary MUST fit in 5-6 lines max
- If no BACKLOG/ exists, skip that line
- If no handoff exists, skip that line
