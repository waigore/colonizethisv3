# CI app selective tests

**SPEC/program** — PR CI runs only `app/test/**` whose static transitive
import closure intersects the changed file set. There is no `full` mode on
PR; an irreducible fallback list (still emitted as `selective`) covers
changes the static import graph cannot reason about. Full unconditional app
tests with the 80% `app/lib/` coverage gate run on the nightly workflow.

---

## Goal

PR CI must run only the app unit/widget tests transitively affected by the
diff. Package-only PRs that touch a `colonizethis_*` package or
`session_log_buffer` must reuse the same selector — their changes are edges
in a workspace-spanning import graph rather than a forced full-matrix
trigger. Tool-only and SPEC-only PRs must not run app tests.

**Performance budget (release-blocking):** End-to-end PR app-test stage
(selector + cache + matrix + any coverage merge) completes in <= 10 minutes
wall-clock for typical diffs.

---

## Selector tool

- **Path:** `tool/compute_app_test_plan.dart`
- **Input:** `--changed-files=<paths>` — comma- or newline-separated paths
  from `git diff --name-only <base>...HEAD`.
- **Output:** JSON on stdout: `{"mode":"selective|skip","tests":["app/test/..."]}`.
- **Purity (D1):** The selector is a pure function of `--changed-files` and
  on-disk workspace state. It does not read environment variables, PR
  labels, or workflow context. The `ci:full-app` label is applied
  workflow-side after the selector runs.

### Output schema

| Field | Values |
|-------|--------|
| `mode` | `selective` \| `skip` |
| `tests` | Sorted list of `app/test/**/*_test.dart` paths (may be empty only when `mode == skip`) |

`full` is no longer emitted by the selector. Cases that would previously
have produced `full` are now produced as `selective` with `tests` equal to
the full sorted list of `app/test/**/*_test.dart` (the irreducible
fallback).

### Mode rules

| Mode | When |
|------|------|
| `skip` | No changed path requires app test execution (e.g. tool-only, SPEC-only, docs-only PR with no `app/**` or workspace-package impact). `tests` is empty. |
| `selective` | Either at least one path produces selected tests via the import graph, **or** an irreducible-fallback trigger fires. In the fallback case, `tests` equals the full sorted list of `app/test/**/*_test.dart`. |

### Irreducible fallback triggers

The selector emits `selective` with the full sorted app-test list (no
`full` mode) when any changed path matches:

- Any `app/**` path that is neither under `app/lib/**/*.dart` nor under
  `app/test/**/*.dart` (assets, `app/pubspec.yaml`, `l10n.yaml`, ARB,
  generated l10n, etc.).
- Root `pubspec.yaml`, `analysis_options.yaml`.
- `tool/compute_app_test_plan.dart`.
- `.github/workflows/quality.yml`.

Missing/unreachable `BASE_SHA` is handled in `quality.yml` and produces the
same effect (full-list selective) without invoking the selector.

### Selective selection (cross-package import graph)

1. Read root `pubspec.yaml` `workspace:` entries and read each package's
   `pubspec.yaml` `name:` to derive a `packageName -> packageRoot` map.
   This makes the package set track workspace drift automatically.
2. Build a single combined file-level import graph over:
   - `app/lib/**/*.dart`
   - `app/test/**/*.dart`
   - For every workspace package mapped above whose `lib/` directory
     exists: `<packageRoot>/lib/**/*.dart`. Per **D2**, package `test/**`
     is **not** walked. App tests reach test-only helpers exclusively
     through `package:colonizethis_test/...`, which resolves into
     `packages/colonizethis_test/lib/**`.
3. Resolve imports as follows; everything else is treated as an external
   leaf and produces no edge:
   - `package:<name>/x.dart` → `<packageRoot(name)>/lib/x.dart` for every
     workspace package in the map (including `colonizethis_app` →
     `app/lib/...`).
   - Relative `./` / `../` imports.
4. For each `app/test/**/*_test.dart`, compute the transitive import
   closure over the combined graph.
5. **Seeds:** changed `app/lib/**/*.dart` files, changed non-`_test.dart`
   files under `app/test/`, and changed files under any walked package
   `lib/` directory.
6. **Include** a test when it is a changed test file or its closure
   intersects the seed set.
7. If at least one changed Dart path produced a seed but no test was
   selected (e.g. an unreachable lib file), the selector emits the
   irreducible fallback (`selective` + full app-test list) rather than an
   empty selection. Tool-only / SPEC-only changes still emit `skip`.

---

## PR CI (`quality.yml`)

- **`changes` job** runs the selector unconditionally when the existing
  `tests` paths-filter is true; emits `app_mode` and `app_tests`.
- **`ci:full-app` label override (D1, workflow-side):** After the selector
  runs, the `changes` job inspects the PR labels. If the PR carries the
  `ci:full-app` label, the workflow overrides `(app_mode, app_tests)` to
  `selective` + the full sorted list of `app/test/**/*_test.dart`,
  regardless of selector output. The selector binary itself does not read
  the label.
- **`app_tests`** is a single matrix job with `shard: [0, 1]`. Each shard
  receives a deterministic round-robin partition of the (possibly
  overridden) sorted `app_tests` list and runs
  `flutter test <its partition> --no-pub --reporter=compact -j 1
  --no-track-widget-creation`. The job is skipped at job level when
  `app_mode == 'skip'`.
- **Coverage gating:** `app_tests` runs with `--coverage` and uploads
  shard lcov **only** when the (possibly overridden) `app_tests` equals
  the full app-test list (irreducible fallback fired or `ci:full-app`
  applied). `quality_app_coverage` runs and enforces the existing 80%
  `app/lib/` threshold under the same condition; otherwise it is skipped.
- **`app_build_linux`:** unchanged; still gated on `tests == 'true'`.

Required-check renames need a repo admin pass to update branch protection
in lockstep with this change.

---

## Nightly (`nightly.yml`)

- **`app_full_tests_*` jobs:** unchanged. Full two-shard app test matrix +
  merged 80% `app/lib/` coverage gate is the authoritative full-app
  verification and the safety net for static-analysis blind spots.

---

## Known gaps (accepted)

- Asset path strings embedded in code without an asset-file diff are not
  detected by the graph; nightly catches regressions.
- Runtime widget lookup by string key without a static import link is not
  detected by the graph; nightly catches regressions.
- Reflection is not used in this codebase.
- Workspace pubspec drift is mitigated by deriving the package map from
  the root `pubspec.yaml` `workspace:` list.

---

## Acceptance criteria

- **Given** a PR that changes only `packages/colonizethis_logic/lib/foo.dart`
  and exactly two `app/test/**/*_test.dart` files have transitive import
  closures containing that file, **when** the selector runs, **then** the
  system emits `mode=selective` and `tests` lists exactly those two test
  paths in sorted order.
- **Given** a PR that changes only `packages/colonizethis_ai/lib/x.dart`
  where `x.dart` transitively imports `package:colonizethis_logic/y.dart`,
  and an app test imports `package:colonizethis_ai/x.dart`, **when** the
  selector runs, **then** the system includes that test in `tests`.
- **Given** a PR that changes only `app/assets/icons/foo.png`, **when** the
  selector runs, **then** the system emits `mode=selective` and `tests`
  equals the full sorted list of `app/test/**/*_test.dart`.
- **Given** a PR that changes only the root `pubspec.yaml`, **when** the
  selector runs, **then** the system emits `mode=selective` with the full
  sorted app-test list.
- **Given** a PR that changes only `tool/compute_app_test_plan.dart`,
  **when** the selector runs, **then** the system emits `mode=selective`
  with the full sorted app-test list.
- **Given** a PR carries the `ci:full-app` label and the selector emitted
  any `(mode, tests)` pair from the diff, **when** the `changes` job in
  `quality.yml` finishes post-processing, **then** `quality.yml` overrides
  the values to `mode=selective` and `tests` equal to the full sorted list
  of `app/test/**/*_test.dart`; the selector binary itself does not read
  the label.
- **Given** a PR that changes only `tool/sim_scenarios/**`, **when** the
  selector runs, **then** the system emits `mode=skip` and `tests` is
  empty.
- **Given** the workflow's final `tests` (after any `ci:full-app`
  override) is non-empty, **when** the `app_tests` matrix runs, **then**
  the union of files invoked across all shards equals that `tests`
  exactly: no test runs outside the list and no test runs in more than
  one shard.
- **Given** the workflow's final `tests` is strictly smaller than the full
  app-test list, **when** the workflow finishes, **then**
  `quality_app_coverage` is skipped and no coverage gate failure occurs.
- **Given** the workflow's final `tests` equals the full app-test list,
  **when** the workflow finishes, **then** `quality_app_coverage` runs
  and enforces the existing `app/lib/` >= 80% threshold.
- **Given** the selector emits `mode=skip` and the PR does not carry
  `ci:full-app`, **when** the workflow runs, **then** the `app_tests`
  matrix is skipped at job level and reports success without invoking
  Flutter.
- **Given** a representative PR that touches only
  `packages/colonizethis_logic/lib/**`, **when** CI runs the new pipeline,
  **then** the end-to-end app-test stage (`app_tests_cache` -> `app_tests`
  matrix -> any coverage merge) completes in <= 10 minutes wall-clock.
- **Given** the selector binary is invoked twice with the same
  `--changed-files` argument and the same workspace state, **when** the
  outputs are compared, **then** `mode` and `tests` are byte-identical
  (deterministic); no environment variable, PR label, or workflow
  context affects the binary's output.
- **Given** this SPEC, **when** the implementing PR lands, **then** the
  spec describes only `selective` and `skip` modes, the cross-package
  import-graph extension (lib-only walk, no package `test/**`), the
  irreducible fallback list, the workflow-side `ci:full-app` label
  override, and updated Given–When–Then ACs aligned with the above.
