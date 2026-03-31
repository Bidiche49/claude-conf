---
name: explore
description: Deep exploration of codebase, docs, and web for any topic or question
argument-hint: <topic or question>
---

Explore #$ARGUMENTS in depth using a structured, parallel approach.

## Process

1. **Plan** (30 seconds max):
   - Break the topic into 2-3 specific sub-questions
   - Identify what to search: codebase, docs, web, or all

2. **Explore** (parallel agents):
   - Launch 1-2 agents maximum for codebase search
   - Launch 1 agent for web/docs if library-specific knowledge needed
   - Each agent has a focused question, not a vague "look around"

3. **Synthesize**:
   - Merge findings from all agents
   - Identify conflicts or gaps
   - Produce a structured report

## Report format

### Exploration: [topic]

#### Key findings

- [Finding 1 — with file:line references where applicable]
- [Finding 2]

#### Architecture / Patterns

- [How the codebase handles this]

#### Recommendations

- [If the user asked "how should we..." — concrete recommendation]
- [If the user asked "how does..." — no recommendation needed]

#### Files explored

- path/to/file — [what was found]

## Rules
- NEVER explore without a plan — even 30 seconds of planning saves 5 minutes of wandering
- Max 2 parallel agents during explore — more creates context fragmentation
- Always include file:line references — vague answers are worthless
- If the topic is too broad, narrow it and tell the user what you narrowed
- If stuck after 2 minutes: stop exploring, report what you found, ask the user to refine
