# Turn package — no `part` / `part of` directives (repo lint)

**SPEC/program** — repository lint gate that forbids Dart `part` / `part of`
file-splitting in `packages/colonizethis_turn/lib/`.

## Motivation

`packages/colonizethis_turn` previously split two libraries
(`naval_resolution.dart`, `world_market_phase.dart`) into `part of` fragments
(Refs #3290 Phase-0). Per #3416 those fragments were converted into proper
libraries with explicit imports. The `part of` pattern couples every fragment
to a single library's implicit namespace, hides cross-file symbol visibility,
and makes individual helpers harder to test in isolation. This gate keeps any
new sub-file in the turn package a proper library with explicit imports.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_turn_no_part_directives.dart` | Checker and CLI entrypoint |
| `tool/ct_repo_lint_manifest.yaml` (`repo.turn_no_part_directives`) | Rule registration |

## Scan scope

The checker scans all files returned by `collectRepoLintDomainDartFiles` and
evaluates only those whose repo-relative path begins with
`packages/colonizethis_turn/lib/`. Generated and test files stay excluded by the
shared repo-lint scan contract.

## What is a `part` directive

A line is treated as a forbidden directive when, after trimming leading
whitespace and excluding blank and line-comment (`//`) lines, it matches the
Dart directive form `part '<file>';` or `part of '<file>';` (single- or
double-quoted). Identifiers such as `participants` or `partition` are not
directives and are out of scope.

## Acceptance criteria

- Given a Dart file under `packages/colonizethis_turn/lib/` that contains a
  line `part 'foo.dart';`, when the checker runs, then the checker fails and the
  violation text names that file's repo-relative path and the 1-based line
  number of the directive.
- Given a Dart file under `packages/colonizethis_turn/lib/` that contains a
  line `part of 'foo.dart';`, when the checker runs, then the checker fails and
  the violation text names that file's repo-relative path and the 1-based line
  number of the directive.
- Given a Dart file under `packages/colonizethis_turn/lib/` that contains no
  `part` / `part of` directive, when the checker runs, then the checker does not
  fail for that file.
- Given a Dart file outside `packages/colonizethis_turn/lib/` that contains a
  `part of` directive, when the checker runs, then the checker does not evaluate
  that file for this rule and does not fail because of it.
- Given a line `final participants = <String>[];` in an in-scope file, when the
  checker runs, then the checker does not treat that line as a `part` directive
  and does not fail because of it.
