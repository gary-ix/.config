---
description: Create or update a discussion note in .local/discussions/
agent: pair-programmer
---

Topic: $ARGUMENTS

If no topic is provided, ask the user.

## Instructions

1. Ensure `.local/discussions/` exists at the project root. Create it if missing.
2. Search `.local/discussions/` for an existing note on the same or closely related topic.
   - **If found**: Update that file — append new sections, revise content, or add follow-up notes. Update the _Last updated_ date. If you're unsure it's the right file, ask before editing.
   - **If not found**: Create a new file.

## File naming

New files use the format: `YYYY-MM-DD-topic-slug.md`

- Date is today's date
- Slug is kebab-case derived from the topic
- Example: `.local/discussions/2026-02-23-auth-strategy.md`

## Document format

```markdown
# Title

_Last updated: YYYY-MM-DD_

## Section heading

Content here...
```

- H1 title reflecting the topic
- Last updated date — **always** set to today on create or update
- Sections organized with H2/H3 headings
- Cover key points, considerations, trade-offs, and decisions as appropriate

## Tone

Conversational but informative — these are working notes and design discussions, not formal docs.
