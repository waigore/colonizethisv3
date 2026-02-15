# Phase 1 — Project tasks

**SPEC/project** — Actionable task list for Phase 1. World model and turn resolution follow **GDD** and **TDD 15 (Technical Architecture)**; the task list and code review are checked against those sources of truth.

**Phasing:** Previous — [phase-0-project-tasks.md](phase-0-project-tasks.md). Next — Phase 2 (when defined).

---

## Purpose

Phase 1 establishes the world model (both regions), turn states, resolution sequence, TurnResolver stub, local resolve, and persistence. It follows the full workflow from [mvp-scope.md](mvp-scope.md): **Design → Dev → Test → Code review**. Do not advance to Phase 2 until Phase 1 code review is complete.

---

## Design tasks

All design deliverables must accord with **GDD** (game and AI logic) and **TDD 15 (Technical Architecture)**. Per SPEC layout: game design lives in **SPEC/game/**; technical architecture in **SPEC/program/** (see [colonizethis-spec-required](../../.cursor/rules/colonizethis-spec-required.mdc)). Each Phase 1 SPEC sub-doc must stay **≤500 words**; split into further sub-specs if needed. Specs must be structured so implementation can point to authorizing sections. If world-model and turn-resolution specs conflict with each other or with GDD/TDD, **resolve before implementation**.

| Task | Description | Deliverable |
|------|-------------|-------------|
| **World model spec** | Define both regions (Old World + New World), core entities (Game, WorldState, Province, Unit, Player, Orders per [repo-and-packages.md](../program/repo-and-packages.md)), and how they relate. Derived from GDD/TDD. Reference [SPEC/program/ruleset-config.md](../program/ruleset-config.md) for where ruleset/config is defined and how it is loaded (game load). | [SPEC/game/world-model.md](../game/world-model.md) (≤500 words). |
| **Turn states and resolution sequence spec** | Define turn phases, turn state enum/representation, and the resolution sequence (order of phases; what TurnResolver does in each step). Stub means: sequence and interfaces exist; individual phase logic can be no-op or minimal (e.g. advance turn counter only) until Phase 2+ fills economy/combat. | [SPEC/program/turn-resolution.md](../program/turn-resolution.md) (≤500 words). |
| **Map data and tile map generation specs** | Topology format, tile map format, and tile-based map generation algorithm are defined and agreed. Phase 1 includes both design and implementation of the algorithm per the specs. map-data.md also specifies the describe_topology CLI expanded behaviour (entire map, interactive mode, options; provinces without owner shown as no owner). | [SPEC/program/map-data.md](../program/map-data.md), [SPEC/program/tile-map-generation.md](../program/tile-map-generation.md), [SPEC/game/tile-map-and-generation.md](../game/tile-map-and-generation.md). |

---

## Dev tasks

Order matters. Implement in sequence; each task assumes the previous is done.

| # | Task | Description |
|---|------|-------------|
| 1 | **World and turn models (colonizethis_models)** | Implement data models and serialization for Game, WorldState, Province, Unit, Player, Orders, turn state; both regions represented; no game logic. |
| 2 | **Save schema and adapter (colonizethis_save)** | Save format and Hive/Isar (or chosen storage) adapter for game state; depends on colonizethis_models. |
| 3 | **TurnResolver stub (colonizethis_logic)** | Resolver type/class with defined phase sequence; each phase no-op or minimal (e.g. advance turn); input/output defined (e.g. WorldState in, WorldState out); no economy/combat/diplomacy logic. |
| 4 | **Wire resolve and persist in app** | App (or a service used by app) invokes TurnResolver for “next turn” and persists result via colonizethis_save; load game restores state. Riverpod providers from Phase 0 get real models and save/load. |
| 5 | **Tile-based map generation implementation** | Implement the algorithm per [SPEC/program/tile-map-generation.md](../program/tile-map-generation.md) and [SPEC/game/tile-map-and-generation.md](../game/tile-map-and-generation.md). Implemented in colonizethis_data or a tool under `tool/` (e.g. `tool/generate_tile_map`). Input: region topology graph and parameters (grid size, seed, border noise, etc.); output: per-region 2D tile map with province/sea zone id, type (land/water), terrain type per cell, and optional resource per tile respecting resource–region and resource–terrain rules and spawn-rate weights (inverse to default market price). Depends on topology loading (colonizethis_data) and, for terrain/resource, resource–region and resource–terrain rules in colonizethis_data (may be stubbed minimally for Phase 1 if needed). |
| 6 | **describe_topology tool expansion** | Expand the CLI per the describe_topology expansion plan. Required: topology path. Optional: `--interactive`, `--tile-map`, `--world-state`. When tile map not provided and interactive or summary needed, generate in-memory via TileMapGenerator (colonizethis_data); print map summary (tile counts per province/sea zone). Optional world-state: load JSON with WorldState.fromJson (add colonizethis_models to tool), show province owner or "no owner". Interactive loop: list provinces (id, region, tile count), prompt for province id, print detail (owner or no owner, tiles count; improvements as no improvement data until model exists). Update SPEC/program/map-data.md CLI section accordingly. |

---

## Test tasks

Tests follow **test/ mirrors lib/** and **\*_test.dart** naming; use **mockito** or **mocktail** for mocks. Per [colonizethis-testing](../../.cursor/rules/colonizethis-testing.mdc): save/load is a **critical path** and must have tests; aim for **80% per-package coverage** for Phase 1 packages, enforced in CI where applicable (e.g. `dart test --coverage`).

| Task | Success criteria |
|------|------------------|
| **Build passes** | `flutter pub get` and `flutter build` (or equivalent) succeed for the app and all packages. |
| **Unit tests — models** | Unit tests for colonizethis_models: creation, serialization, invariants. |
| **Unit tests — resolver stub** | Unit tests for TurnResolver stub (e.g. resolve advances turn state, returns new state). |
| **Save/load round-trip (critical path)** | Write game state, read back, compare or assert key fields; save/load is a critical path per testing rule. |
| **Unit tests — tile map generator** | Given a small topology and params, generator produces a valid tile map (adjacency invariant holds; optional: terrain and resource placement respect rules). Include colonizethis_data (or the tool) in per-package coverage where the generator lives. |
| **describe_topology tool** | With topology (and in-memory tile map when interactive/summary), tool prints topology and map summary; with `--interactive` lists provinces and shows province detail on input; with `--world-state` shows owner or "no owner". Manual or scripted test; tool builds and runs. |
| **Per-package coverage** | Unit tests and coverage for colonizethis_models, colonizethis_save, colonizethis_logic aim for 80% per package; enforce in CI where applicable. |

---

## Code review tasks

Before marking Phase 1 complete, verify:

| Check | Criteria |
|-------|----------|
| **Package boundaries** | Logic in colonizethis_logic; models in colonizethis_models; save in colonizethis_save. No game rules beyond turn advance in resolver. |
| **Spec alignment** | World model and turn-resolution SPEC docs reflected in code. New behavior is traceable to a spec section (world-model or turn-resolution); no behavior without an authorizing spec. Any Phase 1 work touching map or regions is consistent with world-model and, where relevant, [map-data.md](../program/map-data.md) and [tile-map-generation.md](../program/tile-map-generation.md) (e.g. province/region id and topology terms). Map generation implementation follows map-data.md and tile-map-generation.md. describe_topology expansion behaviour matches map-data.md CLI section. |
| **Spec conflicts resolved** | If world-model and turn-resolution specs conflicted with each other or with GDD/TDD, resolution was done before implementation. |
| **State and lifecycle** | State subscriptions and cleanup follow lifecycle conventions where applicable (see [colonizethis-lifecycle](../../.cursor/rules/colonizethis-lifecycle.mdc)). |

---

## Definition of done (Phase 1)

Phase 1 is done when all design and dev tasks below are implemented, all test tasks are passing, and the code review checklist is signed off.

- [x] All Design deliverables written and agreed.
- [x] All Dev tasks implemented.
- [x] All Test tasks passing.
- [ ] Code review checklist signed off.

**Exit criteria:** World model and turn state exist; TurnResolver stub runs and advances turn; save/load round-trip works; tile-based map generation is implemented and tested per the algorithm spec; describe_topology expanded behaviour is implemented and map-data.md CLI section updated; logic in shared packages; ready for Phase 2 (economy, units, movement).

---

## Dependencies and order

- **Design** (world model spec, turn-resolution spec) must be done before Dev.
- Design deliverables live in SPEC (game and program) so the team does not depend only on Obsidian; key structure and terms must be in-repo.
- **Dev:** Models first (colonizethis_models), then save schema/adapter (colonizethis_save), then TurnResolver stub (colonizethis_logic), then app wiring, then tile-based map generation (colonizethis_data or tool/) after topology format/loading is available, then describe_topology tool expansion (tool/describe_topology) after tile-based map generation and models (for world-state parsing).
- **Test** and **Code review** after Dev.

---

## Out of scope for Phase 1

- Economy, production, auto-transport, units with movement (Phase 2).
- Combat, diplomacy, AI (Phases 3–4).
- Victory condition, tech tree (Phase 5).
- JSON rulesets / layered config (per [mvp-scope.md](mvp-scope.md), out of MVP).
- Full TurnResolver phase logic (only stub/sequence in Phase 1).
- New UI components: if Phase 1 adds any new Flutter widgets (e.g. turn indicator or save button), they must follow the UI design rule (Widgetbook, catalog). Phase 1 may only wire the existing shell.

---

## References

- **TDD 15** — Technical Architecture (Obsidian: `Projects/ColonizeThisV3/TDD/15-technical-architecture.md`): package layout, app structure, state, save, Flame vs Flutter.
- **GDD** — Game design (Obsidian): world, regions, entities, rules. SPEC/game/ is the in-repo reflection.
- [mvp-scope.md](mvp-scope.md) — MVP scope and phasing.
- [SPEC/program/repo-and-packages.md](../program/repo-and-packages.md) — Package list, dependency direction.
- [SPEC/program/ruleset-config.md](../program/ruleset-config.md) — Where config is defined and how it is loaded (game load).
- [SPEC/game/world-model.md](../game/world-model.md) — Phase 1 design deliverable.
- [SPEC/program/turn-resolution.md](../program/turn-resolution.md) — Phase 1 design deliverable.
- [SPEC/program/map-data.md](../program/map-data.md) — Topology and tile map format, describe-topology CLI.
- [SPEC/program/tile-map-generation.md](../program/tile-map-generation.md) — Tile-based map generation algorithm and contract.
- **describe_topology expansion plan** — Full CLI interface, data sources, output content, implementation steps, SPEC change for map-data.md (see `.cursor/plans/describe_topology_tool_expansion_a8108dc0.plan.md` or project plan copy).
- `.cursor/rules/colonizethis-core-principles.mdc` — Flutter vs Flame separation.
- `.cursor/rules/colonizethis-spec-required.mdc` — SPEC-first, layout, max 500 words, authorizing spec for behavior.
- `.cursor/rules/colonizethis-testing.mdc` — 80% per-package coverage, test layout, critical path (save/load).

---

## Risks and assumptions

- GDD and TDD 15 live in Obsidian; SPEC (world-model, turn-resolution) is the in-repo reflection for implementation. Design tasks should sync key structure from GDD/TDD into SPEC before Dev.
- Phase 1 implementation may use stub config at game load; ruleset-config is referenced so Phase 2+ can plug in resolved config without reworking the model.
