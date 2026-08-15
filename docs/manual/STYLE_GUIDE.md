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
| Body | Purpose, How it is done, Consequences, Sources | Clear modern English; experienced TBS player; vizier advising a young monarch (patient, empathetic, encouraging) |
| Callout | Counsel exhortations, warnings, hard instructions | Optional archaic 16th–17th century high-society flourishes (“Hark, my liege…”) |
| Forbidden | Body how-to, Purpose, orientation, Consequences, chapter-local AC bullets | Continuous archaic pastiche; code identifiers as player vocabulary; contradicting SPEC; UI-engineering, engine jargon, and genre jargon listed under **Banned classes** |

### Exemplar (tone)

> Your provinces are the breath of the realm. Before you march, ensure the roads and ports that bind them remain yours — else an army stranded inland is a banner without a nation.
>
> **Counsel.** Hark, my liege: the Home Army guards the capital and will not march. Raise field armies if you mean to project force.

## Reading-level gate

Write **Purpose**, **How it is done**, **The other courts**, **Consequences**, and chapter-local AC bullets in everyday English a **12th-grade reader** can follow. Define **game nouns on first use** (then use the noun freely). Counsel callouts may still use the existing archaic register.

Examples of first-use teaching:

- **Great Power** — one of the playable nations.
- **decree** — an action you choose on your turn.
- **Old World** / **New World** — the two maps.

Do not assume the reader already knows those terms.

## Banned classes in player prose

These classes are forbidden in Purpose, How it is done, orientation, Consequences, and chapter-local AC bullets. They are **not** banned in `## Sources` path bullets (those are machine-parseable paths, not player vocabulary).

| Class | Do not write | Write instead |
|-------|----------------|---------------|
| **Code identifiers as player vocabulary** | `ownerId`, `greatPowerPowerScore`, inline `SPEC/ai/…` paths in body prose | What the player owns, sees, or is told |
| **UI-engineering** | `host`, `chrome`, generic `overlays`, `widget` as a screen name, `wait-gate`, `left-rail`, `glyph`, `desk`, engineer catalog pointers | The printed screen title, the control the player taps, “please wait” if a wait screen is in scope |
| **Engine jargon** | “the engine resolves…”, “Orders phase” / “phases” when cited UI SPECs do not print that phrase | “After you confirm **Next turn**, the game carries out…” |
| **Genre jargon not printed on the cited screens** | `parity`, `HUD`, `power score` (unless the screen prints it) | Everyday wording: armies keep pace; the top bar / **Next turn** shows year and turn |

## Rewrite examples

Normative mappings (chapter 1 is the worked example). Use the **player wording** in body prose.

| Banned or unclear | Player wording |
|-------------------|----------------|
| Great Power / Old World / New World / decrees with no definition | Teach on first use: a Great Power is a playable nation; a decree is an action you choose on your turn; Old World and New World are the two maps |
| “military parity” | “Minor Nations keep their armies as strong as the strongest Great Power, so they are hard to conquer casually.” |
| “The HUD and turn summary show year…” | “The top bar and **Next turn** show the year and the turn number.” |
| “your `ownerId` on those provinces”; “after all phases” | “provinces you own”; “checked at the end of the turn, after the game has carried out everything for that turn.” |
| “declared winner by Great Power power score” | Summaries may name the strongest Great Power; on a tie (or no scorers), the declared winner is no-one. Do not imply the in-game UI always names a winner. |
| “while the phase is **Orders**”; “A new Orders phase begins.” | “On the map and empire screens, choose your actions. When you are done, tap **Next turn**.” / “Then you can choose actions again (or the campaign ends).” |
| “The engine resolves movement, combat, …” | “After you confirm **Next turn**, the game carries out movement, fighting, and the rest. You see the results when that finishes — not when you tap.” |
| “host for the map, chrome, next-turn flow, and overlays” | “This is the main game screen: the map, **Next turn**, and the menus that open from here.” |
| “map widget”; “extraction-disc legend”; “teaching chip” | Registry title **Empire overview / map area**. Describe gold/brown discs and “1 of 1” / “1 of 2” marks as what the player sees (detail in Chapter 3). |
| “Icons are defined in the toolbar-icons catalog”; “Market + Deal Book desk”; “market clearance still resolves in turn phases.” | Drop the catalog sentence. Name Trade as the Trade screen (Chapter 8). Do not describe market clearance internals in the primer. |
| “map chrome”; “cartographic chrome”; “stacked-layers” | “The buttons on the map change what you see (resources, roads, borders). They are map tools, not separate screens.” Use the printed **Map display options** labels. |
| “non-interactive progress wait-gate” | Omit, or “You may see a short ‘please wait’ screen before the map appears (Chapter 2).” |
| “left-rail empire buttons”; “map glyph” | “Learn the icons on the left of the map before you hunt every map symbol.” |
| “Parity means their regiments keep pace…” | “Their armies keep pace with the best Great Power weapons.” |
| “capital connectivity”; “growth-stage goals”; “Blessed AI profiles”; “personality parameters” | Rivals choose the same kinds of actions; a chosen **leader** changes how bold or cautious they are, not how you win. Do not teach Blessed, AI Profile, or growth-stage in the primer. |
| “without the empire rail” | “without the icons on the left of the map.” |
| “left-rail” / “wait-gate” in chapter ACs | “left-side icons”; “initializing wait screen.” |

## Player-angle framing (required)

Every update must answer, explicitly or by structure:

1. **Why** the player uses this mechanic (goal, victory pressure, enjoyment).
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
- **Sources bullets are paths, not prose:** backtick SPEC paths stay machine-parseable. Words such as `widget` inside a path (for example `SPEC/ui/map-widget.md`) are **not** banned player vocabulary.

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
