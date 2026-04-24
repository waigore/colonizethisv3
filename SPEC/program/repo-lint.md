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
| `tool/function_size_allowlist.yaml` | **Legacy:** violates [Policy: no violation allowlists](#policy-no-violation-allowlists-repo-lint); remove when function-size checker matches policy |
| `tool/check_part_unit_size.dart` | Dart `part` fragment physical line limit (`SPEC/program/part-unit-size.md`); rule `repo.part_unit_size` |
| `tool/check_no_flame_in_widgets.dart` | Disallow direct `package:flame/*` **import** and **export** lines (single- or double-quoted URI) under `app/lib/widgets/**`; rule `repo.no_flame_in_widgets` |

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
