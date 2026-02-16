# Phase 2 — Project tasks

**SPEC/project** — Actionable task list for Phase 2. Economy and units follow **GDD 04, 04b, 05** and **TDD 04, 05**; SPEC is the in-repo reflection. Full workflow: **Design → Dev → Test → Code review** per [mvp-scope.md](mvp-scope.md).

**Phasing:** Previous — [phase-1-project-tasks.md](phase-1-project-tasks.md). Next — Phase 3 (combat).

---

## Purpose

Phase 2 establishes the economy (commodities, stockpiles, production, auto-transport, workers), a **subset of civilian units plus one military type**, **movement and ownership**, and turn-resolution phases for extraction, production, consumption, and movement. New World exploitation means provinces in both regions can be owned and produce; no separate "colony" entity. Do not advance to Phase 3 until Phase 2 code review is complete.

---

## Scope (Phase 2)

- **Economy:** Centralized stockpile per player; extraction from owned province tiles → stockpile; production (recipes + labour) and consumption (workers, one military type); auto-transport (land automatic/unlimited; sea simplified or stubbed).
- **Units:** Subset of civilians (to be specified in design: e.g. Explorer, Builder, Engineer only) + **one military type** (e.g. Regiment); movement between adjacent provinces; ownership and location in world state.
- **Turn resolution:** Phases implemented for extraction, production, consumption, movement (order validation and application); no combat or diplomacy.
- **New World:** Same ownership and extraction rules as Old World; "colonies" = owned New World provinces.

---

## Design tasks

All design deliverables must accord with **GDD 04, 04b, 05** and **TDD 04, 05**. Each Phase 2 SPEC sub-doc must stay **≤500 words**; split further if needed. Resolve any conflict between economy, unit, and turn-resolution specs before implementation.

| Task | Description | Deliverable |
|------|-------------|-------------|
| **Commodities and production recipes** | Define commodity catalog (ids, categories: food, raw, manufactured, luxury, riches), where stored (colonizethis_data); production recipes (inputs, outputs, labour per output), where stored; overflow/capacity rules for stockpile. Derive from GDD 04 / TDD 04. | [commodity-catalog.md](../game/commodity-catalog.md), [production-recipes.md](../game/production-recipes.md) (each ≤500 words). |
| **Extraction and improvements** | Define extraction formula (per-tile: improvement level, effective = min(level, owner tech cap)); flow from province tiles to owning player stockpile; improvement types (mines, farms, etc.) and max level. Align with [tile-map-and-generation.md](../game/tile-map-and-generation.md) and GDD 04b. | [extraction-and-improvements.md](../game/extraction-and-improvements.md) (≤500 words). |
| **Auto-transport (technical)** | Define algorithm ownership (colonizethis_logic); land = automatic, unlimited, no allocation; sea = stub (e.g. all extracted goods to stockpile) or simple priority. Input: per-province extracted quantities, player stockpile; output: stockpile updated. | [auto-transport.md](../program/auto-transport.md) (≤500 words). |
| **Unit subset** | Define which civilian unit types are in scope (e.g. Explorer, Builder, Engineer only; Spy, Merchant, Rail Builder deferred); one military unit type (e.g. Regiment) with cost and upkeep; no navy. Reference [civilian-units.md](../game/civilian-units.md) and GDD 05. | [unit-types.md](../game/unit-types.md) (≤500 words). |
| **Movement and orders (technical)** | Define movement rules (adjacency from topology, land only); order types: MoveOrder, BuildUnitOrder, WorkOrder (explore, build improvement, prospect); validation (topology, costs, caps); resolution (apply moves, apply builds, apply work). | [movement.md](../program/movement.md), [orders.md](../program/orders.md) (each ≤500 words). |
| **Turn resolution expansion** | Full phase sequence (orders → extraction → production → consumption → movement → end-of-turn); define what each phase does (extraction: tile yields → stockpile; production: recipes + labour; consumption: workers + military; movement: apply move orders). | [turn-resolution.md](../program/turn-resolution.md) (extend), [turn-resolution-phases.md](../program/turn-resolution-phases.md) (new; ≤500 words). |
| **New World exploitation** | State explicitly: New World provinces can be owned; extraction and production work identically to Old World; "colonies" = owned New World provinces; no separate colony entity. | Subsection in [world-model.md](../game/world-model.md) or [new-world-exploitation.md](../game/new-world-exploitation.md) (≤500 words). |
| **sim_economy design** | Specify a standalone CLI tool (`melo sim_economy`) that reuses Phase 2 economy rules to simulate a single player’s stockpile and WorkerPool over N turns. Define CLI interface (including optional JSON script, random-start default mode, and `--seed`), JSON script schema, initial-state ranges, default extraction/assignment behaviour, and how it aligns with extraction/production/consumption phases. | [sim-economy.md](../program/sim-economy.md) (≤500 words). |

**Existing specs to align (no new file):** [stockpiles-and-production.md](../game/stockpiles-and-production.md), [workers-and-population.md](../game/workers-and-population.md), [civilian-units.md](../game/civilian-units.md), [economy-models.md](../program/economy-models.md) — ensure Phase 2 subset and program-level config (no JSON rulesets in MVP) are referenced.

---

## Dev tasks

Order matters. Implement in sequence; each task assumes the previous is done.

| # | Task | Description |
|---|------|-------------|
| 1 | **Economy models (colonizethis_models)** | Add Stockpile (commodity id → quantity), WorkerPool (tiers/counts), Player.stockpile, Player.workerPool, Player.treasury; commodity enum or id type per spec. Serialization and round-trip for save. |
| 2 | **Unit and order models (colonizethis_models)** | Extend Unit: type (civilian subset + one military), owner, location (province id), status (idle, working, done), movement points if required. Orders: MoveOrder, BuildUnitOrder, WorkOrder (structure per [orders.md](../program/orders.md)). |
| 3 | **Commodity catalog and recipes (colonizethis_data)** | Define commodity list and production recipes (inputs, outputs, labour) as program-level constants; consumed by colonizethis_logic. No JSON; single source per mvp-scope. |
| 4 | **Extraction resolution (colonizethis_logic)** | For each owned province, compute per-tile extraction (effective = min(improvement level, tech cap)); sum by commodity; add to owning player stockpile. Tech cap can be stub (e.g. max level 4) for Phase 2. |
| 5 | **Auto-transport (colonizethis_logic)** | Land: extraction output already flows to stockpile (no separate step). Sea: stub or simple: all extracted goods to stockpile. Per auto-transport spec. |
| 6 | **Production resolution (colonizethis_logic)** | Consume recipe inputs and labour from stockpile and WorkerPool; produce outputs to stockpile. Handle insufficient inputs (skip or partial per spec). |
| 7 | **Consumption resolution (colonizethis_logic)** | Workers consume food (and luxuries per tier) from stockpile; one military type consumes upkeep from stockpile; starvation/upkeep rules per spec. |
| 8 | **TurnResolver Phase 2 phases** | Implement extraction, production, consumption, movement phases in TurnResolver; call extraction, production, consumption, movement in sequence per turn-resolution spec; end-of-turn advances turn number. |
| 9 | **Movement resolution (colonizethis_logic)** | Load topology from colonizethis_data; validate MoveOrders (adjacent province); apply moves (update unit locations). No combat. |
| 10 | **Order application** | Apply BuildUnitOrder (deduct cost from stockpile, add unit to world state; worker consumed for military per workers spec). WorkOrder: minimal or stub (e.g. set unit status working; no terrain change yet) or one improvement type per [unit-types.md](../game/unit-types.md). |
| 11 | **Wire app to Phase 2** | App (or service) passes orders into resolve; TurnResolver uses orders in movement and build phases; save/load includes stockpile, workers, units, orders. Riverpod exposes updated state. |
| 12 | **sim_economy CLI** | Implement `melo sim_economy` as a standalone Dart CLI that parses an optional JSON script, constructs an initial player state (stockpile, WorkerPool, optional military and treasury) using `colonizethis_models` and `colonizethis_data`, runs the scripted or default turn loop by delegating to `colonizethis_logic` for extraction/production/consumption, and produces human-readable and optional machine-readable logs. |

---

## Test tasks

Tests follow **test/ mirrors lib/** and **\*_test.dart** naming; use **mockito** or **mocktail** for mocks. Save/load remains a critical path; aim for **80% per-package coverage** for Phase 2 packages (colonizethis_models, colonizethis_logic, colonizethis_data where extended).

| Task | Success criteria |
|------|------------------|
| **Build passes** | `flutter pub get` and `flutter build` succeed for app and all packages. |
| **Unit tests — economy models** | Stockpile add/deduct, WorkerPool tier counts, serialization. |
| **Unit tests — extraction** | Given a small world (owned provinces, tiles with improvements), extraction resolution adds expected quantities to player stockpile; effective cap by tech stub. |
| **Unit tests — production** | Given stockpile and WorkerPool, production resolution consumes inputs and labour and adds outputs per recipe. |
| **Unit tests — consumption** | Workers and military consume food/upkeep from stockpile; starvation/upkeep rules applied. |
| **Unit tests — movement** | Adjacency validation using topology; apply move order updates unit location; invalid destination rejected. |
| **Unit tests — orders** | BuildUnitOrder deducts cost and adds unit; WorkOrder stub sets status or applies one improvement type. |
| **Integration test — one full turn** | Run TurnResolver for one turn with initial state (provinces, tiles, units, orders); assert extraction added to stockpile, production/consumption applied, movement applied, turn number incremented. |
| **Save/load round-trip (critical path)** | Save game state with stockpile, workers, units, orders; load and assert key fields match. |
| **Per-package coverage** | colonizethis_models, colonizethis_logic (and colonizethis_data if extended) aim for 80%; enforce in CI where applicable. |
| **sim_economy tests** | Unit tests for sim_economy script parsing and validation (invalid ids, malformed structure), plus golden-style tests where a short script or default random-start run yields an expected stockpile and WorkerPool after N turns; optionally cross-check one scripted turn against TurnResolver economy phases for behavioural alignment. |

---

## Code review tasks

Before marking Phase 2 complete, verify:

| Check | Criteria |
|-------|----------|
| **Package boundaries** | Economy logic in colonizethis_logic; models in colonizethis_models; commodity/recipe constants in colonizethis_data; no game rules in app. |
| **Spec alignment** | All Phase 2 behavior traceable to a spec section (commodity-catalog, production-recipes, extraction-and-improvements, auto-transport, unit-types, movement, orders, turn-resolution, turn-resolution-phases); no behavior without authorizing spec. |
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
- **Dev:** Models first (economy then units/orders), then colonizethis_data (commodities, recipes), then colonizethis_logic (extraction → auto-transport → production → consumption → movement → order application), then TurnResolver wiring, then app wiring.
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
- `.cursor/rules/colonizethis-testing.mdc` — 80% coverage, critical path (save/load).
 - [SPEC/program/sim-economy.md](../program/sim-economy.md) — Standalone economy simulation tool spec.

---

## Summary: Specs to write or extend

| Spec | Action |
|------|--------|
| **SPEC/game/commodity-catalog.md** | New: commodity catalog, categories, overflow (≤500 words). |
| **SPEC/game/production-recipes.md** | New: recipe structure, where stored (≤500 words). |
| **SPEC/game/extraction-and-improvements.md** | New: extraction formula, improvement levels, flow to stockpile (≤500 words). |
| **SPEC/game/unit-types.md** | New: civilian subset + one military type (≤500 words). |
| **SPEC/game/world-model.md** | Extend: New World and colonies subsection. |
| **SPEC/program/auto-transport.md** | New: land unlimited; sea stub (≤500 words). |
| **SPEC/program/movement.md** | New: movement rules, adjacency, validation (≤500 words). |
| **SPEC/program/orders.md** | New: order types, validation, resolution (≤500 words). |
| **SPEC/program/turn-resolution.md** | Extend: link to turn-resolution-phases; trim phase wording. |
| **SPEC/program/turn-resolution-phases.md** | New: phase sequence and per-phase behaviour (≤500 words). |
| **SPEC/game/stockpiles-and-production.md**, **workers-and-population.md**, **civilian-units.md**, **program/economy-models.md** | Align with scope and program-level config; no new files required. |

---

## Risks and assumptions

- GDD 04, 04b, 05 and TDD 04, 05 live in Obsidian; SPEC is the in-repo reflection for implementation. Design tasks should sync key structure from GDD/TDD into SPEC before Dev.
- Phase 2 uses program-level config only (no JSON rulesets per mvp-scope). Commodity catalog and recipes live in colonizethis_data as constants.
