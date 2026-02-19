# Phase 5 — Project tasks

**SPEC/project** — Actionable task list for Phase 5. Victory and tech follow **GDD 01, 08**; leader bonuses follow **GDD 09**. SPEC is the in-repo reflection. Full workflow: **Design → Dev → Test → Code review** per [mvp-scope.md](mvp-scope.md).

**Phasing:** Previous — [phase-4-project-tasks.md](phase-4-project-tasks.md). Next — Phase 6 (pixel-art, main menu).

---

## Purpose

Phase 5 adds **military victory** (31+ Old World provinces), the **full technology tree** (Imperialism II–derived, all four eras), the **research phase** (slots, funding, prerequisites, treasury commitment), **leader bonuses** (ColonizeThis-specific per GDD 09), and the **show_tech** developer tool. Do not advance to Phase 6 until Phase 5 code review is complete.

---

## Scope (Phase 5)

- **Victory:** Military only: control 31+ Old World provinces; victory screen.
- **Tech tree:** Full tree with dependencies and effects (civilian/military/naval units, extraction limits, improvements, diplomatic options); regiment unlocks by tech; extraction cap derived from catalog; transport (roads/railroads/ports) by player action.
- **Research:** Research phase after Production/Consumption; research orders (slot → techId, funding); cost committed from treasury; prerequisite rule (B unavailable until A done); cancel = lose progress. See [research-resolution.md](../program/research-resolution.md), [turn-resolution-phases.md](../program/turn-resolution-phases.md).
- **Leader bonuses:** Per-GP leader selection at game start; combat bonuses apply in auto-resolve and Quick Battle.
- **show_tech tool:** CLI: markdown diagram of full tree; interactive/query mode (description, dependencies, effects per tech). See [show-tech-tool.md](../program/show-tech-tool.md).
- **Fog of war and exploration:** Four visibility levels (unknown, revealed, fogged, fully visible); Explorer explores (province-level) and prospects (tile-level); extraction gating for minerals. See [fog-and-exploration.md](../game/fog-and-exploration.md), [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md).
- **Ships and naval (foundation):** Fleet model, sea zones, naval movement, and ship reveal (coastal tiles on fleet enter); ship build and home fleet. No full naval combat/interception yet; Phase 5 establishes movement, reveal, and economics for Phase 6 to build on. See [ships-and-naval.md](../game/ships-and-naval.md), [naval-movement-resolution.md](../program/naval-movement-resolution.md).
- **Terrain development:** Imperialism-style, multi-turn civilian development (Builder improvements and town upgrades; Engineer roads, ports, forts; Rail Builder railroads) that modifies per-tile improvement and transport levels used by extraction and connectivity; same rules shared between the main game and `ctdev`'s `sim_game`.

---

## Design tasks

All design deliverables must accord with **GDD 01** (victory), **GDD 08** (technology), **GDD 09** (Great Powers, leaders). Each Phase 5 SPEC sub-doc must stay **≤500 words**; split further if needed.

| Task | Description | Deliverable |
|------|-------------|-------------|
| **Victory condition** | Military: 31+ OW provinces; victory check; victory screen. | [victory.md](../game/victory.md) or extend [world-model.md](../game/world-model.md). |
| **Tech tree overview and rules** | Eras, categories, prerequisites, effect types, research model (slots, funding, cancel). | [tech-tree.md](../game/tech-tree.md). |
| **Tech tree catalog** | Full catalog: id, name, era, category, prerequisites, effects (from Imperialism II). | [tech-tree-catalog.md](../game/tech-tree-catalog.md) and category sub-docs. |
| **Extraction and transport rules** | Tech-derived extraction cap; roads/railroads/ports by player action; transport level 4. | Extend [tech-and-extraction-cap.md](../game/tech-and-extraction-cap.md), [extraction-and-improvements.md](../game/extraction-and-improvements.md). |
| **Regiment and unit unlocks** | Regiment/civilian/diplomatic unlocks from tech catalog; no era gate for buildability. | Extend [military-units.md](../game/military-units.md), [civilian-units.md](../game/civilian-units.md), [diplomacy.md](../game/diplomacy.md). |
| **Research phase (technical)** | Phase placement, steps, treasury, progress, completion, prerequisite rule. | [research-resolution.md](../program/research-resolution.md), [turn-resolution-phases.md](../program/turn-resolution-phases.md). |
| **Research orders** | Order type, validation, merge. | Extend [orders.md](../program/orders.md), [order-engine.md](../program/order-engine.md). |
| **show_tech tool** | Markdown diagram + interactive query; CLI interface. | [show-tech-tool.md](../program/show-tech-tool.md). |
| **Leader bonuses** | Per-GP leader; combat bonuses; when applied. | [leader-bonuses.md](../game/leader-bonuses.md). |
| **Fog and exploration** | Four visibility levels; prospect-required resources; Explorer/Spy semantics; tile-level civilians. | [fog-and-exploration.md](../game/fog-and-exploration.md). |
| **Fog/exploration resolution** | Visibility state, prospected state, WorkOrder explore/prospect, extraction gating, fog decay. | [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md). |
| **Terrain development (game)** | Builder/Engineer/Rail Builder work actions, allowed tiles, tech gates, Imperialism-style costs and multi-turn durations for improvements, roads, ports, forts, rails. | Extend [civilian-units.md](../game/civilian-units.md), [extraction-and-improvements.md](../game/extraction-and-improvements.md), [siege-mechanics.md](../game/siege-mechanics.md); optional `development.md` if needed. |
| **Terrain development (technical)** | Multi-turn work state, WorkOrder targets (`build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`, `build_rail`), Build/Work phase loop, and shared use by `sim_game`. | [development-resolution.md](../program/development-resolution.md), extend [orders.md](../program/orders.md), [turn-resolution-phases.md](../program/turn-resolution-phases.md). |
| **Ships and naval** | Fleet model, sea zones, ship reveal, ship types, naval movement. | [ships-and-naval.md](../game/ships-and-naval.md). |
| **Naval movement resolution** | Fleet movement, ship reveal on enter, topology S<->S. | [naval-movement-resolution.md](../program/naval-movement-resolution.md). |

**Existing specs to align:** [combat.md](../game/combat.md), [combat-resolution.md](../program/combat-resolution.md), [military-units.md](../game/military-units.md).

---

## Dev tasks

Order matters. Implement in sequence; each task assumes the previous is done.

| # | Task | Description |
|---|------|-------------|
| 1 | **Victory check (colonizethis_logic)** | At end of turn (or after Combat), check: does any GP control 31+ OW provinces? If yes, set victory state (winner, victory type). |
| 2 | **Victory screen (app)** | UI: victory screen showing winner, victory type; option to return to main menu or view final state. |
| 3 | **Tech catalog (colonizethis_data)** | Full tech list: era, category, prerequisites, costs, effects (extraction, transport, regiment ids, civilian, diplomatic, labour). Program-level config per [tech-tree-catalog.md](../game/tech-tree-catalog.md) and category sub-docs. |
| 4 | **Research phase (colonizethis_logic)** | Implement research resolution per [research-resolution.md](../program/research-resolution.md) and [turn-resolution-phases.md](../program/turn-resolution-phases.md) (after Consumption). |
| 5 | **Extraction cap from tech** | Derive per-player extraction cap from techUnlocked and catalog; wire into computeExtraction in extraction phase. |
| 6 | **Build validation** | Regiment buildable only if unlocking tech in techUnlocked; military level derived from techUnlocked for minor parity. |
| 7 | **Research orders** | ResearchOrder type; order engine validation (treasury, prerequisites, slot count); merge in turn resolver. |
| 8 | **Leader model (colonizethis_models)** | Leader type per GP; selected at game start; serialized with Game. |
| 9 | **Leader bonuses in combat** | Combat resolver reads leader type; applies bonus per [leader-bonuses.md](../game/leader-bonuses.md). |
| 10 | **show_tech tool** | CLI under `tool/show_tech`: diagram output (markdown), interactive mode (query by tech id → description, dependencies, effects). |
| 11 | **AI research** | AIPlanner emits research orders; simple heuristic; deterministic from turnSeed. |
| 12 | **Leader selection (app)** | UI: at game start, each human player selects leader (or default); AI GPs get assigned leaders. |
| 13 | **Wire app to Phase 5** | Victory check triggers victory screen; research phase runs; leader selection at game start; Technology panel (UXD 03k); save/load includes tech state, research progress, leader, victory. |
| 14 | **Visibility and prospected state** | Add visibility and prospected state to colonizethis_models (WorldState or Player); initial visibility per region. |
| 15 | **Tile-level civilian positioning** | Add tileKey to Unit for civilians; spawn/move sets it; military remains province-only. |
| 16 | **WorkOrder explore/prospect resolution** | orders_application: explore progress + full province reveal; prospect adds tile to prospected set. |
| 17 | **Fog decay** | End-of-turn: other-faction provinces with no Explorer/Spy → fogged. |
| 18 | **Extraction gating for minerals** | resource_extractor: minerals only from prospected tiles; non-minerals unchanged. |
| 19 | **Fleet model and naval units** | Fleet, naval units in colonizethis_models; RegionData.navalUnits or equivalent. |
| 20 | **Naval movement and ship reveal** | MoveOrder for naval; ship reveal on fleet enter sea zone; visibility updates. |
| 21 | **Ship build and home fleet spawn** | BuildUnitOrder for ships; spawn in home fleet (capital port); ship economy catalog in colonizethis_data. |
| 22 | **Terrain development (colonizethis_logic + models)** | Implement multi-turn civilian development per [development-resolution.md](../program/development-resolution.md): add work-progress state to civilian units; extend order application to handle development WorkOrder targets; update `WorldState.tileState` and `portsByProvinceSeaboard` and fort levels on completion; ensure `sim_game` uses the same TurnResolver and exposes resulting state deltas. |

---

## Implementation plan

Documented sequence for implementation (design complete before dev):

1. **Data and config:** Tech catalog in colonizethis_data (ids, names, eras, categories, prerequisites, costs, effects). Derivation helpers: extraction cap from techUnlocked, military level from techUnlocked (set of buildable regiment types).
2. **Research state and orders:** Player: techUnlocked, research progress per slot. Orders: ResearchOrder structure; validation in order engine; merge in turn resolver.
3. **Turn resolution:** Research phase (after Consumption): validate orders, deduct treasury, add progress, complete techs, update techUnlocked and derived state. Extraction phase: pass tech-derived cap into computeExtraction. Build validation: regiment buildable only if unlocking tech researched.
4. **AI:** AIPlanner produces research orders; simple heuristic; deterministic from turnSeed; personality can influence priority (MVP: heuristic fallback).
5. **show_tech tool:** CLI reads tech catalog; outputs markdown diagram; interactive mode queries by tech id (description, dependencies, effects).
6. **UI and save/load:** Technology panel (UXD 03k); save/load techUnlocked, research progress, current-turn research orders.

---

## Test tasks

Tests follow **test/ mirrors lib/** and **\*_test.dart** naming; use **mockito** or **mocktail** for mocks. Save/load remains a critical path; aim for **90% per-package coverage** for Phase 5 packages.

| Task | Success criteria |
|------|------------------|
| **Build passes** | `flutter pub get` and `flutter build` succeed for app and all packages. |
| **Unit tests — victory check** | Given WorldState where GP has 31+ OW provinces, victory check sets winner; 30 provinces does not. |
| **Unit tests — research phase** | Research allocation completes tech; treasury deduction; prerequisite enforcement; regiment unlock and extraction cap updated. |
| **Unit tests — extraction cap** | Extraction cap derived from techUnlocked; computeExtraction uses per-player cap. |
| **Unit tests — build validation** | Regiment buildable only when unlocking tech researched; build rejected otherwise. |
| **Unit tests — terrain development** | Given sequences of Builder/Engineer/Rail Builder WorkOrders, multi-turn progress and material costs behave per spec; resulting improvements, roads/ports/forts/rails are reflected correctly in connectivity and `computeExtraction`. |
| **Unit tests — leader bonuses** | Combat resolver applies correct bonus for leader type (e.g. Napoleon +25% melee). |
| **show_tech** | Diagram output contains all techs; query mode returns correct description, dependencies, effects for a given tech id. |
| **Integration test — victory** | Run game until one GP controls 31+ OW provinces; victory screen appears. |
| **Integration test — tech unlock** | Research tech; new regiment type becomes buildable. |
| **Integration test — sim_game development** | Run `ctdev`'s `sim_game` with civilian WorkOrders (explore/prospect + development); assert that resulting tile improvements, roads/ports/forts/rails, visibility, and prospected state match running the same orders through the main game TurnResolver. |
| **Save/load round-trip (critical path)** | Save game state with tech, research progress, leader, victory; load and assert key fields match. |
| **Per-package coverage** | colonizethis_logic (victory, research, leader bonus application) aim for 90%. |

---

## Code review tasks

Before marking Phase 5 complete, verify:

| Check | Criteria |
|-------|----------|
| **Package boundaries** | Victory and research logic in colonizethis_logic; tech config in colonizethis_data; leader model in colonizethis_models; show_tech in tool/; UI in app. |
| **Spec alignment** | All Phase 5 behaviour traceable to victory.md, tech-tree.md, tech-tree-catalog.md, research-resolution.md, leader-bonuses.md, show-tech-tool.md, fog-and-exploration.md, fog-and-exploration-resolution.md, ships-and-naval.md, naval-movement-resolution.md; no behaviour without authorizing spec. |
| **Phase 5 scope** | Military victory only; full tech tree; research phase and orders; leader bonuses; show_tech tool; fog of war and exploration; ships and naval movement; no alternative victory types. |
| **State and lifecycle** | State subscriptions and cleanup follow lifecycle conventions; no leaks. |

---

## Definition of done (Phase 5)

Phase 5 is done when all design and dev tasks are implemented, all test tasks pass, and the code review checklist is signed off.

- [ ] All Design deliverables written and agreed.
- [ ] All Dev tasks implemented.
- [ ] All Test tasks passing.
- [ ] Code review checklist signed off.

**Exit criteria:** Victory triggers when GP controls 31+ OW provinces; victory screen appears; full tech tree implemented; research phase and orders working; extraction cap and regiment buildability derived from tech; show_tech tool available (diagram + query); leader bonuses apply in combat; leader selection at game start; save/load includes Phase 5 state; ready for Phase 6 (pixel-art, main menu).

---

## Dependencies and order

- **Design** must be done before Dev. All Phase 5 SPEC docs must be in repo and agreed.
- **Dev:** Victory check and victory screen; tech catalog and research phase; extraction cap and build validation; research orders; leader model and bonuses; show_tech tool; AI research; leader selection UI; app wiring.
- **Test** and **Code review** after Dev.

---

## Out of scope for Phase 5

- Alternative victory types (Economic, Scientific, Peaceful, Score).
- Full naval combat and interception (Phase 5 implements basic naval movement and ship reveal; combat/interception may be minimal stub; full logic can be extended later).
- JSON rulesets (mvp-scope: program-level config only).
- Spy bonus for research (optional for MVP; may be deferred).

---

## References

- **GDD 01** — Core loop, victory (Obsidian).
- **GDD 08** — Technology (Obsidian).
- **GDD 09** — Great Powers, leaders (Obsidian).
- **Imperialism II 08-technology** — Full tech chart (Obsidian).
- [mvp-scope.md](mvp-scope.md) — Phase 5 scope.
- [phase-4-project-tasks.md](phase-4-project-tasks.md) — Previous phase; Quick Battle, diplomacy, AI.
- [tech-tree.md](../game/tech-tree.md), [tech-tree-catalog.md](../game/tech-tree-catalog.md) — Tech tree and catalog.
- [research-resolution.md](../program/research-resolution.md), [show-tech-tool.md](../program/show-tech-tool.md) — Research phase and show_tech tool.
- [combat.md](../game/combat.md), [combat-resolution.md](../program/combat-resolution.md) — Combat and leader bonus application.
- [military-units.md](../game/military-units.md) — Regiment types and tech unlocks.
- [fog-and-exploration.md](../game/fog-and-exploration.md), [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md) — Fog, visibility, exploration, prospecting.
- [ships-and-naval.md](../game/ships-and-naval.md), [naval-movement-resolution.md](../program/naval-movement-resolution.md) — Ships, fleets, naval movement, ship reveal.
- `.cursor/rules/colonizethis-testing.mdc` — 90% coverage, critical path (save/load).

---

## Summary: Specs to write or extend

| Spec | Action |
|------|--------|
| **SPEC/game/victory.md** | New: military victory (31+ OW provinces); victory check; victory screen. |
| **SPEC/game/tech-tree.md** | New: overview (eras, categories, prerequisites, effects, research model). |
| **SPEC/game/tech-tree-catalog.md** | New: catalog index; category sub-docs (gathering, transport, labour-economy, diplomacy-civilian, naval, military, new-world). |
| **SPEC/game/tech-and-extraction-cap.md** | Extend: extraction cap derived from catalog; fallback constant. |
| **SPEC/game/extraction-and-improvements.md** | Extend: roads/railroads/ports by player action; tech allows building level. |
| **SPEC/game/military-units.md** | Extend: buildability by unlocking tech; minor parity from buildable set. |
| **SPEC/game/diplomacy.md** | Extend: tech-gated options (Diplomatic Expertise, Empire Building). |
| **SPEC/program/research-resolution.md** | New: research phase steps, validation, orders structure. |
| **SPEC/program/turn-resolution-phases.md** | Update: insert Research phase after Consumption. |
| **SPEC/program/show-tech-tool.md** | New: show_tech CLI (diagram + interactive/query). |
| **SPEC/program/orders.md** | Extend: ResearchOrder type; BuildUnitOrder tech gate. |
| **SPEC/program/order-engine.md** | Extend: research order validation and merge. |
| **SPEC/game/leader-bonuses.md** | New: per-GP leader; combat bonus table; when applied. |
| **SPEC/game/fog-and-exploration.md** | New: four visibility levels; Explorer/Spy semantics; prospect-required resources. |
| **SPEC/program/fog-and-exploration-resolution.md** | New: visibility state, prospected state, WorkOrder resolution, extraction gating. |
| **SPEC/game/ships-and-naval.md** | New: fleets, sea zones, ship reveal, ship types. |
| **SPEC/program/naval-movement-resolution.md** | New: fleet movement, ship reveal on enter. |

---

## Risks and assumptions

- GDD 01, 08, 09 live in Obsidian; SPEC is the in-repo reflection. TDD 08 and GDD 08 aligned with research phase after Consumption, treasury commitment, prerequisite rule, cancel = lose progress.
- Leader bonuses are ColonizeThis-specific (not from Imperialism II); GDD 09 defines the bonus table.
- Phase 5 implements the full tech tree (Imperialism II–derived); no simplification to 1–2 eras.
