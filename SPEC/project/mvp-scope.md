# MVP Scope and Phasing

**SPEC/project** — Project-level scope and phase boundaries. Other specs reference this for what is in MVP.

---

## Source of truth

High-level requirements live in **Obsidian** (GDD, TDD, UXD): game rules, technical architecture, and UX/style. The **SPEC/** folder in the repo holds **implementation specifics** derived from Obsidian — the concrete scope and behavior that implementation must follow. **SPEC/project/** defines MVP scope and phasing; domain specs (SPEC/game/, SPEC/program/, SPEC/ai/, SPEC/ui/) derive from Obsidian and stay within these boundaries.

---

## MVP definition

The MVP is a **standalone app**: single-player vs AI only, no multiplayer, no backend. One full game loop from start to victory. Pixel art is mostly in place (terrain, units, UI frames); some placeholders are acceptable. All turn resolution runs locally; same shared logic will later run on a server for multiplayer.

---

## MVP victory condition

**Military only:** control more than half of Old World provinces (31+). Other victory types (Economic, Scientific, Peaceful, Exploration, Score) are post-MVP.

---

## Game config (MVP)

MVP must use **program-level config**: unit stats, map params, economy/combat modifiers, and other tunable values are **not** hardcoded; they are defined in one place (e.g. `colonizethis_data` or a config module) and read by game logic. This allows rapid iteration by changing config in code without scattering magic numbers.

**JSON-based configuration** (file-based rules, base + difficulty + scenario overlays, `rules/*.json`) is **out of MVP scope** and deferred to a later phase.

---

## Two-region model (MVP in scope)

**Old World + New World** are both in MVP. The two-region dynamic is core: victory is decided in the Old World; the New World is the frontier for resources, riches, and colonies. MVP uses fixed maps for each region. Map data (topology, tile maps) and tile map generation are in scope per [SPEC/program/map-data.md](../program/map-data.md) and [SPEC/program/tile-map-generation.md](../program/tile-map-generation.md). Asia is post-MVP.

---

## Phasing

For each phase the **full dev workflow** is followed: **Design → Dev → Test → Code review**. Do not advance to the next phase until the current phase’s code review is complete.

| Phase | Design | Dev | Test | Code review |
|-------|--------|-----|------|-------------|
| **0** | Scope doc, repo layout, package plan | Packages, app shell (Flutter + Flame), state/save wiring; no game logic | Build passes; app launches; package deps resolve | Structure matches TDD; no game logic in app |
| **1** | World model (both regions), turn states, resolution sequence | Models, TurnResolver stub, local resolve, persist (e.g. Hive/Isar) | Unit tests for models and resolver stub; save/load round-trip | Logic in shared packages; spec alignment |
| **2** | Economy (commodities, production, auto-transport), basic units; New World exploitation/colonies per GDD | Production, delivery, subset of civilians + one military type; movement and ownership | Unit tests for economy and movement; integration test for one full turn | Matches GDD/SPEC; no scope creep |
| **3** | Combat (auto-resolve only) per GDD 06 | Conflict detection, resolve formula, casualties and province flip | Unit tests for combat formula; test battles produce expected outcomes | Combat rules match GDD 06 |
| **4** | Minimal diplomacy (war/peace), AI (one personality); 2–3 Great Powers | AIPlanner, order merge, diplomacy phase | Unit tests for AI and diplomacy; playtest vs AI for several turns | AI and diplomacy within spec |
| **5** | Military victory check, small tech tree, 1–2 eras | Victory screen, research phase, one or two unlocks | Victory triggers correctly; tech unlocks apply; integration test to victory | Victory and tech match GDD |
| **6** | Pixel-art canon, asset set, main menu per UXD | Asset pipeline, Flame/Flutter integration, main menu | Assets load; main menu flows; no regressions on prior phases | Style and structure match UXD |

**Known issues:** Map-generation polish and other deferred items are listed in [known-issues.md](known-issues.md) and are to be tackled after the main development phases.

---

## Scope in/out

| In (MVP) | Out (post-MVP) |
|----------|----------------|
| Fixed two-region map (Old World + New World) | Multiplayer, backend, push, auth |
| 2–3 Great Powers | Quick Battle, full tactical combat |
| Auto-transport, auto-resolve combat | Full diplomacy (overture chain, alliances) |
| One victory (Military: 31+ provinces) | 7 powers, Asia region |
| New World resources and colonies | Full tech tree, all victory types |
| Program-level config; single source for stats/modifiers (no hardcoding) | JSON rulesets; layered overrides (difficulty/scenario); scenario files |
| Map data (topology and tile maps per [map-data.md](../program/map-data.md)); tile-based map generation ([tile-map-generation.md](../program/tile-map-generation.md)) for fixed two-region maps | Procedural map generation; dynamic scenario map loading |

---

## Low-hanging fruit

Deliberate simplifications for MVP: single victory condition; auto-resolve only (no Quick Battle); one AI personality for all AI powers; minimal diplomacy (war/peace); 2–3 powers; fixed two-region map (no procedural generation); program-level config in scope (single source for stats/modifiers). Defer to post-MVP: per-leader personalities, portraits/dialogue, full unit roster, navy, full tech tree, all alternative victory types, and JSON/layered rulesets.
