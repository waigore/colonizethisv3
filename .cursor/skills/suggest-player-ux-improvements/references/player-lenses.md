# Player lenses (decision support, shortcuts, declutter, clarity)

Companion checklist for `suggest-player-ux-improvements`. Use inside the **locked domain** only.

Apply **all** lenses when scoring gaps. A strong recommendation may be primarily decision support, shortcut, **declutter**, or **clarity**—or a combination—as long as it remains **one** improvement.

## Decision support

Ask what the player needs at each stage of a decision.

### Before (orientation)

- What is my goal this turn in this domain?
- What resources/constraints bind me (treasury, stockpile, tech, relations, fog, war)?
- Where should I look first (map, panel, report)?

### At the point of commit

- What does this control cost (materials, treasury, labour, opportunity)?
- Will the order be **rejected**? Primary refusal reason visible?
- What is the expected result phase (movement, build/work, diplomacy, market)?
- Comparative info when choosing among targets (tile A vs B, faction A vs B)?
- Irreversible or war-declaring consequences called out?

### After resolution

- What changed that matters for the next decision?
- Can I find the outcome without rereading the whole map?
- Are “nothing happened” states explicit (empty turn news is OK if stated)?

### Reports vs glanceable HUD

| Kind | Use when |
|------|----------|
| **Glanceable** | Continuous state needed every turn (treasury, war, research slots, unread critical events) |
| **Report / dialog** | Multi-line history, breakdowns, last-turn market fills, battle summaries |
| **Inline on control** | Facts required to enable/disable or choose quantity/target |
| **On request (details)** | Secondary breakdowns, formulas, full ledgers—**not** default chrome |

Prefer putting **commit-critical** facts on the control or one tap away—not three screens deep. Prefer **not** putting encyclopedic detail on the default surface.

## Playflow shortcuts

### Measure friction

For a single player intent (e.g. “prospect this tile”, “invade adjacent province”):

1. Count **distinct surfaces** (screen/dialog/overlay IDs) from intent → order committed.
2. Count **redundant re-selection** (re-picking unit, tile, or faction already known from context).
3. Note **dead ends** (disabled with no reason; back-navigation loss of context).

High friction ≈ high frequency × hop count × context loss.

### Shortcut patterns (prefer existing)

- **Map/context actions** on province/tile selection (extend `MAP20001`-style shortcuts).
- **Filtered panel open** via bus event with preselected unit/tile (already used for civilian work).
- **Turn-shell checklist** before Next Turn (idle units, empty research, pending threats)—informational, not auto-orders.
- **Deep link from report → domain screen** (turn news line opens the relevant panel with context).
- **Defaults** that match last legal choice when safe; never silent rule changes.

### Do not shortcut

- Rare edge cases before common paths
- Actions that need multi-step confirmation for irreversible diplomacy/war without making confirmation clearer
- Auto-issuing orders the player did not affirm

## Declutter and progressive disclosure

Dense, info-packed panels are a first-class friction source. Prefer **streamlined default surfaces** and **details only when the player asks**.

### Density audit (per in-scope surface)

For each panel/dialog/overlay section:

1. **List every player-visible datum** (labels, numbers, chips, tooltips-only counts as on-request if discoverable).
2. Mark each as:
   - **Primary (always show)** — needed for the main decision or action on this surface this turn
   - **Secondary (on request)** — useful drill-down; expand/tooltip/detail dialog/“More”/breakdown
   - **Noise / redundant** — duplicate of another line, internal id, debug-ish, or only meaningful with a manual chapter
3. Count **simultaneous primary rows** above the fold (or first scroll page). High density ≈ many primaries + jargon + no hierarchy.

### Progressive disclosure patterns (prefer existing chrome)

- Summary line → **breakdown dialog** (e.g. commodity breakdown style)
- Section collapsed / tabbed so only the active concern is open
- **More / Details** control for formulas, full ledgers, last-turn history
- Hover/long-press **tooltip** for short definitions (not the only place for commit-critical facts)
- Row → detail for one entity instead of dumping every entity’s full stats in a list

### Declutter rules of thumb

- **One primary job per surface** (or per tab/section). Secondary jobs move behind request.
- **Numbers need units and context** (“£2,400 treasury”, not bare `2400` next to three other bare numbers).
- **Do not show raw internal keys** (prefixed ids, enum names) when a display name exists.
- **Deduplicate:** if the same fact appears in header and body, keep one.
- **Narrow viewports amplify density** — a “fine on desktop” wall of stats is a defect on 320–360 dp (`mobile-adaptation.md`).
- Declutter must **not** hide commit-critical cost/refusal without an obvious path to reveal it.

### Gap type

Mark journey rows `declutter` when the problem is too much simultaneous info, wrong hierarchy, or details forced on by default.

## Self-explanatory clarity (no manual required)

Every string, icon, and number the player is expected to act on should be **understandable in-context** without opening `docs/manual/`.

The manual remains the deep reference for implementers and for optional lore/strategy; **UI must not depend on it** for basic comprehension.

### Clarity audit (per visible element)

For each primary (and any secondary the proposal keeps visible by default), ask:

| Check | Fail when |
|-------|-----------|
| **Plain meaning** | Label is jargon, abbreviation, or phase name only a SPEC reader knows |
| **Why it matters** | Number has no unit, comparison, or “so what” (e.g. bare progress without cost/cap) |
| **What can I do** | Status shown with no path or affordance to change it when the player can |
| **What happens if I act** | Control commits without saying cost, duration, or irreversible effect |
| **Icon alone** | Glyph has no label/tooltip and meaning is not universal in-game |

Use the **manual chapter as a secret answer key** during analysis: if understanding a row requires a paragraph from the manual, the UI has a **clarity** gap—fix the UI (inline plain language, short helper, progressive detail), do **not** recommend “read the manual” as the product solution.

### Clarity fix patterns

- Expand jargon once in plain language next to the term (or first use in the panel)
- Prefer player words from manual **Purpose/Counsel** tone only when they stay short and concrete
- Show **effect in player terms** (“completes next turn”, “declares war”, “costs 2 lumber”)
- Disabled controls: **primary refusal reason** in plain language (not only grayed-out)
- Empty states that say what is missing and where to go next

### Gap type

Mark journey rows `clarity` when the data is present but opaque, expert-only, or manual-dependent.

### Anti-patterns for clarity

- Dumping full GDD tables into the panel “for completeness”
- Tooltips that only restate the same jargon
- Hiding all meaning behind icons with no text path
- Replacing numbers with prose walls (still a density problem)

## Journey table (suggested columns)

| Intent | Player thought | Current path (IDs) | Hops | Gap type | Data needed |
|--------|----------------|--------------------|------|----------|-------------|
| … | … | … | n | decision / shortcut / report / feedback / declutter / clarity | … |

Aim for 3–8 rows; pick the single best gap for the run’s recommendation.

## Scoring (for choosing among gaps)

Prefer higher score; break ties toward **Available/Derivable** data and **smaller issue decomposition**.

| Factor | Higher when |
|--------|-------------|
| Decision blocking | Player often chooses poorly or blindly without the info |
| Frequency | Intent happens many times per session / campaign |
| Hop reduction | Removes ≥1 full screen or repeated context pick |
| Density / overload | Default surface forces many non-primary facts at once; details not on-request |
| Manual dependence | Player cannot interpret a shown fact without external docs |
| Reuse | Extends existing surface instead of new route host |
| Data readiness | Available or Derivable without GDD invention |
