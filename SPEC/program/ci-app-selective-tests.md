# CI app selective tests

**SPEC/program** — PR CI runs a minimal subset of `app/test/**` based on a static import graph. Full app tests and the 80% `app/lib/` coverage gate run on the nightly workflow only.

---

## Goal

When a pull request changes files under `app/`, CI must run only the app unit/widget tests transitively affected by the diff, instead of the full two-shard matrix (~305 tests). Package-only, tool-only, and SPEC-only PRs must not run app tests.

---

## Selector tool

- **Path:** `tool/compute_app_test_plan.dart`
- **Input:** `--changed-files=<paths>` — comma- or newline-separated paths from `git diff --name-only <base>...HEAD`.
- **Output:** JSON on stdout: `{"mode":"full|selective|skip","tests":["app/test/..."]}`.

### Mode rules

| Mode | When |
|------|------|
| `skip` | No changed path requires app test execution (e.g. tool-only PR with no `app/**` impact). |
| `full` | Any force-full trigger (below) or PR label `ci:full-app`. |
| `selective` | At least one `app/lib/**/*.dart` or `app/test/**` helper/test change, and no force-full trigger. |

### Force-full triggers

- Any changed path under `app/` that is not `app/lib/**/*.dart` or `app/test/**/*.dart` (assets, `pubspec.yaml`, `l10n.yaml`, ARB, generated l10n, etc.).
- `packages/**`, root `pubspec.yaml`, `analysis_options.yaml`.
- `tool/compute_app_test_plan.dart`, `.github/workflows/quality.yml`.

### Selective selection

1. Build a file-level import graph over `app/lib/**/*.dart` and `app/test/**/*.dart`.
2. Resolve `package:colonizethis_app/<path>` and relative `./` / `../` imports only; third-party `package:` imports are external leaves.
3. For each `*_test.dart`, compute the transitive import closure.
4. **Seeds:** changed `app/lib/**/*.dart` files plus changed non-`_test.dart` files under `app/test/`.
5. **Include** a test when it is in the changed-test set or its closure intersects the seed set.

---

## PR CI (`quality.yml`)

- **`changes` job** runs the selector when the existing `tests` path filter is true; emits `app_mode` and `app_tests`.
- **`app_tests_cache`**, **`app_tests_shard`**, **`app_tests_selective`**, and **`quality_app_coverage`** gate on `app_mode` (not merely `tests == 'true'`).
- **`app_mode == 'full'`:** existing two-shard matrix with coverage.
- **`app_mode == 'selective'`:** single job, `flutter test <selected files>` without coverage.
- **`app_mode == 'skip'`:** success no-op (required checks still report success).
- **`quality_app_coverage`:** merge + 80% gate only when `app_mode == 'full'`.
- **`app_build_linux`:** unchanged; still runs when `tests == 'true'`.

---

## Nightly (`nightly.yml`)

- **`app_full_tests` job:** full two-shard app test matrix + merged 80% `app/lib/` coverage gate. This is the authoritative full-app verification.

---

## Known gaps (accepted)

- Asset path strings embedded in code without an asset-file diff are not detected; nightly catches regressions.
- Runtime widget lookup by string key without a static import link is not detected.
- Reflection is not used in this codebase.

---

## Acceptance criteria

- **Given** a PR that changes only `app/lib/widgets/ct_panel.dart` and one test file imports it directly, **when** CI runs the selector, **then** `mode` is `selective` and the output `tests` list includes that test file only (plus any test whose transitive closure includes `ct_panel.dart`).
- **Given** a PR that changes only `app/assets/icons/foo.png`, **when** CI runs the selector, **then** `mode` is `full`.
- **Given** a PR that changes only `tool/sim_scenarios/**`, **when** CI runs the selector, **then** `mode` is `skip`.
- **Given** a PR labeled `ci:full-app`, **when** CI computes the app test plan, **then** `app_mode` is `full` regardless of changed paths.
