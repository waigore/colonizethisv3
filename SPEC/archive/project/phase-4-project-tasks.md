# Phase 4 — Project tasks

**SPEC/project** — Actionable task list for Phase 4. Quick Battle follows **GDD 06**; diplomacy and AI follow GDD 07, 10. SPEC is the in-repo reflection. Full workflow: **Design → Dev → Test → Code review** per [mvp-scope.md](mvp-scope.md).

**Phasing:** Previous — [phase-3-project-tasks.md](phase-3-project-tasks.md). Next — [phase-5-project-tasks.md](phase-5-project-tasks.md) (victory, tech, leader bonuses).

---

## Purpose

Phase 4 adds **Quick Battle** (streamlined tactical mode per GDD 06), **full diplomacy** (war/peace, alliances, overture chain, relations, Join Empire/Colony, intervention, aid), **order engine** (current-turn order list, validation, projected effects), and **AI** (one personality; AIPlanner; order merge). Six Great Powers default (configurable at game setup). Do not advance to Phase 5 until Phase 4 code review is complete.

---

## Scope (Phase 4)

- **Quick Battle:** Mode choice is per-battle or game-settings default (Auto-Resolve vs Quick Battle). **Capital sieges always use Quick Battle** (no auto-resolve). Quick Battle: deployment, up to 3 turns, CP-based actions; uses same tactical stats and formula as auto-resolve; output feeds same casualty/flip pipeline. No in-progress Quick Battle state in save/load (battles are either resolved or not).
- **Diplomacy (full):** GP–GP: war, peace, alliances, Join Empire when nearly defeated. GP–Minor: declare war required; overture chain (Trade Consulate → Embassy → NAP → Join Empire); relation score, modifiers, foreign aid; intervention when Minor with Embassy attacked. GP–Tribe: no war required to invade unless another GP has invested; same overture chain; Colony outcome. Relation model; diplomacy phase before Movement.
- **AI:** One personality; AIPlanner generates orders; order engine feeds into merge at turn resolution; order merge with human player(s). Six Great Powers default, configurable at game setup.

---

## Design tasks

All design deliverables must accord with **GDD 06** (combat), **GDD 07** (diplomacy), **GDD 10** (AI). Each Phase 4 SPEC sub-doc must stay **≤500 words**; split further if needed.

| Task | Description | Deliverable |
|------|-------------|-------------|
| **Quick Battle (GDD 06)** | One-province-vs-one-province Quick Battle: lanes (LEFT/CENTER/RIGHT/RESERVE), FRONT/SUPPORT lines, lane terrain tags (OPEN/HILL/WOODS/TOWN/SWAMP), cohesion, 3-round CP-based action loop (Volley Fire, Defend/Entrench, Maneuver, Fall Back/Refuse Flank, Assault/Charge); per-battle or settings default for Auto-Resolve vs Quick Battle; **capital sieges must use Quick Battle** (no auto-resolve). No in-progress Quick Battle state in save/load. | [quick-battle.md](../game/quick-battle.md) (≤500 words). |
| **Quick Battle resolution (technical)** | Lane-level resolution pipeline per [quick-battle.md](../game/quick-battle.md): inputs from UI/AI (lane compositions, terrain, cohesion, seed), per-round strength and cohesion updates, deterministic outcomes; output feeds same casualty/flip application as auto-resolve and plugs into Combat phase. | [quick-battle-resolution.md](../program/quick-battle-resolution.md) (≤500 words). |
| **Order engine (full spec)** | Holds current-turn orders per player; on each new order, re-validate the entire current-turn order list for that player against current world state in submission order; first violating order is rejected together with all subsequent orders for that turn. Orders are not applied to world state until turn resolution. Order engine must support projected effects (dry-run application for UI, e.g. worker count next turn). Validation during the turn is per-player only; at turn resolution, orders affecting other players (attacks, diplomacy) are merged and resolved (human+AI merge, cross-player resolution), then applied in phase order. Determinism: submission order preserved; merge uses stable ordering. | [order-engine.md](../program/order-engine.md) (≤500 words; split if needed). |
| **Diplomacy (full) — game** | Per GDD 07 / Imperialism II: GP–GP war/peace/alliances/Join Empire (when nearly defeated); GP–Minor declare war required, overture chain (Trade Consulate → Embassy → NAP → Join Empire), relation score 0–100, modifiers, foreign aid, intervention when Minor with Embassy attacked; GP–Tribe no war required to invade unless another GP invested, same overture chain, Colony outcome. Relation levels; Tribe vs Minor war rule. | [diplomacy.md](../game/diplomacy.md) (extend; split into sub-docs if >500 words). |
| **Diplomacy (full) — technical** | Relation model (per-pair, score, level, sinceTurn, lastInteractionTurn); overture state machine per Minor/Tribe; diplomatic order types (DeclareWar, OfferPeace, Alliance, EstablishOverture, GrantAid, SetSubsidy, etc.); diplomacy phase resolution order (overture payments, advance overtures, Join Empire/Colony, alliance/peace/war, relation updates); integration with TurnResolver (phase before Movement) and economy (grants from treasury, trade slots by embassy). | [diplomacy-resolution.md](../program/diplomacy-resolution.md) or extend [turn-resolution-phases.md](../program/turn-resolution-phases.md) (≤500 words). |
| **AI (one personality)** | Default AI behaviour and AIPlanner: control rules (human vs AI GPs), per-AI seeds and per-turn seeds, order generation (movement/build/work) respecting diplomacy constraints, tactical Quick Battle heuristics, and order merge behaviour with human players. Order merge: precedence (e.g. human over AI for same entity) and conflict definition; merge runs at turn resolution after per-player order engine validation. | [ai-planner.md](../program/ai-planner.md) or extend [sim-game-default-ai.md](../program/sim-game-default-ai.md); ensure [orders.md](../program/orders.md) defines merge precedence and conflict cases (≤500 words). |

**Existing specs to align:** [combat.md](../game/combat.md), [combat-resolution.md](../program/combat-resolution.md), [orders.md](../program/orders.md), [order-engine.md](../program/order-engine.md), [diplomacy-resolution.md](../program/diplomacy-resolution.md) (or turn-resolution-phases).

---

## Dev tasks

Order matters. Implement in sequence; each task assumes the previous is done.

| # | Task | Description |
|---|------|-------------|
| 1 | **Combat mode selection** | When conflict detected, present choice: Auto-Resolve or Quick Battle (per-battle or game-settings default). Capital sieges force Quick Battle. Store preference or per-battle; default Auto-Resolve. |
| 2 | **Quick Battle — models and config** | In `colonizethis_models` and `colonizethis_data`, add types and config needed for Quick Battle: lanes and lines per side (LEFT/CENTER/RIGHT/RESERVE; FRONT/SUPPORT), lane terrain tags, cohesion values per group, and any additional parameters required by [quick-battle.md](../game/quick-battle.md) and [quick-battle-resolution.md](../program/quick-battle-resolution.md). Ensure save/load covers new state. |
| 3 | **Quick Battle — resolution pipeline** | Implement Quick Battle flow per [quick-battle-resolution.md](../program/quick-battle-resolution.md): 3-round CP-based loop, lane-level strength and cohesion updates, deterministic resolution using shared combat config; output casualties and province flip; feed same application logic as auto-resolve. |
| 4 | **Quick Battle — UI** | UI for mode choice; deployment screen mapping units to lanes/lines; turn flow with CP-based action selection (Volley Fire, Defend/Entrench, Maneuver, Fall Back/Refuse Flank, Assault/Charge); result display. Flutter/Flame integration. |
| 5 | **Order engine (colonizethis_logic)** | Implement order engine per [order-engine.md](../program/order-engine.md): hold current-turn orders per player; on add/remove, re-validate full list in submission order; reject first invalid and all subsequent; expose projected-effects dry-run for UI (no world state mutation). |
| 6 | **Order engine — turn resolution integration** | Turn resolution: accept per-player order lists from order engine; merge human + AI with defined precedence; resolve cross-player (attacks, diplomacy); apply merged/resolved orders in phase order. No application inside order engine. |
| 7 | **Diplomacy model (colonizethis_models + colonizethis_logic)** | Implement full relation model (score 0–100, level), overture state per Minor/Tribe, diplomatic order types; save/load; enforce Tribe vs Minor war rule (attack on Tribe without declaration unless GP invested; attack on Minor requires `AT_WAR`). |
| 8 | **Diplomacy phase (colonizethis_logic)** | Implement Diplomacy phase per [diplomacy.md](../game/diplomacy.md) and [diplomacy-resolution.md](../program/diplomacy-resolution.md): overture payments, advance overtures, Join Empire/Colony resolution, alliance proposals/accept/refuse, Declare War, Peace; relation updates; phase runs before Movement per [turn-resolution-phases.md](../program/turn-resolution-phases.md). |
| 9 | **Diplomacy — economy and intervention** | GrantAid from treasury; relation modifiers; trade slots by embassy; war terminates agreements. Intervention event when Minor with Embassy attacked (Intervene / Do Nothing / Protest); update relations. |
| 10 | **AIPlanner (colonizethis_logic)** | Implement AIPlanner per [ai-planner.md](../program/ai-planner.md): assign AI vs human control, derive per-AI and per-turn seeds, and given `WorldState` produce Orders for AI-controlled GPs (movement, optional build/work) that respect diplomacy and use shared RNG. |
| 11 | **Order merge** | Implement deterministic order merge at turn resolution; precedence and conflict definition per [ai-planner.md](../program/ai-planner.md) or [orders.md](../program/orders.md); merge consumes order-engine output (per-player lists); pass final order list to TurnResolver. |
| 12 | **Wire app to Phase 4** | Combat mode choice; Quick Battle UI; order engine (validation feedback, projected effects in UI); full diplomacy UI (overtures, alliances, relations, aid); AI order generation; save/load includes diplomacy relations and AI control/seeds (no Quick Battle in-progress state — only resolved battles or pre-battle state). |

---

## Test tasks

Tests follow **test/ mirrors lib/** and **\*_test.dart** naming; use **mockito** or **mocktail** for mocks. Save/load remains a critical path; aim for **90% per-package coverage** for Phase 4 packages.

| Task | Success criteria |
|------|------------------|
| **Build passes** | `flutter pub get` and `flutter build` succeed for app and all packages. |
| **Unit tests — combat mode selection** | Given conflicts in multiple provinces, combat mode selection defaults to Auto-Resolve; per-battle or settings default respected; capital siege always uses Quick Battle. |
| **Unit tests — Quick Battle resolution** | Given a deployment, lane terrain, cohesion, and a sequence of actions, Quick Battle resolver produces deterministic, same-form output as auto-resolve (casualties, province flip) for a fixed seed. |
| **Unit tests — order engine** | Add orders in sequence; first invalid order plus all subsequent rejected; projected effects match dry-run (e.g. one build → +1 worker in projection). |
| **Unit tests — diplomacy** | War/peace state updates correctly per `diplomacy.md`; movement/combat validation prevents attacks while `AT_PEACE` and allows them only when `AT_WAR`; full diplomacy (overture state, Join Empire, alliances, relation updates, intervention stub if in scope). |
| **Unit tests — AIPlanner** | Given WorldState and seeds, AIPlanner produces valid Orders for AI-controlled GPs; repeated runs with the same seeds yield identical orders. |
| **Unit tests — order merge** | Given overlapping human and AI orders, merge is deterministic, applies precedence rules, and drops or flags invalid orders without affecting determinism. |
| **Integration test — Quick Battle flow** | Trigger conflict, select Quick Battle, run deployment and 3 rounds of CP-based actions, and verify casualties and province flip are applied correctly to WorldState. |
| **Integration test — AI vs human** | Run a turn with one human GP and one AI GP; AIPlanner generates orders, TurnResolver runs full sequence (including diplomacy checks and Quick Battle where chosen), and results are consistent across runs with the same seeds. |
| **Integration test — order engine + merge** | At turn resolution, per-player lists from order engine are merged and applied; cross-player effects (combat, diplomacy) resolved correctly; determinism with same seeds. |
| **Save/load round-trip (critical path)** | Quick Battle has no in-progress state; save contains either resolved battle outcomes or no mid-battle state; load does not resume a Quick Battle. Save diplomacy relations and AI control/seeds; load and assert key fields match and behaviour remains deterministic. |
| **Per-package coverage** | `colonizethis_logic` (Quick Battle, order engine, diplomacy, AIPlanner, order merge) and any extended models/data aim for 90%. |

---

## Code review tasks

Before marking Phase 4 complete, verify:

| Check | Criteria |
|-------|----------|
| **Package boundaries** | Combat/Quick Battle logic in colonizethis_logic; order engine in colonizethis_logic; diplomacy in colonizethis_logic; AIPlanner in colonizethis_logic; UI in app. |
| **Spec alignment** | All Phase 4 behaviour traceable to quick-battle.md, quick-battle-resolution.md, order-engine.md, diplomacy, diplomacy-resolution (or turn-resolution-phases), ai-planner; no behaviour without authorizing spec. |
| **Phase 4 scope** | Quick Battle + full diplomacy (overtures, alliances, relations, Join Empire/Colony, intervention, aid) + order engine + one AI personality; no JSON rulesets. |
| **State and lifecycle** | State subscriptions and cleanup follow lifecycle conventions; no leaks. |

---

## Definition of done (Phase 4)

Phase 4 is done when all design and dev tasks are implemented, all test tasks pass, and the code review checklist is signed off.

- [ ] All Design deliverables written and agreed.
- [ ] All Dev tasks implemented.
- [ ] All Test tasks passing.
- [ ] Code review checklist signed off.

**Exit criteria:** Quick Battle available as combat mode (capital sieges Quick Battle only); full diplomacy works (war/peace, alliances, overtures, relations, Join Empire/Colony, aid, intervention); order engine holds and validates current-turn orders; projected effects available; merge at resolution; AI generates orders for AI-controlled GPs; one full turn with AI runs correctly; save/load includes Phase 4 state; ready for Phase 5 (victory, tech, leader bonuses).

---

## Dependencies and order

- **Design** must be done before Dev. Order engine spec, full diplomacy (game + technical), Quick Battle capital-siege and mode rules, merge precedence in ai-planner/orders — all Phase 4 SPEC docs must be in repo and agreed.
- **Dev:** Quick Battle (1–4) → Order engine + turn-resolution integration (5–6) → Diplomacy model and phase (7–9) → AIPlanner (10) → Order merge (11) → Wire app (12).
- **Test** and **Code review** after Dev.

---

## Out of scope for Phase 4

- Multiple AI personalities; leader-specific AI.
- Leader bonuses (Phase 5).
- Victory condition, tech tree (Phase 5).
- JSON rulesets (mvp-scope: program-level config only).

---

## References

- **GDD 06** — Combat, Quick Battle (Obsidian).
- **GDD 07** — Diplomacy (Obsidian).
- **GDD 10** — AI systems (Obsidian).
- [mvp-scope.md](mvp-scope.md) — Phase 4 row: Quick Battle, diplomacy, AI.
- [phase-3-project-tasks.md](phase-3-project-tasks.md) — Previous phase; combat, military roster.
- [SPEC/game/combat.md](../game/combat.md), [combat-resolution.md](../program/combat-resolution.md) — Combat and resolution pipeline.
- [SPEC/program/orders.md](../program/orders.md) — Order types and merge.
- [SPEC/program/order-engine.md](../program/order-engine.md) — Order engine and validation.
- [SPEC/program/diplomacy-resolution.md](../program/diplomacy-resolution.md) (or [turn-resolution-phases.md](../program/turn-resolution-phases.md)) — Diplomacy phase.
- `.cursor/rules/colonizethis-testing.mdc` — 90% coverage, critical path (save/load).

---

## Summary: Specs to write or extend

| Spec | Action |
|------|--------|
| **SPEC/game/quick-battle.md** | New: Quick Battle flow, deployment, 3 turns, CP-based actions; per-battle or settings default; capital sieges Quick Battle only; no in-progress save (≤500 words). |
| **SPEC/program/quick-battle-resolution.md** | New: technical pipeline; input from UI; output to casualty/flip application (≤500 words). |
| **SPEC/program/order-engine.md** | New: order engine and validation fully specified (≤500 words; split if needed). |
| **SPEC/game/diplomacy.md** | Extend: full diplomacy (game rules) — relation model, GP–GP/Minor/Tribe, overture chain, Tribe vs Minor war rule, intervention, aid (split into sub-docs if >500 words). |
| **SPEC/program/diplomacy-resolution.md** | New (or extend turn-resolution-phases): technical diplomacy — relation model, overture state machine, order types, phase resolution order, TurnResolver/economy integration (≤500 words). |
| **SPEC/program/ai-planner.md** | New or extend: one personality, order generation, merge precedence and conflict definition (≤500 words). |

---

## Risks and assumptions

- GDD 06, 07, 10 live in Obsidian; SPEC is the in-repo reflection.
- Quick Battle reuses tactical stats and formula from auto-resolve; only the input (human/AI orders) and presentation differ.
- AI personality is minimal: first valid move, optional build/work; no complex strategy.
- Order engine validation is per-player only during the turn; cross-player resolution (combat, diplomacy) happens once at turn resolution.
- Full diplomacy (overtures, alliances, Join Empire/Colony, intervention) is in Phase 4 scope; all rules documented in SPEC/game and SPEC/program.
