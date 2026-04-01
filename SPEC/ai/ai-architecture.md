# AI Architecture (Phase 6)

**SPEC/ai** — Hybrid AI stack for MVP. Source: GDD 10b.

---

## Overview
Characterful, deterministic AI using only observable game state. Difficulty affects starting resources and ruleset modifiers, not AI logic.

## Rules

### Design Principles
- Each leader feels distinct via personality (see [ai-personalities.md](ai-personalities.md)).
- Deterministic: same game state and seeds → same decisions.
- PlayerView-only: AI never reads hidden tiles or enemy data.
- Difficulty via params only: same algorithm at all difficulty levels.

### Hybrid Stack

| Layer | System | Purpose |
|-------|--------|---------|
| Goal management | Behavior trees | Long-term strategy (expand, defend, trade, conquer, tech, diplomacy) |
| Strategic | Utility AI | Domain decisions: economy, military, diplomacy, research |
| Tactical | Shallow search / heuristics | Quick Battle actions; local move/attack |

Behavior trees pick top-level goals; utility AI scores and selects concrete objectives; tactical layer produces combat and movement orders.

**Goal selection implementation:** Goal selection may be implemented as **weighted choice** over strategic goals (expand, defend, trade, conquer, tech, diplomacy) using personality weights, agenda modifiers, and situational snapshot. This satisfies the "behavior tree" requirement when interpreted as hierarchical goal selection. Strict behavior-tree node structure (sequences, selectors) is optional and may be used where designer-editable trees are desired. **Weighted choice is the current implemented approach**; strict behavior-tree structure is deferred to future phases when designer-editable AI trees are required (e.g. for mod support or external AI editors).

### Turn Pipeline (per AI Great Power)
1. **Perception** — Derive observable snapshot: threats, opportunities, economy, relations. All from PlayerView; no hidden data.
2. **Goal selection** — Choose strategy (e.g. weighted choice over goals) using personality weights and hidden agenda modifiers.
3. **Domain planning** — Economy, military, diplomacy, research planners score candidates via personality and agenda weights; each emits candidate orders. The **economy planner** also produces **production assignments** (worker allocation to recipes) and a **cargo preference** for naval/build; see [economy-planner.md](economy-planner.md).
4. **Execution** — Combine, cap, and validate orders; emit dialogue/mood events. Strategic AI may emit **optional** agenda-flavoured dialogue and a matching base PortraitMoodEvent for each AI leader on a deterministic cadence derived from the dialogue seed (see [dialogue-and-mood.md](dialogue-and-mood.md) § When to emit for `kDialogueTurnsBetweenComments` and cadence rules).
5. **Tactical** — Quick Battle: CP-based actions per lane, deterministic given state and seed.

### Tactical Behavior Rules
- Prefer occupying good terrain (hill, town, woods) with high-value units.
- Avoid exposing fragile units in swamp unless numerically overwhelming.
- Use Volley Fire / Defend when outmatched or holding key lanes (especially center).
- Use Maneuver / Fall Back to rotate damaged units or shift strength to threatened flanks.
- Use Assault / Charge when enemy lane is disrupted and terrain is favorable.

### Strategic Behavior Preferences
AI uses the order suggestion API and applies:
- **Movement:** Prefer contested or enemy territory (at war); avoid factions at peace.
  - **Filter:** All AI paths (simple heuristics and full-AI domain planner) must drop move orders whose destination is owned by a faction at peace with the mover (or by a Minor with no war). No move into at-peace or minor-without-war territory.
  - **Prefer enemy:** When choosing among valid move candidates, score moves into enemy (at-war) territory higher than moves into unowned or own territory; weighted selection then prefers enemy/contested. Default bonus +20 to score when destination owner is at war with the mover.
- **Build/work:** Prefer cheaper orders improving owned, visible provinces.
- **Research:** Prefer lower-era, cheaper techs unlocking core capabilities.
- **Diplomacy (Full AI):**
  - Compute a per-pair `warDesireScore` (0..100) for GP↔target where target can be GP, Minor, or Tribe.
  - Use the same composite power basis as diplomacy power score (military + province + naval) for strength ratio.
  - Compute improve-relations desire as `100 - warDesireScore`.
  - Keep relation gate for war declarations.
  - Apply per GP-target pair cooldowns for war-declare and improve-relations retries.
  - While at war, recompute war desire each turn to decide continue-war vs offer-peace bias and adjust desired territory objective.
- **Province identity:** Movement targets, build provinces, and visibility use the **prefixed** form `regionId|localId` per [world-model-identity.md](../game/world-model-identity.md).

Seeded randomness selects among acceptable candidates; personality weights bias selection.

### Seeding
Per-turn seed: `turnSeed[P, T] = hash(globalGameSeed, aiSeed[P], T)`. Sub-seeds: perception, goals, economy, military, diplomacy, research, tactical, dialogue, agenda. Same save + seeds → same orders and events.

## Interactions
- [economy-planner.md](economy-planner.md) — worker allocation (production), cargo preference
- [ai-personalities.md](ai-personalities.md) — per-leader weights
- [hidden-agendas.md](hidden-agendas.md) — agenda modifiers
- [dialogue-and-mood.md](dialogue-and-mood.md) — event emission
- [world-model-identity.md](../game/world-model-identity.md) — province identity (prefixed id) in AI context
- Program: [ai-planner.md](../program/ai-planner.md) — control rules, order merge
- Program: [ai-systems-impl.md](../program/ai-systems-impl.md) — module boundaries, APIs

### Implementation (turn pipeline)
AI order generation runs so that orders are available for the **Orders** phase of turn resolution. Merge (human + AI) and application order are defined in [turn-resolution-phases.md](../program/turn-resolution-phases.md) (phase 1 Orders) and [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § Orders. Control rules and merge semantics: [ai-planner.md](../program/ai-planner.md); module boundaries and APIs: [ai-systems-impl.md](../program/ai-systems-impl.md).

## Acceptance criteria
- **Determinism:** Same game state and seeds produce the same AI decisions and orders; per-turn seed and sub-seeds as in § Seeding.
- **PlayerView-only:** AI reads only observable state; no hidden tiles or enemy-only data.
- **Turn pipeline:** AI emits orders that are merged with human orders in the Orders phase; phase sequence and application order per [turn-resolution-phases.md](../program/turn-resolution-phases.md), [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md).
- **Goal selection and domains:** Behavior tree or weighted goal selection drives strategy; utility AI (economy, military, diplomacy, research) scores candidates; personality and hidden agendas bias selection per § Rules.
- **Province identity:** Movement targets, build provinces, and visibility use prefixed form `regionId|localId` per [world-model-identity.md](../game/world-model-identity.md).
- **Movement (filter and prefer):** Move orders are filtered by diplomacy (no move to at-peace or minor-without-war). Among valid moves, selection prefers moves into enemy/contested territory via configurable score bonus.
- **Difficulty:** Difficulty affects starting parameters and ruleset modifiers only, not AI logic or personality.
