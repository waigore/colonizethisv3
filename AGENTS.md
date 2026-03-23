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

## Context-specific rules

| Rule file | Applies to | Focus |
|-----------|------------|-------|
| `colonizethis-tools.mdc` | `tool/**` | Thin facades + Melos execution + docs |
| `colonizethis-testing.mdc` | `**/*_test.dart`, `**/test/**/*.dart` | Test layers, critical paths, coverage policy |
| `colonizethis-ui-design.mdc` | `SPEC/ui/**`, `**/lib/widgets/**`, `**/lib/ui/**` | UI specs, wireframes, Widgetbook/catalog, pixel-art process |
| `colonizethis-component-structure.mdc` | `**/*.dart` | Folder conventions, extraction/reuse, naming |
| `colonizethis-code-review.mdc` | `**/*.dart` | Review checklist and quality gates |
| `colonizethis-lifecycle.mdc` | `**/*.dart` | Flame/Flutter lifecycle conventions |
| `colonizethis-assets.mdc` | `**/*.dart`, `**/pubspec.yaml`, `**/assets/**` | Asset structure, naming, loading |
| `colonizethis-tui.mdc` | `SPEC/tui/**`, `ctterm/**` | ctterm-specific behavior and constraints |
| `colonizethis-acceptance-criteria.mdc` | `SPEC/ai/**`, `SPEC/game/**`, `SPEC/program/**`, `SPEC/ui/**` | Given–When–Then, testable AC quality |

## Quick reference

1. Check/extend SPEC first; implement only spec-authorized behavior.
2. Keep Flutter UI and Flame simulation concerns separated.
3. Prefer reuse; keep screens thin and delegate logic to services/controllers/components.
4. Coverage policy: **90% for logic/ai/map packages; 80% everywhere else**.
5. Run app/ctdev widget tests with `flutter test` (or `melos run test_app`), not `dart test app/...`.
6. Use `logger` for runtime logs; use `basic_logger_file` for file logging.
7. For cross-panel UI orchestration, use `AppEventBus` (`SPEC/program/app-ui-wiring.md`, `SPEC/program/app-event-bus.md`).

For complete details, read the relevant rule file(s) in `.cursor/rules/`.
