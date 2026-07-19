# AI package — no `part` / `part of` directives (repo lint)

**SPEC/program** — repository lint gate that forbids Dart `part` / `part of`
file-splitting in `packages/colonizethis_ai/lib/`.

## Motivation

`packages/colonizethis_ai` previously split planning and perception modules
into `part` / `part of` fragments (treasury, expand, colonial, orchestrator,
diplomacy, diplomatic scoring, recruitment, economy, conquest, perception).
Per #4079 Phase 9 those fragments were converted into proper libraries with
explicit imports and shared constant/type hubs where needed to avoid cycles.
The `part of` pattern couples every fragment to a single library's implicit
namespace and hides cross-file symbol visibility. This gate keeps any new
sub-file in the AI package a proper library with explicit imports, matching
the equivalent gates for peer domain packages
(`repo.world_no_part_directives`, `repo.turn_no_part_directives`,
`repo.diplomacy_no_part_of`, `repo.orders_no_part_directives`,
`repo.economy_no_part_directives`, `repo.models_no_part_directives`,
`repo.combat_no_part_directives`).

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_ai_no_part_directives.dart` | Checker and CLI entrypoint |
| `tool/ct_repo_lint_manifest.yaml` (`repo.ai_no_part_directives`) | Rule registration |

## Scan scope

The checker scans all files returned by `collectRepoLintDomainDartFiles` and
evaluates only those whose repo-relative path begins with
`packages/colonizethis_ai/lib/`. Generated Dart and test files stay excluded
by the shared repo-lint scan contract.

## What is a `part` directive

A line is treated as a forbidden directive when, after trimming leading
whitespace and excluding blank and line-comment (`//`) lines, it matches the
Dart directive form `part '<file>';` or `part of '<file>';` (single- or
double-quoted). Identifiers such as `participants` or `partition` are not
directives and are out of scope.

## Acceptance criteria

- Given a Dart file under `packages/colonizethis_ai/lib/` that contains a
  line `part 'foo.dart';`, when the checker runs, then the checker fails and
  the violation text names that file's repo-relative path and the 1-based line
  number of the directive.
- Given a Dart file under `packages/colonizethis_ai/lib/` that contains a
  line `part of 'foo.dart';`, when the checker runs, then the checker fails and
  the violation text names that file's repo-relative path and the 1-based line
  number of the directive.
- Given a Dart file under `packages/colonizethis_ai/lib/` that contains no
  `part` / `part of` directive, when the checker runs, then the checker does
  not fail for that file.
- Given a Dart file outside `packages/colonizethis_ai/lib/` that contains a
  `part of` directive, when the checker runs, then the checker does not
  evaluate that file for this rule and does not fail because of it.
- Given a line `final participants = <String>[];` in an in-scope file, when the
  checker runs, then the checker does not treat that line as a `part` directive
  and does not fail because of it.
