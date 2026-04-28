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
| `tool/control_flow_nesting_depth_allowlist.yaml` | **Legacy:** violates [Policy: no violation allowlists](#policy-no-violation-allowlists-repo-lint); remove when nesting checker matches policy (see `SPEC/program/control-flow-nesting-depth.md`) |
| `tool/check_function_size.dart` | Function measured-line threshold (`SPEC/program/function-size.md`); rule `repo.function_size` |
| `tool/check_part_unit_size.dart` | Dart `part` fragment physical line limit (`SPEC/program/part-unit-size.md`); rule `repo.part_unit_size` |
| `tool/check_debug_console_logic_contract_boundary.dart` | AST-enforced import allowlist for debug-console -> logic boundary; rule `repo.debug_console_logic_contract_boundary` |
| `tool/check_app_event_handler_scope_logic_boundary.dart` | Enforce that `app/lib/core/services/app_event_handler_scope.dart` has no direct import from `app/lib/features/game/logic/**`; rule `repo.app_event_handler_scope_logic_boundary` |
| `tool/check_no_flame_in_widgets.dart` | Disallow direct `package:flame/*` **import** and **export** lines (single- or double-quoted URI) under `app/lib/widgets/**`; rule `repo.no_flame_in_widgets` |
| `tool/check_no_screen_in_game_widgets.dart` | Disallow `*_screen.dart` files under `app/lib/features/game/widgets/**`; rule `repo.no_screen_in_game_widgets` |
| `tool/check_game_widgets_file_size.dart` | Enforce `app/lib/features/game/widgets/**` Dart files at **700 physical lines or fewer**; rule `repo.game_widgets_file_size` |
| `tool/check_land_province_bucket_keys.dart` | For guarded explore/fog/news paths, disallow local-only land-province tile-bucket lookups (`tileKeysByRegionAndProvince[region]?[localId]`); require canonical full-id buckets only; rule `repo.land_province_bucket_keys` |

## Rule IDs and groups

Each rule has a stable `rule_id` (prefix `repo.`). **Groups** (non-exhaustive): `structure`, `architecture`, `identifiers`, `exceptions`, `game_invariants`, `ui_i18n`. Violation text from underlying tools should include **file path and line** (and column when the checker provides it). The orchestrator prints a banner `--- [rule_id] title ---` before each rule so logs stay attributable.

**Dart `runner` rules** listed in the manifest are executed **in-process** by `ct_repo_lint_lib.dart` (calling `runCheck…` entrypoints on the existing `tool/check_*.dart` modules). Unknown `rule_id` values or future scripts without an in-process binding still use `dart run <script>` as a fallback. Standalone `dart run tool/check_*.dart` remains supported via thin `main()` wrappers.

## CI contract

- **Quality workflow (order):** After root `dart pub get`, **`dart run tool/run_workspace_analyze_errors_only.dart`** runs **`dart analyze`** or **`flutter analyze`** for **every** `dart pub workspace list` member (including `test/` and `integration_test/`). The step **fails only on analyzer `error` diagnostics** (warnings and infos do not fail), matching `tool/run_quality_gate_tests.sh`. Entrypoint: `tool/run_workspace_analyze_errors_only.dart`; Melos: `melos run workspace_analyze_errors_only`. Then **`tool/verify_order_engine_codegen.sh`**, then **`dart run tool/ct_repo_lint.dart`**. Gates that are **not** bundled repo-lint rules stay separate (e.g. coverage thresholds, `custom_lint`, package tests).
- **App UI string gate:** Rule `repo.app_hardcoded_ui_strings` runs only when `CT_REPO_LINT_INCLUDE_APP` is exactly `true` (workflow sets this from path filters when app/package paths changed).
- **`app_tests_cache` job:** Still runs **`flutter analyze`** under `app/` only (errors-only grep) before packing the test cache; redundant with the app slice of the workspace gate but keeps an early signal for app-only paths.

## PR incremental scans

Rules marked `pr_incremental: true` in the manifest receive `--files <csv>` when `GITHUB_BASE_REF` is set and `git fetch` / `git diff origin/<base>...HEAD -- '*.dart'` succeeds and yields paths—matching the previous inline `quality.yml` behavior. Use `--force-full-scan` to disable incremental arguments locally or in scripts.

## Adding or changing rules

Do **not** add new top-level `tool/check_*.dart` **entrypoints** for CI without updating this SPEC and the manifest. Prefer:

1. Add a row under `rules:` in `tool/ct_repo_lint_manifest.yaml` with a new stable `rule_id`.
2. Implement or extend logic in a **library** or existing checker module; expose `int runCheck…(String repoRoot, …)` for `ct_repo_lint_lib.dart` to call in-process, keep a thin `main()` that `exit(runCheck…(…))` for `dart run`, and register the manifest row. Add a `switch` arm in `_tryRunDartRuleInProcess` when introducing a new stable `rule_id`.
3. Reuse `collectRepoLintDomainDartFiles` and related helpers from `ct_repo_lint_scan_contract.dart` when scanning the same domain `lib/` trees; reuse identifier-literal roots/skip helpers, canonical province tile-key collectors, and app UI lib helpers where they match the checker’s domain (see contract tests).
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
- Given `packages/colonizethis_debug_console/lib/**` imports only allowlisted `colonizethis_logic` contract entrypoints, when `dart run tool/ct_repo_lint.dart` runs rule `repo.debug_console_logic_contract_boundary`, then the rule passes without violations.
- Given any debug-console file imports `package:colonizethis_logic/src/**` or another non-allowlisted `package:colonizethis_logic/...` entrypoint, when repo lint runs rule `repo.debug_console_logic_contract_boundary`, then the run fails and reports file path, line, and disallowed import context in checker output.
- Given `app/lib/core/services/app_event_handler_scope.dart` has no direct imports from `package:colonizethis_app/features/game/logic/**`, when repo lint runs rule `repo.app_event_handler_scope_logic_boundary`, then the rule passes without violations.
- Given `app/lib/core/services/app_event_handler_scope.dart` directly imports any `package:colonizethis_app/features/game/logic/**` path, when repo lint runs rule `repo.app_event_handler_scope_logic_boundary`, then the run fails and reports file path and line number.
