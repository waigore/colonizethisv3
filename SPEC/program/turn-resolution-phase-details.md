# Turn Resolution — Per-Phase Details

**SPEC/program** — Detailed behaviour for each turn-resolution phase. Overview: [turn-resolution-phases.md](turn-resolution-phases.md). Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Phase handler registry

Turn resolution uses a fixed phase sequence ([turn-resolution-phases.md](turn-resolution-phases.md)). Each phase is implemented by a **`TurnPhaseHandler`** (`turn_resolver_config.dart`): `(TurnPipelineState, TurnResolverConfig, turn) → TurnPhaseStepOutcome`. The canonical map is **`TurnPhaseHandlerRegistry.defaults`** (`turn_phase_handler_registry.dart`): one handler per `TurnPhase` in `turnResolutionSequence`. Every `TurnPhaseHandler` implementation — including the Orders noop and the research/diplomacy/combat/build-work/end-of-turn handlers that emit events — lives in **`turn/phases/*.dart`** (one phase per file, re-exported by `turn/phases.dart`); the registry module only maps each `TurnPhase` to its handler. Tests and callers may override individual phases via `TurnResolverConfig.phaseHandlerOverrides` (merged over defaults). Refs #2560.

---

## Orders

Phase 1. Gather and validate orders; Great Powers only submit. Merge human and AI orders; resolve cross-player effects before application. Order types, validation, and application are defined in [order-engine.md](order-engine.md) and [orders.md](orders.md). Phase-details below follow the fixed sequence in [turn-resolution-phases.md](turn-resolution-phases.md).

---

## Diplomacy

Full resolution per [diplomacy-resolution.md](diplomacy-resolution.md): overtures, Join Empire/Colony, alliances, war/peace, relation updates. Runs after Production and before Research/Movement so same-turn diplomacy ownership and relation changes are visible to downstream phases.

---

## Extraction

(1) **Connectivity:** Recompute per-player connectivity (see [extraction-pipeline.md](extraction-pipeline.md)). (2) **Extract:** Per-tile effective extraction: min(improvement, tech cap), then min(..., transport level); minerals only from prospected tiles per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md); sum by commodity; separate same-region vs overseas. **Great Power capital bonus:** add `Game.capitalTileGrainBonusPerTurn` grain (default 5) to **land** totals for each player with a capital tile, unconditional on connectivity ([extraction-and-improvements.md](../game/extraction-and-improvements.md) § Capital tile grain bonus). (3) **Land:** Add same-region totals to stockpile. (4) **Sea:** Allocate overseas totals by priority, capped by cargo holds derived from the player's home fleet (in port at capital; see [auto-transport.md](auto-transport.md)); add only the transported portion to stockpile. Reference: [capital-and-connectivity.md](../game/capital-and-connectivity.md), [extraction-pipeline.md](extraction-pipeline.md).

**Override:** When `extractedByPlayerId` is **non-empty**, the phase applies `applyExtractionForPlayers` only: per-player maps are merged into central stockpiles with **no** connectivity, tile extraction, land/overseas split, cargo-hold cap, or interception. See [auto-transport.md](auto-transport.md) § Caller-supplied extraction override.

---

## Riches to treasury

For each riches commodity (gold, silver, gems, diamonds, spices): add quantity × basePrice × **richesCashMultiplier** to treasury; remove from stockpile. Base prices: spices = 50; others from spawn weights. **richesCashMultiplier** is optional (default 1.0); scenario or ruleset may override (e.g. Search for El Dorado 1.5). Where the value is defined: [ruleset-config.md](ruleset-config.md) (economy.riches_cash_multiplier). Reference: Imperialism II 02-economy, GDD 04.

---

## Consumption

Per player, order is: (1) **Land military regiments** — compute food demand, consume from stockpile first, derive **land** feeding coverage ratio → land combat morale multiplier (coverage ≥ 1.0 → 1.0; 0.5–<1.0 → 0.75; <0.5 → 0.5). (2) **Navy** — all ships in that player's fleets: food per ship from `ShipEconomyCatalog` (default ruleset: 2 food units per ship); consume from stockpile; derive **naval** feeding coverage (`fullyFedShips / totalShips`, or 1.0 when `totalShips == 0`). Apply the **same three-tier morale multiplier** to **effective naval strength** in sea battles as for land combat. (3) **Workers** — per [workers-and-population.md](../game/workers-and-population.md): food priority **Masters → Journeymen → Apprentices → Peasants**; workers who lack food or (for trained tiers) lack luxury assignment are **on strike** (no labour) but **not removed**; **luxury deduction** only for food-fed trained workers who receive a unit, up to stockpile. Upkeep shortfall for military and navy affects combat multipliers, not unit/ship count. Unknown `ship_type_id` in fleet state is a **fatal** resolution error.

---

## Production

Runs **after** Consumption for that turn. Per recipe: consume inputs and labour from stockpile and **idle worker labour** (from post-Consumption `WorkerIdleCounts`); add outputs. Insufficient input: skip or partial per spec. Labour does not use raw `WorkerPool` headcounts alone.

---

## Research

(1) Read orders (slot → techId, funding). (2) Validate treasury and prerequisites; reject/reduce per [research-resolution.md](research-resolution.md). (3) Deduct spending. (4) Add progress per slot. (5) Where progress ≥ cost: mark researched, update techUnlocked and derived state, clear slot. (6) Tech assignable only if prerequisites in techUnlocked.

---

## Movement

Apply validated land MoveOrders; naval MoveOrders (dock only at owned provinces; undock into adjacent sea zone) and mission assignments (ship reveal on fleet enter sea zone per [naval-movement-resolution.md](naval-movement-resolution.md)); set unit/fleet location and active missions.

---

## Minor Regiment Upgrade

(1) Compute `maxGreatPowerMilitaryLevel` from post-Research Great Power buildable **land regiment** tiers. (2) For each **Old World Minor Nation**, set `effectiveMilitaryLevel` to that max and upgrade eligible land regiments in place to match parity level. (3) Preserve each upgraded regiment's damage state. (4) For each Tribe, set `effectiveMilitaryLevel` to 1 (no parity), without applying minor parity upgrade logic. This phase runs after Movement and before any naval or land combat resolution. Reference: [factions.md](../game/factions.md), [military-units.md](../game/military-units.md).

---

## Naval Interception & Naval Combat

(1) Resolve patrol/blockade interceptions, trade/transport raids, conflicts between hostile fleets per [naval-movement-resolution.md](naval-movement-resolution.md). (2) For contested sea zones: build BattleContextSea; resolve per [naval-combat-resolution.md](naval-combat-resolution.md); update fleet compositions and locations. (3) Beachhead fleets resolved before associated land invasions; when a fleet successfully completes a `Beachhead` mission against a hostile coastal province, the System records a **beachhead marker** for that province that lasts for exactly the next turn and is consulted by land movement/combat resolution to permit associated coastal invasions; after that turn's invasions resolve (or if no invasions occur), the marker is removed.

---

## Combat

(1) **Conflict detection:** group units by faction per province; if two+ factions, build BattleContext (one defender, one+ attackers). (2) Run combat resolver chain; collect casualties and province owners. (3) **Apply:** remove casualties; set `province.ownerId` for conquered provinces and, when a province changes owner, clear any active Spy timers for `(newOwner, thatProvince)` so that own provinces never decay via Spy timers per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md). (4) **Capital reassignment:** For each player that has a non-null capital province and capital tile and no longer owns that capital province, run **runtime** capital reassignment per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Capital loss and reassignment. This is **not** game-init capital choice: no `pickCapitalForFaction` tile heuristics, no § Capital Setup port/road placement during reassignment. Choose new capital province in the original region from owned provinces (seaboard preferred, then inland; deterministic sort). Set the player’s capital tile from that province’s **`townTileKey` only**; do not mutate province `townTileKey` or tile state for ports/roads. If the player has no owned provinces in the original region, clear capital to null. If the chosen province lacks a parseable `townTileKey`, throw `CapitalReassignmentFatalError` (or equivalent); the implementation must log **`logic:`** at **error** with **full error and stack trace** before or as the error propagates. **Region-scoped topology:** use `topologyByRegion[regionId]` when present for sea-bound checks, else the combined topology. Reassignment runs whenever combat runs (no dependency on `tileMapByRegion`). After reassignment, apply the **Great Power fall** rule per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Great Power fall. The debug `/flip_province` command path must reuse this same reassignment-plus-fall sequencing to keep terminal capital-loss outcomes consistent with combat resolution. **Host:** Turn resolution callers must treat uncaught reassignment failures as fatal to the session and preserve logs for diagnostics. Reference: [combat.md](../game/combat.md), [combat-resolution.md](combat-resolution.md).

---

## Build / work

BuildUnitOrder: by unit type category — civilian: deduct cash from treasury and paper from stockpile per [civilian-units.md](../game/civilian-units.md), add unit; military: deduct cost, consume worker, add unit; naval: deduct cost, add ship to home fleet (in port at capital). WorkOrder: exploration/prospecting per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md); civilian development (Builder, Engineer, Rail Builder) per [development-resolution.md](development-resolution.md) with multi-turn progress and completion effects. Same behaviour in main game and ctdev sim_game.

---

## End-of-turn

(1) **Victory check** — If `Game.victory` is null, evaluate military victory: count Old World provinces per Great Power; if any GP has ≥31 OW provinces, set `Game.victory` (winner, type military, turn number). If victory already set, skip. See [victory.md](../game/victory.md) and [#86](https://github.com/waigore/colonizethisv3/issues/86). (2) **Era-change dialogue** — When the calendar era changes on the next turn, emit dialogue events per [dialogue-and-mood.md](../ai/dialogue-and-mood.md); skip this step when the campaign calendar cap applies on the current turn (no advance into the next calendar year). (3) **Spy 5-turn fog decay** — Decrement spy-reveal timers; for each (player, province) where timer reaches 0, set that province’s tiles to fogged for that player **only when the province is owned by another faction; timers for a player's own provinces are ignored and cleared without changing visibility**. See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md) § Fog decay (Spy). (4) **Explorer/Spy fog decay** — For each other-faction province where a player had Explorer/Spy, if none remain (and no Spy timer active), set tiles to fogged. (5) **Coastal sea zone full visibility** — For each Great Power (including human), set all tiles in sea zones adjacent (P–S in topology) to provinces that player fully owns to fullyVisible in WorldState. Runs after fog decay so visibility is consistent for all players. See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md) § Coastal sea zone full visibility, [fog-and-exploration.md](../game/fog-and-exploration.md). (6) **Turn advance / calendar cap** — If `Game.victory` is still null and the campaign calendar cap applies (last full turn whose start calendar year is the normative stop year **1800** for default `gdd01`; derived from `turnTimeMapping` per [turn-time-mapping.md](../game/turn-time-mapping.md) § Campaign calendar cap), set `Game.calendarCampaignHalted` true, keep `turnState.turnNumber` unchanged, and set phase to Orders. Otherwise increment turn number and set phase to Orders. (7) **Orders** — The current-turn order list is cleared after turn resolve (not carried over). The caller that owns the order list or OrderEngine clears it after TurnResolver returns. See [order-engine.md](order-engine.md) § End-of-turn order list. Merge and apply of orders for the next turn happen when that turn's Orders phase runs.

---

## Acceptance criteria

- **Phase ordering:** The implemented TurnResolver runs phases in the fixed sequence defined in [turn-resolution-phases.md](turn-resolution-phases.md); no extra phases mutate game state between these steps.
- **Determinism:** Given the same starting WorldState, orders, ruleset, and random seeds, a full turn resolution (all phases) produces the same resulting WorldState and victory state.
- **End-of-turn:** Military victory is evaluated once per turn (when `Game.victory` is null) and remains stable thereafter; era-change dialogue (skipped when the calendar cap ends the turn), fog decay (including Spy timers that only ever affect other-faction provinces), coastal sea zone full visibility (per fog-and-exploration-resolution), and turn/phase advance **or calendar halt** behave as described above.

### Given–When–Then acceptance criteria

- Given a Spy timer is active for (player, province) with `turnsLeft > 1` and the province is owned by another faction  
  When the system runs the end-of-turn phase  
  Then the timer for that (player, province) is decremented by 1 and tile visibility for that province remains unchanged for that player.

- Given a Spy timer is active for (player, province) with `turnsLeft == 1` and the province is owned by another faction  
  When the system runs the end-of-turn phase  
  Then the timer entry for that (player, province) is removed and all tiles in that province become fogged for that player.

- Given a Spy timer is present for (player, province) where that province is owned by the same player (e.g. from an older save)  
  When the system runs the end-of-turn phase  
  Then the timer entry for that (player, province) is removed without changing tile visibility, so that all tiles in that province remain fully visible for that player.

- Given combat resolution completes and a player must undergo capital reassignment but the chosen province has an invalid or missing `townTileKey` per [capital-and-connectivity.md](../game/capital-and-connectivity.md)  
  When the Combat phase runs capital reassignment  
  Then the system emits `logic:` error-level logs including the exception and full stack trace and throws so that turn resolution does not return a completed state.

- **Consistency with specs:** Per-phase behaviour matches this document and its referenced specs (e.g. [diplomacy-resolution.md](diplomacy-resolution.md), [extraction-pipeline.md](extraction-pipeline.md), [combat-resolution.md](combat-resolution.md)); no phase performs work that belongs to another phase.

## Constraints

- **Province identity:** Province ids used in phase behaviour (e.g. unit/fleet location, `province.ownerId`, capital, victory count, fog by province) follow [world-model-identity.md](../game/world-model-identity.md): use prefixed form (`regionId|localId`); never look up by province id alone.
