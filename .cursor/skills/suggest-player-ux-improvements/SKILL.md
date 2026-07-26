---
name: suggest-player-ux-improvements
description: |-
  Scouts one player-facing UX domain (decision support, reports/feedback, playflow shortcuts,
  declutter/progressive disclosure, or self-explanatory clarity), checks whether needed game
  data already exists, and proposes exactly one clearly scoped improvement in chat—player-first,
  engineer-second—ready to decompose into one issue or a small dependency-aware issue set.
  Read-only; does not edit the repo or file GitHub issues.

  Use when the user asks for UI/UX streamlining ideas, player experience improvements, missing
  reports or feedback, playflow shortcuts, decision-support gaps, dense/cluttered panels,
  progressive disclosure, copy/labels that require the manual, or a focused UX opportunity
  from the player’s seat.
---

# Suggest player UX improvements (ColonizeThis)

## Scope (strict)

- **Read-only:** do **not** edit, create, or delete repo files (code, SPEC, manual, tests, config).
- **Chat only:** deliver the recommendation in chat. Do **not** create GitHub issues, PRs, or commits unless the user later switches to another skill (`plan-feature`, `create-github-issue`, `implement-github-issue`).
- **Single domain per run:** one problem domain, clearly defined and scoped.
- **Single improvement per run:** recommend **exactly one** improvement. It must be easy to turn into **one issue** or a **small set of related dependent issues** (typically 1–3; never a grab-bag backlog).
- **Player first, engineer second:** lead with the player problem and desired play experience; only then describe engineering path, data availability, and handoff.

If the user asks to implement, file an issue, or update specs, stop following this skill and use the appropriate workflow skill.

## When this applies

- “Suggest a UI improvement for the player experience”
- “What report / feedback / shortcut would help players most?”
- “Streamline playflow for X” (or: pick a domain and propose one fix)
- “Audit decision support on [domain]”
- “This panel is too dense / declutter X / details only when asked”
- “Can the player understand this without the manual?”
- Optional user hints: domain name, journey (e.g. first 20 turns), or a screen family

## Authority and related skills

| Concern | Source |
|---------|--------|
| Game rules / decisions | `SPEC/game/` (GDD) |
| Architecture / wiring | `SPEC/program/` (esp. app UI wiring, event bus, turn resolution) |
| Player-app screens | `SPEC/ui/`, `SPEC/ui/screen-registry.md`, `app/lib/config/ui_screen_ids.dart` |
| Player-facing how-to | `docs/manual/` (actions appendix + domain chapters) |
| UI structure (after implementation) | `document-app-ui` + `colonizethis-ui-documentation.mdc` |
| Feature issue filing | `plan-feature` or `create-github-issue` (user-initiated next step) |

Read [`.cursor/skills/suggest-player-ux-improvements/references/sources.md`](references/sources.md) for domain → SPEC/manual/screen maps.  
Read [`.cursor/skills/suggest-player-ux-improvements/references/player-lenses.md`](references/player-lenses.md) for decision-support, shortcut, **declutter**, and **clarity** checklists.

## Workflow

```
Task progress:
- [ ] 1. Capture ask / optional clarify
- [ ] 2. Locate and lock one domain (heuristics)
- [ ] 3. Load player model (GDD + manual + actions)
- [ ] 4. Inventory current UI for that domain
- [ ] 5. Walk player journeys (decision, shortcut, declutter, clarity)
- [ ] 6. Data availability analysis
- [ ] 7. De-duplicate against open issues (light)
- [ ] 8. Pick exactly one improvement
- [ ] 9. Deliver chat brief (player first, engineer second)
```

### 1. Capture the ask

From the user message, note:

| Field | Notes |
|--------|--------|
| **Hinted domain or journey** | Explicit (“trade”) or empty |
| **Lens preference** | Decision support / shortcuts / reports / declutter / clarity / any |
| **Constraints** | Mobile, “no new screens”, effort, etc. |
| **Must not** | Rules the user forbids changing |

If the ask is ambiguous **and** heuristics cannot pick a domain with confidence, ask **one short clarification** (options preferred). Do not deep-scan the whole app first.

### 2. Locate and lock one domain (heuristics)

Pick **exactly one** domain from this catalog (or a user-named subset that fits):

| Domain id | Player intent (short) | Typical UI anchors (IDs) |
|-----------|----------------------|---------------------------|
| `turn-shell` | End turn safely; understand what just happened | `GAME10001`, `DLG60001`, `DLG50001`, `OVL70001` |
| `map-province` | Act from the map / tile / province | `MAP10001`, `MAP20001`, game side menu |
| `civilian-work` | Explore, prospect, build, assign work | `UNIT10001`, `UNIT40001`, map shortcuts |
| `military-land` | Armies, move/invade, train land | `UNIT20001`, `UNIT50001`, `DLG20001`, combat surfaces |
| `naval` | Fleets, missions, train ships | `UNIT30001`, `UNIT60001`, `DLG30001`, `DLG40001` |
| `economy-production` | Labour, stockpiles, production | `GAME20001`, `PROD20001` |
| `trade` | World market bids/offers, deal book | `GAME60001` |
| `diplomacy` | Relations, treaties, aid/subsidy | `GAME30001`, `GAME30002`, `DIPL20001`, dialogue overlays |
| `research` | Tech slots and funding | `GAME40001` |
| `victory-progress` | Know how close to win / campaign end | victory overlay, HUD if any, manual ch. 15 |

**Selection heuristics** (apply in order; stop when one domain wins):

1. **User named it** → use that domain (normalize to an id above).
2. **High-frequency + multi-hop path** — decrees that appear often in `docs/manual/16-appendix-actions.md` and require 3+ distinct screens/dialogs before commit.
3. **Decision without data at commit point** — order/confirm UI that GDD says needs facts (cost, gates, force, relations) which the screen spec does not surface.
4. **Post-resolution blindness** — outcomes that resolve in a turn phase but lack a clear player report (turn news / event feed / domain screen).
5. **Incomplete shortcut coverage** — one surface has map/context shortcuts for some related actions but not siblings in the same appendix table.
6. **Idle / readiness friction** — player can waste a turn (empty research, idle civilians, no orders) without shell feedback (`turn-shell` bias).
7. **Dense / overloaded default surface** — a primary panel or dialog dumps many secondary facts, tables, or jargon at once with no progressive disclosure (province overlay tabs, production/trade tables, multi-section unit panels are common suspects).
8. **Manual-dependent labels** — default UI shows facts or terms that a new player cannot interpret without `docs/manual/` (internal names, bare numbers, unexplained phase jargon).
9. **Default if still tied:** `turn-shell` (affects every session).

**Lock the domain in writing** before deep analysis:

```markdown
## Domain lock
- **Domain:** <id> — <one-line player intent>
- **In scope:** <screens/IDs, journeys, data topics>
- **Out of scope:** <adjacent domains this run will not propose>
- **Why this domain (heuristic):** <1–2 sentences>
```

If two domains are equally strong, prefer the one the user can act on this week (smaller surface) **or** ask the user to choose between the two options.

### 3. Load player model (read-only)

Within the locked domain only:

1. **Manual** — matching `docs/manual/` chapter(s) + `16-appendix-actions.md` rows for relevant decrees.
2. **GDD** — `SPEC/game/` files that define the decisions and outcomes (see sources map).
3. **What “effective play” means here** — 2–4 bullets: decisions the player must make well to advance their cause.

Do not invent new game rules. UI may **expose** existing rules and state; flag any desire that would require GDD changes as **SPEC impact: GDD**.

### 4. Inventory current UI

For each in-scope screen/dialog (registry + `SPEC/ui/<screen>.md` + implementation path if needed):

- Entry paths (how the player gets there)
- Decisions committed here
- Data currently shown (**primary vs secondary** — what is always visible vs only in a sub-dialog/tooltip)
- Feedback after action / after next turn
- Known shortcuts (map icons, bus events, filtered panels)
- **Density notes:** sections that feel packed; scroll walls; duplicate facts
- **Clarity notes:** labels/numbers/icons that need the manual or GDD jargon to decode

Stay factual; cite screen IDs and spec paths.

### 5. Walk player journeys

Use the lenses in [`.cursor/skills/suggest-player-ux-improvements/references/player-lenses.md`](references/player-lenses.md):

| Lens | Question |
|------|----------|
| **Decision support** | Before/during/after the action, what must the player see to choose well? |
| **Playflow shortcut** | For a common intent, how many hops today vs a streamlined path? |
| **Declutter / progressive disclosure** | What can leave the default surface and appear only on request (expand, details, breakdown)? |
| **Self-explanatory clarity** | Can every default-visible fact be understood without the manual? What plain-language or structure fix removes that dependency? |

Build a short journey table (3–8 rows is enough). Mark each gap as `decision` | `shortcut` | `report` | `feedback` | `declutter` | `clarity`.

**Manual as answer key, not product solution:** use `docs/manual/` and GDD to know what the player *should* understand; if the UI only makes sense after reading the manual, that is a **clarity** (or declutter+clarity) gap—recommend UI that teaches in place, not “link to manual chapter” as the primary fix.

### 6. Data availability analysis (required)

For the candidate improvement(s) you are considering, determine whether the UI can be fed today:

| Status | Meaning |
|--------|---------|
| **Available in model** | Field/type exists on world/game/player state (name the type/path) |
| **Available via existing UI API** | Already computed for another screen/provider/bus event |
| **Derivable** | Can be computed client-side from existing public model without new simulation rules |
| **Resolver-only today** | Exists during turn resolution / logs / AI but not exposed to player UI |
| **Missing / GDD gap** | Not specified or not stored; improvement needs SPEC before UI |

Search read-only in:

- `packages/colonizethis_models/` (or equivalent model package)
- Domain logic used by the app for that screen
- `SPEC/program/` for turn events, order validation messages, news/event pipelines
- Existing providers / view-models under `app/lib/features/game/`

Record a compact **data table** in the final brief. Prefer improvements where data is **Available** or **Derivable**. If the best player need is **Missing**, either:

- Narrow to an **expose-existing-data** slice, or
- Make the single recommendation a **SPEC+UI** paired issue set (still one improvement theme).

### 7. Light de-duplication

Before locking the recommendation:

- Skim open issues when `gh` works: `gh issue list --state open --limit 100` and/or search by domain keywords / screen IDs.
- If the same improvement is already open, **do not re-propose it as new work** — cite the issue and either refine the angle (strictly different) or pick the next-best gap in the **same domain**.

If `gh` is unavailable, note that and proceed with SPEC/code evidence only.

### 8. Pick exactly one improvement

Selection rules:

1. **Highest player impact** inside the locked domain (blocks good decisions, high-frequency friction, **severe density**, or **manual-dependent misunderstanding**).
2. **Clear direction** — a teammate could file issues without re-doing discovery.
3. **Decomposable** — fits one of:
   - **Single issue** — one PR-sized change, or
   - **Small issue set** — 2–3 issues with explicit dependencies (e.g. `I1 data exposure → I2 UI → I3 manual/docs` only if needed).
4. **Feasible** — prefer Available/Derivable data; call out GDD work only when unavoidable.
5. **Reuse first** — extend turn news, event feed, province overlay, existing panels, existing breakdown dialogs; do not invent a parallel shell.
6. **Streamline by default** — if the win is declutter, the proposal must state what stays **always visible**, what moves **on request**, and how the player requests details (control name / pattern).
7. **Self-explanatory by default** — if the win is clarity, every remaining default-visible element must pass the no-manual check in player-lenses; secondary jargon may live in details only if the primary path stays plain.

**Reject** (for this run’s recommendation):

- Pure visual polish / pixel-art / theming (→ design rules, not this skill)
- ctdev/debug-only surfaces
- Multi-domain epics (“overhaul economy + war + trade”)
- Unbounded “improve UX” laundry lists
- “Add more numbers for power users” with no hierarchy (worsens density)
- “Player should read the manual” as the primary remedy for unclear UI

List **at most two** runner-up titles in one line each (no full write-ups) so the user can request another run later.

### 9. Deliver chat brief (mandatory template)

Use this structure. **Player sections first.** Do not file issues.

```markdown
## Domain lock
- **Domain:** …
- **In scope:** …
- **Out of scope:** …
- **Why this domain:** …

## Player recommendation (the one improvement)

### Title
<imperative, ≤~80 chars — issue-title ready>

### Player problem
<What the player cannot see, decide, or do efficiently today — 2–4 sentences.>

### Player outcome
<What effective play looks like after this lands — concrete, not “more intuitive”.>

### Current path
- Intent: …
- Steps today: <screen IDs / controls, hop count>
- What is missing or painful: …

### Proposed experience
<Player-visible behavior only. Controls, feedback, reports, shortcuts, hierarchy. No implementation dump.>
- **Default (always visible):** …
- **On request (details):** … how the player opens them …
- **Clarity:** how a new player understands each default fact without the manual …

### Why this advances their cause
<How better decisions, fewer hops, less overload, or clearer meaning help expansion, economy, war, diplomacy, research, or victory.>

### Non-goals
- …

## Evidence
- Manual: …
- GDD: …
- UI specs / IDs: …
- Code (if needed): …

## Data availability
| Need | Status | Where / notes |
|------|--------|----------------|
| … | Available / Derivable / Resolver-only / Missing | … |

## Engineer direction (handoff)

### Summary for implementers
<One short paragraph.>

### Suggested issue decomposition
- **Issue A** — … *(depends on: —)*  
  - Outline: …
  - Draft ACs: Given … When … Then …
- **Issue B** — … *(depends on: A)*  <!-- omit if single issue -->
  - …

### SPEC impact
- none | UI only | program | GDD | manual — list likely paths

### Likely touch points
- Screens / widgets: …
- Wiring (bus/providers): …
- Models / logic (read-only findings): …
- Follow-up skills: `plan-feature` or `create-github-issue` → `implement-github-issue` → `document-app-ui` if surfaces change → `update-game-manual` if player-facing flow changes

### Risks / edge cases
- …

## Runner-ups (not recommended this run)
- … — <one line why deferred>
- …

## Next step for the user
Chat-only complete. To proceed: ask to **plan-feature** / **file an issue** for “<Title>”, or run this skill again on another domain.
```

## Quality bar

- **One domain, one improvement** — no multi-theme dumps.
- **Direction is issue-ready** — titles, ACs, dependencies, SPEC impact present.
- **Facts vs inference** — label hypotheses; cite paths.
- **Player language first** — avoid leading with refactors, widgets, or CI.
- **Data honesty** — never assume a field exists; mark status.
- **Density honesty** — if recommending declutter, name which facts leave the default surface and how details are requested.
- **Clarity honesty** — default-visible copy must be plain enough that a new player need not open the manual; use the manual only as analyst ground truth.
- **Mobile-aware** — if the change hits narrow viewports, note `SPEC/ui/mobile-adaptation.md` as a constraint (do not redesign chrome style here).
- **Architecture** — cross-panel via AppEventBus patterns; Flame vs Flutter boundaries respected in the engineer section.

## Anti-patterns

- Filing GitHub issues or editing SPEC in this skill
- Proposing new combat/economy rules disguised as “UI”
- Recommending five small unrelated tweaks “for completeness”
- Skipping data availability
- Scoping “the whole game shell + all panels” as one domain without a locked slice
- Style-only suggestions (fonts, colors, pixel assets)
- Stuffing more stats onto an already dense default panel without progressive disclosure
- Treating the game manual as the in-product explanation layer

## Related

- Plan and file: [.cursor/skills/plan-feature/SKILL.md](../plan-feature/SKILL.md)
- Bug/gap issue: [.cursor/skills/create-github-issue/SKILL.md](../create-github-issue/SKILL.md)
- UI docs when building: [.cursor/skills/document-app-ui/SKILL.md](../document-app-ui/SKILL.md)
- Manual after player-facing change: [.cursor/skills/update-game-manual/SKILL.md](../update-game-manual/SKILL.md)
- Code-focused scouting (not player UX): [.cursor/skills/refactoring-opportunity-github-issue/SKILL.md](../refactoring-opportunity-github-issue/SKILL.md)
