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

### Turn Pipeline (per AI Great Power)
1. **Perception** — Derive observable snapshot: threats, opportunities, economy, relations. All from PlayerView; no hidden data.
2. **Goal selection** — Behavior tree chooses strategy using personality weights and hidden agenda modifiers.
3. **Domain planning** — Economy, military, diplomacy, research planners score candidates via personality and agenda weights; each emits candidate orders.
4. **Execution** — Combine, cap, and validate orders; emit dialogue/mood events.
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
- **Build/work:** Prefer cheaper orders improving owned, visible provinces.
- **Research:** Prefer lower-era, cheaper techs unlocking core capabilities.

Seeded randomness selects among acceptable candidates; personality weights bias selection.

### Seeding
Per-turn seed: `turnSeed[P, T] = hash(globalGameSeed, aiSeed[P], T)`. Sub-seeds: perception, goals, economy, military, diplomacy, research, tactical, dialogue, agenda. Same save + seeds → same orders and events.

## Interactions
- [ai-personalities.md](ai-personalities.md) — per-leader weights
- [hidden-agendas.md](hidden-agendas.md) — agenda modifiers
- [dialogue-and-mood.md](dialogue-and-mood.md) — event emission
- Program: [ai-planner.md](../program/ai-planner.md) — control rules, order merge
- Program: [ai-systems-impl.md](../program/ai-systems-impl.md) — module boundaries, APIs
