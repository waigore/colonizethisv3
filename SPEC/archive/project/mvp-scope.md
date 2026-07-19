# MVP Scope and Phasing

**SPEC/project** — Project-level scope and phase boundaries. Other specs reference this for what is in MVP.

---

## Source of truth

High-level requirements live in **Obsidian** (GDD, TDD, UXD): game rules, technical architecture, and UX/style. The **SPEC/** folder in the repo holds **implementation specifics** derived from Obsidian — the concrete scope and behavior that implementation must follow. **SPEC/project/** defines MVP scope and phasing; domain specs (SPEC/game/, SPEC/program/, SPEC/ai/, SPEC/ui/) derive from Obsidian and stay within these boundaries.

---

## MVP definition

The MVP is a **standalone app**: single-player vs AI only, no multiplayer, no backend. One full game loop from start to victory. Pixel art is mostly in place (terrain, units, UI frames); some placeholders are acceptable. All turn resolution runs locally; same shared logic will later run on a server for multiplayer. MVP is complete when **logic Phases 0–6** (game rules, economy, combat, diplomacy, victory, tech, pixel-art canon) **and UI Phases U1–U3** (implementation of UI flows per UXD 03a–03m) are implemented and passing their respective tests.

---

## MVP victory condition

**Military only:** control more than half of Old World provinces (31+). Other victory types (Economic, Scientific, Peaceful, Exploration, Score) are post-MVP.

---

## Game config (MVP)

MVP must use **program-level config**: unit stats, map params, economy/combat modifiers, and other tunable values are **not** hardcoded; they are defined in one place (e.g. `colonizethis_data` or a config module) and read by game logic. This allows rapid iteration by changing config in code without scattering magic numbers.

**JSON-based configuration** (file-based rules, base + difficulty + scenario overlays, `rules/*.json`) is **out of MVP scope** and deferred to a later phase.

---

## Two-region model (MVP in scope)

**Old World + New World** are both in MVP. The two-region dynamic is core: victory is decided in the Old World; the New World is the frontier for resources, riches, and colonies. Map data (topology, tile maps) and tile map generation are in scope; **procedural world generation** for new games is in scope per [SPEC/game/game-setup.md](../game/game-setup.md). Asia is post-MVP.

---

## Phasing

For each phase the **full dev workflow** is followed: **Design → Dev → Test → Code review**. Do not advance to the next phase until the current phase’s code review is complete.

| Phase | Design | Dev | Test | Code review | UI expectations |
|-------|--------|-----|------|-------------|-----------------|
| **0** | Scope doc, repo layout, package plan | Packages, app shell (Flutter + Flame), state/save wiring; no game logic | Build passes; app launches; package deps resolve | Structure matches TDD; no game logic in app | App shell and routing exist; no gameplay UIs beyond a placeholder game entry point. UXD 03a–03d may be drafted but are not required to be implemented. |
| **1** | World model (both regions), turn states, resolution sequence | Models, TurnResolver stub, local resolve, persist (e.g. Hive/Isar) | Unit tests for models and resolver stub; save/load round-trip | Logic in shared packages; spec alignment | Shell and save/load wiring are sufficient for **UI Phase U1** to start: main menu, basic Game Setup/Load, and a simple in-game shell can be implemented against the stubbed TurnResolver. |
| **2** | Economy (commodities, production, auto-transport), basic units; New World exploitation/colonies per GDD | Production, delivery, subset of civilians + one military type; movement and ownership | Unit tests for economy and movement; integration test for one full turn | Matches GDD/SPEC; no scope creep | No additional UI is required to exit Phase 2, but economy and movement APIs are stable enough for **U2** to wire the Production (`03g`) and Development (`03f`) panels to real data. |
| **3** | Combat (auto-resolve) per GDD 06; full military roster; tactical stats; initiative; siege; generals; sim_combat | Conflict detection, initiative ordering, tactical stat aggregation, siege-aware resolver, casualties and province flip; sim_combat CLI | Unit tests for combat formula, tactical stats, initiative, siege; sim_combat determinism; test battles produce expected outcomes | Combat rules match GDD 06; full roster in scope | Combat and roster are stable enough for **U2** to power the Units panel (`03e`) with stack lists and basic orders and for **U3** to surface recruitment limits in Academy (`03h`). No new UI is required for Phase 3 exit. |
| **4** | Quick Battle (GDD 06); full diplomacy (war/peace, alliances, overtures, relations, Join Empire/Colony, intervention, aid); order engine; AI (one personality); 6 Great Powers (configurable) | Quick Battle UI and resolution; order engine and turn-resolution integration; AIPlanner; order merge; full diplomacy phase | Unit tests for Quick Battle resolution, order engine, AI, full diplomacy; playtest vs AI for several turns | Quick Battle, order engine, full diplomacy, and AI within spec | Full diplomacy and Quick Battle logic exist. **U2** can implement the Diplomacy panel (`03j`) for war/peace, overtures, alliances, and hook combat mode selection / Quick Battle UIs to the existing resolver; these UIs are not required for Phase 4 exit but are fully authorized. |
| **5** | Military victory check, small tech tree (1–2 eras), leader bonuses (GDD 09) | Victory screen, research phase, leader selection, leader bonuses in combat | Victory triggers correctly; tech unlocks apply; leader bonuses apply; integration test to victory | Victory, tech, and leaders match GDD | Military victory checks and a small tech tree are in place. **U1** can complete the Victory and Progress UI (`03l`), and **U3** can implement the basic Technology panel (`03k`) that surfaces current caps and the Phase 5 tech subset. |
| **6** | Pixel-art canon, asset set, main menu per UXD | Asset pipeline, Flame/Flutter integration, main menu | Assets load; main menu flows; no regressions on prior phases | Style and structure match UXD | Pixel-art canon and main menu styling apply to all previously implemented UIs (`03a`–`03m`). No new layouts are required; this phase focuses on asset pipeline and visual fidelity for the existing UI frame. |

**Known issues:** Deferred map-generation polish and similar items were tracked in the project issue tracker (not in SPEC) after the main development phases.

---

## Scope in/out

| In (MVP) | Out (post-MVP) |
|----------|----------------|
| Two-region map (Old World + New World); procedural world generation for new games | Multiplayer, backend, push, auth |
| 6 Great Powers (configurable at game setup); Minor Nations and Tribes (reactive, no order phase) | Full tactical combat (manual unit movement on battlefield) |
| Full military roster (Phase 3); auto-transport; auto-resolve combat; Quick Battle (Phase 4); full diplomacy (Phase 4); order engine; full naval system (fleets, missions, combat, interception, trade raids) by Phase 6; full hybrid AI (colonizethis_ai) by Phase 6 | Multiplayer-only or post-MVP diplomacy extensions |
| One victory (Military: 31+ provinces) | Asia region |
| New World resources and colonies | Full tech tree, all victory types |
| Program-level config; single source for stats/modifiers (no hardcoding) | JSON rulesets; layered overrides (difficulty/scenario); scenario files |
| Map data (topology and tile maps per [map-data.md](../program/map-data.md)); tile-based map generation ([tile-map-gen-algorithm.md](../program/tile-map-gen-algorithm.md)); game setup per [game-setup.md](../game/game-setup.md) | Dynamic scenario map loading (beyond procedural) |

---

## UI Phases (UXD implementation)

UI implementation is organized into three dedicated phases that sit alongside logic Phases 0–6. These phases implement the gameplay UIs defined in UXD `03a`–`03m` without changing the underlying game-logic phasing.

| UI Phase | Design scope | Dev scope | Test scope | Depends on logic phases |
|----------|--------------|-----------|------------|-------------------------|
| **U1 — Shell & Victory** | UXD `03a` (Main Menu and Shell), `03b` (Game Setup and Load), `03c` (Settings), `03d` (Map and Empire Shell), `03m` (Empire Sidebar and Global Flows), `03l` (Victory and Progress UI); aligned with GDD 03, 08, 12. | Implement main menu, game setup/load, settings, in-game shell (map + HUD + sidebar frame), and victory screen per UXD; wire these screens to the existing app shell, colonizethis_logic (TurnResolver stub/implementation), and colonizethis_save. | Widget tests for each screen; integration test for “start new game → play to victory → return to main menu” path; basic golden tests for shell layouts. | Phases 0–1 (shell, save/load, world model, TurnResolver stub) and Phase 5 (victory condition, small tech tree) complete enough to drive UI. |
| **U2 — Core Management Panels** | UXD `03e` (Units UI), `03f` (Development UI), `03g` (Production UI), `03j` (Diplomacy UI); aligned with GDD 04, 05, 06, 07. | Implement Units, Development, Production, and full Diplomacy panels; map interactions in these panels to orders and state backed by colonizethis_logic (economy, movement, combat, diplomacy, order engine) and colonizethis_models. | Widget tests per panel (list + detail, filters, disabled states); integration tests ensuring orders created via UI match expected effects when TurnResolver runs; coverage of diplomacy interactions (war/peace, overtures, alliances) via the UI. | Phases 2–4 (economy & auto-transport, units & movement, auto-resolve/Quick Battle, full diplomacy, order engine, AI) provide the required models, config, and resolvers. |
| **U3 — Advanced & Stubbed Panels** | UXD `03h` (Academy UI), `03i` (Shipyard UI), `03k` (Technology UI); aligned with GDD 05, 08 and relevant SPEC/game docs (e.g. military units, tech-and-extraction-cap). | Implement Academy, Shipyard, and Technology panels. Where mechanics are limited in MVP (navy, full tech tree), surface read-only or clearly disabled controls with explanatory text and avoid expanding game rules beyond existing specs. | Widget tests confirming queues, counts, and disabled states behave as specified; basic integration tests that UI reads and reflects current recruitment/tech state without introducing new mechanics. | Phases 3 and 5 (full military roster, small tech tree, extraction caps) supply the data these panels display; navy mechanics beyond what is in scope remain post-MVP. |

## Low-hanging fruit

Deliberate simplifications for MVP: single victory condition; Quick Battle (streamlined tactical, Phase 4); one AI personality in Phase 4, extended to full hybrid AI in Phase 6; 6 Great Powers (configurable at game setup); Minor Nations and Tribes reactive; full military roster (Phase 3); navy introduced in Phase 5 (movement, fleets, ship reveal) and completed in Phase 6 (missions, combat, interception, trade raids); two-region map with procedural world generation for new games; program-level config in scope (single source for stats/modifiers). Defer to post-MVP: per-leader personalities, portraits/dialogue beyond MVP needs, full tech tree beyond what Phase 5 requires, alternative victory types, and JSON/layered rulesets.
