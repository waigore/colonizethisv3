---
name: update-game-manual
description: Updates the ColonizeThis player game manual under docs/manual/ after SPEC or UI changes—maps affected chapters via Sources footers, preserves vizier tone and player-angle framing, enforces chapter template and draft-marking. Use when SPEC/game, SPEC/ui, allowlisted SPEC/program files, orders, screens, or manual chapters change, or when the user asks to refresh the game manual.
---

# Update the player game manual (ColonizeThis)

## Authority

Normative writing: **[`docs/manual/STYLE_GUIDE.md`](../../../docs/manual/STYLE_GUIDE.md)**. Rule: **[`.cursor/rules/colonizethis-game-manual.mdc`](../../../.cursor/rules/colonizethis-game-manual.mdc)**.

Cursor copy: [`.cursor/skills/update-game-manual/SKILL.md`](../../../.cursor/skills/update-game-manual/SKILL.md) — keep workflow in sync; policy changes belong in the style guide and `.mdc`.

## When to use

- SPEC/game, SPEC/ui, or allowlisted SPEC/program changes that affect what the player can do, see, or be told.
- User asks to update or align the **player game manual**.

## Workflow

1. List changed repo-relative SPEC paths.
2. Map to chapters by **exact match** on `## Sources` bullets under `docs/manual/`.
3. Update prose per style guide (player angle, tone, template, draft marking).
4. Refresh Sources footers; complete the skill checklist in the Cursor SKILL.md.

## Output

Paths considered, chapters updated or non-update justification, checklist result.
