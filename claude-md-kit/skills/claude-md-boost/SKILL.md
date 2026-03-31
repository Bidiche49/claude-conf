---
name: claude-md-boost
description: Optimize project CLAUDE.md — expert prompt engineering + stack best practices
---

Rewrite the project CLAUDE.md as a CTO and prompt engineering expert. Every line must measurably change Claude's behavior. 20 precise lines > 100 lines of filler.

## Process

1. **If no CLAUDE.md exists** → tell the user to run `/claude-md-init` first. Stop.

2. **Cleanup phase** (integrated — don't ask the user to run cleanup separately):
   - Read project CLAUDE.md and `~/.claude/CLAUDE.md`
   - Identify installed modules (markers: `<!-- critical-thinking:start -->`, `<!-- backlog:start -->`, etc.)
   - Remove duplicates with global config (same rules as `/claude-md-cleanup`)

3. **Explore the project:**
   - Directory structure, config files, stack detection
   - Read 4-6 representative code files (handler, service, model, test, config)
   - Identify real patterns, naming conventions, error handling style

4. **Analyze the current CLAUDE.md** — for each rule, ask:
   - Is it actionable? (can you verify compliance in a code review?)
   - Does it come from real code or is it generic filler?
   - Are build/test commands the real ones from config files?
   - Is anything critical for this stack missing?

5. **Rewrite the CLAUDE.md:**
   - Preserve the user's intent (what they wanted to express)
   - Make every rule specific and actionable
   - Add stack-specific conventions detected in the code (with BON/MAUVAIS examples from real code)
   - Structure in optimal order: Projet → Regles → Build & Test → Architecture → Conventions → Config → Etat actuel

   **Stack best practices to check for** (only add what's actually used in the project):
   ```
   iOS/Swift    : weak self in closures, deinit cleanup, navigation patterns, force unwrap rules, concurrency (actors/async-await)
   React/Next   : hooks rules (deps arrays), component patterns (server vs client), state management, SSR boundaries
   Node/Express : error handling middleware, async/await patterns, validation layer, env config
   Flutter      : widget lifecycle, state management (Riverpod/Bloc/Provider), platform channels, key usage
   Go           : error handling (wrap vs return), goroutine patterns, interface design, table-driven tests
   Python       : type hints, async/await, test fixtures, dependency injection patterns
   Rust         : ownership patterns, Result/Option handling, trait design, test organization
   PHP/Laravel  : service pattern, Eloquent conventions, form requests, middleware
   ```

6. **Present the diff** — show old vs new for each section that changed, with rationale.

7. **Wait for explicit validation** before writing.

## Golden rule

Every line added must change Claude's behavior in a measurable way. If a rule would be ignored or changes nothing, don't add it. If you can't explain what Claude would do DIFFERENTLY because of a rule, that rule is filler — delete it.
