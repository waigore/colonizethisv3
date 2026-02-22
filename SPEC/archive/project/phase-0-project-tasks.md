# Phase 0 — Project tasks

**SPEC/project** — Actionable task list for Phase 0. Structure and package layout follow **TDD 15 (Technical Architecture)**; the task list and code review are checked against that source of truth.

---

## Purpose

Phase 0 establishes scope, repo layout, package plan, app shell (Flutter + Flame), and state/save wiring with **no game logic**. It follows the full workflow from [mvp-scope.md](mvp-scope.md): **Design → Dev → Test → Code review**. Do not advance to Phase 1 until Phase 0 code review is complete.

---

## Design tasks

All design deliverables must accord with **TDD 15 (Technical Architecture)**. Source of truth: Obsidian `TDD/15-technical-architecture.md`.

| Task | Description | Deliverable |
|------|-------------|-------------|
| **Scope doc** | Confirm MVP scope and phasing are complete. | N/A — [mvp-scope.md](mvp-scope.md) already exists and is the scope doc. |
| **Repo layout** | Define and document repo layout per TDD 15: monorepo with `packages/` and Flutter app (location: e.g. `app/` or root — SPEC must state which); where SPEC, assets, and tooling live. | SPEC doc (e.g. [SPEC/program/repo-and-packages.md](../program/repo-and-packages.md)) that reflects TDD 15 Project Structure so implementation has an in-repo source of truth. |
| **Package plan** | Define packages and responsibilities per TDD 15 Package Layout: `colonizethis_logic`, `colonizethis_models`, `colonizethis_ai`, `colonizethis_data`, `colonizethis_save` (with TDD 15’s "or merged into _logic" choice for _models and _save documented). Document dependency direction (app → shared packages; _ai → _logic) and "no game logic in app" (logic in shared packages). | Same or linked SPEC doc with package names, dependency direction, and config consumers. Reference [SPEC/program/ruleset-config.md](../program/ruleset-config.md) for config consumers. |

---

## Dev tasks

Order matters. Implement in sequence; each task assumes the previous is done.

| # | Task | Description |
|---|------|-------------|
| 1 | **Create package structure** | Implement repo layout and package plan from Design: `packages/` with the five TDD 15 packages (or three if _models/_save merged into _logic), each with `pubspec.yaml` and dependency edges per TDD 15. |
| 2 | **App shell — Flutter** | Minimal Flutter app matching TDD 15 Flutter App structure: `lib/main.dart`, `app.dart`, `config/` (routes, themes), `core/`, `features/` (at least `game/flame/` placeholder), `providers/`, `widgets/`. Entrypoint and runApp; no game logic. |
| 3 | **App shell — Flame** | Integrate Flame per TDD 15 Client rendering: app hosts one Flame game/screen (e.g. empty component under `features/game/flame/`); Flutter shell and Flame boundary clear; communication via state/callbacks only (no direct widget mixing). |
| 4 | **State/save wiring** | Per TDD 15 State Management and Local Storage: add Riverpod (placeholder or stub providers) and Hive box names (`settings`, `games`, `offline_queue`) as stubs or empty wiring; no TurnResolver, no Game/WorldState, no persistence logic. Purpose: Phase 1 can plug in models and TurnResolver without reworking the shell. |

---

## Test tasks

| Task | Success criteria |
|------|------------------|
| **Build passes** | `flutter pub get` and `flutter build` (or equivalent) succeed for the app and all packages. |
| **App launches** | App runs on at least one target (e.g. macOS or web). |
| **Package deps resolve** | All `pubspec.yaml` dependencies resolve with no version conflicts. |

---

## Code review tasks

Before marking Phase 0 complete, verify:

| Check | Criteria |
|-------|----------|
| **Structure matches TDD 15** | Repo layout and package list match SPEC and TDD 15 (package names, `lib/` structure, packages under `packages/`). Dependency direction matches TDD 15 (app → shared packages; _ai → _logic; no UI in shared packages). |
| **No game logic in app** | App and Flame shell contain only structure, wiring, and placeholders; no TurnResolver, no world model, no game rules. |

---

## Definition of done (Phase 0)

- [ ] All Design deliverables written and agreed.
- [ ] All Dev tasks implemented.
- [ ] All Test tasks passing.
- [ ] Code review checklist signed off.

**Exit criteria:** App runs; packages resolve; structure and wiring ready for Phase 1.

---

## Dependencies and order

- **Design** (scope, repo layout, package plan) must be done before Dev.
- Repo layout and package plan may be one or two documents but must live in SPEC (program or project) so the team does not depend only on Obsidian for structure.
- **Dev:** Package structure first, then app shell (Flutter then Flame), then state/save wiring.
- **Test** and **Code review** after Dev.

---

## Out of scope for Phase 0

- No world model, turn resolution, or persistence implementation (Phase 1).
- No game config/ruleset implementation beyond package names and dependency direction (program-level config *usage* starts in later phases; package *plan* only in Phase 0).
- No JSON rulesets or layered rules (per [mvp-scope.md](mvp-scope.md), out of MVP).
- **No server/ or backend:** TDD 15 describes a backend; [mvp-scope.md](mvp-scope.md) defines MVP as standalone with no backend. Phase 0 does not create `server/` or any backend code.

---

## References

- **TDD 15** — Technical Architecture (Obsidian: `Projects/ColonizeThisV3/TDD/15-technical-architecture.md`): source of truth for package layout, app structure, state (Riverpod), save (Hive), and Flame vs Flutter.
- [SPEC/program/ruleset-config.md](../program/ruleset-config.md) — Config consumers (colonizethis_logic, colonizethis_ai); app receives config at game load.
- [mvp-scope.md](mvp-scope.md) — MVP scope and phasing.
- `.cursor/rules/colonizethis-core-principles.mdc` — Flutter vs Flame separation.

---

## Risks and assumptions

- TDD 15 lives in Obsidian; SPEC (e.g. repo-and-packages) is the in-repo reflection for implementation. Design tasks should sync key structure from TDD 15 into SPEC before Dev.
