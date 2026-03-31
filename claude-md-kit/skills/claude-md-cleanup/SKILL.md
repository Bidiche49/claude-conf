---
name: claude-md-cleanup
description: Clean up project CLAUDE.md — remove duplicates with global config
---

Analyze the project CLAUDE.md and remove everything already covered by the global config or installed modules. Keep only what's specific to this project.

## Process

1. **Read** the project's `CLAUDE.md`
2. **Read** `~/.claude/CLAUDE.md` and identify installed modules by scanning for markers:
   - `<!-- critical-thinking:start -->` — mindset, anti-complaisance, debugging approach covered
   - `<!-- backlog:start -->` — ticketing system covered
   - Also check for: handoff system, supervisor rules, general rules (no AI mention, documentation, etc.)

3. **Classify each section** of the project CLAUDE.md:
   - **SUPPRIMER** — duplicate of global (same concept, even if different wording). Examples:
     - Ticketing/backlog rules → covered by backlog-kit
     - Handoff/context saving → covered by handoff-kit
     - "No band-aid fixes" / "understand before coding" → covered by critical-thinking
     - "Never mention Claude/AI" → covered by global general rules
     - Generic dev advice ("write tests", "be clean") → useless, remove
   - **GARDER** — specific to this project (stack conventions, build commands, architecture, project-specific rules)
   - **REFORMULER** — mix of generic + specific → keep only the specific part

4. **Present the plan** to the user:
   ```
   SECTIONS A SUPPRIMER (doublons avec global) :
   - "[section name]" — reason (covered by [module/section])

   SECTIONS A GARDER :
   - "[section name]" — reason

   SECTIONS A REFORMULER :
   - "[section name]" — keep [specific part], remove [generic part]
   ```

5. **Wait for explicit validation** before writing.

6. **Write** the cleaned CLAUDE.md. Preserve the structure and intent of kept sections.

## Key rule

Detect by MEANING, not string matching. "Pas de fix en pansement" and "No band-aid fixes" are the same concept — both must be flagged as duplicates.
