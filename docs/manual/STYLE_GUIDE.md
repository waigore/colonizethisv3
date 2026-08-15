# Player game manual — style guide and chapter template

Normative conventions for authors and for the `update-game-manual` skill. Behavior authority remains `SPEC/`; this guide governs **how** the player manual is written and maintained.

## Purpose of the manual

- Immerse the player in the game’s fiction and systems.
- Guide a new player toward victory and enjoyment.
- Catalog every player-available action with UI entry points, validation, and when results appear.

Do **not** document unimplemented behavior as operable. Do **not** write min-max exploit guides.

## Tone contract

| Register | Where | Voice |
|----------|-------|-------|
| Body | Purpose, How it is done, Consequences, Sources | Everyday modern English a 12th-grade reader can follow; vizier advising a young monarch (patient, empathetic, encouraging) |
| Callout | Counsel exhortations, warnings, hard instructions | Optional archaic 16th–17th century high-society flourishes (“Hark, my liege…”) — meaning must still pass the reading-level test |
| Forbidden | Entire chapter | UI-engineering words; genre or engine jargon not printed on screen; continuous archaic pastiche in how-to steps; code identifiers as player vocabulary; contradicting SPEC |

### Exemplar (tone)

> Your provinces are the breath of the realm. Before you march, make sure the roads and ports that connect them still belong to you. An army cut off inland is a banner without a nation.
>
> **Counsel.** Hark, my liege: the Home Army guards the capital and will not march. Raise field armies if you mean to send troops away from home.

## Reading level and banned language (strict)

The handbook is for a **broad player audience**, not for designers or genre veterans.

**Target reader:** a 12th-grade reader (about 17–18) who has never played a turn-based strategy game and does not know UI, design, or simulation-engine terms.

**Pass test (required):** read each sentence as that reader. If they would need a designer or genre glossary to follow it, the sentence fails. Game-world nouns (province, Great Power, decree) pass only after a plain-English definition on first use in that chapter.

This contract is **not advisory**. A chapter update that leaves a failing sentence is incomplete.

### Required

- Everyday words. Short, direct sentences. One action per how-to step.
- Name things as the player sees them: button label, tab name, screen title, map tool.
- Teach the game’s own nouns in plain English the first time they appear in the chapter.
- Prefer common words: map, button, menu, screen, turn, Next turn, army, road, port.

### Banned classes (not a closed list)

Treat these as **classes**. The examples show the class; any word in the same class is banned even if it is not listed.

| Class | What it is | Examples (not exhaustive) | Use instead |
|-------|------------|---------------------------|-------------|
| UI-engineering / design-system | Layout or interaction terms a player would not say while pointing at the screen | chrome, affordance, left-rail, rail, glyph, locator, widget, viewport, host, wait-gate, cartographic, extraction-disc, teaching chip, desk (as “Deal Book desk”) | The on-screen name, or “button,” “menu,” “map tools,” “left-side icons” |
| Genre / engine jargon | Specialist strategy-game or simulation words the player cannot read in the game | HUD, TBS, 4X, resolver, tick, ownerId, capital connectivity, parity, growth-stage, personality parameters, power score (unless the screen prints that phrase), “the engine resolves,” “Orders phase” when the UI only says Orders | What happens in play, in everyday words |
| Code identifiers | Type names, file paths, raw screen IDs used as the name of a thing | `WorkOrder`, `ArmyMoveOrder`, `SPEC/…`, `app/lib` | Player decree language; screen titles. Authoring chapters may still *cite* screen IDs per **Screen-ID citation**; never speak them as vocabulary |

**“Overlay”** is allowed only when it is the visible title of that surface. Do not use it as a generic word for “panel that opens.”

If the game prints a word, use that printed word. Do not invent a designer synonym.

### Rewrite examples

| Fails | Passes |
|-------|--------|
| Map control affordances use the same icon set; treat them as map chrome. | The buttons on the map change what you see (resources, roads, borders). They are map tools, not separate screens. |
| The engine resolves movement, combat, and end-of-turn checks. | After you confirm **Next turn**, the game carries out movement, fighting, and the rest. You see the results when that finishes — not when you tap. |
| Minor Nations keep military parity with the strongest Great Power. | Minor Nations keep their armies as strong as the strongest Great Power, so they are hard to conquer casually. |
| Secure capital connectivity, then assign civilian work. | Make sure your land still links to the capital by road or port, then give your workers something to do. |

### Hard fail

Do not treat a chapter as updated, and do not run `export-player-manual`, while any added or edited sentence fails this section. When you edit a section, the **whole section** must pass (no mix of jargon and plain speech).

## Player-angle framing (required)

Every update must answer, explicitly or by structure:

1. **Why** the player uses this part of the game (goal, victory pressure, enjoyment).
2. **How** it changes their chances of winning or surviving.
3. **What** they do in the UI (screen ID, control, result) — not a restatement of an internal engine note.

## Screen-ID citation

- Cite surfaces by stable 8-character ID from `SPEC/ui/screen-registry.md` (e.g. `` `GAME20001` ``).
- Prefer “`` `GAME20001` `` Game screen” over fragile display-title-only references.
- Never invent screen IDs.

## Draft surface marking

Aligned with `SPEC/ui/screen-registry.md` (`draft` vs `active`):

- **Omit** a draft surface, **or** mention it only with the marker.
- Inline form (required on every draft citation): `**[DRAFT]** \`SCREENID\`` immediately before the display name (placeholder shape: `**[DRAFT]** \`XXXXXXXX\` Display name`).
- Draft surfaces must **not** appear in **How it is done** as operable steps; if mentioned, use Counsel or a short “not yet available” note, still with the marker.
- When the player manual cites only `active` registry rows, keep this convention as process text for future drafts — no live exemplar screen is required.

## Callout conventions

Use a short bold lead-in, then the counsel text:

```markdown
**Counsel.** Hark, my liege: …

**Warning.** …

**Tip.** …
```

Keep archaic register inside these callouts when used; keep surrounding paragraphs modern.

## Chapter template (required sections)

Every chapter file under `docs/manual/` (except this style guide and `index.md`) must contain these sections in order:

1. `#` title (chapter name)
2. `## Purpose`
3. `## How it is done`
4. `## Counsel`
5. `## The other courts`
6. `## Consequences`
7. `## Acceptance criteria for this chapter`
8. `## Sources` (last `##` section; machine-parseable — see below)

### Section intents

| Section | Content |
|---------|---------|
| Purpose | High-level why, framed as the monarch’s interest |
| How it is done | Step-by-step flows: screen ID, control, dialog, result; every in-scope action |
| Counsel | Warnings, tips, easily missed implications (callouts; archaic OK here) |
| The other courts | How AI Great Powers may respond (`SPEC/ai/*`) |
| Consequences | How game state/world is likely to evolve |
| Acceptance criteria for this chapter | Checklist for writers/reviewers (map to the ToC “Must document” row) |
| Sources | Exact SPEC path bullets (below) |

### Skeleton

```markdown
# Chapter title

## Purpose

…

## How it is done

…

## Counsel

…

## The other courts

…

## Consequences

…

## Acceptance criteria for this chapter

- [ ] …

## Sources

- `SPEC/game/example.md`
```

## Sources footer format (machine-parseable)

Every chapter file ends with exactly this structure as its **last** `##` section:

```markdown
## Sources

- `SPEC/game/example.md`
- `SPEC/ui/example-screen.md`
- `SPEC/program/orders.md`
- `SPEC/ai/example.md`
```

Rules:

- Heading text is exactly `## Sources` (no variants).
- Each bullet is a single repo-relative path in backticks; **no** trailing prose on the same bullet.
- Paths use forward slashes and match the repo tree.
- The updater skill maps changed SPEC paths to chapters by **exact string match** against these bullets.

## Required-review `SPEC/program/` allowlist

**Required** manual review when a PR modifies any of:

| Path | Why player-facing |
|------|-------------------|
| `SPEC/program/orders.md` | Order types, validation, rejection vocabulary |
| `SPEC/program/turn-resolution-phases.md` | Player-facing “when you’ll see the result” |
| `SPEC/program/turn-resolution-phase-details.md` | Phase detail for appendix / resolution timing |
| `SPEC/program/order-engine.md` | Rejection/validation detail cited by the appendix |

Plus **all** of `SPEC/game/**` and `SPEC/ui/**`.

**Advisory only** (no mandatory path trigger): every other `SPEC/program/**` path.

**Player UX / gameplay impact** (authoritative): update the manual whenever work changes what the player can do, see, or be told — even when no required-review path changed. Policy: `.cursor/rules/colonizethis-game-manual.mdc`. Planning skills (`create-github-issue`, `plan-feature`) must capture manual deliverables in issues when applicable.

PRs that hit a required-review path or player UX/gameplay impact must update affected chapters (via Sources footers) **or** explicitly justify why no manual change is needed.

## Honesty and non-goals

- Document only implemented, specced behavior.
- No in-app viewer in this manual’s issue scope.
- No strategy-guide solved play.
- On conflict with SPEC, fix the manual.
