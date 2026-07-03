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

Full resolution per [diplomacy-resolution.md](diplomacy-resolution.md): overtures, Join Empire/Colony, alliances, war/peace, relation updates. Runs after Production and before Spy resolution so same-turn diplomacy ownership and relation changes are visible to downstream phases.

---

## Spy resolution

Immediately after Diplomacy and before Research (Refs #3834): (1) kill rolls for foreign spies (5% base + garrison + empire-wide counter-esp bonus); (2) diplomacy -8 penalty per kill with `lastInteractionTurn` update; (3) 10% defection rolls for survivors when counter-espionage is active; (4) `SpyCaughtEvent` / `SpyDefectedEvent` emission. Research then applies passive spy RP boost from surviving spies in rival GP provinces. See [civilian-units.md](../game/civilian-units.md) § Spy mechanics.

---

## Extraction

(1) **Connectivity:** Recompute per-player connectivity (see [extraction-pipeline.md](extraction-pipeline.md)). (2) **Extract:** Per-tile effective extraction: min(improvement, tech cap), then min(..., transport level); minerals only from prospected tiles per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md); sum by commodity; separate same-region vs overseas. **Great Power capital bonus:** add `Game.capitalTileGrainBonusPerTurn` grain (default 5) to **land** totals for each player with a capital tile, unconditional on connectivity ([extraction-and-improvements.md](../game/extraction-and-improvements.md) § Capital tile grain bonus). (3) **Land:** Add same-region totals to stockpile. (4) **Sea:** Allocate overseas totals by priority, capped by cargo holds derived from the player's home fleet (in port at capital; see [auto-transport.md](auto-transport.md)); add only the transported portion to stockpile. Reference: [capital-and-connectivity.md](../game/capital-and-connectivity.md), [extraction-pipeline.md](extraction-pipeline.md).

**Override:** When `extractedByPlayerId` is **non-empty**, the phase applies `applyExtractionForPlayers` only: per-player maps are merged into central stockpiles with **no** connectivity, tile extraction, land/overseas split, cargo-hold cap, or interception. See [auto-transport.md](auto-transport.md) § Caller-supplied extraction override.

---

## Riches to treasury

For each riches commodity (gold, silver, gems, diamonds, spices): add quantity × basePrice × **richesCashMultiplier** to treasury; remove from stockpile. Base prices: spices = 50; others from spawn weights. **richesCashMultiplier** is optional (default 1.0); scenario or ruleset may override (e.g. Search for El Dorado 1.5). Where the value is defined: [ruleset-config.md](ruleset-config.md) (economy.riches_cash_multiplier). Reference: Imperialism II 02-economy, GDD 04.

After applying each Great Power's own stockpile riches, the phase additionally credits **owning Great Powers** for riches yielded by tiles they previously purchased from a Minor or Tribe via the Merchant `purchase_land` work order. Per [world-market.md](../game/world-market.md) § First right of refusal § Riches handoff, riches commodities are not auto-offered on the world market; instead the per-tile non-Great-Power extraction yield ([extraction-and-improvements.md](../game/extraction-and-improvements.md) § Non-Great-Power extraction, with mineral filter bypassed for purchased tiles) for any tile whose resource is in the riches set is converted to the buyer Great Power's treasury at `units × richesBasePrice(commodityId) × richesCashMultiplier` (truncated to int). The set of eligible purchased tiles is sourced from [PurchasedTileIndex.fromGame](world-market-resolution.md) so post-conquest provinces (now owned by a Great Power) are filtered out — a conquered province's riches resume flowing through phase 2 Extraction and the new owner's own stockpile.

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

(1) **Conflict detection:** group units by faction per province; if two+ factions, build BattleContext (one defender, one+ attackers). (2) Run combat resolver chain; collect casualties and province owners. (3) **Apply:** remove casualties; set `province.ownerId` for conquered provinces and, when a province changes owner, clear any active Spy timers for `(newOwner, thatProvince)` so that own provinces never decay via Spy timers per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md). (4) **Capital reassignment:** For **each capital-bearing faction** — Great Power player, Minor Nation, and Tribe — that has a non-null capital province and capital tile and no longer owns that capital province, run **runtime** capital reassignment per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Capital loss and reassignment. This is **not** game-init capital choice: no `pickCapitalForFaction` tile heuristics, no § Capital Setup port/road placement during reassignment. Choose new capital province in the original region from owned provinces (seaboard preferred, then inland; deterministic sort). Set the faction's capital tile from that province's **`townTileKey` only**; do not mutate province `townTileKey` or tile state for ports/roads. For Great Powers, the new capital province's `townDevelopmentLevel` is set to `4`; for Minor Nations and Tribes, `townDevelopmentLevel` is **not** modified. If the faction has no owned provinces in the original region, clear that faction's capital to null. If the chosen province lacks a parseable `townTileKey`, throw `CapitalReassignmentFatalError` (or equivalent); the implementation must log **`logic:`** at **error** with **full error and stack trace** before or as the error propagates. **Region-scoped topology:** use `topologyByRegion[regionId]` when present for sea-bound checks, else the combined topology. Reassignment runs whenever combat runs (no dependency on `tileMapByRegion`). After reassignment, apply the **Great Power fall** rule per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Great Power fall, then the **Minor Nation and Tribe terminal fall** rule per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Minor Nation and Tribe terminal fall. The debug `/flip_province` command path must reuse this same reassignment-plus-fall sequencing across Great Powers, Minor Nations, and Tribes to keep terminal capital-loss outcomes consistent with combat resolution. **Host:** Turn resolution callers must treat uncaught reassignment failures as fatal to the session and preserve logs for diagnostics. Reference: [combat.md](../game/combat.md), [combat-resolution.md](combat-resolution.md).

---

## Build / work

**Order within the phase (per player, deterministic):** (1) **`RecruitWorkerOrder`** — apply queued worker recruit / train actions per [workers-and-population.md](../game/workers-and-population.md) § Recruiting, Training, and Disbanding (cost row, peasant reservation, tech gates). Worker pool deltas settle first so subsequent `BuildUnitOrder` peasant consumes see post-recruit headcounts. (2) **`BuildUnitOrder`** — by unit type category — civilian: deduct cash from treasury and paper from stockpile per [civilian-units.md](../game/civilian-units.md), add unit; military: deduct cost, consume worker, add unit; naval: deduct cost, add ship to home fleet (in port at capital). (3) **`WorkOrder`** — exploration / prospecting per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md); civilian development (Builder, Engineer, Rail Builder) per [development-resolution.md](development-resolution.md) with multi-turn progress and completion effects. Same behaviour in main game and ctdev sim_game.

**Same-turn labour:** Worker pool changes applied here affect **next turn** Consumption and Production only — Consumption and Production for the current turn already ran in phases 4–5 (see [workers-and-population.md](../game/workers-and-population.md) § Phase placement).

---

## End-of-turn

(1) **Victory check** — If `Game.victory` is null, evaluate military victory: count Old World provinces per Great Power; if any GP has ≥31 OW provinces, set `Game.victory` (winner, type military, turn number). If victory already set, skip. See [victory.md](../game/victory.md) and [#86](https://github.com/waigore/colonizethisv3/issues/86). (2) **Era-change dialogue** — When the calendar era changes on the next turn, emit dialogue events per [dialogue-and-mood.md](../ai/dialogue-and-mood.md); skip this step when the campaign calendar cap applies on the current turn (no advance into the next calendar year). (3) **Immediate spy fog decay** — For each other-faction province, if no Spy owned by the player remains in that province, set tiles to fogged for that player (multi-spy presence tracked by count; fog reverts only when count drops to zero). No spy grace timer. See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md). (4) **Explorer fog decay** — For each other-faction province where a player had Explorer, if none remain, set tiles to fogged. (5) **Coastal sea zone full visibility** — For each Great Power (including human), set all tiles in sea zones adjacent (P–S in topology) to provinces that player fully owns to fullyVisible in WorldState. Runs after fog decay so visibility is consistent for all players. See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md) § Coastal sea zone full visibility, [fog-and-exploration.md](../game/fog-and-exploration.md). (6) **Turn advance / calendar cap** — If `Game.victory` is still null and the campaign calendar cap applies (last full turn whose start calendar year is the normative stop year **1800** for default `gdd01`; derived from `turnTimeMapping` per [turn-time-mapping.md](../game/turn-time-mapping.md) § Campaign calendar cap), set `Game.calendarCampaignHalted` true, keep `turnState.turnNumber` unchanged, and set phase to Orders. Otherwise increment turn number and set phase to Orders. (7) **Orders** — The current-turn order list is cleared after turn resolve (not carried over). The caller that owns the order list or OrderEngine clears it after TurnResolver returns. See [order-engine.md](order-engine.md) § End-of-turn order list. Merge and apply of orders for the next turn happen when that turn's Orders phase runs.

---

## Acceptance criteria

- **Phase ordering:** The implemented TurnResolver runs phases in the fixed sequence defined in [turn-resolution-phases.md](turn-resolution-phases.md); no extra phases mutate game state between these steps.
- **Determinism:** Given the same starting WorldState, orders, ruleset, and random seeds, a full turn resolution (all phases) produces the same resulting WorldState and victory state.
- **End-of-turn:** Military victory is evaluated once per turn (when `Game.victory` is null) and remains stable thereafter; era-change dialogue (skipped when the calendar cap ends the turn), immediate spy/explorer fog decay (no spy grace timer), coastal sea zone full visibility (per fog-and-exploration-resolution), and turn/phase advance **or calendar halt** behave as described above.

### Given–When–Then acceptance criteria

- Given two Spies owned by the same player are present in the same foreign province  
  When one Spy leaves and the other remains  
  Then tile visibility for that province is unchanged for that player.

- Given the last Spy owned by a player leaves a foreign province (or is killed)  
  When the system runs the end-of-turn phase  
  Then all tiles in that province become fogged for that player immediately.

- Given combat resolution completes and a player must undergo capital reassignment but the chosen province has an invalid or missing `townTileKey` per [capital-and-connectivity.md](../game/capital-and-connectivity.md)  
  When the Combat phase runs capital reassignment  
  Then the system emits `logic:` error-level logs including the exception and full stack trace and throws so that turn resolution does not return a completed state.

- Given combat resolution completes and a Minor Nation no longer owns its capital province but still owns at least one other province in the original capital region with a valid `townTileKey`  
  When the Combat phase runs capital reassignment  
  Then the system sets that Minor Nation's `capitalProvinceId` and `capitalTile` to the deterministic eligible new capital per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Capital loss and reassignment, does not modify `WorldState.portsByProvinceSeaboard`, `WorldState.tileState`, or any province `townDevelopmentLevel`, and does not remove the Minor Nation entry from `Game.minorNations`.

- Given combat resolution completes and a Tribe no longer owns its capital province but still owns at least one other province in the original capital region with a valid `townTileKey`  
  When the Combat phase runs capital reassignment  
  Then the system sets that Tribe's `capitalProvinceId` and `capitalTile` to the deterministic eligible new capital per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Capital loss and reassignment, does not modify any port, road, or province `townDevelopmentLevel`, and does not remove the Tribe entry from `Game.tribes`.

- Given combat resolution completes and a Minor Nation no longer owns its capital province and has no other owned provinces remaining in the original capital region  
  When the Combat phase runs capital reassignment and Minor Nation terminal fall  
  Then the system clears that Minor Nation's `capitalProvinceId` and `capitalTile`, transfers every province previously owned by that Minor Nation in any region to the faction that currently owns the lost capital, removes the Minor Nation entry from `Game.minorNations`, and removes all `Unit` and `Fleet` entries whose `ownerId` matches the fallen Minor Nation id.

- Given combat resolution completes and a Tribe no longer owns its capital province and has no other owned provinces remaining in the original capital region  
  When the Combat phase runs capital reassignment and Tribe terminal fall  
  Then the system clears that Tribe's `capitalProvinceId` and `capitalTile`, transfers every province previously owned by that Tribe in any region to the faction that currently owns the lost capital, removes the Tribe entry from `Game.tribes`, and removes all `Unit` and `Fleet` entries whose `ownerId` matches the fallen Tribe id.

- **Consistency with specs:** Per-phase behaviour matches this document and its referenced specs (e.g. [diplomacy-resolution.md](diplomacy-resolution.md), [extraction-pipeline.md](extraction-pipeline.md), [combat-resolution.md](combat-resolution.md)); no phase performs work that belongs to another phase.

## Constraints

- **Province identity:** Province ids used in phase behaviour (e.g. unit/fleet location, `province.ownerId`, capital, victory count, fog by province) follow [world-model-identity.md](../game/world-model-identity.md): use prefixed form (`regionId|localId`); never look up by province id alone.
