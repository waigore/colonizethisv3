# Phase 2 — Project tasks

**SPEC/project** — Actionable task list for Phase 2. Economy and units follow **GDD 04, 04b, 05** and **TDD 04, 05**; SPEC is the in-repo reflection. Full workflow: **Design → Dev → Test → Code review** per [mvp-scope.md](mvp-scope.md).

**Phasing:** Previous — [phase-1-project-tasks.md](phase-1-project-tasks.md). Next — [phase-3-project-tasks.md](phase-3-project-tasks.md).

---

## Purpose

Phase 2 establishes the economy (commodities, stockpiles, production, auto-transport, workers), a **subset of civilian units plus one military type**, **movement and ownership**, and turn-resolution phases for extraction, production, consumption, and movement. New World exploitation means provinces in both regions can be owned and produce; no separate "colony" entity. Do not advance to Phase 3 until Phase 2 code review is complete.

---

## Scope (Phase 2)

- **Economy:** Centralized stockpile per player; extraction from owned province tiles → stockpile; production (recipes + labour) and consumption (workers, one military type); auto-transport (land automatic/unlimited; sea simplified or stubbed).
- **Units:** Subset of civilians (to be specified in design: e.g. Explorer, Builder, Engineer only) + **one military type** (e.g. Regiment); movement between adjacent provinces; ownership and location in world state.
- **Turn resolution:** Phases implemented for extraction, production, consumption, movement (order validation and application); no combat or diplomacy.
- **New World:** Same ownership and extraction rules as Old World; "colonies" = owned New World provinces.
- **Factions:** Three types (Great Power, Minor Nation, Tribe) per Imperialism II baseline; only Great Powers give orders and can win; minors/tribes reactive (defend, trade, diplomacy targets). Game holds 7 Great Powers plus Minor Nations and Tribes; ownership by faction id.
- **Game setup:** Pre-game phases: world generation (procedural OW + NW), province and capital assignment for GPs then minors then tribes, creation of all factions and initial state. Configurable GP count (default 7), continent count, minor count, tribe count.

---

## Design tasks

All design deliverables must accord with **GDD 04, 04b, 05** and **TDD 04, 05**. Each Phase 2 SPEC sub-doc must stay **≤500 words**; split further if needed. Resolve any conflict between economy, unit, and turn-resolution specs before implementation.

| Task | Description | Deliverable |
|------|-------------|-------------|
| **Commodities and production recipes** | Define commodity catalog (ids, categories: food, raw, manufactured, luxury, riches), where stored (colonizethis_data); production recipes (inputs, outputs, labour per output), where stored; overflow/capacity rules for stockpile. Derive from GDD 04 / TDD 04. | [commodity-catalog.md](../game/commodity-catalog.md), [production-recipes.md](../game/production-recipes.md) (each ≤500 words). |
| **Capital and connectivity** | Define capital (province + tile), capital-choice phase, sea-bound rule, capital port/road auto-build, connectivity rule (tile to capital tile via roads/port), overseas definition, recompute each turn. | [capital-and-connectivity.md](../game/capital-and-connectivity.md), optional [capital-choice-phase.md](../game/capital-choice-phase.md). |
| **Tech and extraction cap** | Per-player tech table (key-value); static tech list in colonizethis_data; extraction cap from tech (or constant for Phase 2). | [tech-and-extraction-cap.md](../game/tech-and-extraction-cap.md) (≤500 words). |
| **Extraction pipeline (technical)** | Connectivity resolver (inputs, output, algorithm summary); resource extractor (inputs, effective yield and transport level, output per-player land vs overseas); integration with extraction phase. | [extraction-pipeline.md](../program/extraction-pipeline.md) (≤500 words). |
| **Extraction and improvements** | Define extraction formula (per-tile: improvement level, effective = min(level, owner tech cap)); transport level (0/1/2/4), effective yield = min(production, transport level); improvement types, roads per tile, ports per seaboard; flow to stockpile. Align with [tile-map-and-generation.md](../game/tile-map-and-generation.md) and GDD 04b. | [extraction-and-improvements.md](../game/extraction-and-improvements.md) (≤500 words). |
| **Auto-transport (technical)** | Input from resource extractor; land = all same-region to stockpile; sea = overseas only, cargo-hold limit (stub), priority allocation. Output: stockpile updated. | [auto-transport.md](../program/auto-transport.md) (≤500 words). |
| **Unit subset** | Define which civilian unit types are in scope (e.g. Explorer, Builder, Engineer only; Spy, Merchant, Rail Builder deferred); one military unit type (e.g. Regiment) with cost and upkeep; no navy. Reference [civilian-units.md](../game/civilian-units.md) and GDD 05. | [unit-types.md](../game/unit-types.md) (≤500 words). |
| **Movement and orders (technical)** | Define movement rules (adjacency from topology, land only); order types: MoveOrder, BuildUnitOrder, WorkOrder (explore, build improvement, prospect); validation (topology, costs, caps); resolution (apply moves, apply builds, apply work). | [movement.md](../program/movement.md), [orders.md](../program/orders.md) (each ≤500 words). |
| **Turn resolution expansion** | Full phase sequence (orders → extraction → production → consumption → movement → end-of-turn); extraction phase: connectivity → extract → land add → sea add. Reference [extraction-pipeline.md](../program/extraction-pipeline.md), [capital-and-connectivity.md](../game/capital-and-connectivity.md). | [turn-resolution.md](../program/turn-resolution.md) (extend), [turn-resolution-phases.md](../program/turn-resolution-phases.md) (new; ≤500 words). |
| **New World exploitation** | State explicitly: New World provinces can be owned; extraction and production work identically to Old World; "colonies" = owned New World provinces; no separate colony entity. | Subsection in [world-model.md](../game/world-model.md) or [new-world-exploitation.md](../game/new-world-exploitation.md) (≤500 words). |
| **sim_economy design** | Specify a standalone CLI tool (`melo sim_economy`) that reuses Phase 2 economy rules to simulate a single player’s stockpile and WorkerPool over N turns. Define CLI interface (including optional JSON script, random-start default mode, and `--seed`), JSON script schema, initial-state ranges, default extraction/assignment behaviour, and how it aligns with extraction/production/consumption phases. | [sim-economy.md](../program/sim-economy.md) (≤500 words). |
| **Turn-time mapping** | Define turn-to-calendar-year formula (configurable, GDD 01 default); parameters in ruleset contract; formula fixed at game creation. | [turn-time-mapping.md](../game/turn-time-mapping.md) (≤500 words). |
| **Factions** | Define three faction types (Great Power, Minor Nation, Tribe) per Imperialism II: what each can/cannot do (win, orders, provinces, capital, military, navy, trade, diplomacy, research, combat). Only Great Powers give orders; minors/tribes reactive. OW minor military parity: formula so minor unit types at least as advanced as average of all Great Powers. | [factions.md](../game/factions.md) (≤500 words). |
| **Game setup** | Pre-game phases: config (GP count, continent count, minor count, tribe count); world generation (OW + NW); province and capital assignment for GPs (fair, land-connected, sea-bound capital); assignment of remaining OW to minors, NW to tribes; create all factions and initial state. Capital-choice for GPs only. | [game-setup.md](../game/game-setup.md) (≤500 words). |
| **Game-setup pipeline (technical)** | Orchestration: config → map gen (OW, NW) → province/capital assignment → build Game and WorldState with all factions. | [game-setup-pipeline.md](../program/game-setup-pipeline.md) (≤500 words). |

**Existing specs to align (no new file):** [stockpiles-and-production.md](../game/stockpiles-and-production.md), [workers-and-population.md](../game/workers-and-population.md), [civilian-units.md](../game/civilian-units.md), [economy-models.md](../program/economy-models.md) — ensure Phase 2 subset and program-level config (no JSON rulesets in MVP) are referenced.

---

## Dev tasks

Order matters. Implement in sequence; each task assumes the previous is done.

| # | Task | Description |
|---|------|-------------|
| 1 | **Economy models (colonizethis_models)** | Add Stockpile (commodity id → quantity), WorkerPool (tiers/counts), Player.stockpile, Player.workerPool, Player.treasury; commodity enum or id type per spec. Serialization and round-trip for save. |
| 2 | **World state: tile state and capital (colonizethis_models)** | Add mutable tile state (improvement level, road level) keyed by (region, province, tile); port per (province, seaboard) or per tile with seaboard; Player.capitalProvinceId, Player.capitalTile. Serialization. May be split with Capital choice phase if that is a separate flow. |
| 3 | **Turn-time mapping (colonizethis_models + colonizethis_logic)** | Add TurnTimeMapping model (startYear, cutoffYear, yearsPerTurnBefore/After); default in colonizethis_data; Game.turnTimeMapping; turnToYear() in colonizethis_logic; serialize with Game; backward compat for legacy saves. |
| 4 | **Faction model (colonizethis_models)** | Add Faction type (greatPower \| minorNation \| tribe) or separate MinorNation/Tribe types; Game holds list of Players (GPs) and list of MinorNations and Tribes (or single Factions list with type). Province.ownerId and Unit.ownerId = faction id. All factions have capital (capitalProvinceId, capitalTile); minors/tribes set from setup. Serialization. |
| 5 | **Game setup orchestration (colonizethis_logic or app)** | Implement game creation per [game-setup-pipeline.md](../program/game-setup-pipeline.md): load config (GP count, continent count, minor count, tribe count); call map gen for OW and NW; run province/capital assignment for GPs then minors then tribes; build initial WorldState and Game with all factions. Integrate with GameService.createNewGame or equivalent. |
| 6 | **Minor military parity (design only in Phase 2)** | No implementation required in Phase 2; formula and intent specified in [factions.md](../game/factions.md). Implementation deferred to phase with combat (e.g. Phase 3). Optionally: add field on Minor Nation for effectiveMilitaryLevel (or equivalent) for future use. |
| 7 | **Connectivity resolver (colonizethis_logic)** | Implement connectivity resolver per [extraction-pipeline.md](../program/extraction-pipeline.md); input: game + tile maps + topology; output: per-player connected tiles or per-province connected flag. Unit-test with small grid. |
| 8 | **Resource extractor (colonizethis_logic)** | Implement resource extractor using connectivity resolver; output per-player land and overseas commodity totals; use tech cap (from player tech table or constant). Unit-test with stub connectivity. |
| 9 | **Unit and order models (colonizethis_models)** | Extend Unit: type (civilian subset + one military), owner, location (province id), status (idle, working, done), movement points if required. Orders: MoveOrder, BuildUnitOrder, WorkOrder (structure per [orders.md](../program/orders.md)). |
| 10 | **Commodity catalog and recipes (colonizethis_data)** | Define commodity list and production recipes (inputs, outputs, labour) as program-level constants; consumed by colonizethis_logic. No JSON; single source per mvp-scope. |
| 11 | **Extraction resolution (colonizethis_logic)** | Extraction phase: call connectivity resolver, then resource extractor; add land totals to stockpile; call sea transport (cargo stub, priority); add overseas to stockpile. Remove dependency on caller-supplied extractedByPlayerId for normal play; keep optional override for tests/sim_economy if desired. |
| 12 | **Auto-transport (colonizethis_logic)** | Land: no separate step (handled in extraction). Sea: allocate overseas extraction to stockpile by priority, capped by cargo holds (stub). Validation: stockpile capacity. Per [auto-transport.md](../program/auto-transport.md). |
| 13 | **Production resolution (colonizethis_logic)** | Consume recipe inputs and labour from stockpile and WorkerPool; produce outputs to stockpile. Handle insufficient inputs (skip or partial per spec). |
| 14 | **Consumption resolution (colonizethis_logic)** | Workers consume food (and luxuries per tier) from stockpile; one military type consumes upkeep from stockpile; starvation/upkeep rules per spec. |
| 15 | **TurnResolver Phase 2 phases** | Implement extraction, production, consumption, movement phases in TurnResolver; call extraction, production, consumption, movement in sequence per turn-resolution spec; end-of-turn advances turn number. |
| 16 | **Movement resolution (colonizethis_logic)** | Load topology from colonizethis_data; validate MoveOrders (adjacent province); apply moves (update unit locations). No combat. |
| 17 | **Order application** | Apply BuildUnitOrder (deduct cost from stockpile, add unit to world state; worker consumed for military per workers spec). WorkOrder: minimal or stub (e.g. set unit status working; no terrain change yet) or one improvement type per [unit-types.md](../game/unit-types.md). |
| 18 | **Capital-choice phase (setup)** | UI or scenario to set capital province + tile; validate sea-bound; apply capital port/road auto-build; persist. Or stub/scenario-only for Phase 2 if UI deferred. |
| 19 | **Wire app to Phase 2** | App (or service) passes orders into resolve; TurnResolver uses orders in movement and build phases; save/load includes stockpile, workers, units, orders, tile state, capital. Riverpod exposes updated state. |
| 20 | **sim_economy CLI** | Implement `melo sim_economy` as a standalone Dart CLI that parses an optional JSON script, constructs an initial player state (stockpile, WorkerPool, optional military and treasury) using `colonizethis_models` and `colonizethis_data`, runs the scripted or default turn loop by delegating to `colonizethis_logic` for extraction/production/consumption, and produces human-readable and optional machine-readable logs. |

---

## Test tasks

Tests follow **test/ mirrors lib/** and **\*_test.dart** naming; use **mockito** or **mocktail** for mocks. Save/load remains a critical path; aim for **90% per-package coverage** for Phase 2 packages (colonizethis_models, colonizethis_logic, colonizethis_data where extended).

| Task | Success criteria |
|------|------------------|
| **Build passes** | `flutter pub get` and `flutter build` succeed for app and all packages. |
| **Unit tests — economy models** | Stockpile add/deduct, WorkerPool tier counts, serialization. |
| **Unit tests — turn-time mapping** | turnToYear returns 1500 for turn 1, 1700 for turn 101, 1702 for turn 103; custom mapping works; legacy Game without turnTimeMapping uses default. |
| **Unit tests — faction model** | Faction type (or MinorNation/Tribe) serialization; Game with players + minors + tribes round-trip; Province.ownerId and Unit.ownerId accept faction id. |
| **Unit / integration — game setup** | Game creation with config produces correct number of GPs, minors, tribes; provinces assigned to factions; each GP has one capital; minors/tribes have capitals from setup. |
| **Unit tests — connectivity** | Given a small tile map, provinces, roads, capital tile; connectivity resolver returns expected connected tiles; losing a province breaks connectivity as specified. |
| **Unit tests — extraction** | Given connectivity and tile state (improvements, transport levels), resource extractor returns expected land and overseas totals; tech cap and transport level cap applied. |
| **Unit tests — sea transport** | Overseas totals plus cargo-hold stub: allocation by priority respects cap; excess not added to stockpile. |
| **Unit tests — production** | Given stockpile and WorkerPool, production resolution consumes inputs and labour and adds outputs per recipe. |
| **Unit tests — consumption** | Workers and military consume food/upkeep from stockpile; starvation/upkeep rules applied. |
| **Unit tests — movement** | Adjacency validation using topology; apply move order updates unit location; invalid destination rejected. |
| **Unit tests — orders** | BuildUnitOrder deducts cost and adds unit; WorkOrder stub sets status or applies one improvement type. |
| **Integration test — one full turn** | Run TurnResolver for one turn with initial state (provinces, tiles, units, orders); extraction phase uses resolver + extractor; land and overseas (with stub cargo) applied to stockpile; assert stockpile deltas, cargo limit behaviour, production/consumption applied, movement applied, turn number incremented. |
| **Save/load round-trip (critical path)** | Save game state with stockpile, workers, units, orders, tile state, capital; load and assert key fields match. |
| **Per-package coverage** | colonizethis_models, colonizethis_logic (and colonizethis_data if extended) aim for 90%; enforce in CI where applicable. |
| **sim_economy tests** | Unit tests for sim_economy script parsing and validation (invalid ids, malformed structure), plus golden-style tests where a short script or default random-start run yields an expected stockpile and WorkerPool after N turns; optionally cross-check one scripted turn against TurnResolver economy phases for behavioural alignment. |

---

## Code review tasks

Before marking Phase 2 complete, verify:

| Check | Criteria |
|-------|----------|
| **Package boundaries** | Economy logic in colonizethis_logic; models in colonizethis_models; commodity/recipe constants in colonizethis_data; no game rules in app. |
| **Spec alignment** | All Phase 2 behavior traceable to a spec section (commodity-catalog, production-recipes, extraction-and-improvements, auto-transport, unit-types, movement, orders, turn-resolution, turn-resolution-phases, capital-and-connectivity, tech-and-extraction-cap, extraction-pipeline, turn-time-mapping, factions, game-setup, game-setup-pipeline); no behavior without authorizing spec. |
| **Phase 2 scope** | No combat, no diplomacy, no navy, no full civilian roster (only specified subset); no JSON rulesets (program-level config only). |
| **State and lifecycle** | State subscriptions and cleanup follow lifecycle conventions; no leaks. |

---

## Definition of done (Phase 2)

Phase 2 is done when all design and dev tasks are implemented, all test tasks pass, and the code review checklist is signed off.

- [ ] All Design deliverables written and agreed.
- [ ] All Dev tasks implemented.
- [ ] All Test tasks passing.
- [ ] Code review checklist signed off.

**Exit criteria:** Economy (stockpile, workers, extraction, production, consumption, auto-transport) works; Phase 2 unit subset and one military type exist; movement and orders resolve; one full turn runs correctly; save/load includes Phase 2 state; ready for Phase 3 (combat).

---

## Dependencies and order

- **Design** must be done before Dev. All Phase 2 SPEC docs (game + program) must be in repo and agreed.
- **Dev:** Models first (economy, tile state and capital, then units/orders), then colonizethis_data (commodities, recipes, tech list), then colonizethis_logic (connectivity resolver → resource extractor → extraction phase → auto-transport → production → consumption → movement → order application), then TurnResolver wiring, then app wiring.
- **Test** and **Code review** after Dev.

---

## Out of scope for Phase 2

- Combat, diplomacy, AI (Phases 3–4).
- Navy, sea movement, cargo holds (Phase 2 land only; sea transport stubbed).
- Full civilian roster (Spy, Merchant, Rail Builder deferred).
- Victory condition, tech tree (Phase 5).
- JSON rulesets / layered config (mvp-scope: out of MVP).
- New UI beyond wiring (Phase 6 pixel-art and main menu).

---

## References

- **GDD 04, 04b, 05** — Economy, provinces/tiles/terrain, units (Obsidian).
- **TDD 04, 05** — Economy implementation, units implementation (Obsidian).
- [mvp-scope.md](mvp-scope.md) — Phase 2 row: economy, basic units, movement and ownership.
- [SPEC/program/repo-and-packages.md](../program/repo-and-packages.md) — Package list and dependency direction.
- [SPEC/program/turn-resolution.md](../program/turn-resolution.md), [turn-resolution-phases.md](../program/turn-resolution-phases.md) — Phase sequence and per-phase behaviour.
- [SPEC/game/world-model.md](../game/world-model.md) — Core entities; add New World exploitation note.
- [SPEC/game/stockpiles-and-production.md](../game/stockpiles-and-production.md), [SPEC/game/workers-and-population.md](../game/workers-and-population.md), [SPEC/game/civilian-units.md](../game/civilian-units.md), [SPEC/program/economy-models.md](../program/economy-models.md) — Existing specs to align.
- Imperialism II 02-economy (Obsidian) — Transport level table, connectivity, cargo holds.
- GDD 04, TDD 04 — Stockpile flow, transport algorithm, cargo stub.
- `.cursor/rules/colonizethis-testing.mdc` — 90% coverage, critical path (save/load).
- [SPEC/program/sim-economy.md](../program/sim-economy.md) — Standalone economy simulation tool spec.
- [SPEC/game/factions.md](../game/factions.md) — Faction types (Great Power, Minor Nation, Tribe), capabilities, minor military parity.
- [SPEC/game/game-setup.md](../game/game-setup.md) — Pre-game phases and config.
- [SPEC/program/game-setup-pipeline.md](../program/game-setup-pipeline.md) — Technical game creation orchestration.

---

## Summary: Specs to write or extend

| Spec | Action |
|------|--------|
| **SPEC/game/commodity-catalog.md** | New: commodity catalog, categories, overflow (≤500 words). |
| **SPEC/game/production-recipes.md** | New: recipe structure, where stored (≤500 words). |
| **SPEC/game/capital-and-connectivity.md** | New: capital (province + tile), connectivity, overseas, recompute each turn (≤500 words). |
| **SPEC/game/tech-and-extraction-cap.md** | New: per-player tech table, extraction cap (≤500 words). |
| **SPEC/game/capital-choice-phase.md** | New: capital-choice phase, sea-bound, auto-build port/road. Extend: Great Powers only; minors/tribes get capitals from setup (≤500 words). |
| **SPEC/game/extraction-and-improvements.md** | Extend: transport level (0/1/2/4), effective yield, roads per tile, ports per seaboard (≤500 words). |
| **SPEC/game/unit-types.md** | New: civilian subset + one military type (≤500 words). |
| **SPEC/game/world-model.md** | Extend: New World and colonies; Player capital; mutable tile state (improvement, road, port); faction ownership (Province/Unit owner = faction id); Game holds minors + tribes; only GPs submit orders (reference factions.md). |
| **SPEC/program/extraction-pipeline.md** | New: connectivity resolver, resource extractor, extraction phase order (≤500 words). |
| **SPEC/program/auto-transport.md** | Extend: input from resource extractor; land same-region; sea overseas only, cargo stub, priority (≤500 words). |
| **SPEC/program/movement.md** | New: movement rules, adjacency, validation (≤500 words). |
| **SPEC/program/orders.md** | New: order types, validation, resolution (≤500 words). |
| **SPEC/program/turn-resolution.md** | Extend: link to turn-resolution-phases; trim phase wording. |
| **SPEC/program/turn-resolution-phases.md** | Extend: extraction phase (connectivity → extract → land add → sea add); orders = Great Powers only; combat/diplomacy note for minors/tribes; minor military parity step when combat in scope. |
| **SPEC/game/turn-time-mapping.md** | New: turn-to-calendar-year formula, GDD 01 default, configurable per game (≤500 words). |
| **SPEC/game/factions.md** | New: three faction types, capabilities, minor military parity (≤500 words). |
| **SPEC/game/game-setup.md** | New: pre-game phases, config, province/capital assignment (≤500 words). |
| **SPEC/program/game-setup-pipeline.md** | New: technical orchestration of game creation (≤500 words). |
| **SPEC/game/ruleset-config.md** | Extend: game/setup config (GP count, continent count, minor count, tribe count). |
| **SPEC/game/stockpiles-and-production.md**, **workers-and-population.md**, **civilian-units.md**, **program/economy-models.md** | Align with scope and program-level config; no new files required. |

---

## Risks and assumptions

- GDD 04, 04b, 05 and TDD 04, 05 live in Obsidian; SPEC is the in-repo reflection for implementation. Design tasks should sync key structure from GDD/TDD into SPEC before Dev.
- Phase 2 uses program-level config only (no JSON rulesets per mvp-scope). Commodity catalog and recipes live in colonizethis_data as constants.
