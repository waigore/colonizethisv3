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

- **Base:** Default values (GDD 01). Single source for current product.
- **current product:** Default only; turn-time mapping is not read from the ruleset at game creation. Game setup uses `TurnTimeMapping.gdd01`. See [game-setup-pipeline.md](../program/game-setup-pipeline.md) step 7e and [ruleset-config.md](../program/ruleset-config.md).
- **Scenario:** May override (later). Scenarios not in current product scope.
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

Calendar year is derived from `WorldState.turnState.turnNumber` using the game's `turnTimeMapping`. Turn resolution also applies a **campaign calendar cap** so full turns do not continue past the last turn whose start year equals the normative stop year (default **1800** for `TurnTimeMapping.gdd01`); see § Campaign calendar cap below and [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § End-of-turn.

---

## Campaign calendar cap

- **Normative stop year (current product):** **1800** — the last full turn that may be resolved is the turn number `T` where `yearAtTurn(T) == 1800` under the game's `turnTimeMapping` (for default `gdd01`, **`T = 201`**). The engine sets `Game.calendarCampaignHalted` when that turn's end-of-turn processing completes without military victory; `Game.victory` stays null. Further `runTurnResolutionPipeline` calls are no-ops until save/load or a future session reset.
- **Infinite mode bypass:** When `Game.infiniteMode == true` (chosen at new-game setup, persisted on `Game`), end-of-turn **does not** set `calendarCampaignHalted` at the cap turn; `turnNumber` advances and calendar years continue at post-1700 pacing (1 year per turn). Military victory still ends the campaign.
- **Military victory first:** If `Game.victory` is set on or before this turn, military completion rules take precedence; the calendar cap does not clear victory.
- **Custom mappings:** When no turn satisfies `yearAtTurn(T) == 1800` exactly (pacing gaps), the cap is **not applied** and campaigns may run until military victory or another future stop rule.
- **Declared winner (no military victory):** Session summaries (e.g. observer CLI) use the Great Power with the **strictly highest** `greatPowerPowerScore` among `Game.players`; on a tie or empty result, declare **no-one**. See [victory.md](victory.md) § Calendar campaign end.

---

## Acceptance criteria (calendar cap)

- Given default `TurnTimeMapping.gdd01` and `Game.victory == null`  
  When the System evaluates `turnNumberForStartCalendarYear(1800)`  
  Then the System returns turn **201** and `yearAtTurn(201) == 1800`.

- Given default `TurnTimeMapping.gdd01`  
  When the System evaluates `turnNumberForStartCalendarYear(1699)`  
  Then the System returns **null** (no turn starts in that calendar year under the two-segment pacing).

- Given a game whose `WorldState.turnState.turnNumber` is **201**, `Game.victory == null`, and `turnTimeMapping` is null or `gdd01`  
  When the System runs the end-of-turn phase after all prior phases for that turn  
  Then the System sets `Game.calendarCampaignHalted` to **true**, leaves `turnNumber` at **201**, sets phase to **Orders**, and leaves `Game.victory` null.

- Given `Game.calendarCampaignHalted == true`  
  When the System invokes full turn resolution again on that game  
  Then the System returns a completed result without advancing the turn number or mutating prior world state fields beyond idempotent news-digest bookkeeping.

- Given `Game.infiniteMode == true`, default `TurnTimeMapping.gdd01`, and `Game.victory == null`  
  When the System runs the end-of-turn phase at turn **201**  
  Then the System leaves `Game.calendarCampaignHalted` **false**, advances `turnNumber` to **202**, and `yearAtTurn(202) == 1801`.

---

## References

- GDD 01 Time Progression (Obsidian).
- Imperialism II 01-game-fundamentals (Obsidian).
- [world-model.md](world-model.md) — Game holds optional turnTimeMapping.
- [ruleset-config.md](../program/ruleset-config.md) — turnTimeMapping in config contract.

---

## Acceptance Criteria

- Given a `TurnTimeMapping` configuration with `startYear = 1500`, `cutoffYear = 1700`, `yearsPerTurnBeforeCutoff = 2`, and `yearsPerTurnAfterCutoff = 1`  
  When the System maps turn numbers to calendar years for display  
  Then the System maps turn 1 to year 1500, maps turn 100 to year 1700, uses 2 years per turn for turns 1–100 inclusive, and uses 1 year per turn for all turns greater than 100.

- Given a `TurnTimeMapping` object with integer fields `startYear`, `cutoffYear`, `yearsPerTurnBeforeCutoff`, and `yearsPerTurnAfterCutoff` that satisfy the constraints implied by the table in this doc  
  When the System serializes a Game that includes this `turnTimeMapping` and later reloads it from storage  
  Then the System restores the same mapping values and continues to derive calendar years from `WorldState.turnState.turnNumber` using the restored mapping without recalculating or changing the parameters mid-campaign.

- Given a caller passes a turn number less than 1 to the calendar-year mapping function  
  When the System applies the `TurnTimeMapping` formula  
  Then the System may return a year outside the intended 1500–1850 range but does not throw an error or mutate game state, and callers that need meaningful years for narrative or UI only invoke the mapping with turn numbers greater than or equal to 1.
