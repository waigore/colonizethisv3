# Turn Resolution — Per-Phase Details

**SPEC/program** — Detailed behaviour for each turn-resolution phase. Overview: [turn-resolution-phases.md](turn-resolution-phases.md).

---

## Orders

Phase 1. Gather and validate orders; Great Powers only submit. Merge human and AI orders; resolve cross-player effects before application. Order types, validation, and application are defined in [order-engine.md](order-engine.md) and [orders.md](orders.md). Phase-details below start at Diplomacy (phase 2).

---

## Diplomacy

Full resolution per [diplomacy-resolution.md](diplomacy-resolution.md): overtures, Join Empire/Colony, alliances, war/peace, relation updates. Runs before Movement so war/peace current for movement and combat.

---

## Extraction

(1) **Connectivity:** Recompute per-player connectivity (see [extraction-pipeline.md](extraction-pipeline.md)). (2) **Extract:** Per-tile effective extraction: min(improvement, tech cap), then min(..., transport level); minerals only from prospected tiles per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md); sum by commodity; separate same-region vs overseas. (3) **Land:** Add same-region totals to stockpile. (4) **Sea:** Allocate overseas totals by priority, capped by cargo holds (stub); add to stockpile. Reference: [capital-and-connectivity.md](../game/capital-and-connectivity.md), [extraction-pipeline.md](extraction-pipeline.md).

---

## Riches to treasury

For each riches commodity (gold, silver, gems, diamonds, spices): add quantity × basePrice to treasury; remove from stockpile. Base prices: spices = 50; others from spawn weights. Reference: Imperialism II 02-economy, GDD 04.

---

## Production

Per recipe: consume inputs and labour from stockpile and WorkerPool; add outputs. Insufficient input: skip or partial per spec.

---

## Consumption

Military regiments consume food upkeep **before** workers and navy. Per player: (1) Compute regiment food demand. (2) Consume food from stockpile (military-first). (3) Derive feeding coverage ratio → morale/strength modifier for Combat (coverage ≥ 1.0 → 1.0; 0.5–<1.0 → 0.75; <0.5 → 0.5). (4) Workers/navy consume remainder per [workers-and-population.md](../game/workers-and-population.md); starvation removes workers. Upkeep shortfall for military affects morale/strength, not unit count.

---

## Research

(1) Read orders (slot → techId, funding). (2) Validate treasury and prerequisites; reject/reduce per [research-resolution.md](research-resolution.md). (3) Deduct spending. (4) Add progress per slot. (5) Where progress ≥ cost: mark researched, update techUnlocked and derived state, clear slot. (6) Tech assignable only if prerequisites in techUnlocked.

---

## Movement

Apply validated land MoveOrders; naval MoveOrders and mission assignments (ship reveal on fleet enter sea zone per [naval-movement-resolution.md](naval-movement-resolution.md)); set unit/fleet location and active missions.

---

## Naval Interception & Naval Combat

(1) Resolve patrol/blockade interceptions, trade/transport raids, conflicts between hostile fleets per [naval-movement-resolution.md](naval-movement-resolution.md). (2) For contested sea zones: build BattleContextSea; resolve per [naval-combat-resolution.md](naval-combat-resolution.md); update fleet compositions and locations. (3) Beachhead fleets resolved before associated land invasions.

---

## Combat

(1) **Minor military parity:** compute `maxGreatPowerMilitaryLevel`; set each Minor Nation/Tribe `effectiveMilitaryLevel` ([factions.md](../game/factions.md)). (2) **Conflict detection:** group units by faction per province; if two+ factions, build BattleContext (one defender, one+ attackers). (3) Run combat resolver chain; collect casualties and province owners. (4) **Apply:** remove casualties; set `province.ownerId` for conquered provinces. (5) **Capital reassignment:** For each Great Power that no longer owns their capital province, run capital reassignment using the **same shared API as game init** (DRY): choose new capital in original region from owned provinces, prefer seaboard, then call shared capital-placement logic (pick province + tile, apply port/road, apply road path from port to capital). Per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Capital loss and reassignment, [game-setup-pipeline.md](game-setup-pipeline.md) § 7b. If the player has no provinces in the original region, leave capital null; document in spec. Reference: [combat.md](../game/combat.md), [combat-resolution.md](combat-resolution.md).

---

## Build / work

BuildUnitOrder: by unit type category — civilian: deduct cash from treasury and paper from stockpile per [civilian-units.md](../game/civilian-units.md), add unit; military: deduct cost, consume worker, add unit; naval: deduct cost, add ship to home fleet. WorkOrder: exploration/prospecting per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md); civilian development (Builder, Engineer, Rail Builder) per [development-resolution.md](development-resolution.md) with multi-turn progress and completion effects. Same behaviour in main game and ctdev sim_game.

---

## End-of-turn

Fog decay: for each other-faction province where player had Explorer/Spy, if none remains → fogged. Increment WorldState turn number. Clear or carry over orders as designed.
