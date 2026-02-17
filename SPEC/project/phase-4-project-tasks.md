# Phase 4 — Project tasks

**SPEC/project** — Actionable task list for Phase 4. Quick Battle follows **GDD 06**; diplomacy and AI follow GDD 07, 10. SPEC is the in-repo reflection. Full workflow: **Design → Dev → Test → Code review** per [mvp-scope.md](mvp-scope.md).

**Phasing:** Previous — [phase-3-project-tasks.md](phase-3-project-tasks.md). Next — [phase-5-project-tasks.md](phase-5-project-tasks.md) (victory, tech, leader bonuses).

---

## Purpose

Phase 4 adds **Quick Battle** (streamlined tactical mode per GDD 06), **minimal diplomacy** (war/peace), and **AI** (one personality; AIPlanner; order merge). Do not advance to Phase 5 until Phase 4 code review is complete.

---

## Scope (Phase 4)

- **Quick Battle:** Per-battle mode choice (Auto-Resolve vs Quick Battle). Quick Battle: deployment, up to 3 turns, simplified orders (Attack/Defend/Fall Back); uses same tactical stats and formula as auto-resolve; output feeds same casualty/flip pipeline.
- **Diplomacy (minimal):** War/peace; no overture chain or alliances.
- **AI:** One personality; AIPlanner generates orders; order merge with human player(s); 7 Great Powers configurable.

---

## Design tasks

All design deliverables must accord with **GDD 06** (combat), **GDD 07** (diplomacy), **GDD 10** (AI). Each Phase 4 SPEC sub-doc must stay **≤500 words**; split further if needed.

| Task | Description | Deliverable |
|------|-------------|-------------|
| **Quick Battle (GDD 06)** | One-province-vs-one-province Quick Battle: lanes (LEFT/CENTER/RIGHT/RESERVE), FRONT/SUPPORT lines, lane terrain tags (OPEN/HILL/WOODS/TOWN/SWAMP), cohesion, 3-round CP-based action loop (Volley Fire, Defend/Entrench, Maneuver, Fall Back/Refuse Flank, Assault/Charge); per-battle mode choice vs auto-resolve. | [quick-battle.md](../game/quick-battle.md) (≤500 words). |
| **Quick Battle resolution (technical)** | Lane-level resolution pipeline per [quick-battle.md](../game/quick-battle.md): inputs from UI/AI (lane compositions, terrain, cohesion, seed), per-round strength and cohesion updates, deterministic outcomes; output feeds same casualty/flip application as auto-resolve and plugs into Combat phase. | [quick-battle-resolution.md](../program/quick-battle-resolution.md) (≤500 words). |
| **Diplomacy (minimal)** | Per-player-pair relation state (`AT_PEACE`/`AT_WAR`, `sinceTurn`, `lastInteractionTurn`); explicit `Declare War` and white peace actions; no overture chain or alliances; combat gated by `AT_WAR`. | [diplomacy.md](../game/diplomacy.md) or extend existing (≤500 words). |
| **AI (one personality)** | Default AI behaviour and AIPlanner: control rules (human vs AI GPs), per-AI seeds and per-turn seeds, order generation (movement/build/work) respecting diplomacy constraints, tactical Quick Battle heuristics, and order merge behaviour with human players. | [ai-planner.md](../program/ai-planner.md) or extend [sim-game-default-ai.md](../program/sim-game-default-ai.md) (≤500 words). |

**Existing specs to align:** [combat.md](../game/combat.md), [combat-resolution.md](../program/combat-resolution.md), [orders.md](../program/orders.md).

---

## Dev tasks

Order matters. Implement in sequence; each task assumes the previous is done.

| # | Task | Description |
|---|------|-------------|
| 1 | **Combat mode selection** | When conflict detected, present choice: Auto-Resolve or Quick Battle. Store preference or per-battle; default Auto-Resolve. |
| 2 | **Quick Battle — models and config** | In `colonizethis_models` and `colonizethis_data`, add types and config needed for Quick Battle: lanes and lines per side (LEFT/CENTER/RIGHT/RESERVE; FRONT/SUPPORT), lane terrain tags, cohesion values per group, and any additional parameters required by [quick-battle.md](../game/quick-battle.md) and [quick-battle-resolution.md](../program/quick-battle-resolution.md). Ensure save/load covers new state. |
| 3 | **Quick Battle — resolution pipeline** | Implement Quick Battle flow per [quick-battle-resolution.md](../program/quick-battle-resolution.md): 3-round CP-based loop, lane-level strength and cohesion updates, deterministic resolution using shared combat config; output casualties and province flip; feed same application logic as auto-resolve. |
| 4 | **Quick Battle — UI** | UI for mode choice; deployment screen mapping units to lanes/lines; turn flow with CP-based action selection (Volley Fire, Defend/Entrench, Maneuver, Fall Back/Refuse Flank, Assault/Charge); result display. Flutter/Flame integration. |
| 5 | **Diplomacy model (colonizethis_models + colonizethis_logic)** | Implement per-pair relation state in world model (`AT_PEACE`/`AT_WAR`, `sinceTurn`, `lastInteractionTurn`) and update logic; ensure save/load persists relations; enforce diplomacy constraints when validating movement/combat orders (no combat unless `AT_WAR`). |
| 6 | **Diplomacy phase (colonizethis_logic)** | Implement Diplomacy phase per [diplomacy.md](../game/diplomacy.md): explicit `Declare War` and white peace actions; update relation records; integrate with `TurnResolver` order in [turn-resolution-phases.md](../program/turn-resolution-phases.md). |
| 7 | **AIPlanner (colonizethis_logic)** | Implement AIPlanner per [ai-planner.md](../program/ai-planner.md): assign AI vs human control, derive per-AI and per-turn seeds, and given `WorldState` produce Orders for AI-controlled GPs (movement, optional build/work) that respect diplomacy and use shared RNG. |
| 8 | **Order merge** | Implement deterministic order merge: combine human orders with AI orders, resolve conflicts by clear precedence, validate against diplomacy/world state, and pass final order list to TurnResolver. |
| 9 | **Wire app to Phase 4** | Combat mode choice; Quick Battle UI; diplomacy UI (minimal war/peace interactions); AI order generation; save/load includes Quick Battle state, diplomacy relations, and AI control/seeds. |

---

## Test tasks

Tests follow **test/ mirrors lib/** and **\*_test.dart** naming; use **mockito** or **mocktail** for mocks. Save/load remains a critical path; aim for **80% per-package coverage** for Phase 4 packages.

| Task | Success criteria |
|------|------------------|
| **Build passes** | `flutter pub get` and `flutter build` succeed for app and all packages. |
| **Unit tests — combat mode selection** | Given conflicts in multiple provinces, combat mode selection defaults to Auto-Resolve; per-battle Quick Battle choice is stored and respected in resolution. |
| **Unit tests — Quick Battle resolution** | Given a deployment, lane terrain, cohesion, and a sequence of actions, Quick Battle resolver produces deterministic, same-form output as auto-resolve (casualties, province flip) for a fixed seed. |
| **Unit tests — diplomacy** | War/peace state updates correctly per `diplomacy.md`; movement/combat validation prevents attacks while `AT_PEACE` and allows them only when `AT_WAR`. |
| **Unit tests — AIPlanner** | Given WorldState and seeds, AIPlanner produces valid Orders for AI-controlled GPs; repeated runs with the same seeds yield identical orders. |
| **Unit tests — order merge** | Given overlapping human and AI orders, merge is deterministic, applies precedence rules, and drops or flags invalid orders without affecting determinism. |
| **Integration test — Quick Battle flow** | Trigger conflict, select Quick Battle, run deployment and 3 rounds of CP-based actions, and verify casualties and province flip are applied correctly to WorldState. |
| **Integration test — AI vs human** | Run a turn with one human GP and one AI GP; AIPlanner generates orders, TurnResolver runs full sequence (including diplomacy checks and Quick Battle where chosen), and results are consistent across runs with the same seeds. |
| **Save/load round-trip (critical path)** | Save game state with Quick Battle state (if any in progress or logged), diplomacy relations, and AI control/seeds; load and assert key fields match and behaviour remains deterministic. |
| **Per-package coverage** | `colonizethis_logic` (Quick Battle, diplomacy, AIPlanner, order merge) and any extended models/data aim for 80%. |

---

## Code review tasks

Before marking Phase 4 complete, verify:

| Check | Criteria |
|-------|----------|
| **Package boundaries** | Combat/Quick Battle logic in colonizethis_logic; diplomacy in colonizethis_logic; AIPlanner in colonizethis_logic; UI in app. |
| **Spec alignment** | All Phase 4 behaviour traceable to quick-battle.md, quick-battle-resolution.md, diplomacy, ai-planner; no behaviour without authorizing spec. |
| **Phase 4 scope** | Quick Battle + minimal diplomacy + one AI personality; no full diplomacy (overture chain, alliances); no JSON rulesets. |
| **State and lifecycle** | State subscriptions and cleanup follow lifecycle conventions; no leaks. |

---

## Definition of done (Phase 4)

Phase 4 is done when all design and dev tasks are implemented, all test tasks pass, and the code review checklist is signed off.

- [ ] All Design deliverables written and agreed.
- [ ] All Dev tasks implemented.
- [ ] All Test tasks passing.
- [ ] Code review checklist signed off.

**Exit criteria:** Quick Battle available as combat mode; minimal diplomacy (war/peace) works; AI generates orders for AI-controlled GPs; one full turn with AI runs correctly; save/load includes Phase 4 state; ready for Phase 5 (victory, tech, leader bonuses).

---

## Dependencies and order

- **Design** must be done before Dev. All Phase 4 SPEC docs must be in repo and agreed.
- **Dev:** Quick Battle resolution pipeline first, then UI; diplomacy phase; AIPlanner; order merge; app wiring.
- **Test** and **Code review** after Dev.

---

## Out of scope for Phase 4

- Full diplomacy (overture chain, alliances, Join Empire).
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
- `.cursor/rules/colonizethis-testing.mdc` — 80% coverage, critical path (save/load).

---

## Summary: Specs to write or extend

| Spec | Action |
|------|--------|
| **SPEC/game/quick-battle.md** | New: Quick Battle flow, deployment, 3 turns, Attack/Defend/Fall Back; per-battle mode choice (≤500 words). |
| **SPEC/program/quick-battle-resolution.md** | New: technical pipeline; input from UI; output to casualty/flip application (≤500 words). |
| **SPEC/game/diplomacy.md** | New or extend: minimal diplomacy (war/peace) (≤500 words). |
| **SPEC/program/ai-planner.md** | New or extend: one personality, order generation, merge (≤500 words). |

---

## Risks and assumptions

- GDD 06, 07, 10 live in Obsidian; SPEC is the in-repo reflection.
- Quick Battle reuses tactical stats and formula from auto-resolve; only the input (human/AI orders) and presentation differ.
- AI personality is minimal: first valid move, optional build/work; no complex strategy.
