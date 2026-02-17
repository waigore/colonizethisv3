# Phase 5 — Project tasks

**SPEC/project** — Actionable task list for Phase 5. Victory and tech follow **GDD 01, 08**; leader bonuses follow **GDD 09**. SPEC is the in-repo reflection. Full workflow: **Design → Dev → Test → Code review** per [mvp-scope.md](mvp-scope.md).

**Phasing:** Previous — [phase-4-project-tasks.md](phase-4-project-tasks.md). Next — Phase 6 (pixel-art, main menu).

---

## Purpose

Phase 5 adds **military victory** (31+ Old World provinces), a **small tech tree** (1–2 eras), and **leader bonuses** (ColonizeThis-specific: Victoria, Napoleon, etc. per GDD 09) that affect combat. Do not advance to Phase 6 until Phase 5 code review is complete.

---

## Scope (Phase 5)

- **Victory:** Military only: control 31+ Old World provinces; victory screen.
- **Tech tree:** 1–2 eras; regiment unlocks; extraction cap; research phase.
- **Leader bonuses:** Per-GP leader selection at game start; combat bonuses (e.g. +20% attack, vs Tribes bonus) apply in auto-resolve and Quick Battle.

---

## Design tasks

All design deliverables must accord with **GDD 01** (victory), **GDD 08** (technology), **GDD 09** (Great Powers, leaders). Each Phase 5 SPEC sub-doc must stay **≤500 words**; split further if needed.

| Task | Description | Deliverable |
|------|-------------|-------------|
| **Victory condition** | Military: 31+ OW provinces; victory check at end of turn; victory screen. | [victory.md](../game/victory.md) or extend [world-model.md](../game/world-model.md) (≤500 words). |
| **Tech tree (1–2 eras)** | Small tech tree; regiment unlocks per era; extraction cap; research phase; tech costs and prerequisites. | [tech-tree.md](../game/tech-tree.md) or extend [tech-and-extraction-cap.md](../game/tech-and-extraction-cap.md) (≤500 words). |
| **Leader bonuses** | Per-GP leader; combat bonuses (e.g. Victoria +20% naval, Napoleon +25% melee, Isabella +30% vs Tribes); when and how they apply (auto-resolve, Quick Battle). | [leader-bonuses.md](../game/leader-bonuses.md) or extend great-powers if exists (≤500 words). |

**Existing specs to align:** [combat.md](../game/combat.md), [combat-resolution.md](../program/combat-resolution.md), [military-units.md](../game/military-units.md).

---

## Dev tasks

Order matters. Implement in sequence; each task assumes the previous is done.

| # | Task | Description |
|---|------|-------------|
| 1 | **Victory check (colonizethis_logic)** | At end of turn (or after Combat), check: does any GP control 31+ OW provinces? If yes, set victory state (winner, victory type). |
| 2 | **Victory screen (app)** | UI: victory screen showing winner, victory type; option to return to main menu or view final state. |
| 3 | **Tech tree config (colonizethis_data)** | Tech list: 1–2 eras; regiment unlocks; extraction cap; costs and prerequisites. Program-level config. |
| 4 | **Research phase (colonizethis_logic)** | Research phase in turn resolution: GPs allocate research; tech completion unlocks regiments and extraction cap. |
| 5 | **Leader model (colonizethis_models)** | Leader type per GP (e.g. Victoria, Napoleon); selected at game start; serialized with Game. |
| 6 | **Leader bonuses in combat** | Combat resolver reads leader type; applies bonus (e.g. +20% attacker strength for Napoleon) per [leader-bonuses.md](../game/leader-bonuses.md). |
| 7 | **Leader selection (app)** | UI: at game start, each human player selects leader (or default); AI GPs get assigned leaders. |
| 8 | **Wire app to Phase 5** | Victory check triggers victory screen; research phase runs; leader selection at game start; save/load includes tech state, leader, victory. |

---

## Test tasks

Tests follow **test/ mirrors lib/** and **\*_test.dart** naming; use **mockito** or **mocktail** for mocks. Save/load remains a critical path; aim for **80% per-package coverage** for Phase 5 packages.

| Task | Success criteria |
|------|------------------|
| **Build passes** | `flutter pub get` and `flutter build` succeed for app and all packages. |
| **Unit tests — victory check** | Given WorldState where GP has 31+ OW provinces, victory check sets winner; 30 provinces does not. |
| **Unit tests — research phase** | Research allocation completes tech; regiment unlock and extraction cap updated. |
| **Unit tests — leader bonuses** | Combat resolver applies correct bonus for leader type (e.g. Napoleon +25% melee). |
| **Integration test — victory** | Run game until one GP controls 31+ OW provinces; victory screen appears. |
| **Integration test — tech unlock** | Research tech; new regiment type becomes buildable. |
| **Save/load round-trip (critical path)** | Save game state with tech, leader, victory; load and assert key fields match. |
| **Per-package coverage** | colonizethis_logic (victory, research, leader bonus application) aim for 80%. |

---

## Code review tasks

Before marking Phase 5 complete, verify:

| Check | Criteria |
|-------|----------|
| **Package boundaries** | Victory and research logic in colonizethis_logic; tech config in colonizethis_data; leader model in colonizethis_models; UI in app. |
| **Spec alignment** | All Phase 5 behaviour traceable to victory.md, tech-tree.md, leader-bonuses.md; no behaviour without authorizing spec. |
| **Phase 5 scope** | Military victory only; 1–2 eras tech; leader bonuses; no alternative victory types; no full tech tree. |
| **State and lifecycle** | State subscriptions and cleanup follow lifecycle conventions; no leaks. |

---

## Definition of done (Phase 5)

Phase 5 is done when all design and dev tasks are implemented, all test tasks pass, and the code review checklist is signed off.

- [ ] All Design deliverables written and agreed.
- [ ] All Dev tasks implemented.
- [ ] All Test tasks passing.
- [ ] Code review checklist signed off.

**Exit criteria:** Victory triggers when GP controls 31+ OW provinces; victory screen appears; tech tree (1–2 eras) unlocks regiments and extraction cap; leader bonuses apply in combat; leader selection at game start; save/load includes Phase 5 state; ready for Phase 6 (pixel-art, main menu).

---

## Dependencies and order

- **Design** must be done before Dev. All Phase 5 SPEC docs must be in repo and agreed.
- **Dev:** Victory check first, then victory screen; tech config and research phase; leader model and bonuses; leader selection UI; app wiring.
- **Test** and **Code review** after Dev.

---

## Out of scope for Phase 5

- Alternative victory types (Economic, Scientific, Peaceful, Score).
- Full tech tree; all four eras.
- Navy, sea combat.
- JSON rulesets (mvp-scope: program-level config only).

---

## References

- **GDD 01** — Core loop, victory (Obsidian).
- **GDD 08** — Technology (Obsidian).
- **GDD 09** — Great Powers, leaders (Obsidian).
- [mvp-scope.md](mvp-scope.md) — Phase 5 row: victory, tech tree, 1–2 eras.
- [phase-4-project-tasks.md](phase-4-project-tasks.md) — Previous phase; Quick Battle, diplomacy, AI.
- [SPEC/game/combat.md](../game/combat.md), [combat-resolution.md](../program/combat-resolution.md) — Combat and leader bonus application.
- [SPEC/game/military-units.md](../game/military-units.md) — Regiment types and tech unlocks.
- `.cursor/rules/colonizethis-testing.mdc` — 80% coverage, critical path (save/load).

---

## Summary: Specs to write or extend

| Spec | Action |
|------|--------|
| **SPEC/game/victory.md** | New: military victory (31+ OW provinces); victory check; victory screen (≤500 words). |
| **SPEC/game/tech-tree.md** | New or extend tech-and-extraction-cap: 1–2 eras; regiment unlocks; extraction cap; research phase (≤500 words). |
| **SPEC/game/leader-bonuses.md** | New: per-GP leader; combat bonus table; when and how applied (≤500 words). |

---

## Risks and assumptions

- GDD 01, 08, 09 live in Obsidian; SPEC is the in-repo reflection.
- Leader bonuses are ColonizeThis-specific (not from Imperialism II); GDD 09 defines the bonus table.
- Tech tree in Phase 5 is minimal (1–2 eras); full tree is post-MVP.
