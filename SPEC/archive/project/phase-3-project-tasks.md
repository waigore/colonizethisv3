# Phase 3 — Project tasks

**SPEC/project** — Actionable task list for Phase 3. Combat follows **GDD 06**; SPEC is the in-repo reflection. Full workflow: **Design → Dev → Test → Code review** per [mvp-scope.md](mvp-scope.md).

**Phasing:** Previous — [phase-2-project-tasks.md](phase-2-project-tasks.md). Next — [phase-4-project-tasks.md](phase-4-project-tasks.md) (Quick Battle, diplomacy, AI).

---

## Purpose

Phase 3 adds **auto-resolve combat**: conflict detection when units end movement in enemy-held provinces; tactical stats (FPN, FPM, RNG, DEF, MVR) from the full Imperialism II military roster; initiative-based battle ordering; siege mechanics; general bonuses; a single resolve formula (per GDD 06); casualties and province flip; **minor military parity** for Old World minors (and tribes); and **sim_combat** CLI for combat testing. No diplomacy, no AI, no Quick Battle. Do not advance to Phase 4 until Phase 3 code review is complete.

---

## Scope (Phase 3)

- **Units:** Full Imperialism II military roster (28 regiment types, 8 categories, 4 eras); tactical stats per [military-units.md](../game/military-units.md); medals (0–4); generals (deployment, rally, initiative).
- **Combat:** Triggered when a unit's move ends in a province owned by another faction (or with enemy units). Only Great Powers initiate attacks; Minor Nations and Tribes defend when their provinces are attacked.
- **Resolution:** One auto-resolve formula: strength from tactical stats (FPN, FPM) and medals; modifiers from terrain, fort level, difficulty; siege mechanics (wall protection, emplaced artillery) when fort present; outcome determines casualties and winner; province flip when defender eliminated.
- **Initiative:** Battle order by army initiative (composition + general medals) when multiple battles affect same province.
- **Config:** Tactical stats per regiment, terrain/fort modifiers, difficulty, initiative weights in program-level config (colonizethis_data), per [ruleset-config.md](../game/ruleset-config.md) combat group.
- **Turn resolution:** **Combat** phase after Movement (before Build/work); conflict detection → initiative-based battle ordering → resolve each battle → apply casualties and province flips.
- **Minor military parity:** Implement the formula from [factions.md](../game/factions.md) (minor/tribe effective military level ≥ average of all Great Powers); apply at turn start or dedicated step; combat resolver uses it for Minor/Tribe defenders.
- **sim_combat:** CLI tool to run combat resolver on scripted scenarios; inputs (unit compositions, province, fort level, terrain); output winner, casualties, optional log.

---

## Design tasks

All design deliverables must accord with **GDD 06**. Each Phase 3 SPEC sub-doc must stay **≤500 words**; split further if needed. Resolve any conflict between combat and turn-resolution specs before implementation.

| Task | Description | Deliverable |
|------|-------------|-------------|
| **Military roster** | Full Imperialism II regiment table: 28 types, 8 categories, 4 eras; FPN, FPM, RNG, DEF, MVR per type; tech unlocks; generals (medals, deployment, initiative). | [military-units.md](../game/military-units.md) (≤500 words). |
| **Combat rules (GDD 06)** | When combat triggers; attacker vs defender; strength from tactical stats and medals; initiative (composition + general); modifiers (terrain, fort, difficulty); siege (fort levels, wall protection, emplaced artillery); general bonuses; auto-resolve formula; casualties; province flip. | [combat.md](../game/combat.md) (≤500 words). |
| **Siege mechanics** | Fort structure, wall protection, melee/firearms/artillery eligibility per Imperialism II 06-combat. | [siege-mechanics.md](../game/siege-mechanics.md) (≤500 words). |
| **Combat resolution (technical)** | Conflict detection; initiative-based battle ordering; tactical stat aggregation; siege-aware resolver; casualty and flip application; integration with Combat phase. | [combat-resolution.md](../program/combat-resolution.md) (≤500 words). |
| **Turn resolution — combat phase** | Insert Combat phase after Movement, before Build/work; behaviour: conflict detection → initiative ordering → resolve → apply casualties and province flips. | Extend [turn-resolution.md](../program/turn-resolution.md), [turn-resolution-phases.md](../program/turn-resolution-phases.md). |
| **Minor military parity (implementation)** | When to run (turn start or dedicated phase); formula and storage (e.g. effectiveMilitaryLevel on faction); how combat resolver uses it for Minor/Tribe defenders. | Extend [factions.md](../game/factions.md); implementation note in [combat-resolution.md](../program/combat-resolution.md). |
| **sim_combat design** | CLI tool that runs combat resolver on scripted scenarios; inputs (unit compositions, province, fort level, terrain); output winner, casualties, optional log. | [sim-combat.md](../program/sim-combat.md) (≤500 words). |
| **sim_game design** (optional) | Specify CLI tool that runs full game simulation; deterministic default AI; full Phase 3 turn sequence; initial state from file or procedural; output report and optional JSON log. | [sim-game.md](../program/sim-game.md), [sim-game-default-ai.md](../program/sim-game-default-ai.md) (each ≤500 words). |

**Existing specs to align:** [military-units.md](../game/military-units.md) (full military roster), [civilian-units.md](../game/civilian-units.md), [movement.md](../program/movement.md), [orders.md](../program/orders.md) — MoveOrder into enemy province = attack. [ruleset-config.md](../game/ruleset-config.md) — combat parameter group (tactical stats, terrain, fort, initiative, medals).

---

## Dev tasks

Order matters. Implement in sequence; each task assumes the previous is done.

| # | Task | Description |
|---|------|-------------|
| 1 | **Military roster config (colonizethis_data)** | Full regiment table with tactical stats (FPN, FPM, RNG, DEF, MVR) per [military-units.md](../game/military-units.md); terrain modifiers, fort modifiers, difficulty multipliers, initiative weights, medal multipliers. Consumed by combat resolver. No JSON; single source per mvp-scope. |
| 2 | **Unit model — military types and medals (colonizethis_models)** | Extend Unit: unitType enum/string for all 28 military regiment types; medals (0–4). General model: General with medals, optional attachment to garrison/army. Serialization. |
| 3 | **Minor military parity (colonizethis_models + colonizethis_logic)** | Add field on MinorNation/Tribe for effective military level (or equivalent). Implement parity step: compute average of Great Powers' military level; set minor/tribe level. Unit-test with stub GP levels. |
| 4 | **Conflict detection (colonizethis_logic)** | After movement phase: for each province, collect units by faction; if more than one faction present, record battle(s). Attacker = faction that moved in; defender = province owner. Output: list of battles. |
| 5 | **Initiative computation and battle ordering (colonizethis_logic)** | Compute initiative per battle (army composition, general medals). Sort battles by initiative (desc), then province id. Use for resolution order. |
| 6 | **Combat resolver (colonizethis_logic)** | Per battle: aggregate strength from tactical stats (FPN, FPM) and medals; apply siege modifiers (fort level, emplaced artillery); apply terrain/fort/difficulty; run formula → winner, casualties per side. Remove casualty units from world state; if defender eliminated, set province.ownerId to attacker. Deterministic. |
| 7 | **TurnResolver — Combat phase** | Add Combat phase after Movement in TurnResolver. Call conflict detection, initiative ordering, then for each battle call combat resolver; apply all casualties and province flips to WorldState. End-of-turn unchanged. |
| 8 | **Wire app to Phase 3** | Save/load includes any new combat-related state (parity field, unit types, medals, generals). TurnResolver runs combat phase; app/service passes orders as before. No new UI required for Phase 3 (optional: show combat result in log or HUD). |
| 9 | **sim_combat CLI** | Implement sim_combat per [sim-combat.md](../program/sim-combat.md): parse `--script`, `--output`, `--json-output`, `--seed`; construct battle input from script; delegate to combat resolver; write report and optional JSON. Place: `tool/sim_combat/` or `tool/`. |
| 10 | **sim_game — CLI and turn loop** (optional) | Implement sim_game CLI per [sim-game.md](../program/sim-game.md): full game simulation with default AI; full Phase 3 turn sequence including combat. Place: `tool/sim_game/`. |

---

## Test tasks

Tests follow **test/ mirrors lib/** and **\*_test.dart** naming; use **mockito** or **mocktail** for mocks. Save/load remains a critical path; aim for **90% per-package coverage** for Phase 3 packages (colonizethis_models, colonizethis_logic, colonizethis_data where extended).

| Task | Success criteria |
|------|------------------|
| **Build passes** | `flutter pub get` and `flutter build` succeed for app and all packages. |
| **Unit tests — combat config** | Config is loaded; tactical stats per regiment and modifiers readable by resolver. |
| **Unit tests — tactical stat aggregation** | Given unit compositions with types and medals, resolver computes expected effective strength (FPN, FPM, medals). |
| **Unit tests — initiative** | Given two battles with different compositions/generals, initiative ordering yields correct resolution order. |
| **Unit tests — siege modifiers** | Fort level applies damage reduction; emplaced artillery contributes to defender strength. |
| **Unit tests — minor military parity** | Given N Great Powers with military levels, parity step sets each minor/tribe level ≥ average of GPs; serialization if stored on model. |
| **Unit tests — conflict detection** | Given world state after movement with two factions in one province, detection returns one battle with correct attacker/defender; multiple provinces with conflicts return multiple battles. |
| **Unit tests — combat formula** | Given attacker strength, defender strength, modifiers: resolver returns expected winner and casualties; province flip when defender eliminated. |
| **Unit tests — combat resolution** | Apply resolution to a small scenario: one attacker unit, one defender unit in province; after resolve, casualties applied and optionally province flip; no crash when defender wins. |
| **Integration test — one full turn with combat** | Run TurnResolver with initial state where a MoveOrder sends a unit into enemy province; after Movement then Combat phase, assert casualties and/or province ownership change per spec. |
| **Save/load round-trip (critical path)** | Save game state after combat (parity, unit types, medals, generals); load and assert key fields match. |
| **Per-package coverage** | colonizethis_models (if extended), colonizethis_logic aim for 90%; colonizethis_data for combat config. |
| **sim_combat — determinism** | Run sim_combat with same script and `--seed` twice; outputs (report or JSON) are identical. |

---

## Code review tasks

Before marking Phase 3 complete, verify:

| Check | Criteria |
|-------|----------|
| **Package boundaries** | Combat logic in colonizethis_logic; combat config in colonizethis_data; models in colonizethis_models; no game rules in app. |
| **Spec alignment** | All Phase 3 behaviour traceable to a spec section (military-units.md, combat.md, siege-mechanics.md, combat-resolution.md, turn-resolution-phases Combat phase, factions parity, sim-combat.md); no behaviour without authorizing spec. |
| **Phase 3 scope** | Auto-resolve only; no Quick Battle; full military roster; no diplomacy, no AI; no JSON rulesets (program-level config only). |
| **State and lifecycle** | State subscriptions and cleanup follow lifecycle conventions; no leaks. |

---

## Definition of done (Phase 3)

Phase 3 is done when all design and dev tasks are implemented, all test tasks pass, and the code review checklist is signed off.

- [ ] All Design deliverables written and agreed.
- [ ] All Dev tasks implemented.
- [ ] All Test tasks passing.
- [ ] Code review checklist signed off.

**Exit criteria:** Combat triggers on move into enemy province; full military roster and tactical stats; initiative-based battle ordering; siege mechanics; one auto-resolve formula runs; casualties and province flip applied; minor military parity implemented; sim_combat CLI runs; one full turn with combat runs correctly; save/load includes Phase 3 state; ready for Phase 4 (Quick Battle, diplomacy, AI).

---

## Dependencies and order

- **Design** must be done before Dev. All Phase 3 SPEC docs (game + program) must be in repo and agreed.
- **Dev:** Military config and unit model first, then parity, conflict detection, initiative, combat resolver, TurnResolver Combat phase, app wiring, sim_combat.
- **Test** and **Code review** after Dev.

---

## Out of scope for Phase 3

- Diplomacy, war/peace, AI (Phase 4).
- Quick Battle (Phase 4).
- Navy, sea combat.
- JSON rulesets (mvp-scope: program-level config only).

---

## References

- **GDD 06** — Combat (Obsidian).
- [mvp-scope.md](mvp-scope.md) — Phase 3 row: combat, full military roster, tactical stats, initiative, siege, sim_combat.
- [phase-2-project-tasks.md](phase-2-project-tasks.md) — Previous phase; movement and orders.
- [SPEC/game/factions.md](../game/factions.md) — Who initiates/defends; minor military parity.
- [SPEC/game/military-units.md](../game/military-units.md), [civilian-units.md](../game/civilian-units.md) — Full military roster and tactical stats; civilian units.
- [SPEC/game/siege-mechanics.md](../game/siege-mechanics.md) — Fort structure, wall protection, emplaced artillery.
- [SPEC/game/ruleset-config.md](../game/ruleset-config.md) — Combat parameter group.
- [SPEC/program/turn-resolution.md](../program/turn-resolution.md), [turn-resolution-phases.md](../program/turn-resolution-phases.md) — Phase sequence and Combat phase.
- [SPEC/program/movement.md](../program/movement.md), [SPEC/program/orders.md](../program/orders.md) — MoveOrder into enemy province.
- [SPEC/program/sim-combat.md](../program/sim-combat.md) — sim_combat tool.
- `.cursor/rules/colonizethis-testing.mdc` — 90% coverage, critical path (save/load).

---

## Summary: Specs to write or extend

| Spec | Action |
|------|--------|
| **SPEC/game/military-units.md** | New: full regiment roster, tactical stats, era/category, generals (≤500 words). |
| **SPEC/game/combat.md** | Extend: tactical stats as strength, medals, initiative, siege, general bonuses, auto-resolve formula. |
| **SPEC/game/siege-mechanics.md** | New: fort levels, wall protection, emplaced artillery, melee/firearms/artillery rules (≤500 words). |
| **SPEC/program/combat-resolution.md** | Extend: initiative-based battle ordering, tactical stat aggregation, siege-aware resolver. |
| **SPEC/program/turn-resolution.md** | Extend: add Combat phase to sequence. |
| **SPEC/program/turn-resolution-phases.md** | Extend: Combat phase behaviour (conflict detection → initiative ordering → resolve → apply). |
| **SPEC/game/factions.md** | Extend: minor military parity implementation note. |
| **SPEC/program/sim-combat.md** | New: combat simulation CLI — purpose, scope, CLI, script format, output (≤500 words). |
| **SPEC/program/sim-game.md**, **sim-game-default-ai.md** | Optional: full game simulation tool. |

---

## Risks and assumptions

- GDD 06 lives in Obsidian; SPEC (combat.md, military-units.md, siege-mechanics.md, combat-resolution.md) is the in-repo reflection. Design should sync formula and triggers from GDD 06 into SPEC before Dev.
- Move into enemy province is the only attack trigger in Phase 3; no separate AttackOrder.
- Minor military parity is implemented in Phase 3 as specified in [factions.md](../game/factions.md).
- Imperialism II 05-units-military and 06-combat (Obsidian) are the reference for tactical stats and siege mechanics.
