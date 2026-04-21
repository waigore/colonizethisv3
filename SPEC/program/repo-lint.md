# Repo lint (unified CLI)

**SPEC/program** — Single entrypoint for **repository-wide** convention checks that are not `dart analyze` / `custom_lint` (those stay IDE- and analyzer-driven).

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/ct_repo_lint_manifest.yaml` | Lists **rules** with stable **`rule_id`**, **group**, human title, SPEC path, and how to invoke the checker |
| `tool/ct_repo_lint.dart` | Orchestrator: loads manifest, runs rules in order, stops on first failure |
| `tool/ct_repo_lint_lib.dart` | Parse/execute helpers (also covered by `test/ct_repo_lint_test.dart`) |
| `tool/ct_repo_lint_scan_contract.dart` | **Shared scan contract:** (1) `collectRepoLintDomainDartFiles` + predicates for exception / disallowed-AST **`lib/`** trees; (2) identifier-literal roots/skip helpers; (3) canonical province tile-key collection (`collectRepoLintCanonicalProvinceTileKeyDartFiles`); (4) app UI gate (`collectRepoLintAppLibDartFilesSorted`, `repoLintAppLibHardcodedUiVisitorShouldSkip`); (5) `repoLintSplitRelativeDartPathsArg` for PR incremental path lists — see `test/ct_repo_lint_scan_contract_test.dart` |
| `tool/check_repeated_magic_numbers.dart` | Repeated **hash/LCG-style** integer literals (`SPEC/program/repeated-magic-numbers.md`); rule `repo.repeated_magic_numbers` |
| `tool/check_control_flow_nesting_depth.dart` | Control-flow nesting depth (`SPEC/program/control-flow-nesting-depth.md`); rule `repo.control_flow_nesting_depth` |
| `tool/control_flow_nesting_depth_allowlist.yaml` | Grandfathered symbols at depth ≥4 (shrink-only; see nesting-depth SPEC) |
| `tool/check_function_size.dart` | Function measured-line threshold (`SPEC/program/function-size.md`); rule `repo.function_size` |
| `tool/function_size_allowlist.yaml` | Grandfathered symbols over measured-line threshold (shrink-only; see function-size SPEC) |
| `tool/check_part_unit_size.dart` | `part` file and parent+parts compilation-unit thresholds (`SPEC/program/part-unit-size.md`); rule `repo.part_unit_size` |
| `tool/part_unit_size_allowlist.yaml` | Grandfathered oversized `part` files and parent units (shrink-only; see part-unit-size SPEC) |

## Rule IDs and groups

Each rule has a stable `rule_id` (prefix `repo.`). **Groups** (non-exhaustive): `structure`, `architecture`, `identifiers`, `exceptions`, `game_invariants`, `ui_i18n`. Violation text from underlying tools should include **file path and line** (and column when the checker provides it). The orchestrator prints a banner `--- [rule_id] title ---` before each rule so logs stay attributable.

**Dart `runner` rules** listed in the manifest are executed **in-process** by `ct_repo_lint_lib.dart` (calling `runCheck…` entrypoints on the existing `tool/check_*.dart` modules). Unknown `rule_id` values or future scripts without an in-process binding still use `dart run <script>` as a fallback. Standalone `dart run tool/check_*.dart` remains supported via thin `main()` wrappers.

## CI contract

- **Quality workflow:** One step runs `dart run tool/ct_repo_lint.dart` after OrderEngine codegen verification. Gates that are **not** bundled repo-lint rules stay separate (e.g. `tool/verify_order_engine_codegen.sh`, coverage thresholds, `custom_lint`, package tests).
- **App UI string gate:** Rule `repo.app_hardcoded_ui_strings` runs only when `CT_REPO_LINT_INCLUDE_APP` is exactly `true` (workflow sets this from path filters when app/package paths changed).

## PR incremental scans

Rules marked `pr_incremental: true` in the manifest receive `--files <csv>` when `GITHUB_BASE_REF` is set and `git fetch` / `git diff origin/<base>...HEAD -- '*.dart'` succeeds and yields paths—matching the previous inline `quality.yml` behavior. Use `--force-full-scan` to disable incremental arguments locally or in scripts.

## Adding or changing rules

Do **not** add new top-level `tool/check_*.dart` **entrypoints** for CI without updating this SPEC and the manifest. Prefer:

1. Add a row under `rules:` in `tool/ct_repo_lint_manifest.yaml` with a new stable `rule_id`.
2. Implement or extend logic in a **library** or existing checker module; expose `int runCheck…(String repoRoot, …)` for `ct_repo_lint_lib.dart` to call in-process, keep a thin `main()` that `exit(runCheck…(…))` for `dart run`, and register the manifest row. Add a `switch` arm in `_tryRunDartRuleInProcess` when introducing a new stable `rule_id`.
3. When a new checker scans the **same domain `lib/` tree** as exception / disallowed-AST enforcement, reuse **`collectRepoLintDomainDartFiles`** (and related predicates) from **`tool/ct_repo_lint_scan_contract.dart`**. When it matches **tech / work-target / civilian** literal scans (`app`, `packages`, `tool` trees, `lib/`-gated, fixture-dir markers), reuse **`repoLintIdentifierLiteralScanRoots`** and **`repoLintIdentifierLiteralShouldSkipFile`** with a checker-local `excludedPaths` set. For **canonical province `targetTileKey`** coverage, reuse **`collectRepoLintCanonicalProvinceTileKeyDartFiles`** (tests/generated + checker excludes only — not fixture-dir markers). For **`app/lib` UI copy**, reuse **`collectRepoLintAppLibDartFilesSorted`** and **`repoLintAppLibHardcodedUiVisitorShouldSkip`**.
4. Align wording with `colonizethis_exception_lint` (and similar) when the same policy exists in the analyzer.

## CLI options

`dart run tool/ct_repo_lint.dart --help` — `--list`, `--rule`, `--group`, `--manifest`, `--verbose`, `--force-full-scan`, `--sarif <path>`.

### SARIF (GitHub annotations / code scanning)

- **`--sarif <path>`** or **`--sarif=-`** (stdout): after the run, write **SARIF 2.1.0** with one **result** per failed rule (`level: error`, `message` points to full log for file:line detail). The tool **runs all selected rules** when SARIF is requested (it does not stop at the first failure) so the report lists every failing gate. Checker **stdout** is relayed to **stderr** in this mode so the SARIF stream (file or `-`) stays valid JSON.
- **`--list` and `--sarif` are mutually exclusive.**
- Upload in CI (optional): e.g. `github/codeql-action/upload-sarif` with the generated file; wire paths and permissions per GitHub’s current docs.

## Follow-ups (out of scope for initial landing)

- Align **canonical province tile-key** and **app hardcoded UI string** checkers with the same contract patterns where it reduces duplication without changing coverage.
- Optionally lift shared roots into the manifest once all consumers read it.

## Acceptance criteria

- Given the repository root as cwd, when CI runs `dart run tool/ct_repo_lint.dart` with the workflow env, then all manifest rules applicable to that job execute and failures surface with `rule_id` in the orchestrator banner.
- Given a contributor adds a convention, when they follow CONTRIBUTING and this doc, then they register the rule in the manifest rather than adding a new standalone Quality workflow step for the same concern.
