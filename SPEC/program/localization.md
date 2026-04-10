# Localization (Flutter app)

## Scope
- **Applies to:** `app/` (Flutter/Flame app shell + overlays + menus + screens).
- **Locales:** `en` only initially.
- **Fallback:** `en` is the fallback locale.
- **What is localized:** **All user-visible UI copy** emitted by `app/lib/**`, including:
  - Screen titles, buttons, labels, tooltips, dialogs, error messages.
  - Dynamic strings (interpolated values, plurals where applicable).
  - UI-visible game content surfaced by the app (e.g., resources, units, tech names/descriptions) when displayed as UI copy.

## Mechanism (built-in Flutter i18n)
- Use Flutter `gen_l10n` + ARB files to generate `AppLocalizations`.
- Use `flutter_localizations` to localize built-in Material/Cupertino widgets.
- Generated localization access is via `AppLocalizations.of(context)` (or an app helper that returns the same instance).

## File layout
- **Config:** `app/l10n.yaml`
- **ARB directory:** `app/lib/l10n/`
- **Generated output:** default Flutter generated location (Flutter toolchain); app code imports from `package:flutter_gen/gen_l10n/app_localizations.dart`.
- **Maintainability:** Keys are namespaced/prefixed by feature (e.g. `mainMenu_newGame`, `victory_titleMilitary`), and messages include ARB metadata for translator context.

## CI quality gate (GitHub)
- The Quality workflow must run `flutter gen-l10n` for `app/` and produce an **untranslated / missing messages report** via `untranslated-messages-file`.
- CI **fails** if the untranslated report contains **any** missing/untranslated messages for any locale.
- CI runs this gate when the existing Quality workflow is already running tests for `app/**` changes.
- The `app/` analyzer gate must enable `custom_lint` with `hardcoded_strings_lint` and surface `avoid_hardcoded_strings_in_widgets` where the package reports violations.
- The Quality workflow must also run `tool/check_app_hardcoded_ui_strings.py` (and `tool/run_quality_gate_tests.sh` locally) so multiline widgets, `Semantics`/`Tooltip` ordering, `_buildSection` titles, and other known lint gaps still fail CI when user-visible literals remain in `app/lib/**`.
- Enforcement applies to `app/lib/**` user-visible UI copy with only narrow technical exceptions defined by `SPEC/ui/localization.md`.

## Acceptance criteria
- **AC1:** `app/` builds with `flutter gen-l10n` enabled and `flutter_localizations` configured.
- **AC2:** `MaterialApp` declares `localizationsDelegates` and `supportedLocales` from `AppLocalizations`.
- **AC3:** All user-visible UI copy in `app/lib/**` is sourced from `AppLocalizations` (including dynamic strings and tooltips).
- **AC4:** The Quality workflow fails if the untranslated report produced by `untranslated-messages-file` contains any entries.
- **AC5:** `en` is the default/fallback locale.
- **AC6:** Given a hardcoded user-visible string in `app/lib/**` that matches the enforced patterns in `tool/check_app_hardcoded_ui_strings.py`, when the Quality workflow runs that script (with `app/**` in scope), then the PR fails. When `hardcoded_strings_lint` reports `avoid_hardcoded_strings_in_widgets` on `app/lib/**`, `flutter analyze` in the same workflow must also fail on analyzer errors.

