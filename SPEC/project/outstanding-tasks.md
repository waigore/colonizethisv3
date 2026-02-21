# Outstanding Project Tasks

**SPEC/project** — Comprehensive gap analysis documenting unimplemented, partially implemented, and undertested features. Tasks ordered by priority (P0 first) so implementers can quickly understand what needs to be done.

---

## Priority Key

| Priority | Meaning |
|----------|---------|
| **P0** | Critical blocker — blocks MVP completion or causes incorrect gameplay |
| **P1** | High priority — significant feature gap，影响核心玩法 |
| **P2** | Medium priority — noticeable gap but not blocking |
| **P3** | Nice to have — can be deferred to post-MVP |

**Complexity Key**

| Complexity | Estimate |
|------------|----------|
| **Small** | 1–2 days |
| **Medium** | 3–5 days |
| **Large** | 1+ weeks |

---

## P0: Critical — Blocks MVP or Causes Incorrect Gameplay

### Task: Fix Research Funding Values to Match Spec

**Status:** **Done** (verified). Code and tests match spec.

**Gap (resolved):** Research funding values in code now match the spec in `SPEC/game/tech-tree.md`.

| Spec (`tech-tree.md`) | Code (`research_resolver.dart`) — implemented |
|-----------------------|----------------------------------------------|
| Low: 50 gold, 100 RP/turn | 50 gold, 100 RP |
| Medium: 150 gold, 300 RP/turn | 150 gold, 300 RP |
| High: 400 gold, 800 RP/turn | 400 gold, 800 RP |
| Maximum: 1000 gold, 2500 RP/turn (2.5x efficiency) | 1000 gold, 2500 RP |

**Referenced specs:**
- [SPEC/game/tech-tree.md](SPEC/game/tech-tree.md) — Research Model section
- [SPEC/program/research-resolution.md](SPEC/program/research-resolution.md)

**What needs to be done:**
1. Update `_pointsForFunding()` to return spec values: 100/300/800/2500 RP (or adjust to match intended balance)
2. Update `_treasuryForFunding()` to return spec values: 50/150/400/1000 gold
3. Add efficiency bonus for Maximum funding (2.5x RP multiplier)
4. Verify enum `ResearchFundingLevel` has all required levels

**Complexity:** Small

---

### Task: Complete Capital and Connectivity (extraction, ports, sea paths, capital reassignment)

**Gap:** Connectivity is extraction-only and tile-level; port–capital rule (seaboard vs road/rail path); road path from port to capital at init (full path); sea-zone connectivity via sea paths; capital reassignment on loss; road level = transport level and railroads. Specs updated per plan; implementation and tests remain.

**Referenced specs:**
- [SPEC/game/capital-and-connectivity.md](SPEC/game/capital-and-connectivity.md)
- [SPEC/game/capital-choice-phase.md](SPEC/game/capital-choice-phase.md)
- [SPEC/program/game-setup-pipeline.md](SPEC/program/game-setup-pipeline.md)
- [SPEC/game/map-topology.md](SPEC/game/map-topology.md)
- [SPEC/program/turn-resolution-phase-details.md](SPEC/program/turn-resolution-phase-details.md)
- [SPEC/program/extraction-pipeline.md](SPEC/program/extraction-pipeline.md)
- [SPEC/game/extraction-and-improvements.md](SPEC/game/extraction-and-improvements.md)

**What needs to be done:**
1. Spec updates as in plan (connectivity scope, capital setup order and path, port connection rule, sea paths, capital loss, road/transport level) — **Done** (specs updated).
2. Init: after placing capitals and ports, for each port land-connected to capital, build road along shortest path (pathfinding on province tiles).
3. Connectivity resolver: port connected to capital iff (1) capital on seaboard or (2) road/rail path from capital to port; use sea-zone topology for sea path between ports (BFS on S–S); overseas tiles connected if road path to a port that is connected to capital.
4. Combat phase: after applying ownership changes, reassign capital for any GP that lost their capital using the **same shared API as init** (DRY): original region, prefer seaboard, then call shared capital-placement logic (pick province + tile, apply port/road, apply road path from port to capital).
5. Tests: add/expand connectivity and capital tests per plan § 7 (init path, seaboard vs inland capital, sea path, severed road, capital reassignment, railroad, edge case).

**Implementation details (include in TDD and/or in this task body so implementer has them):** Capital placement (DRY): one shared code path for init and reassignment — pickCapitalForFaction, applyCapitalPortAndRoad, then apply road path (shortest path on province tiles; set road level on each tile); pathfinding in one place; current code is stub (road only on capital and port tiles). Connectivity resolver: if capital on seaboard, all owned ports reachable via sea-path BFS from capital sea zone are connected; if not on seaboard, only ports reachable by road/rail from capital; sea-path = BFS on topology over sea zones (S–S edges). Transport level = tile road level (or port 4). Reassignment: call shared capital-placement; if no provinces in original region, leave capital null.

**Test cases to add:**
1. Init road path: capital inland + port 2+ steps away → every tile on shortest path has road level set; connectivity includes port and path.
2. Capital on seaboard: same-region port in same sea zone connected; overseas port in same/sea-path-reachable zone connected without land path.
3. Capital not on seaboard: only ports reachable by road/rail from capital connected; same-region port with no road path not connected.
4. Sea path (multi–sea zone): S1–S2 edge; capital on S1, overseas port on S2 → overseas port and tiles with road to it connected.
5. Severed road: province along road path lost → tiles beyond and port there no longer connected; next-turn recompute reflects it.
6. Capital loss and reassignment: combat flips capital → reassignment runs; new capital same region, preferred seaboard; port/road applied; next-turn connectivity uses new capital.
7. Railroad: road level 4 (railroad) extends connectivity like road; effective yield uses transport level 4.
8. Edge: player loses capital and has no provinces in original region → document behaviour (e.g. no capital, empty connectivity); test if specified.

**Complexity:** Medium (multi-file logic + tests)

---

### Task: Add Tests for Economy Modules

**Status:** **Done** (verified). economy_consumption_test, economy_extraction_test, economy_production_test, economy_riches_to_treasury_test exist; research_phase_test covers research resolver.

**Gap:** Five economy modules in `colonizethis_logic` have no dedicated test files:

| Missing Tests For | File Location |
|------------------|---------------|
| Consumption | `lib/src/economy/economy_consumption.dart` |
| Extraction | `lib/src/economy/economy_extraction.dart` |
| Production | `lib/src/economy/economy_production.dart` |
| Riches to Treasury | `lib/src/economy/economy_riches_to_treasury.dart` |
| Research Resolver | `lib/src/turn/research_resolver.dart` |

**Referenced specs:**
- [SPEC/game/stockpiles-and-production.md](SPEC/game/stockpiles-and-production.md)
- [SPEC/program/economy-models.md](SPEC/program/economy-models.md)
- [SPEC/program/research-resolution.md](SPEC/program/research-resolution.md)

**What needs to be done:**
1. ~~Create `test/economy_consumption_test.dart`~~ — **Done.** Worker/navy/army food consumption, starvation order.
2. ~~Create `test/economy_extraction_test.dart`~~ — **Done.** applyExtractionToStockpile, applyExtractionForPlayers.
3. ~~Create `test/economy_production_test.dart`~~ — **Done.** Recipe application, labour limits, output to stockpile.
4. ~~Create `test/economy_riches_to_treasury_test.dart`~~ — **Done.** Riches conversion rates, multiplier.
5. ~~Create `test/research_resolver_test.dart`~~ — **Done.** Covered by `research_phase_test.dart` (funding levels, progress, prerequisites).

**Complexity:** Medium

---

### Task: Add Tests for Core Logic Modules

**Status:** **Done** (verified). province_lookup_test.dart, simple_ai_heuristics_test.dart, constants_test.dart exist; research_phase_test.dart covers research resolver.

**Gap (resolved):** Dedicated test files exist; verify coverage as needed.

| Missing Tests For | File Location |
|------------------|---------------|
| Province Lookup | `lib/src/world/province_lookup.dart` |
| Simple AI Heuristics | `lib/src/ai/simple_ai_heuristics.dart` |
| Constants | `lib/src/constants.dart` |

**Referenced specs:**
- [SPEC/game/world-model.md](SPEC/game/world-model.md) — Province identity section
- [SPEC/program/ai-planner.md](SPEC/program/ai-planner.md)

**What needs to be done:**
1. Create `test/province_lookup_test.dart` — test `(regionId, provinceId)` lookup, prefixed id parsing
2. Create `test/simple_ai_heuristics_test.dart` — verify AI scoring functions
3. Create `test/constants_test.dart` — verify constant values match spec

**Note:** `simple_ai_heuristics_test.dart` already exists — verify it covers all functions.

**Complexity:** Small

---

### Task: Civilian Units Spec — Verification and Test Coverage (P0)

**Status:** Implementation done per Civilian Units Spec plan. Specs updated; order engine, orders_application, fog/visibility, init town assignment, extraction town cap, and suggestions updated. The following P0 items need **verification and tests** as below.

**Referenced specs:**
- [SPEC/game/civilian-units.md](SPEC/game/civilian-units.md) — Work order summary table
- [SPEC/program/development-resolution.md](SPEC/program/development-resolution.md)
- [SPEC/program/orders.md](SPEC/program/orders.md)
- [SPEC/program/fog-and-exploration-resolution.md](SPEC/program/fog-and-exploration-resolution.md)
- [SPEC/game/capital-and-connectivity.md](SPEC/game/capital-and-connectivity.md)
- [SPEC/game/extraction-and-improvements.md](SPEC/game/extraction-and-improvements.md)

| # | Item | Status | Test cases to add |
|---|------|--------|-------------------|
| 1 | Spy: presence reveal and fog decay | **Done** | Integration: Spy in non-owner province → province fully visible; Spy leaves → 5-turn timer; after 5 turns province fogged; other player does not see Spy location. |
| 2 | Spy: steal_tech work order | **Done** | Success within 5 turns (8%/turn), expiry when 0 turns, no tech to steal, target = other GP capital only. |
| 3 | Spy: counter_spy work order | **Done** | Probability cap 30%, 5% per friendly Spy; multiple friendly Spies; enemy Spy removed on success. |
| 4 | Merchant: purchase_land work order | **Done** | Success: embassy, at peace, treasury ≥ 15× base price, tile with resource (prospected if mineral) → treasury deducted, tile purchased. Reject: no embassy, at war, insufficient treasury, no resource, mineral not prospected. |
| 5 | Work order material costs | **Done** | Reject when materials insufficient; deduct on apply for build_improvement, build_road, build_port, build_fort, build_rail, upgrade_town. |
| 6 | Work order durations and config | **Done** | Multi-turn work uses totalTurnsForWork; units with currentWork only get cancel (no new work suggestions). |
| 7 | UnitStatus: standardize idle | **Done** | On completion set status = idle (not done). Optional: remove `done` from enum or document idle/working only. |
| 8 | Province town at init | **Done** | Init step 7d: each province has townTileKey; capital province = capital tile; same region = tile with shortest path to capital; overseas = port or first tile. |
| 9 | Town-linked extraction | **Done** | Effective yield capped by province townDevelopmentLevel; upgrade_town completion sets town development level. |
| 10 | Embassy gate for purchase_land | **Done** | validateWork purchase_land requires embassy with Minor/Tribe. |
| 11 | build_road tech gate | **Done** | Road level 2 requires Road Construction tech in validation and completion. |
| 12 | Work order summary table and engine/suggestions | **Done** | Table in civilian-units.md; order engine and suggestions use workOrderTargetsByUnitType and cost checks. |

**What needs to be done:**
1. Add integration / scenario tests for Merchant purchase_land (full flow with embassy, at peace, treasury, resource; reject cases).
2. Add Spy integration tests: steal_tech (spy in other GP capital, 5 turns, tech granted or expiry), counter_spy (enemy spy in our province, friendly counter_spy, probability kill), spy visibility (other player does not see our Spy).
3. Add work order tests: apply build_road/build_fort etc. with sufficient materials → materials deducted; insufficient → order not applied or rejected in validation.
4. Add town and extraction tests: init assigns town; extraction uses town development level; upgrade_town increases town development level.

**Complexity:** Small–Medium (test authoring)

---

## P1: High Priority — Significant Feature Gap

### Task: Complete Siege Mechanics Implementation

**Gap:** Province model has `fortLevel` field and basic fort build in `orders_application.dart`. Core siege numbers are implemented; gates/sortie and on-wall vs behind-wall targeting remain.

| Missing Component | Spec Reference | Status |
|-------------------|----------------|--------|
| Wall damage reduction percentages | `siege-mechanics.md` | **Done** — 0/25/45/60% in combat_config, combat_resolver |
| Emplaced artillery resolution | `siege-mechanics.md` | **Done** — fortGunCount, wallHp in resolver |
| Gates and sortie logic | `siege-mechanics.md` | Spec clarified; deferred to future tactical expansion |
| Units on/behind wall behavior | `siege-mechanics.md` | Spec clarified; deferred to future tactical expansion |

**Referenced specs:**
- [SPEC/game/siege-mechanics.md](SPEC/game/siege-mechanics.md)
- [SPEC/game/combat.md](SPEC/game/combat.md) — Battle Mode section

**What needs to be done:**
1. Define exact damage reduction percentages in spec (currently TBD):
   - Fort 0: 0%
   - Fort 1 (Wood): 25%
   - Fort 2 (Stone): 45%
   - Fort 3 (Modern): 60%
2. Implement wall HP and breach mechanics in `CombatResolver`
3. Implement emplaced artillery fire during siege (bonus to defender)
4. Implement gate mechanics — units can sortie/retreat through gates
5. Implement "units on wall" vs "units behind wall" targeting rules
6. Update combat mode selection to use siege rules when `fortLevel >= 1`

**Complexity:** Large

---

### Task: Complete Naval Missions and Interception

**Gap:** `NavalMissionOrder` exists with types (Patrol, Blockade, Beachhead, Defend). Interception and retreat are implemented; Beachhead landing/invasion enablement remains.

| Missing Component | Spec Reference | Status |
|-------------------|----------------|--------|
| Patrol interception (30% base) | `ships-and-naval.md` | **Done** — naval_combat_resolver.dart |
| Blockade interception (50% base) | `ships-and-naval.md` | **Done** — kNavalInterceptBaseBlockade |
| Superior/inferior force modifiers | `ships-and-naval.md` | **Done** — kNavalInterceptSuperiorBonus / InferiorPenalty |
| Beachhead landing logic | `ships-and-naval.md` | Deferred — landing site / invasion next turn |
| Retreat from naval combat | `ships-and-naval.md` | **Done** — base 0.6, speed, aggression in resolveSeaBattle |

**Referenced specs:**
- [SPEC/game/ships-and-naval.md](SPEC/game/ships-and-naval.md)
- [SPEC/program/naval-movement-resolution.md](SPEC/program/naval-movement-resolution.md)
- [SPEC/program/naval-combat-resolution.md](SPEC/program/naval-combat-resolution.md)

**What needs to be done:**
1. Implement interception probability calculation with base values and modifiers
2. Implement force comparison (superior/inferior detection)
3. Implement Beachhead mission — fleet establishes landing site, enables invasion next turn
4. Implement naval retreat logic with speed advantage and aggression modifiers
5. Wire naval missions into TurnResolver's Naval Interception & Combat phase

**Complexity:** Medium

---

### Task: Complete Trade/Transport Raids Integration

**Status:** **Done** (verified). `applyTradeInterception` in sea_transport.dart; wired in turn_resolver.

**Gap (resolved):** Naval interception reduces overseas cargo; integration with economy is implemented.

| Missing Component | Spec Reference | Status |
|-------------------|----------------|--------|
| Cargo interception during blockade | `ships-and-naval.md` | **Done** — blockade bonus, escort factor |
| Ship loss chances | `ships-and-naval.md` | **Done** — civilian penalty, fleet updates |
| Escort protection calculations | `ships-and-naval.md` | **Done** — escortStrengthWeight, escortFactorMax |
| Home fleet raid application | `auto-transport.md` | **Done** — applied after overseas allocation in turn_resolver |

**Referenced specs:**
- [SPEC/game/ships-and-naval.md](SPEC/game/ships-and-naval.md) — Trade and Transport Interception section
- [SPEC/program/auto-transport.md](SPEC/program/auto-transport.md)

**What needs to be done:**
1. Implement interception chance with base × blockadeBonus × (1 - escortFactor)
2. Implement cargo loss calculation with raidEfficiency
3. Implement civilian ship penalty (2x vulnerability)
4. Implement escort strength reduction formula
5. Wire into sea transport after naval combat phase

**Complexity:** Medium

---

### Task: Complete Development/Work Order Resolution

**Status:** Verified. Improvement 0–4, road 0–2/4, port, fort, rail; multi-turn currentWork in orders_application; test added for multi-turn decrement and completion.

**Gap (resolved):** Work order completion and multi-turn tracking are implemented.

| Missing Component | Spec Reference | Status |
|-------------------|----------------|--------|
| Improvement build (mine/farm/ranch) | `extraction-and-improvements.md` | **Done** — setImprovement clamp 0–4 |
| Road building | `extraction-and-improvements.md` | **Done** — setRoadLevel 0–2 |
| Port building | `extraction-and-improvements.md` | **Done** |
| Fort building | `extraction-and-improvements.md` | **Done** — fortLevel clamp 0–3 |
| Railroad building | `extraction-and-improvements.md` | **Done** — setRoadLevel 4 |
| Multi-turn work tracking | `development-resolution.md` | **Done** — currentWork remainingTurns |

**Referenced specs:**
- [SPEC/game/extraction-and-improvements.md](SPEC/game/extraction-and-improvements.md)
- [SPEC/program/development-resolution.md](SPEC/program/development-resolution.md)

**What needs to be done:**
1. Verify improvement levels (0–4) are correctly applied
2. Verify transport level upgrades (1=road, 2=improved road, 4=railroad/port)
3. Implement multi-turn work project tracking (currently mostly single-turn)
4. Verify build costs per level match spec

**Complexity:** Medium

---

### Task: Add Desert Terrain and Allow Diamonds to Spawn in Desert

**Status:** **Done** (verified). TerrainType.desert, diamonds on desert, terrain_region_rules, combat_config, fog-and-exploration and orders.md updated.

**Gap (resolved):** Desert terrain added; diamonds spawn on desert in New World.

**Specs to update (must be updated first, per SPEC-first rule):**
- [SPEC/game/resource-terrain-region-rules.md](SPEC/game/resource-terrain-region-rules.md) — table: diamonds terrain **swamp** → **desert**; remove or reword the proxy note.
- [SPEC/game/fog-and-exploration.md](SPEC/game/fog-and-exploration.md) — mineral-eligible terrain: add **desert** (for diamonds).
- [SPEC/program/orders.md](SPEC/program/orders.md) — prospect order: mineral-eligible terrain list to include **desert**.

**Referenced specs:**
- [SPEC/game/resource-terrain-region-rules.md](SPEC/game/resource-terrain-region-rules.md)
- [SPEC/game/fog-and-exploration.md](SPEC/game/fog-and-exploration.md)
- [SPEC/program/orders.md](SPEC/program/orders.md)
- [SPEC/game/tile-map-and-generation.md](SPEC/game/tile-map-and-generation.md)
- [SPEC/game/extraction-and-improvements.md](SPEC/game/extraction-and-improvements.md)

**What needs to be done:**
1. **Spec updates:** Apply the three spec edits above.
2. **Implement:** Add `TerrainType.desert` in `packages/colonizethis_data/lib/src/terrain_type.dart`; set diamonds to desert in `resource_rules.dart`; add desert to New World only in `terrain_region_rules.dart` (list + distribution weight); add `'desert'` to `combat_config.dart` `terrainModifiers`; add desert color and label in `tile_map_visualization_shared.dart` and `tile_map_visualization.dart`; update Province terrain comment in `province.dart` if desired.
3. **Test:** Update or add tests for terrain count / diamond terrain (resource_rules, terrain_region_rules, combat_config); adjust tile_map_generator_test and tile_map_visualization_test if they assert on number of terrain types (e.g. 6 instead of 5).

**Complexity:** Small

---

### Task: Implement Mineral Prospecting Gate

**Status:** **Done** (verified). playerProspectedTiles, prospect work order, extraction gates; tests in resource_extractor_test, orders_application_test, order_visibility_test.

**Gap (resolved):** Minerals require prospecting before extraction; implemented and tested.

**Referenced specs:**
- [SPEC/game/extraction-and-improvements.md](SPEC/game/extraction-and-improvements.md) — Mineral Prospecting Gate section
- [SPEC/game/fog-and-exploration.md](SPEC/game/fog-and-exploration.md)

**What needs to be done:**
1. Add `prospected` flag to tile state
2. Add Explorer work order to prospect tiles
3. Modify extraction to skip non-prospected mineral tiles
4. Add unit test for prospecting workflow

**Complexity:** Small

---

### Task: Verify and Complete Worker/Population Model

**Status:** Food consumption and starvation verified and tested (economy_consumption_test, economy_logic_test). Luxury and training deferred per spec MVP note.

**Gap:** Worker model exists (`WorkerPool`). Food and starvation implemented; luxury and training deferred.

| Component | Spec Reference | Status |
|-----------|----------------|--------|
| Worker tiers (Peasant/Journeyman/Master) | `workers-and-population.md` | **Done** — model and consumption |
| Food consumption | `workers-and-population.md` | **Done** — 1/2 food per tier, tested |
| Luxury consumption | `workers-and-population.md` | Deferred (MVP scope) |
| Starvation (worker death) | `workers-and-population.md` | **Done** — order peasants first, tested |
| Training (tier upgrade) | `workers-and-population.md` | Deferred (CLARIFICATION NEEDED) |

**Referenced specs:**
- [SPEC/game/workers-and-population.md](SPEC/game/workers-and-population.md)

**What needs to be done:**
1. Verify food consumption in `economy_consumption.dart` matches spec (1 grain+meat per tier)
2. Verify luxury consumption for trained workers (sugar, cigars, furs)
3. Verify starvation removes workers when food cannot be met
4. Implement worker training (fabric + paper + cash → next tier)

**Complexity:** Medium

---

## P2: Medium Priority — Noticeable Gap

### Task: Complete Ship Reveal Mechanic

**Status:** **Done** (verified). turn_resolver applies ship reveal on fleet enter sea zone (coastal tiles → revealed for owner).

**Referenced specs:**
- [SPEC/game/ships-and-naval.md](SPEC/game/ships-and-naval.md) — Ship Reveal Mechanic section

**What needs to be done:**
1. When fleet enters sea zone, find adjacent coastal provinces
2. Set those provinces' tiles to `VisibilityLevel.revealed` for the player
3. This enables Explorer deployment to New World

**Complexity:** Small

---

### Task: Complete Capital Choice Phase

**Status:** **Done** (verified). capital_choice_test.dart covers isProvinceSeaBound, setCapital with auto-port.

| Component | Spec Reference | Status |
|-----------|----------------|--------|
| Sea-bound capital requirement | `capital-choice-phase.md` | Needs verification |
| Auto-port building | `capital-and-connectivity.md` | Implemented |
| Auto-road from port to capital | `capital-and-connectivity.md` | Implemented |

**Referenced specs:**
- [SPEC/game/capital-choice-phase.md](SPEC/game/capital-choice-phase.md)
- [SPEC/game/capital-and-connectivity.md](SPEC/game/capital-and-connectivity.md)

**What needs to be done:**
1. Verify capital selection enforces sea-bound province
2. Verify auto-port and auto-road on selection
3. Test edge case: capital province is already coastal

**Complexity:** Small

---

### Task: Complete Minor Nation Military Parity

**Status:** **Done** (verified). applyMinorMilitaryParity at start of Combat phase in turn_resolver; minor_military_parity_test.dart exists.

**Referenced specs:**
- [SPEC/game/factions.md](SPEC/game/factions.md) — Minor military parity section

**What needs to be done:**
1. Verify parity is applied at start of Combat phase (not elsewhere)
2. Verify damaged units stay damaged during upgrade (templates regenerated)
3. Verify minor nations only in Old World

**Complexity:** Small

---

### Task: Complete Quick Battle UI Integration

**Gap:** `QuickBattleResolver` and models exist, but player interaction (tactical mode) is not integrated into the app:

| Component | Spec Reference | Status |
|-----------|----------------|--------|
| Lane/line battlefield layout | `quick-battle.md` | Model exists |
| Cohesion (morale) system | `quick-battle.md` | Implemented |
| Command Point actions | `quick-battle.md` | Not in UI |
| Terrain modifiers per lane | `quick-battle.md` | Not wired to combat |
| Player input for actions | `quick-battle.md` | Not implemented |

**Referenced specs:**
- [SPEC/game/quick-battle.md](SPEC/game/quick-battle.md)
- [SPEC/program/quick-battle-resolution.md](SPEC/program/quick-battle-resolution.md)

**What needs to be done:**
1. Integrate QuickBattle screen into app (Flutter + Flame)
2. Implement lane selection and CP spending UI
3. Wire terrain modifiers from province to lane
4. Connect resolver output to combat casualty pipeline

**Complexity:** Large (UI integration)

---

### Task: Complete Diplomacy Full Actions

**Gap:** `DiplomacyResolver` exists but many diplomatic actions are incomplete:

| Missing Action | Spec Reference | Status |
|----------------|----------------|--------|
| Join Empire (GP absorbing GP) | `diplomacy.md` | Not implemented |
| Alliance with mutual defense | `diplomacy.md` | Partial |
| Subsidies (trade) | `diplomacy.md` | **Done** — SetSubsidy in resolver; GP→GP transfer, GP→Minor relation +3 |
| Foreign aid grants | `diplomacy.md` | **Done** — GrantAid in resolver |
| Intervention (protecting Minor) | `diplomacy.md` | Resolver helpers exist; wire into combat flow for full flow |

**Referenced specs:**
- [SPEC/game/diplomacy.md](SPEC/game/diplomacy.md)
- [SPEC/program/diplomacy-resolution.md](SPEC/program/diplomacy-resolution.md)

**What needs to be done:**
1. Implement Join Empire — removes target GP, transfers provinces
2. Implement Alliance — mutual defense clause triggers on ally attack
3. ~~Implement Subsidies~~ — **Done.** SetSubsidy in diplomacy_resolver; consulate/embassy required; GP→GP treasury transfer, GP→Minor/Tribe relation +3.
4. ~~Implement Foreign Aid~~ — **Done.** GrantAid in diplomacy_resolver.
5. Wire Intervention — needsInterventionChoice/applyInterventionChoice exist; call from combat/turn flow when Minor with Embassy is attacked

**Complexity:** Medium

---

### Task: Complete Auto-Transport Priority Logic

**Status:** Priority-based allocation implemented (allocateOverseasToStockpile by CommodityCategory). Cargo stub per spec Phase 2; sum-of-ships deferred.

**Gap (resolved):** Priority order and "leave remainder behind" are implemented.

**Referenced specs:**
- [SPEC/program/auto-transport.md](SPEC/program/auto-transport.md) — Priority ordering section

**Priority order:**
1. Critical Food (grain, meat)
2. Raw Materials (iron, coal, lumber)
3. Food Variety (fish, dairy)
4. Riches (gold, silver, gems)
5. Trade Goods (textiles, spices)
6. Luxury (wine, tobacco)

**What needs to be done:**
1. Implement priority-based allocation when cargo full
2. Implement cargo hold limit calculation (sum of ship cargo)
3. Leave remainder behind when cargo full

**Complexity:** Small

---

## P3: Nice to Have — Post-MVP

### Task: Add Victory Screen to UI

**Status:** **Done.** When `Game.victory != null`, ctdev shows a victory overlay (winner name, type, turn) with "Return to main menu" and "View final state".

**Referenced specs:**
- [SPEC/game/victory.md](SPEC/game/victory.md) — Victory Screen section

**What needs to be done:**
1. When `Game.victory != null`, show victory overlay
2. Display winner name, victory type, turn number
3. Provide "return to main menu" and "view final state" options

**Complexity:** Small (UI)

---

### Task: Verify Fog Decay Implementation

**Status:** **Done** (verified). Tests in turn_resolver_test: endOfTurn applies fog decay when no Explorer/Spy; Explorer in other-faction province prevents decay. Resolver fix: explorer type check case-insensitive; province id uses localIdFrom for consistency.

**Referenced specs:**
- [SPEC/game/fog-and-exploration.md](SPEC/game/fog-and-exploration.md)

**What needs to be done:**
1. Verify decay happens in End-of-Turn phase
2. Verify Explorer/Spy presence prevents decay
3. Verify other-faction provinces fog correctly

**Complexity:** Small

---

## Test Coverage Summary

### colonizethis_logic: Files Without Dedicated Tests

| Module | File | Priority | Note |
|--------|------|----------|------|
| Consumption | `economy/economy_consumption.dart` | P0 | economy_consumption_test.dart |
| Extraction | `economy/economy_extraction.dart` | P0 | economy_extraction_test.dart |
| Production | `economy/economy_production.dart` | P0 | economy_production_test.dart |
| Riches to Treasury | `economy/economy_riches_to_treasury.dart` | P0 | economy_riches_to_treasury_test.dart |
| Research Resolver | `turn/research_resolver.dart` | P0 | Covered by research_phase_test.dart |
| Province Lookup | `world/province_lookup.dart` | P0 | province_lookup_test.dart exists |
| Simple AI Heuristics | `ai/simple_ai_heuristics.dart` | P0 | simple_ai_heuristics_test.dart exists |
| Constants | `constants.dart` | P0 | constants_test.dart exists |

### Coverage Status

- **Total lib files:** 37
- **Test files:** 40 (including characterization tests)
- **Files without dedicated tests:** 8 (22%)

Target: **90% coverage** per project rules. Current gap is primarily in economy modules.

---

---

## Completed (Verified)

Tasks below have been verified against the codebase and are implemented. Date: 2025-02.

| Task | Verification |
|------|--------------|
| Fix Research Funding Values | research_resolver.dart: 50/150/400/1000 gold, 100/300/800/2500 RP; research_phase_test asserts. |
| Add Desert Terrain | TerrainType.desert, diamonds on desert, terrain_region_rules, combat_config, specs updated. |
| Mineral Prospecting Gate | playerProspectedTiles, prospect work order, extraction gates; tests in resource_extractor_test, orders_application_test, order_visibility_test. |
| Ship Reveal Mechanic | turn_resolver: fleet enter sea zone → coastal tiles revealed for owner. |
| Add Tests for Core Logic | province_lookup_test, simple_ai_heuristics_test, constants_test, research_phase_test exist. |
| Add Tests for Economy Modules | economy_consumption/extraction/production/riches_to_treasury_test + research_phase_test cover research resolver. |
| Minor Nation Military Parity | applyMinorMilitaryParity at start of _runCombatPhase; minor_military_parity_test. |
| Capital Choice Phase | capital_choice_test: isProvinceSeaBound, setCapital with auto-port. |
| Complete Trade/Transport Raids Integration | applyTradeInterception in sea_transport.dart; wired in turn_resolver; sea_transport_test. |
| Siege (core numbers) | fortDamageReduction 0/25/45/60%, wallHpByFortLevel, fortGunCount in combat_config and combat_resolver. |
| Verify Fog Decay | Tests in turn_resolver_test; Explorer/Spy prevents decay; resolver uses case-insensitive type and localIdFrom. |
| Add Victory Screen | Victory overlay in ctdev when game.victory != null; return to menu and view final state. |

---

## References

- [SPEC/game/](SPEC/game/) — Game design documents (GDD)
- [SPEC/program/](SPEC/program/) — Technical design documents (TDD)
- [colonizethis_logic/lib/src/](packages/colonizethis_logic/lib/src/) — Implementation
- [colonizethis_logic/test/](packages/colonizethis_logic/test/) — Tests
- [tool/test_coverage.py](tool/test_coverage.py) — Coverage script
