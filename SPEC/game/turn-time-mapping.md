# Turn-Time Mapping

**SPEC/game** — Maps turn number to calendar year for narrative and UI. Derived from GDD 01 Time Progression, Imperialism II 01-game-fundamentals.

---

## Purpose

Scale game turns to a historical calendar so players experience the colonial era (1500–1850) as a recognizable timeline. Used for Turn Summary, HUD, and future Gazette/narrative content.

---

## Default Formula (GDD 01)

Reference: GDD 01 Time Progression, Imperialism II 01-game-fundamentals.

| Years | Turn duration | Turns |
|-------|---------------|-------|
| 1500–1700 | 2 years per turn | 1–100 |
| 1700+ | 1 year per turn | 101+ |

- **Start year:** 1500 (turn 1).
- **Cutoff:** After turn 100, year 1700; thereafter 1 year per turn.
- **Total game length:** Typically 150–200 turns (GDD 01).

---

## Configurable Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `startYear` | 1500 | Year for turn 1. |
| `cutoffYear` | 1700 | Year at which pacing changes. |
| `yearsPerTurnBeforeCutoff` | 2 | Years per turn from start to cutoff. |
| `yearsPerTurnAfterCutoff` | 1 | Years per turn after cutoff. |

Turns before cutoff = `(cutoffYear - startYear) / yearsPerTurnBeforeCutoff` (e.g. 100).

---

## Configuration Layers

- **Base:** Default values (GDD 01). Single source for MVP.
- **MVP:** Default only; turn-time mapping is not read from the ruleset at game creation. Game setup uses `TurnTimeMapping.gdd01`. See [game-setup-pipeline.md](../program/game-setup-pipeline.md) step 7e and [ruleset-config.md](../program/ruleset-config.md).
- **Scenario:** May override (post-MVP). Scenarios not in MVP scope.
- **Immutability:** Formula fixed at game creation; cannot change during play.

## Edge cases

- **Turn 1:** Maps to `startYear` (1500 default).
- **Turn 0 or negative:** Not defined by GDD; implementation may yield values outside the intended calendar range. Callers should use turn ≥ 1 for display or narrative.

---

## Consumers

- **UI:** Turn Summary, HUD (e.g. "Turn 47 (1702)").
- **Gazette/narrative:** Event text keyed by year (future).
- **Era display:** Tech tree and theming by year/era.

---

## Derivation

Calendar year is derived from `WorldState.turnState.turnNumber` using the game's `turnTimeMapping`. No change to turn resolution logic. See [turn-resolution.md](../program/turn-resolution.md).

---

## References

- GDD 01 Time Progression (Obsidian).
- Imperialism II 01-game-fundamentals (Obsidian).
- [world-model.md](world-model.md) — Game holds optional turnTimeMapping.
- [ruleset-config.md](../program/ruleset-config.md) — turnTimeMapping in config contract.
