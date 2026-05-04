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

## File layout (Refs #2074)
- **Config:** `app/l10n.yaml`
- **ARB inputs only:** `app/lib/l10n/arb/` (e.g. `app_en.arb`) — `l10n.yaml` **`arb-dir`**.
- **Generated output:** `app/l10n.yaml` sets **`output-dir: lib/l10n/gen`** and **`output-localization-file: app_l10n_flutter_gen.dart`**, so `flutter gen-l10n` (including the build/run integration) writes **`app_l10n_flutter_gen*.dart`**, **`untranslated.json`**, and related artifacts **only** under **`app/lib/l10n/gen/`** (entire directory **gitignored**). Hand-maintained Dart stays in **`app/lib/l10n/*.dart`** outside `gen/`, so stale incremental-build stamps cannot list hand paths as prior codegen outputs to delete.
- **Hand-maintained Dart:** `app/lib/l10n/app_localizations_contract.dart`, delegate, lookup, `l10n.dart`, `app_localizations_en.dart`, `app_localizations_en_part*.dart`, etc. App code and tests import **`package:colonizethis_app/l10n/l10n.dart`**, which exports the contract + delegate (`Refs #2021`) and defines **`appL10n`**.
- **Maintainability:** Keys are namespaced/prefixed by feature (e.g. `mainMenu_newGame`, `victory_titleMilitary`), and messages include ARB metadata for translator context.

## Merge / local validation prerequisite
- On a checkout that **already built** with a **pre-#2074** `l10n.yaml` (ARB and gen beside hand files), **clear stale build metadata** before validating: run **`flutter clean`** in `app/` **or** remove stale **`app/.dart_tool/flutter_build/**/gen_localizations.stamp`**. Otherwise an old stamp can still reference removed output paths and the next **`flutter run`** may delete hand files until stamps align with the current config.

## CI quality gate (GitHub)
- The Quality workflow must run `flutter gen-l10n` for `app/` and produce an **untranslated / missing messages report** via `untranslated-messages-file` at **`lib/l10n/gen/untranslated.json`**.
- CI **fails** if the untranslated report contains **any** missing/untranslated messages for any locale.
- CI runs this gate when the existing Quality workflow is already running tests for `app/**` changes.
- **`app_build_linux`** (`.github/workflows/quality.yml`): after **`flutter build linux --release --no-pub`**, CI asserts an allowlist of **tracked hand l10n files** still exist and match **`git`** at **`HEAD`** (`git diff --exit-code` on those paths), so a regression that deletes or rewrites hand files after a full app build fails the job.
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

