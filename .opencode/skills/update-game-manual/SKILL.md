---
name: update-game-manual
description: Updates the ColonizeThis player game manual under docs/manual/ when player UX or gameplay changes—maps affected chapters via Sources footers, preserves vizier tone and grade-12 reading level (UI-engineering and genre jargon banned), player-angle framing, chapter template, and draft-marking. Use when SPEC/game, SPEC/ui, allowlisted SPEC/program files, orders, screens, or manual chapters change; when create-github-issue/plan-feature issues include manual ACs; or when the user asks to refresh the game manual.
---

# Update the player game manual (ColonizeThis)

## Authority

Normative writing: **[`docs/manual/STYLE_GUIDE.md`](../../../docs/manual/STYLE_GUIDE.md)**. Rule: **[`.cursor/rules/colonizethis-game-manual.mdc`](../../../.cursor/rules/colonizethis-game-manual.mdc)**.

Cursor copy: [`.cursor/skills/update-game-manual/SKILL.md`](../../../.cursor/skills/update-game-manual/SKILL.md) — keep workflow in sync; policy changes belong in the style guide and `.mdc`.

## When to use

- SPEC/game, SPEC/ui, allowlisted SPEC/program changes, or player UX/gameplay changes that affect what the player can do, see, or be told.
- Issues filed via **`create-github-issue`** or **`plan-feature`** with manual ACs (policy: `colonizethis-game-manual.mdc`).
- User asks to update or align the **player game manual**.

## Workflow

1. List changed repo-relative SPEC paths.
2. Map to chapters by **exact match** on `## Sources` bullets under `docs/manual/`.
3. Update prose per style guide (player angle, tone, grade-12 reading level, template, draft marking). The reading-level gate is a hard fail.
4. Refresh Sources footers; complete the skill checklist in the Cursor SKILL.md.

## Output

Paths considered, chapters updated or non-update justification, checklist result.
