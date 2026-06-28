# CI app selective tests

**SPEC/program** — PR CI runs only the subset of `app/test/**` whose static cross-package import closure intersects the diff. There is no `full` mode on PR; the irreducible fallback emits the full sorted app-test list under `mode = selective`, and the workflow runs that list across the same shard matrix.

---

## Goal

Run only the app tests the static import graph proves the diff can affect; package-only paths no app test imports trigger no app tests. Force-full conservatism is replaced by a cross-package `lib/**` graph, an irreducible-fallback set emitting the full sorted list under `selective`, and a workflow-side `ci:full-app` label override.

Performance goal: PR app-test stage (`changes` → `app_tests_cache` → `app_tests_shard` matrix → any coverage merge) completes in **<= 10 min** wall-clock.

---

## Selector

- **Path:** `tool/compute_app_test_plan.dart`
- **Input:** `--changed-files=<paths>` (comma- or newline-separated).
- **Output:** JSON `{"mode":"selective|skip","tests":["app/test/..."]}`.
- **Determinism:** Pure function of `--changed-files` plus on-disk workspace state. Reads no env vars, no PR labels, no workflow context. Reruns with identical inputs are byte-identical.

### Mode rules

| Mode | When |
|------|------|
| `skip` | No changed path can affect any app test. `tests` is empty. |
| `selective` | Either a closure-intersecting Dart change under `app/lib/**`, `app/test/**`, or `packages/<name>/lib/**`, **or** an irreducible-fallback trigger fired and the selector emits the full sorted app-test list. `tests` is authoritative. |

No `full` mode exists. Workflow-side label handling is described under "PR CI".

### Cross-package import graph (lib-only walk)

1. Read root `pubspec.yaml` `workspace:` list; build the package name → root-dir map (only `packages/` entries).
2. Walk `app/lib/**/*.dart`, `app/test/**/*.dart`, and every workspace package's `lib/**/*.dart`. Package `test/**` is **not** walked: the only legitimate cross-package edge from `app/test/**` (test-only helpers via `package:colonizethis_test/...`) resolves into `packages/colonizethis_test/lib/**`, already in the graph.
3. Resolve `package:colonizethis_app/<p>` → `app/lib/<p>` and `package:<workspace_pkg>/<p>` → `packages/<workspace_pkg>/lib/<p>`. Other `package:` URIs are external leaves. Relative imports resolve as before.
4. For each `app/test/**/*_test.dart`, compute the transitive import closure.

### Seeds

Changed paths seed closure intersection when they are any of:

- `app/lib/**/*.dart`,
- `app/test/**/*.dart` that is **not** a `*_test.dart` (test helpers),
- `packages/<workspace_pkg>/lib/**/*.dart`.

A changed `app/test/**/*_test.dart` that **still exists on disk** is added directly to the selected set. A changed test path that no longer exists (a deletion in the diff) is **not** scheduled — it cannot be run — but it still counts as a graph-relevant change, so an accompanying empty selection is resolved by the safety net below.

### Irreducible fallback (selective + full app-test list)

Triggered by:

- Any `app/**` path that is neither `app/lib/**/*.dart` nor `app/test/**/*.dart` (assets, ARB, generated l10n).
- Root `pubspec.yaml`, `analysis_options.yaml`.
- `tool/compute_app_test_plan.dart` (the selector itself).
- `.github/workflows/quality.yml`.

### Safety net (newly added / deleted files)

A graph-relevant seed (`app/lib/**`, `app/test/**` helper, or `packages/<pkg>/lib/**` Dart path) that produces an empty selected set — typically a newly added file not yet imported, or a deleted file no longer in the graph — falls back to `selective` + full sorted app-test list, mirroring the irreducible fallback.

---

## PR CI (`quality.yml`)

- **`changes`** runs the selector, then post-processes: when the PR carries `ci:full-app` (or `BASE_SHA` is missing/unreachable), it overrides `mode = selective` and `tests = <full sorted app-test list>`; otherwise it forwards selector output. Emits `app_is_full_list` (true iff the post-processed `tests` equals the full list).
- **`app_tests_shard`** (`matrix.shard: [0, 1]`): runs the deterministic round-robin partition (`test_i → shard i % total_shards`) of `app_tests` when non-empty. Coverage flags only when `app_is_full_list == true`; selective subsets skip coverage to stay under budget.
- **`quality_app_coverage`**: runs only when `app_is_full_list == true`. Merges shard lcov into `app/coverage/lcov.info` and enforces `app/lib/` >= 80%. Otherwise skips with success.
- **`app_build_linux`**: unchanged; gated on the existing `tests` path filter.
- **Required-check change:** the legacy `App tests (selective)` job is removed; `App tests (shard 0/2)` and `App tests (shard 1/2)` names remain stable. Branch protection must drop the `selective` check.

---

## Nightly (`nightly.yml`)

- **`app_full_tests`**: full two-shard matrix + merged 80% coverage gate. Unchanged. Safety net for asset / runtime-key / reflection blind spots.

---

## Known gaps (accepted)

- Asset path strings embedded in code without an asset-file diff: nightly catches regressions.
- Runtime widget lookup by string key without a static import link: not detected.
- Reflection: not used in this codebase.

---

## Acceptance criteria

- **Given** a PR changing only `packages/colonizethis_logic/lib/foo.dart` and exactly one `app/test/**/*_test.dart` has a closure containing that file, **when** the selector runs, **then** `mode = selective` and `tests` is that one test path only.
- **Given** a PR changing only `packages/colonizethis_ai/lib/x.dart` where `x.dart` imports `package:colonizethis_logic/y.dart`, and an app test imports `package:colonizethis_ai/x.dart`, **when** the selector runs, **then** `tests` contains that app test.
- **Given** a PR that deletes `app/test/foo_test.dart` (the path appears in the diff but no longer exists on disk) and modifies one `app/test/**` helper imported by other tests, **when** the selector runs, **then** `tests` contains the tests whose closure intersects the changed helper and **never** contains the deleted `app/test/foo_test.dart` path.
- **Given** a PR changing only `app/assets/icons/foo.png`, **when** the selector runs, **then** `mode = selective` and `tests` equals the full sorted app-test list.
- **Given** a PR changing only root `pubspec.yaml`, **when** the selector runs, **then** `mode = selective` and `tests` equals the full sorted app-test list.
- **Given** a PR changing only `tool/compute_app_test_plan.dart`, **when** the selector runs, **then** `mode = selective` and `tests` equals the full sorted app-test list.
- **Given** a PR changing only `tool/sim_scenarios/**`, **when** the selector runs, **then** `mode = skip` and `tests` is empty.
- **Given** a PR carries the `ci:full-app` label and the selector emitted any `(mode, tests)` pair, **when** the `changes` job finishes post-processing, **then** the workflow forwards `mode = selective` and `tests = <full sorted app-test list>`; the selector binary itself does not read the label.
- **Given** the post-processed `tests` is non-empty, **when** the `app_tests` matrix runs, **then** the union across shards equals `tests` exactly (no test runs outside, none runs twice).
- **Given** the post-processed `tests` equals the full app-test list, **when** the workflow finishes, **then** `quality_app_coverage` runs and enforces `app/lib/` >= 80%; otherwise `quality_app_coverage` is skipped.
- **Given** the selector emits `mode = skip` and no `ci:full-app` label is set, **when** the workflow runs, **then** the `app_tests` matrix is skipped at job level and reports success without invoking `flutter test`.
- **Given** the selector binary is invoked twice with identical `--changed-files` and the same workspace state, **when** outputs are compared, **then** `mode` and `tests` are byte-identical; no env var, label, or workflow context affects the binary's output.
