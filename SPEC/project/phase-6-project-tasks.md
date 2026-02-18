# Phase 6 — Project tasks

**SPEC/project** — Actionable task list for Phase 6. Full AI follows **GDD 10** (ai/); pixel-art and main menu follow UXD. Full workflow: **Design → Dev → Test → Code review** per [mvp-scope.md](mvp-scope.md).

**Phasing:** Previous — [phase-5-project-tasks.md](phase-5-project-tasks.md). Phase 6 is the final MVP logic phase.

---

## Purpose

Phase 6 adds **full hybrid AI** (architecture, personalities, hidden agendas, dialogue and mood signaling, dossier) and **pixel-art canon, asset set, main menu** per UXD. The Phase 4 minimal AIPlanner remains available for tooling; Phase 6 full AI supersedes it for standard gameplay. ctdev must support a toggle to choose simple (Phase 4) vs full (Phase 6) AI. Do not consider MVP complete until Phase 6 code review is done.

---

## Scope (Phase 6)

- **Full AI (colonizethis_ai):** Hybrid stack (behavior trees + utility AI + shallow tactical); perception from PlayerView only; personality-driven goal selection and domain planning; hidden agenda assignment (deterministic, seed-based) and behavior modifiers; evidence accumulation and PlayerView-safe dossier projection; dialogue and portrait-mood event emission. Single AI algorithm; difficulty affects only starting parameters and ruleset modifiers.
- **Naval completion:** Full naval system built on Phase 5 foundations: missions (Patrol, Blockade, Beachhead, Defend), naval interception and retreat, naval combat resolution (BattleContextSea), and trade/transport raids; navy must be fully playable end-to-end by Phase 6 exit.
- **Pixel-art and main menu:** Asset pipeline, Flame/Flutter integration, main menu per UXD; styling applied to existing UIs.
- **ctdev:** Toggle to run with simple AI (Phase 4) or full AI (Phase 6) when simulating games.

---

## Design tasks

All design deliverables must accord with **GDD 10** (AI) and UXD for assets/menu. Each SPEC sub-doc must stay **≤500 words**; split further if needed.

| Task | Description | Deliverable |
|------|-------------|-------------|
| **Full AI architecture** | Hybrid stack, turn pipeline (perception → goals → domain planners → orders), seeding, PlayerView-only rule, package boundary (colonizethis_ai). | [SPEC/ai/ai-architecture.md](../ai/ai-architecture.md), [SPEC/program/ai-systems-impl.md](../program/ai-systems-impl.md). |
| **AI personalities** | Leader list, archetypes, domain weights, behavioral modifiers; config in colonizethis_data. | [SPEC/ai/ai-personalities.md](../ai/ai-personalities.md). |
| **Hidden agendas and dossier** | Agenda types, deterministic assignment, behavior modifiers, evidence rules, suspicion levels, dossier sections and PlayerView-safe projection. | [SPEC/ai/hidden-agendas.md](../ai/hidden-agendas.md), [SPEC/ai/ai-dossier.md](../ai/ai-dossier.md), [SPEC/program/ai-events-and-dossier.md](../program/ai-events-and-dossier.md). |
| **Dialogue and mood signaling** | DialogueEvent and PortraitMoodEvent models; categories and situations; mood state machine for negotiations; when to emit. | [SPEC/ai/dialogue-and-mood.md](../ai/dialogue-and-mood.md). |
| **Pixel-art and main menu (UXD)** | Asset pipeline, main menu flows, styling for existing UIs. | Per UXD; no new SPEC doc required if already defined. |
| **Naval completion (game + program)** | Finalize naval missions, interception, retreat, naval combat resolution, and trade/transport raids per ships-and-naval and naval-* program specs. | Extend [ships-and-naval.md](../game/ships-and-naval.md), [naval-movement-resolution.md](../program/naval-movement-resolution.md), [naval-combat-resolution.md](../program/naval-combat-resolution.md) as needed. |

**Existing specs to align:** [ai-planner.md](../program/ai-planner.md), [order-engine.md](../program/order-engine.md), [player-view.md](../program/player-view.md).

---

## Dev tasks

Order matters. Implement in sequence; each task assumes the previous is done.

### Full AI (colonizethis_ai)

| # | Task | Description |
|---|------|-------------|
| 1 | **colonizethis_ai package** | Create package skeleton: pubspec, core interfaces (strategic order generation, tactical decisions), seed bundle and derivation from turnSeed. |
| 2 | **Perception and PlayerView adapter** | Build AIWorldSnapshot from PlayerView (threats, opportunities, economy, relations). No direct Game access for visibility. |
| 3 | **Behavior-tree goal manager** | Goal selection (defend, expand, conquer, trade, tech, diplomacy) using personality weights and hidden agenda modifiers. |
| 4 | **Domain planners (utility AI)** | Economy, military, diplomacy, research planners: call order suggestion API from colonizethis_logic; score candidates with personality and agenda; emit orders. |
| 5 | **Tactical AI for Quick Battle** | Shallow search or heuristics per lane; CP-based actions; deterministic from tacticalSeed. |
| 6 | **Hidden agenda assignment and modifiers** | At game start, assign agenda per AI from agendaSeed; apply modifiers in goal and domain logic. Evidence rules: record entries when actions match (e.g. war on weaker neighbor). |
| 7 | **Dossier projection and evidence storage** | Store evidence per (observer, subject, agenda); expose PlayerView-safe dossier (suspicion levels, evidence list, basic intel). No true agenda exposed. |
| 8 | **Dialogue and mood event emission** | Emit DialogueEvent and PortraitMoodEvent from AI and negotiation mood state machine; deterministic. Callbacks or event sink provided by caller. |
| 9 | **Wire logic and app to full AI** | colonizethis_logic (or app) calls colonizethis_ai for AI order generation when full AI is enabled; replace Phase 4 AIPlanner path for standard gameplay; merge and resolve orders unchanged. |
| 10 | **ctdev AI toggle** | In ctdev Running Game (or equivalent), add option to use simple (Phase 4) AI or full (Phase 6) AI for simulations. Both paths produce valid, deterministic orders. |

### Pixel-art and main menu

| # | Task | Description |
|---|------|-------------|
| 11 | **Asset pipeline and main menu** | Per UXD: asset loading, main menu flows, apply pixel-art canon and styling to existing UIs (03a–03m). |

### Naval completion (logic)

| # | Task | Description |
|---|------|-------------|
| 12 | **Naval combat resolver (colonizethis_logic)** | Implement BattleContextSea construction and naval combat resolution pipeline per [naval-combat-resolution.md](../program/naval-combat-resolution.md); update fleets and WorldState. |
| 13 | **Naval missions and interception** | Implement Patrol, Blockade, Beachhead, and Defend missions, including interception checks and retreat handling per [naval-movement-resolution.md](../program/naval-movement-resolution.md); integrate with TurnResolver’s Naval Interception & Naval Combat phase. |
| 14 | **Trade/transport raids integration** | Wire naval interception into the economy pipeline: apply cargo interception and ship loss probabilities to overseas deliveries per [naval-movement-resolution.md](../program/naval-movement-resolution.md) and [auto-transport.md](../program/auto-transport.md). |
| 15 | **AI naval behaviour** | Extend full AI planners to issue naval orders (patrol routes, blockades, convoy escorts, beachheads/invasions) consistent with the new naval rules; ensure determinism and PlayerView-only perception. |

---

## Test tasks

Tests follow **test/ mirrors lib/** and **\*_test.dart** naming. Save/load remains critical; aim for **80% per-package coverage** for colonizethis_ai and touched logic.

| Task | Success criteria |
|------|------------------|
| **Build passes** | `flutter pub get` and `flutter build` succeed for app and all packages including colonizethis_ai. |
| **Unit tests — AI determinism** | Same game state and seeds → same AI orders and same DialogueEvent/PortraitMoodEvent sequence. |
| **Unit tests — personality differentiation** | Same scenario with different leaders produces measurably different order choices (e.g. Napoleon vs Victoria). |
| **Unit tests — hidden agenda** | Each agenda type changes decision thresholds/weights per spec; evidence accumulates correctly; dossier projection shows correct suspicion bands; true agenda never exposed. |
| **Unit tests — dialogue and mood** | For given state transitions, correct event categories and moods emitted; content resolution is data-driven (tests use keys/contexts). |
| **Unit tests — dossier** | Dossier read API returns only PlayerView-safe data; evidence list and suspicion levels consistent with evidence rules. |
| **Integration test — full AI turn** | One turn with full AI: orders generated, validated, merged, resolved; dialogue/mood events emitted; determinism across runs. |
| **Integration test — ctdev toggle** | ctdev can select simple or full AI; both produce valid orders; no cross-talk. |
| **Save/load round-trip (critical path)** | Save includes AI state (agenda, evidence, seeds); load reproduces same AI behavior. |
| **Per-package coverage** | colonizethis_ai and AI-related code in colonizethis_logic aim for 80%. |
| **Pixel-art and main menu** | Assets load; main menu flows; no regressions on prior phases. |

---

## Code review tasks

Before marking Phase 6 complete, verify:

| Check | Criteria |
|-------|----------|
| **Package boundaries** | AI logic in colonizethis_ai; colonizethis_logic provides PlayerView and order suggestion API and calls colonizethis_ai; no AI logic in app beyond wiring. |
| **Spec alignment** | All AI behaviour traceable to SPEC/ai/* and SPEC/program/ai-systems-impl.md, ai-events-and-dossier.md; no un-specified AI behaviour. |
| **PlayerView and determinism** | AI never reads hidden state; all randomness from seeds; same state + seeds → same output. |
| **Phase 6 scope** | Full AI (architecture, personalities, hidden agendas, dialogue/mood, dossier), ctdev toggle, pixel-art and main menu; portraits/assets deferred to UI phases where specified. |
| **State and lifecycle** | State subscriptions and cleanup follow conventions; no leaks. |

---

## Definition of done (Phase 6)

Phase 6 is done when all design and dev tasks are implemented, all test tasks pass, and the code review checklist is signed off.

- [ ] All Design deliverables written and agreed.
- [ ] All Dev tasks implemented.
- [ ] All Test tasks passing.
- [ ] Code review checklist signed off.

**Exit criteria:** Full hybrid AI in colonizethis_ai; personality and hidden agenda drive decisions; dialogue and mood events emitted; dossier and evidence implemented and PlayerView-safe; ctdev can choose simple or full AI; pixel-art canon and main menu in place; save/load includes Phase 6 AI state; MVP logic complete.

---

## Dependencies and order

- **Design** must be done before Dev. All Phase 6 SPEC docs (ai/, program/) in repo and agreed.
- **Dev:** AI package and pipeline first (1–10), then pixel-art and main menu (11). Wire app after full AI is callable.
- **Test** and **Code review** after Dev.

---

## Out of scope for Phase 6

- Portrait assets and rich dossier/dialogue UI layout (deferred to UI phases); only events and data are implemented.
- Multiple difficulty levels that change AI strength (difficulty = starting params and modifiers only).
- JSON rulesets (mvp-scope: program-level config only).

---

## References

- **GDD 10** — AI systems (Obsidian GDD/ai/).
- **TDD 10** — AI implementation (Obsidian TDD/10-ai-systems.md).
- [mvp-scope.md](mvp-scope.md) — Phase 6 row: pixel-art, main menu; full AI scoped in this doc.
- [phase-5-project-tasks.md](phase-5-project-tasks.md) — Previous phase.
- [SPEC/ai/ai-architecture.md](../ai/ai-architecture.md), [SPEC/ai/ai-personalities.md](../ai/ai-personalities.md), [SPEC/ai/hidden-agendas.md](../ai/hidden-agendas.md), [SPEC/ai/dialogue-and-mood.md](../ai/dialogue-and-mood.md), [SPEC/ai/ai-dossier.md](../ai/ai-dossier.md).
- [SPEC/program/ai-systems-impl.md](../program/ai-systems-impl.md), [SPEC/program/ai-planner.md](../program/ai-planner.md), [SPEC/program/ai-events-and-dossier.md](../program/ai-events-and-dossier.md), [SPEC/program/order-engine.md](../program/order-engine.md), [SPEC/program/player-view.md](../program/player-view.md).
- `.cursor/rules/colonizethis-testing.mdc` — 80% coverage, critical path (save/load).
