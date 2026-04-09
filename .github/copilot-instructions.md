# Copilot Session Protocol for GAPP

## Mandatory Start-of-Session Steps

Before proposing code changes, running refactors, or creating new files, always do the following in order:

1. Read [BLUEPRINT.md](../BLUEPRINT.md) fully.
2. Produce a short "Session Context Snapshot" (5 bullets max) covering:
   - Product goal
   - Current architecture
   - Active features in development
   - Planned features
   - Critical business rules
3. Confirm that requested work aligns with existing specs in [memory/specs](../memory/specs).
4. If any conflict is detected between the task and docs, call it out before implementing.

## Mandatory End-of-Session Documentation Check

A task is not considered complete until documentation alignment is checked.

At session close, always run this checklist:

1. Did navigation behavior change?
2. Did business rules change?
3. Did data model/contracts change?
4. Did implementation status or roadmap change?
5. Did feature ownership/scope change?

If any answer is yes:

1. Update [BLUEPRINT.md](../BLUEPRINT.md).
2. Update affected spec files under [memory/specs](../memory/specs).
3. Include a "Docs Updated" summary listing touched files and what changed.

If all answers are no:

- Include a "Docs Check" note: "No documentation updates required after validation."

## Priority and Source of Truth

1. Source of truth order:
   - [BLUEPRINT.md](../BLUEPRINT.md)
   - [memory/specs/01-visit-lifecycle.md](../memory/specs/01-visit-lifecycle.md)
   - [memory/specs/02-visit-editing.md](../memory/specs/02-visit-editing.md)
   - [memory/specs/03-visit-initiation-screen.md](../memory/specs/03-visit-initiation-screen.md)
   - [memory/specs/04-implementation-guide.md](../memory/specs/04-implementation-guide.md)
2. Never silently diverge from these docs.
3. When implementation intentionally diverges, update docs in the same session.

## Response Format Requirements

At the beginning of each session, include:

- "Session Context Snapshot" (max 5 bullets)

At the end of each session, include either:

- "Docs Updated" with changed docs
or
- "Docs Check: No documentation updates required after validation."
