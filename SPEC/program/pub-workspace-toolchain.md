# Pub workspace toolchain

**SPEC/program** — Authoritative notes for Dart/Flutter SDK alignment, `pub.dev` resolution, and workspace lockfile policy. Tracks **GitHub #2073** (pub advisories decode + dependency refresh). Does not define game or simulation behavior.

---

## Goals

- **Given** a maintainer runs `dart pub get` or `flutter pub get` from any workspace member against the default `pub.dev` hosted source, **when** the toolchain matches the documented CI pin (see below), **then** dependency acquisition completes without `FormatException: advisoriesUpdated must be a String` failures from the SDK’s `pub` advisories decode path.
- **Given** the pinned SDK, **when** the solver runs `dart pub upgrade` / `flutter pub upgrade` (and optional `--major-versions` where policy allows), **then** direct and transitive versions are the **newest jointly resolvable** graph; any row in `pub outdated` that remains below pub.dev “Latest” is either **unblocked later by a Flutter/SDK release** or listed as an **intentional exception** in **[CONTRIBUTING.md](../../CONTRIBUTING.md)** (same section this spec references—do not duplicate long rationale here).

---

## CI and local SDK

- GitHub Actions installs Flutter via `subosito/flutter-action@v2` with an explicit **`flutter-version`** pin (`3.41.9` at time of writing) on **`.github/workflows/quality.yml`**, **`app-android-release.yml`**, and **`widgetbook-release.yml`**. That stable release bundles **Dart 3.11.5**.
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
