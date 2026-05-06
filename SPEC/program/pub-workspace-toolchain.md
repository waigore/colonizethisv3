# Pub workspace toolchain

**SPEC/program** — Authoritative notes for Dart/Flutter SDK alignment, `pub.dev` resolution, and workspace lockfile policy. Tracks **GitHub #2073** (pub advisories decode + dependency refresh). Does not define game or simulation behavior.

---

## Goals

- **Given** a maintainer runs `dart pub get` or `flutter pub get` from any workspace member against the default `pub.dev` hosted source, **when** the toolchain matches the documented CI pin (see below), **then** dependency acquisition completes without `FormatException: advisoriesUpdated must be a String` failures from the SDK’s `pub` advisories decode path.
- **Given** the pinned SDK, **when** the solver runs `dart pub upgrade` / `flutter pub upgrade` (and optional `--major-versions` where policy allows), **then** direct and transitive versions are the **newest jointly resolvable** graph; any row in `pub outdated` that remains below pub.dev “Latest” is either **unblocked later by a Flutter/SDK release** or listed as an **intentional exception** in **[CONTRIBUTING.md](../../CONTRIBUTING.md)** (same section this spec references—do not duplicate long rationale here).

---

## CI and local SDK

- GitHub Actions installs Flutter via `subosito/flutter-action@v2` with an explicit **`flutter-version`** pin (`3.41.9` at time of writing) on **`.github/workflows/quality.yml`**, **`app-android-release.yml`**, and **`widgetbook-release.yml`**. That stable release bundles **Dart 3.11.5**.
- Repo lint rule **`repo.flutter_action_pins`** (`tool/check_flutter_action_pins.dart`) enforces that every workflow step using `subosito/flutter-action@...` includes `with.flutter-version` and that the pin is a semantic version **>= `3.41.9`**.
- Repo lint rule **`repo.workspace_outdated_resolvable`** (`tool/check_workspace_outdated_resolvable.dart`) audits the Pub workspace host root plus **every** workspace member (`flutter pub outdated` for Flutter members, `dart pub outdated` for pure-Dart members), and enforces that each package stays at the **Resolvable** version (fails when `current != resolvable`).
- Repo lint rule **`repo.workspace_outdated_latest_direct`** (`tool/check_workspace_outdated_latest_direct.dart`) audits the same scope and enforces that **direct/dev** dependencies are upgraded to **Latest** whenever that latest version is already jointly resolvable (`resolvable == latest`).
- Both workspace outdated rules support an optional runtime exclusion list via `CT_WORKSPACE_OUTDATED_EXCLUDE` (comma-separated package names). The default is empty; use exclusions only for short-lived upstream blockers and document the rationale in **[CONTRIBUTING.md](../../CONTRIBUTING.md)** and the linked issue/PR.
- **CONTRIBUTING.md** states the same minimum for local development so resolution, advisories behavior, and analyzer output match automation.
- Workspace `pubspec.yaml` files use **`environment.sdk: '>=3.11.5 <4.0.0'`** so pure-Dart packages do not claim compatibility below the Dart shipped with the supported Flutter pin.

---

## Intentional dependency caps

 Maintainer-facing detail (Flutter `test_api` pin, `analyzer` / **`custom_lint_builder`** / **`custom_lint`** stack, and related transitives) lives in **CONTRIBUTING.md** under **`dart pub outdated` / “Latest” vs what the workspace resolves**. Those caps are the **documented intentional exceptions** for **#2073** acceptance criteria until upstream publishes a compatible **`custom_lint_builder`** (or the project migrates lint integration per a future issue).

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
- **Given** an outdated row remains below pub.dev **Latest**, **when** the row is constrained by the pinned Flutter SDK (`flutter_test` -> `test_api`) or the documented `analyzer`/`custom_lint_builder` stack cap, **then** that row is treated as an intentional exception and must match the rationale documented in **[CONTRIBUTING.md](../../CONTRIBUTING.md)**.
- **Given** an outdated row remains below **Resolvable** (not just below **Latest**), **when** no intentional exception applies, **then** follow-up implementation work is required on #2073 (constraint update, coordinated major bump, or lockfile refresh) before the issue can be considered complete.
- **Given** `CT_WORKSPACE_OUTDATED_EXCLUDE` is set with package names, **when** the workspace outdated lint rules run, **then** rows for those package names are excluded from violation checks and the issue/PR using that exclusion documents why the exception is temporary.
