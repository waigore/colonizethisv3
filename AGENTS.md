# Agent instructions (ColonizeThis)

Cursor rules are the source of truth for implementation and review behavior.

## Rule location

- Path: `.cursor/rules/`
- Format: Markdown `.mdc` with front matter (`description`, optional `globs`, `alwaysApply`)

## Always-applied rules

| Rule file | Focus |
|-----------|-------|
| `colonizethis-spec-required.mdc` | SPEC-first workflow and source-of-truth boundaries |
| `colonizethis-core-principles.mdc` | Dart/Flutter/Flame coding principles and architecture boundaries |
| `colonizethis-logging-file.mdc` | Required file logging approach (`basic_logger_file`) |
| `colonizethis-logic-ai-decoupling.mdc` | Enforces one-way architecture boundary between `colonizethis_logic` and `colonizethis_ai` |

## Context-specific rules

| Rule file | Applies to | Focus |
|-----------|------------|-------|
| `colonizethis-tools.mdc` | `tool/**` | Thin facades + Melos execution + docs |
| `colonizethis-testing.mdc` | `**/*_test.dart`, `**/test/**/*.dart`, `**/integration_test/**/*.dart` | Test layers, critical paths, coverage policy |
| `colonizethis-e2e-ui-stability.mdc` | `**/integration_test/**/*.dart`, `**/*_e2e_test.dart` | UI e2e stability: deterministic locators and visibility-first interactions |
| `colonizethis-ui-design.mdc` | `SPEC/ui/**`, `**/lib/widgets/**`, `**/lib/ui/**` | UI specs, wireframes, Widgetbook/catalog, pixel-art process |
| `colonizethis-component-structure.mdc` | `**/*.dart` | Folder conventions, extraction/reuse, naming |
| `colonizethis-code-review.mdc` | `**/*.dart` | Review checklist and quality gates |
| `colonizethis-lifecycle.mdc` | `**/*.dart` | Flame/Flutter lifecycle conventions |
| `colonizethis-assets.mdc` | `**/*.dart`, `**/pubspec.yaml`, `**/assets/**` | Asset structure, naming, loading |
| `colonizethis-acceptance-criteria.mdc` | `SPEC/ai/**`, `SPEC/game/**`, `SPEC/program/**`, `SPEC/ui/**` | Given–When–Then, testable AC quality |

## Rule interaction

Multiple context-specific rules may apply to a single file (e.g., a UI widget may match both `ui-design` and `component-structure`). All applicable rules are **additive**; when they conflict, the more specific rule takes precedence (e.g., testing rules override general code-review for test files).

## Quick reference

1. **SPEC-first**: Check/extend SPEC first; implement only spec-authorized behavior. See `colonizethis-spec-required.mdc`.
2. **Separation of concerns**: Keep Flutter UI and Flame simulation concerns separated. See `colonizethis-core-principles.mdc`.
3. **Thin screens**: Prefer reuse; keep screens thin and delegate logic to services/controllers/components. See `colonizethis-component-structure.mdc`.
4. **Coverage policy**: **90% for logic/ai/map packages; 80% everywhere else**. See `colonizethis-testing.mdc`.
5. **Widget tests**: Run app/ctdev widget tests with `flutter test` (or `melos run test_app`), not `dart test app/...`. See `colonizethis-testing.mdc`.
6. **E2E UI stability**: In UI-heavy e2e tests, prefer deterministic widget locators, scope finders to roots, and ensure visibility before taps; avoid coordinate-based gestures unless unavoidable. See `colonizethis-e2e-ui-stability.mdc`.
7. **Logging**: Policy and annexes: `SPEC/program/logging/logging.md`; ctdev file/Sim Log: `SPEC/program/ctdev-logging.md`; use `basic_logger_file` per `colonizethis-logging-file.mdc` where file sinks apply.
8. **Cross-panel UI orchestration**: "Panels" refers to app panels/dialogs/components. Panels should **not** directly invoke or depend on each other unless absolutely necessary. Use `AppEventBus` for cross-panel communication. See `SPEC/program/app-ui-wiring.md` and `SPEC/program/app-event-bus.md`.

For complete details, read the relevant rule file(s) in `.cursor/rules/`.

## Project agent skills

Skills live under `.cursor/skills/<name>/SKILL.md`. When a skill matches the task, read and follow it.

| Skill | Use when |
|-------|----------|
| `create-github-issue` | Turn an informal bug/report into a structured GitHub issue (read-only repo work; may use `gh`). |
| `clean-local-branches` | Prune local branch refs, keeping `dev` and open-PR heads; never delete remote branches. |
| `fix-pr` | Unblock a PR by fixing failing checks and quality gates. |
| `implement-github-issue` | User gives an issue **#** or **URL**; validate problem/design/testable ACs, update **SPEC** if needed, implement, add positive/negative tests, open PR to **`dev`** with **`Refs #…`** (do **not** auto-close). Very large issues: one isolatable slice only. |
| `merge-dev-into-android-build` | Merge `dev` into `build/app/android` for APK build workflows. |
| `plan-feature` | Scope a feature from SPEC/code (read-only), then open a capturing issue—no implementation. |
| `refine-github-issue` | Refine an open issue from comment feedback (repro, root cause, priorities); update the body or return numbered clarifications when feedback conflicts with SPEC. |
| `review-github-issue` | Review an issue for **purpose ↔ proposed method** coherence and internal consistency; repo/SPEC/test evidence only when needed to show the method cannot satisfy the purpose. Consolidated comment with priorities and remedies; use **`verify-github-issue`** for AC↔implementation closure. |
| `verify-github-issue` | Verify one open issue against ACs/specs/tests; gap analysis or closure steps. |

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution guidelines.
