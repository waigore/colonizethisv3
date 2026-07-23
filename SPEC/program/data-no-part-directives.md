# Data package — no `part` / `part of` directives (repo lint)

**SPEC/program** — repository lint gate that forbids new Dart `part` / `part of`
file-splitting in `packages/colonizethis_data/lib/` outside a shrink-only
grandfather allowlist while wave-4 de-part slices land.

## Motivation

`packages/colonizethis_data` had residual `part of` clusters (`tech_catalog`,
`combat_config`, `naming_rules`). Per #4121 those clusters are being converted
into proper libraries with explicit imports. The `part of`
pattern couples every fragment to a single library's implicit namespace and
makes individual helpers harder to test in isolation. This gate blocks new
`part` directives outside the grandfather while migration completes, matching
peer packages (`repo.orders_no_part_directives`, `repo.world_no_part_directives`,
`repo.app_no_part_directives`, etc.).

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_data_no_part_directives.dart` | Checker and CLI entrypoint |
| `tool/data_no_part_directives_grandfather.dart` | Shrink-only grandfather allowlist |
| `tool/ct_repo_lint_manifest.yaml` (`repo.data_no_part_directives`) | Rule registration |

## Scan scope

The checker scans all files returned by `collectRepoLintDomainDartFiles` and
evaluates only those whose repo-relative path begins with
`packages/colonizethis_data/lib/`. Generated Dart and test files stay excluded
by the shared repo-lint scan contract.

## Grandfather allowlist

Files listed in `tool/data_no_part_directives_grandfather.dart` may still contain
`part` / `part of` directives during migration. The allowlist is **shrink-only**:
stale entries (missing file or file no longer containing a part directive) fail
CI, and new part directives outside the allowlist fail CI.

## What is a `part` directive

A line is treated as a forbidden directive when, after trimming leading
whitespace and excluding blank and line-comment (`//`) lines, it matches the
Dart directive form `part '<file>';` or `part of '<file>';` (single- or
double-quoted). Identifiers such as `participants` or `partition` are not
directives and are out of scope.

## Acceptance criteria

- Given `packages/colonizethis_data/lib/**` on `dev` where every `part` /
  `part of` directive is confined to the shrink-only grandfather allowlist in
  `tool/data_no_part_directives_grandfather.dart`, when
  `dart run tool/ct_repo_lint.dart` runs rule `repo.data_no_part_directives`,
  then the rule passes without violations and exits `0` (Refs #4121).
- Given a `packages/colonizethis_data/lib/**` Dart file not on the grandfather
  allowlist that contains `part 'foo.dart';` or `part of 'foo.dart';`, when the
  checker runs, then the run fails listing each offending `path:line` and exits
  `1` (Refs #4121).
- Given a stale grandfather allowlist entry (missing file or file no longer
  containing a `part` directive), when the checker runs, then the run fails
  with a stale-entry message and exits `1` (Refs #4121).
- Given a line `final participants = <String>[];` in an in-scope file, when the
  checker runs, then the checker does not treat that line as a `part` directive
  and does not fail because of it.
