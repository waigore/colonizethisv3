# Agent instructions (ColonizeThis)

This project uses **Cursor rules** as the source of truth for how to work in the codebase. Agents (including Cursor AI) should follow these rules when editing code, adding features, or reviewing.

## Where the rules live

- **Path:** `.cursor/rules/`
- **Format:** Markdown with optional front matter (`.mdc`). Each file describes one concern (SPEC, testing, UI, tools, etc.).

## Always-applied rules

These rules are applied in every context; follow them for all changes.

| Rule file | Summary |
|-----------|---------|
| **colonizethis-spec-required.mdc** | SPEC-first: specify before implementing; no behavior that contradicts specs. GDD `SPEC/game/`, TDD `SPEC/program/`, AI `SPEC/ai/`, UI `SPEC/ui/` (sub-specs, max 1000 words). Source of truth: GDD for game/AI, TDD for architecture. Conflicts: resolve GDD/TDD first. Rulesets: configurable; specify where/how in GDD/TDD. New behavior: point to authorizing spec or add/extend spec first. |
| **colonizethis-core-principles.mdc** | Stack: Flutter (UI), Flame (game/simulation), Dart. Strict typing, null safety, logger (no `print`). Thin screens; delegate to services/controllers/Flame. Province lookup: always use `(regionId, provinceId)` or prefixed id; never province id alone. |
| **colonizethis-logging-file.mdc** | Whenever file logging is needed, use **basic_logger_file** (BasicLogger + FileOutputLogger). Do not implement custom file logging (e.g. raw File/IOSink or manual log-to-file). |

## Context-specific rules

Apply these when working in the indicated areas (by path or topic).

| Rule file | When to apply | Summary |
|-----------|----------------|---------|
| **colonizethis-tools.mdc** | `tool/**` | Tools are thin facades; logic lives in packages. Run from root via Melos: `melos run <tool_name> -- [args]`. Document in `docs/project-tools.md`. |
| **colonizethis-testing.mdc** | `**/*_test.dart`, `**/test/**/*.dart` | 90% per-package coverage. Unit / widget / game-component layers. Mocks (mockito/mocktail). Critical paths: combat, economy, save/load, ruleset loading. |
| **colonizethis-ui-design.mdc** | `SPEC/ui/**`, `**/lib/widgets/**`, `**/lib/ui/**` | Wireframes in UI spec; Widgetbook + widget catalog for components; pixel art via spec and PixelLab; UXD 02/03/04/05/07. Flame vs Flutter division. |
| **colonizethis-component-structure.mdc** | `**/*.dart` | Folder layout: `lib/game/`, `lib/widgets/`, `lib/screens/`, etc. Reuse at 2+ places; Flame `*Component`, Flutter catalog + Widgetbook. |
| **colonizethis-code-review.mdc** | `**/*.dart` | Checklist: function &lt; 20 lines, widget &lt; ~60 lines, no UI+logic mix, constants for strings, explicit types, spec alignment, logging, reuse, tests. |
| **colonizethis-lifecycle.mdc** | `**/*.dart` | Flame: `onLoad` (init), `onMount`/`onRemove` (subscribe/cleanup), `update`/`render` (tick/paint). Flutter: `initState`/`dispose`. |
| **colonizethis-assets.mdc** | `**/*.dart`, `**/pubspec.yaml`, `**/assets/**` | Asset dirs: `assets/images/`, `assets/audio/`, `assets/data/`. Snake_case naming. Load in Flame `onLoad()`; use caches. |
| **colonizethis-tui.mdc** | `SPEC/tui/**`, `ctterm/**` | TUI (ctterm): SPEC/tui and ctterm.md source of truth; Given–When–Then for TUI AC; keyboard-first; Nocterm; log prefixes `tui:*`; province identity (prefixed id); no Flutter in ctterm. |

## Quick reference for agents

1. **Before implementing:** Check GDD/TDD/UI spec; implement only what is specified; if missing, add or extend the spec first.
2. **Code style:** Strict Dart, logger (no `print`), thin screens, single responsibility. Province lookup: always `(regionId, provinceId)` or prefixed id.
3. **When touching UI:** Wireframes in spec; Widgetbook + catalog; pixel art per UXD (exact prompts in spec; check assets first, don’t regenerate if suitable asset exists); Flame for canvas, Flutter for shell/overlays/menus.
4. **When adding a tool:** Thin facade in `tool/<name>`; logic in packages; Melos script and `docs/project-tools.md` updated.
5. **When writing tests:** 90% per package; unit/widget/game-component layers; cover combat, economy, save/load, ruleset loading. **App/ctdev widget tests:** run with `flutter test` from app/ (or `melos run test_app`); do not use `dart test app/...`.
6. **When file logging:** Use **basic_logger_file** (BasicLogger + FileOutputLogger); do not implement custom file logging.
7. **When reviewing/generating code:** Use the code-review checklist (lengths, types, spec, logging, reuse, tests).

For full text of each rule, read the files in `.cursor/rules/`.
