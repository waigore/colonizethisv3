# Repo lint (unified CLI)

**SPEC/program** — Single entrypoint for **repository-wide** convention checks that are not `dart analyze` / `custom_lint` (those stay IDE- and analyzer-driven).

## Policy: no violation allowlists (repo lint)

**Repo lint** means manifest rules (`repo.*` in `tool/ct_repo_lint_manifest.yaml`) executed by `dart run tool/ct_repo_lint.dart`.

**Forbidden:** Keyed waiver data (grandfather YAML, per-path or per-symbol caps) whose purpose is to let in-scope code violate a rule’s threshold or predicate while CI still passes.

**Allowed:** Scope-only wiring in `tool/ct_repo_lint_scan_contract.dart`, checker path predicates, and env such as `CT_REPO_LINT_INCLUDE_APP` that exclude whole paths—not waivers inside an analyzed file.

Grandfather YAMLs named in the table below are **legacy** until removed; **do not add new violation allowlists.**

### Acceptance criteria (policy)

- Given a `repo.*` rule implementation, when a maintainer audits it for waiver data, then the maintainer finds no keyed tables loaded solely to raise effective limits for specific in-scope symbols or files.
- Given `SPEC/program/repo-lint.md`, when a contributor adds or changes a manifest rule, then the contributor does not introduce a new violation-allowlist mechanism.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/ct_repo_lint_manifest.yaml` | Lists **rules** with stable **`rule_id`**, **group**, human title, SPEC path, and how to invoke the checker |
| `tool/ct_repo_lint.dart` | Orchestrator: loads manifest, runs rules in order, stops on first failure |
| `tool/ct_repo_lint_lib.dart` | Parse/execute helpers (also covered by `test/ct_repo_lint_test.dart`) |
| `tool/ct_repo_lint_scan_contract.dart` | Shared roots, skip helpers, canonical tile-key collectors, app UI path gate, PR path split — see `test/ct_repo_lint_scan_contract_test.dart` |
| `tool/check_repeated_magic_numbers.dart` | Repeated **hash/LCG-style** integer literals (`SPEC/program/repeated-magic-numbers.md`); rule `repo.repeated_magic_numbers` |
| `tool/check_control_flow_nesting_depth.dart` | Control-flow nesting depth (`SPEC/program/control-flow-nesting-depth.md`); rule `repo.control_flow_nesting_depth` |
| `tool/check_function_size.dart` | Function measured-line threshold (`SPEC/program/function-size.md`); rule `repo.function_size` |
| `tool/check_part_unit_size.dart` | Dart `part` fragment physical line limit (`SPEC/program/part-unit-size.md`); rule `repo.part_unit_size` |
| `tool/check_debug_console_logic_contract_boundary.dart` | AST-enforced import allowlist for debug-console -> logic boundary; rule `repo.debug_console_logic_contract_boundary` |
| `tool/check_app_event_handler_scope_logic_boundary.dart` | Enforce that `app/lib/core/services/app_event_handler_scope.dart` has no direct import from `app/lib/features/game/logic/**`; rule `repo.app_event_handler_scope_logic_boundary` |
| `tool/check_no_flame_in_widgets.dart` | Disallow direct `package:flame/*` **import** and **export** lines (single- or double-quoted URI) under `app/lib/widgets/**`; rule `repo.no_flame_in_widgets` |
| `tool/check_no_screen_in_game_widgets.dart` | Disallow `*_screen.dart` files under `app/lib/features/game/widgets/**`; rule `repo.no_screen_in_game_widgets` |
| `tool/check_game_widgets_file_size.dart` | Enforce `app/lib/features/game/widgets/**` Dart files at **700 physical lines or fewer**; rule `repo.game_widgets_file_size` |
| `tool/check_dart_file_non_comment_line_size.dart` | Enforce repository-wide Dart files at **1000 non-comment lines or fewer** (fail when strictly greater), excluding generated suffixes (`.g.dart`, `.freezed.dart`, `.mocks.dart`, `.gen.dart`); rule `repo.dart_file_non_comment_line_size` |
| `tool/check_land_province_bucket_keys.dart` | For guarded explore/fog/news paths, disallow local-only land-province tile-bucket lookups (`tileKeysByRegionAndProvince[region]?[localId]`); require canonical full-id buckets only; rule `repo.land_province_bucket_keys` |

## Rule IDs and groups

Each rule has a stable `rule_id` (prefix `repo.`). **Groups** (non-exhaustive): `structure`, `architecture`, `identifiers`, `exceptions`, `game_invariants`, `ui_i18n`. Violation text from underlying tools should include **file path and line** (and column when the checker provides it). The orchestrator prints a banner `--- [rule_id] title ---` before each rule so logs stay attributable.

**Dart `runner` rules** listed in the manifest are executed **in-process** by `ct_repo_lint_lib.dart` (calling `runCheck…` entrypoints on the existing `tool/check_*.dart` modules). Unknown `rule_id` values or future scripts without an in-process binding still use `dart run <script>` as a fallback. Standalone `dart run tool/check_*.dart` remains supported via thin `main()` wrappers.

## CI contract

- **Quality workflow (order):** After root `dart pub get`, **`dart run tool/run_workspace_analyze_errors_only.dart`** runs **`flutter pub get`** then **`flutter gen-l10n`** (when **`l10n.yaml`** exists) in each **Flutter** workspace package, then **`dart analyze`** or **`flutter analyze`** for **every** `dart pub workspace list` member (including `test/` and `integration_test/`). The step **fails only on analyzer `error` diagnostics** (warnings and infos do not fail), matching `tool/run_quality_gate_tests.sh`. The **repo-root** `colonizethis` package excludes **`test/**`** in `analysis_options.yaml` because those files are checker harness fixtures that reference `package:colonizethis_app` without a root dependency on `app/`. Entrypoint: `tool/run_workspace_analyze_errors_only.dart`; Melos: `melos run workspace_analyze_errors_only`. Then **`tool/verify_order_engine_codegen.sh`**, then **`dart run tool/ct_repo_lint.dart`**. Gates that are **not** bundled repo-lint rules stay separate (e.g. coverage thresholds, `custom_lint`, package tests).
- **App UI string gate:** Rule `repo.app_hardcoded_ui_strings` runs only when `CT_REPO_LINT_INCLUDE_APP` is exactly `true` (workflow sets this from path filters when app/package paths changed).
- **`app_tests_cache` job:** Still runs **`flutter analyze`** under `app/` only (errors-only grep) before packing the test cache; redundant with the app slice of the workspace gate but keeps an early signal for app-only paths.

## Test and `integration_test/` static analysis scope (GitHub #2014)

**Goal:** `test/` and `integration_test/` Dart are **first-class** for the same categories of static gates as `lib/` where the toolchain and rule design apply. **Generated code, goldens, fixtures, and similar trees stay excluded** (see [Shared exclusions](#shared-exclusions-testintegration_test-generation-and-fixtures)).

**Phasing:** Land in **at most five mergeable slices** on `dev`. Each merged slice **must keep required CI green**. Do **not** widen **fatal** enforcement under `test/` / `integration_test/` (manifest rules, `ct_repo_lint_scan_contract` collectors, binary AST checkers) unless violations are **fixed in the same PR** **or** an intermediate slice uses a **SPEC-documented** non-fatal / audit / baseline mechanism for that transition (recorded in this doc or the rule’s SPEC with an issue link).

### Failure semantics (do not conflate)

| Mechanism | CI interpretation |
|-----------|---------------------|
| **`dart analyze` / `flutter analyze`** (**when CI uses error-only parsing**) | Fail the job only on **analyzer `error` severity** lines; **warnings and infos do not fail** the gate unless project policy explicitly changes. |
| **`dart run tool/ct_repo_lint.dart`** and manifest-driven `runner` rules | **Binary pass/fail** per rule design (`exit` non-zero on violation); not governed by “analyzer errors only.” |
| **`custom_lint` / `dart run custom_lint`** | Treat as **analyzer diagnostics** (same severity model as `dart analyze` for the plugin); CI should match the wired script’s contract (see [exception-enforcement.md](exception-enforcement.md)). |
| **Standalone AST scripts** (e.g. `dart tool/check_long_string_switches.dart`) | **Binary** on their own thresholds unless a SPEC says otherwise. |

### Shared exclusions (test/integration_test, generation, fixtures)

Across tools that intentionally share skip logic, exclude at minimum:

- Suffixes: `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `*.gen.dart` (and any other generated suffixes called out per package).
- Path fragments (fixture / golden trees): see `repoLintFixtureDirPathMarkers` in `tool/ct_repo_lint_scan_contract.dart` (`/test_data/`, `/fixtures/`, `/golden/`, etc.) wherever that helper applies.

`tool/check_long_string_switches.dart` does **not** use `collectRepoLintDomainDartFiles`; it walks repo `.dart` files with its **own** exclusions (e.g. `.dart_tool`, `.pub-cache`, `build`, `*.g.dart`, and the tech embed path). Treat it as **already covering tests** unless SPEC is intentionally updated to narrow exclusions.

### Scan contract vs lib-only checkers (GitHub #2014)

**Domain collector** `collectRepoLintDomainDartFiles` in `tool/ct_repo_lint_scan_contract.dart` includes workspace **`packages/*/lib|test|integration_test`**, **`app/lib|test|integration_test`**, **`ctdev/lib|test`**, and **`tool/**`** Dart that passes `repoLintPathIsDomainLibSourceForScan` or `repoLintPathIsDomainTestOrIntegrationTestSourceForScan`: generated suffixes and `repoLintFixtureDirPathMarkers` paths are excluded; **repo-root `test/**`** (checker/tool tests) stays excluded so those files do not run production AST rules. Checkers using it include (non-exhaustive): `check_disallowed_ast_patterns`, `check_custom_exceptions`, `check_function_size`, `check_part_unit_size`, `check_control_flow_nesting_depth`; `check_debug_console_logic_contract_boundary` delegates to the disallowed-AST checker. Per-file guards in `check_disallowed_ast_patterns` use **`repoLintPathShouldSkipAstRuleFile`** (same exclusions except package `test/` is analyzed). `check_repeated_magic_numbers` remains scoped by its own SPEC (`SPEC/program/repeated-magic-numbers.md`) and excludes test trees.

**Identifier-literal helpers** `repoLintIdentifierLiteralShouldSkipFile` and **canonical tile-key** `collectRepoLintCanonicalProvinceTileKeyDartFiles` / `repoLintCanonicalProvinceTileKeyShouldSkipFile` use roots **`app`**, **`packages`**, **`ctdev`**, **`tool`** and include **`lib/`**, **`test/`**, and **`integration_test/`** under those trees (still skipping generated, repo-root `test/`, and fixture markers). **App hardcoded UI strings** remain **`app/lib/**` only** via `collectRepoLintAppLibDartFilesSorted` / `repoLintAppLibHardcodedUiVisitorShouldSkip` (production UI surface).

### CI workflow parity

**Today:** `.github/workflows/quality.yml` is the **only** workflow (as of the #2014 documentation slice) that runs `ct_repo_lint`, domain `custom_lint`, and (in `app_tests_cache`) `flutter analyze` plus `check_long_string_switches`. Any **additional** workflow that runs the same class of checks **must** match the **scope and exclusions** documented here.

**Workspace analyzer:** Implemented — see [CI contract](#ci-contract) (`quality` job, `tool/run_workspace_analyze_errors_only.dart`).

### Acceptance criteria (#2014 documentation)

- Given this section and CONTRIBUTING, when a maintainer widens a fatal repo rule to `test/`, then the change either **co-fixes violations** in the same PR or documents an allowed **audit/baseline** transition in SPEC with tracking reference.
- Given `.github/workflows/quality.yml`, when a contributor adds a new job that runs `ct_repo_lint`, domain `custom_lint`, or package analyze steps, then that job follows the **failure semantics** table above and the **exclusion** rules in this section unless a narrower rule SPEC explicitly overrides.
- Given `tool/check_long_string_switches.dart`, when triaging #2014, then implementers treat long-string switch coverage as **already including tests** unless a deliberate SPEC change narrows scope.

### Phased roadmap (GitHub #2014, ≤5 mergeable slices)

Each slice must leave **`dev` required checks green**. Order matters: do **not** widen fatal repo-lint or scan-contract scope to `test/` / `integration_test/` until violations are fixed in the same PR or a SPEC-approved non-fatal transition exists.

| Slice | Scope | Status on `dev` (authoritative: workflow + tools) |
|-------|--------|-----------------------------------------------------|
| **1** | SPEC, CONTRIBUTING, testing-rule cross-links: scope, exclusions, mergeability, analyzer vs binary semantics, workflow job names | **Documented** — this table + CI contract above; other workflows audited (see below). |
| **2** | **`custom_lint`:** zero analyzer **error**-severity issues in `test/` and `integration_test/` for every package wired by `tool/run_custom_lint_domain_exceptions.sh` (same bar as `lib/`) | **CI enforced** — Quality runs the script after `ct_repo_lint`; fix violations in the same PR as any tightening. |
| **3** | **`dart analyze` / `flutter analyze`:** every Pub workspace package analyzed with test trees; **errors-only** gate | **CI enforced** — `quality` runs `dart run tool/run_workspace_analyze_errors_only.dart` after `dart pub get` (runs **`flutter gen-l10n`** for each Flutter workspace package with **`l10n.yaml`** before analyze); `app_tests_cache` keeps an early **`flutter analyze`** under `app/` only (redundant for app but preserves cache-job signal). Local: `tool/run_quality_gate_tests.sh` includes the same workspace step. |
| **4** | **`ct_repo_lint` + manifest:** `collectRepoLintDomainDartFiles` includes package **`test/`** and **`integration_test/`** (and identifier-literal / canonical tile-key collectors include **`ctdev`** roots); violations fixed in the same change set | **Implemented** — see [Scan contract vs lib-only checkers](#scan-contract-vs-lib-only-checkers-github-2014). |
| **5** | **AST checkers** using the scan contract: per-file skip uses **`repoLintPathShouldSkipAstRuleFile`**; contract tests cover inclusion/exclusion | **Implemented** — `test/ct_repo_lint_scan_contract_test.dart`. |

Slices **4** and **5** may be **one PR** if scan-contract changes and checker fixes ship together, staying within the five-slice budget.

### Workflow audit (parity with #2014)

Only **`.github/workflows/quality.yml`** runs **`dart run tool/run_workspace_analyze_errors_only.dart`**, **`dart run tool/ct_repo_lint.dart`**, or **`bash tool/run_custom_lint_domain_exceptions.sh`**. A repository search of `.github/workflows/*.yml` for those strings finds no other matches as of the slice-1 documentation update. Any **new** workflow that runs the same class of checks must match **scope**, **exclusions**, and the **failure semantics** table in this section.

## PR incremental scans

Rules marked `pr_incremental: true` in the manifest receive `--files <csv>` when `GITHUB_BASE_REF` is set and `git fetch` / `git diff origin/<base>...HEAD -- '*.dart'` succeeds and yields paths—matching the previous inline `quality.yml` behavior. Use `--force-full-scan` to disable incremental arguments locally or in scripts.

## Adding or changing rules

Do **not** add new top-level `tool/check_*.dart` **entrypoints** for CI without updating this SPEC and the manifest. Prefer:

1. Add a row under `rules:` in `tool/ct_repo_lint_manifest.yaml` with a new stable `rule_id`.
2. Implement or extend logic in a **library** or existing checker module; expose `int runCheck…(String repoRoot, …)` for `ct_repo_lint_lib.dart` to call in-process, keep a thin `main()` that `exit(runCheck…(…))` for `dart run`, and register the manifest row. Add a `switch` arm in `_tryRunDartRuleInProcess` when introducing a new stable `rule_id`.
3. Reuse `collectRepoLintDomainDartFiles` and related helpers from `ct_repo_lint_scan_contract.dart` when scanning the same domain trees (`lib/`, `test/`, `integration_test/` per contract); reuse identifier-literal roots/skip helpers, canonical province tile-key collectors, and app UI lib helpers where they match the checker’s domain (see contract tests).
4. Align wording with `colonizethis_exception_lint` (and similar) when the same policy exists in the analyzer.

## CLI options

`dart run tool/ct_repo_lint.dart --help` — `--list`, `--rule`, `--group`, `--manifest`, `--verbose`, `--force-full-scan`, `--sarif <path>`.

### SARIF (GitHub annotations / code scanning)

- **`--sarif <path>`** or **`--sarif=-`**: write **SARIF 2.1.0** (one result per failed rule); runs all selected rules; checker stdout goes to stderr so JSON stays valid. **`--list` and `--sarif` are mutually exclusive.**
- Optional CI upload via `github/codeql-action/upload-sarif` per GitHub docs.

## Follow-ups (out of scope for initial landing)

- Align **canonical province tile-key** and **app hardcoded UI string** checkers with the same contract patterns where it reduces duplication without changing coverage.
- Optionally lift shared roots into the manifest once all consumers read it.

## Acceptance criteria

- Given the repository root as cwd, when CI runs `dart run tool/ct_repo_lint.dart` with the workflow env, then all manifest rules applicable to that job execute and failures surface with `rule_id` in the orchestrator banner.
- Given a contributor adds a convention, when they follow CONTRIBUTING and this doc, then they register the rule in the manifest rather than adding a new standalone Quality workflow step for the same concern.
- Given the [Policy: no violation allowlists](#policy-no-violation-allowlists-repo-lint) section, when implementation work completes for a legacy checker still loading grandfather YAML, then that checker, its tests, and the per-rule SPEC no longer document or depend on violation allowlists.
- Given app game feature code, when `dart run tool/ct_repo_lint.dart` runs rule `repo.no_screen_in_game_widgets`, then no file matching `*_screen.dart` exists under `app/lib/features/game/widgets/**`.
- Given app game widget files, when `dart run tool/ct_repo_lint.dart` runs rule `repo.game_widgets_file_size`, then each Dart file under `app/lib/features/game/widgets/**` has 700 physical lines or fewer.
- Given repository Dart files (excluding generated suffixes `.g.dart`, `.freezed.dart`, `.mocks.dart`, `.gen.dart`), when `dart run tool/ct_repo_lint.dart` runs rule `repo.dart_file_non_comment_line_size`, then each scanned file has at most 1000 non-comment lines and the run fails while listing every violating file when any file is strictly greater than 1000.
- Given `packages/colonizethis_debug_console/lib/**` imports only allowlisted `colonizethis_logic` contract entrypoints, when `dart run tool/ct_repo_lint.dart` runs rule `repo.debug_console_logic_contract_boundary`, then the rule passes without violations.
- Given any debug-console file imports `package:colonizethis_logic/src/**` or another non-allowlisted `package:colonizethis_logic/...` entrypoint, when repo lint runs rule `repo.debug_console_logic_contract_boundary`, then the run fails and reports file path, line, and disallowed import context in checker output.
- Given `app/lib/core/services/app_event_handler_scope.dart` has no direct imports from `package:colonizethis_app/features/game/logic/**`, when repo lint runs rule `repo.app_event_handler_scope_logic_boundary`, then the rule passes without violations.
- Given `app/lib/core/services/app_event_handler_scope.dart` directly imports any `package:colonizethis_app/features/game/logic/**` path, when repo lint runs rule `repo.app_event_handler_scope_logic_boundary`, then the run fails and reports file path and line number.
