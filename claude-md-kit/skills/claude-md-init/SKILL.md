---
name: claude-md-init
description: Generate a CLAUDE.md from scratch for a project without one
---

Generate a project-specific CLAUDE.md by analyzing the real codebase. Every line must be actionable and specific to THIS project.

## Process

1. **Check** if `CLAUDE.md` exists at project root. If yes, warn and ask confirmation before overwriting.

2. **Explore the project:**
   - Directory structure (top 2-3 levels)
   - Config files: package.json, pubspec.yaml, go.mod, Cargo.toml, pyproject.toml, composer.json, Makefile, *.xcodeproj, tsconfig.json, .eslintrc*, etc.
   - `git log --oneline -20` for recent activity
   - Detect: stack, framework, ORM, test runner, linter, monorepo vs monolith

3. **Read 4-6 representative files** (controller, service, model, test, config) — pick files with real logic, not boilerplate.

4. **Read `~/.claude/CLAUDE.md`** to identify what's already covered globally (mindset, ticketing, handoff, critical-thinking, general rules). Do NOT duplicate any of it.

5. **Generate CLAUDE.md** with this exact structure:

```markdown
# CLAUDE.md — [Project Name]

## Projet
[2-3 lines: what it does, who it's for, main stack]

## Regles specifiques a ce projet
[Rules NOT in the global config — specific to THIS project]
[e.g. "Never run xcodebuild directly", "Prisma migrations must be generated, not hand-written"]

## Build & Test
[REAL commands read from package.json/Makefile/etc. — not guesses]

## Architecture
[Simplified directory structure + stack table (framework/lib/version)]

## Conventions code (ce projet)
[Patterns extracted from REAL code read in step 3]
[Use BON/MAUVAIS format with examples from the actual codebase]

## Configuration
[Env vars (not values), API endpoints, services, external deps]

## Etat actuel
[Active branches, next steps if detectable from git]
```

6. **Present** the generated CLAUDE.md to the user. Explain key choices. **Wait for explicit validation before writing the file.**

## Rules — NON-NEGOTIABLE

- **NEVER write generic content.** FORBIDDEN: "Write clean code", "Follow best practices", "Test before committing", "Use meaningful names" — all useless filler.
- **NEVER duplicate the global CLAUDE.md** — ticketing, handoff, mindset, critical-thinking, general rules are already there.
- **Every rule must be actionable** — if you can't verify compliance in a code review, don't add it.
- **Conventions from real code only** — if unsure, leave it out. Fewer specific lines > many generic lines.
- **Build/test commands must be real** — read from config files, never guess.
