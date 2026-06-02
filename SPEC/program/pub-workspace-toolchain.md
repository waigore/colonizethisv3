# Pub workspace toolchain

**SPEC/program** — Authoritative notes for Dart/Flutter SDK alignment, `pub.dev` resolution, and workspace lockfile policy. Tracks **GitHub #2073** (pub advisories decode + dependency refresh). Does not define game or simulation behavior.

---

## Goals

- **Given** a maintainer runs `dart pub get` or `flutter pub get` from any workspace member against the default `pub.dev` hosted source, **when** the toolchain matches the documented CI pin (see below), **then** dependency acquisition completes without `FormatException: advisoriesUpdated must be a String` failures from the SDK’s `pub` advisories decode path.
- **Given** the pinned SDK, **when** the solver runs `dart pub upgrade` / `flutter pub upgrade` (and optional `--major-versions` where policy allows), **then** direct and transitive versions are the **newest jointly resolvable** graph; any row in `pub outdated` that remains below pub.dev “Latest” is either **unblocked later by a Flutter/SDK release** or listed as an **intentional exception** in [Intentional dependency caps](#intentional-dependency-caps) below.

---

## CI and local SDK

- GitHub Actions installs Flutter via `subosito/flutter-action@v2` with an explicit **`flutter-version`** pin (`3.41.9` at time of writing) on **`.github/workflows/quality.yml`**, **`app-android-release.yml`**, and **`widgetbook-release.yml`**. That stable release bundles **Dart 3.11.5**.
- Repo lint rule **`repo.flutter_action_pins`** (`tool/check_flutter_action_pins.dart`) enforces that every workflow step using `subosito/flutter-action@...` includes `with.flutter-version` and that the pin is a semantic version **>= `3.41.9`**.
- Repo lint rule **`repo.workspace_outdated_resolvable`** (`tool/check_workspace_outdated_resolvable.dart`) audits the Pub workspace host root plus **every** workspace member (`flutter pub outdated` for Flutter members, `dart pub outdated` for pure-Dart members), and enforces that each package stays at the **Resolvable** version (fails when `current != resolvable`).
- Repo lint rule **`repo.workspace_outdated_latest_direct`** (`tool/check_workspace_outdated_latest_direct.dart`) audits the same scope and enforces that **direct/dev** dependencies are upgraded to **Latest** whenever that latest version is already jointly resolvable (`resolvable == latest`).
- Both workspace outdated rules support an optional runtime exclusion list via `CT_WORKSPACE_OUTDATED_EXCLUDE` (comma-separated package names). The default is empty; use exclusions only for short-lived upstream blockers and document the rationale in the linked issue/PR.
- Local development uses the same Flutter pin so resolution, advisories behavior, and analyzer output match automation.
- Workspace `pubspec.yaml` files use **`environment.sdk: '>=3.11.5 <4.0.0'`** so pure-Dart packages do not claim compatibility below the Dart shipped with the supported Flutter pin.
- If `dart pub get` or `flutter pub get` fails resolving hosted packages with **`FormatException: advisoriesUpdated must be a String`**, upgrade Flutter/Dart to at least the pin (or a newer stable that remains compatible with the workspace `environment.sdk` lower bound).

---

## Intentional dependency caps

`pub outdated` compares the lockfile to **pub.dev Latest**; some rows stay behind on a healthy workspace. Documented intentional exceptions until follow-ups land:

- **`test` / `test_api` / `test_core`:** SDK `flutter_test` pins `test_api`; standalone `test` may sit **below** Latest until a newer Flutter stable relaxes the pin. Do not force overrides on `test_api`. Follow-up: **#2541**.
- **`analyzer` / `analyzer_plugin` / `_fe_analyzer_shared` / `custom_lint_visitor`:** `colonizethis_exception_lint` and `custom_lint_builder` must agree on an `analyzer` major. `analyzer_plugin` 0.14.x needs `analyzer` 13, but `custom_lint_builder` stays on `analyzer` 8.x — the workspace holds `analyzer` 8.4.0 / `analyzer_plugin` 0.13.10 until upstream ships an analyzer-13 stack. Follow-up: **#2539**.
- **`hardcoded_strings_lint`:** 1.0.4 stays on the analyzer-8 stack; 2.x needs analyzer 13 (blocked by #2539). Follow-up: **#2540**.
- **`meta`:** `meta` 1.17.0 in `colonizethis_data` matches the version pinned by SDK `flutter_test`; 1.18.x is not jointly resolvable until the Flutter pin moves.
- **Other transitives** (`xml`, `vector_math`, `matcher`, `custom_lint_core`, …): May lag Latest until a **direct** dependency raises its constraints.

When bumping deps, prefer `pub upgrade` with coordinated `pubspec.yaml` edits over overrides; if a row cannot move, note the blocker in the PR or issue.

### Toolchain dependency pinning (#2532)

Toolchain direct and dev dependencies (`analyzer`, `test`, `custom_lint`, `custom_lint_builder`, `analyzer_plugin`, `hardcoded_strings_lint`, `meta` where declared) use **explicit pinned versions** (exact `x.y.z`, not floating `^`) in `pubspec.yaml`. Deliberate upgrades happen via PR that refreshes pins and lockfiles together — routine `pub get` must not silently drift those versions. Do not use `CT_WORKSPACE_OUTDATED_EXCLUDE` for documented blockers; cite the follow-up issue (**#2539**, **#2540**, **#2541**) in the PR instead. Predecessor: **#2073** (Flutter pin, advisories path, `repo.workspace_outdated_*` rules).

---

## Verification (manual)

- **`dart pub get`** at the repository root after a clean cache is the primary smoke test for advisories + workspace resolution on the pinned SDK.
- **`dart run tool/run_workspace_analyze_errors_only.dart`** and **`dart run tool/ct_repo_lint.dart`** exercise the post-resolution graph used in **Quality** CI.
- **GitHub Actions:** Confirm the latest **`quality`** workflow run for **`dev`** completed successfully (includes `pub get` / Flutter install under the pin). Record the outcome on **#2073** when auditing acceptance criteria.
- **Repo lint:** `dart run tool/ct_repo_lint.dart --rule repo.flutter_action_pins` passes, confirming all workflow Flutter installs remain pinned.
- **Workspace outdated guard:** `dart run tool/ct_repo_lint.dart --rule repo.workspace_outdated_resolvable` passes, confirming no audited package is below **Resolvable**.
- **Direct-latest guard:** `dart run tool/ct_repo_lint.dart --rule repo.workspace_outdated_latest_direct` passes, confirming audited direct dependencies are not left below **Latest** when the solver can already resolve Latest.

## Workspace outdated audit (manual)

- **Given** a maintainer is validating dependency-refresh progress for #2073, **when** they run `dart pub outdated` from the repository root (Pub workspace host) plus `flutter pub outdated` for Flutter workspace members and `dart pub outdated` for pure-Dart workspace members, **then** the combined output is the authoritative audit for direct and transitive version drift in this repository.
- **Given** an outdated row remains below pub.dev **Latest**, **when** the row is constrained by the pinned Flutter SDK (`flutter_test` -> `test_api`) or the documented `analyzer`/`custom_lint_builder` stack cap, **then** that row is treated as an intentional exception and must match the rationale documented in [Intentional dependency caps](#intentional-dependency-caps) above.
- **Given** an outdated row remains below **Resolvable** (not just below **Latest**), **when** no intentional exception applies, **then** follow-up implementation work is required on #2073 (constraint update, coordinated major bump, or lockfile refresh) before the issue can be considered complete.
- **Given** `CT_WORKSPACE_OUTDATED_EXCLUDE` is set with package names, **when** the workspace outdated lint rules run, **then** rows for those package names are excluded from violation checks and the issue/PR using that exclusion documents why the exception is temporary.

For the manual audit command set (per-member `pub outdated` driver script and result interpretation), see **[workspace-outdated-audit.md](workspace-outdated-audit.md)**.
