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
- **Generated output:** `app/l10n.yaml` sets **`synthetic-package: false`** so `flutter gen-l10n` writes `app_localizations*.dart` under `app/lib/l10n/` (gitignored). App code and tests import via **`package:colonizethis_app/l10n/app_localizations.dart`** (and `l10n.dart` helpers), which resolves to those generated files after `flutter gen-l10n`.
- **Maintainability:** Keys are namespaced/prefixed by feature (e.g. `mainMenu_newGame`, `victory_titleMilitary`), and messages include ARB metadata for translator context.

## CI quality gate (GitHub)
- The Quality workflow must run `flutter gen-l10n` for `app/` and produce an **untranslated / missing messages report** via `untranslated-messages-file`.
- CI **fails** if the untranslated report contains **any** missing/untranslated messages for any locale.
- CI runs this gate when the existing Quality workflow is already running tests for `app/**` changes.
- **Authoritative hardcoded-UI gate:** Quality runs `dart run tool/ct_repo_lint.dart` with `CT_REPO_LINT_INCLUDE_APP=true` when app/package paths changed (rule `repo.app_hardcoded_ui_strings`; see [repo-lint.md](repo-lint.md)), which invokes `tool/check_app_hardcoded_ui_strings.dart`. Direct run: `dart run tool/check_app_hardcoded_ui_strings.dart` (repo root). It parses `app/lib/**` with the Dart AST (not line regexes), visits `Text` / `SelectableText` (including non-`const` calls, which appear as `MethodInvocation` under `parseString`), `Tooltip.message`, `InputDecoration` `labelText` / `hintText`, `Semantics` `label` / `value` / `hint` / `tooltip`, and `SnackBarAction.label`, including **multiline** arguments. It fails the PR when a disallowed string literal or a string interpolation that contains static user-visible text is passed there. Suppressions: `// ignore: avoid_hardcoded_strings_in_widgets` on the same or previous line, or `// ignore_for_file: avoid_hardcoded_strings_in_widgets` for the file. Narrow literal exceptions match `SPEC/ui/localization.md` (short tokens, snake_case ids, paths, etc.).
- **Supplemental:** The `app/` package keeps `custom_lint` + `hardcoded_strings_lint` for IDE feedback; it is **not** the sole CI signal because that plugin can miss cases in this workspace configuration.
- Enforcement applies to `app/lib/**` user-visible UI copy with only narrow technical exceptions defined by `SPEC/ui/localization.md`.
- Unit tests for the checker live at `test/check_app_hardcoded_ui_strings_test.dart` and run in the Quality workflow.

## Acceptance criteria
- **AC1:** `app/` builds with `flutter gen-l10n` enabled and `flutter_localizations` configured.
- **AC2:** `MaterialApp` declares `localizationsDelegates` and `supportedLocales` from `AppLocalizations`.
- **AC3:** All user-visible UI copy in `app/lib/**` is sourced from `AppLocalizations` (including dynamic strings and tooltips).
- **AC4:** The Quality workflow fails if the untranslated report produced by `untranslated-messages-file` contains any entries.
- **AC5:** `en` is the default/fallback locale.
- **AC6:** Given a hardcoded user-visible string in `app/lib/**` in a covered widget slot (see CI gate list above), when the Quality workflow runs `dart run tool/ct_repo_lint.dart` with the app rule enabled (`CT_REPO_LINT_INCLUDE_APP=true`), then the PR fails with a violation listing the file and line.

