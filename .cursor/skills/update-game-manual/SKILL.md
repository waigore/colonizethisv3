---
name: update-game-manual
description: Updates the ColonizeThis player game manual under docs/manual/ when player UX or gameplay changes—maps affected chapters via Sources footers, preserves vizier tone and grade-12 reading level (UI-engineering and genre jargon banned), player-angle framing, chapter template, and draft-marking. Use when SPEC/game, SPEC/ui, allowlisted SPEC/program files, orders, screens, or manual chapters change; when create-github-issue/plan-feature issues include manual ACs; or when the user asks to refresh the game manual.
---

# Update the player game manual (ColonizeThis)

## Authority

- Style guide + template: [`docs/manual/STYLE_GUIDE.md`](../../docs/manual/STYLE_GUIDE.md)
- ToC: [`docs/manual/index.md`](../../docs/manual/index.md)
- Cursor rule: [`.cursor/rules/colonizethis-game-manual.mdc`](../../.cursor/rules/colonizethis-game-manual.mdc)
- Behavior SPECs remain source of truth; never invent gameplay that contradicts GDD/TDD/UI/AI specs.

## When to use

- A PR or task changes `SPEC/game/**`, `SPEC/ui/**`, or allowlisted `SPEC/program/` files (`orders.md`, `turn-resolution-phases.md`, `turn-resolution-phase-details.md`, `order-engine.md`).
- New/changed player-facing orders, validation, screens, map tools, or visible outcomes.
- An issue filed via **`create-github-issue`** or **`plan-feature`** includes a **Manual** subtask or AC (policy: `.cursor/rules/colonizethis-game-manual.mdc`).
- User asks to update, refresh, or align the **game manual** (not the codebase course).

Skip pure internal `SPEC/program/**` paths outside the allowlist unless the author judges the change affects what the player can do, see, or be told (advisory).

## Workflow

```
Task progress:
- [ ] 1. List changed SPEC paths (repo-relative)
- [ ] 2. Map paths → chapters via exact match on ## Sources bullets
- [ ] 3. Read STYLE_GUIDE (tone + reading-level) + current chapter prose + authoritative SPEC
- [ ] 4. Update chapters (player angle, template, tone)
- [ ] 5. Reading-level gate — hard fail until every touched section passes
- [ ] 6. Refresh ## Sources bullets; verify draft marking
- [ ] 7. Run skill checklist; note any justify-non-update decisions
```

### 1. Identify affected SPEC paths

Collect repo-relative paths touched (e.g. `SPEC/game/victory.md`). Include UI screen specs when screen IDs or flows change.

### 2. Map to chapters

For each path, scan `docs/manual/*.md` chapter files (not `index.md` / `STYLE_GUIDE.md`) for a `## Sources` bullet whose backtick content **exactly equals** that path. Update every matching chapter.

If no chapter yet cites the path but the ToC coverage map says it belongs in a chapter, add the prose and append the path to that chapter’s Sources when the chapter exists; if the chapter is still pending, note the gap for the next chapter batch.

### 3. Update prose

For each affected chapter:

1. Prefer the **player’s** goal and enjoyment over engine internals.
2. Keep all seven required sections; put operable UI steps only under **How it is done**, citing screen IDs.
3. Confine archaic register to **Counsel** callouts; those sentences must still pass the reading-level test.
4. Ground **The other courts** in `SPEC/ai/*` when AI reaction is in scope — describe what rivals **do**, not planner internals.
5. Quote only player-critical numbers; flag ruleset-configurable values rather than duplicating drifting tables.
6. Draft registry rows: omit or use `**[DRAFT]** \`SCREENID\``; never operable how-to steps.
7. Write every sentence to the STYLE_GUIDE **Reading level and banned language** contract. Name on-screen words. Define game nouns on first use. Do not assume the reader has played a strategy game.

### 4. Reading-level gate (hard fail)

Not advisory. Re-read STYLE_GUIDE **Reading level and banned language**, then:

1. Apply the 12th-grade pass test to every sentence you added or changed.
2. Scan each **touched section** against the banned classes (UI-engineering, genre/engine jargon, code identifiers). The examples in the style guide are the class, not a closed list.
3. If any sentence fails, rewrite it. Leave no mixed section (jargon next to plain speech).
4. Do **not** run `export-player-manual`, and do **not** report the chapter as updated, until every touched section passes.

Existing chapters you did not edit may still contain old jargon. Do not expand scope to a full-handbook rewrite unless the user asked for one.

### 5. Sources footer

Ensure `## Sources` is the last `##` section; one backtick-wrapped path per bullet; no trailing prose.

### 6. Checklist (before finishing)

- [ ] **HARD FAIL:** Reading-level contract held (STYLE_GUIDE). A 12th-grade reader who has never played this genre can follow every added or edited sentence. No UI-engineering or genre/engine jargon in touched sections.
- [ ] Tone contract respected (modern body; archaic only in callouts; callouts still pass the reading-level test).
- [ ] Player-angle framing present (why / winning-enjoyment / UI how).
- [ ] Chapter template sections intact.
- [ ] Chapter-local ACs still accurate for the ToC “Must document” row.
- [ ] `## Sources` machine-parseable; paths match repo tree.
- [ ] Draft citations marked or omitted.
- [ ] No contradiction with cited SPECs; no exploit guide content.
- [ ] If no chapter change was needed for a required-review path, PR/issue note justifies why.

## Output

Report: SPEC paths considered, chapters updated (or justify non-update), reading-level gate result, any pending chapter gaps, checklist result.

## After authoring updates

When chapter files under `docs/manual/[0-9][0-9]-*.md` change **and** the reading-level gate passed, run **`export-player-manual`** so playtest agents read a fresh player export at `docs/manual/player-export/`. See `SPEC/program/player-manual-export.md`. Do not export failing prose.

## Related

- `export-player-manual` — regenerate self-contained player handbook (run after this skill)
- `document-app-ui` — screen specs/IDs (manual cites IDs; does not assign them)
- `implement-github-issue` — when manual work is part of a tracked issue
