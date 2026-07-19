# AI contracts package — no `part` / `part of` directives (repo lint)

**SPEC/program** — repository lint gate that forbids Dart `part` / `part of`
file-splitting in `packages/colonizethis_ai_contracts/lib/`.

## Motivation

`packages/colonizethis_ai_contracts` previously split Full AI civilian work
selection into a nine-file `part` / `part of` cluster. Per #4084 those
fragments were converted into proper libraries with explicit imports and
shared helper hubs. The sibling package gate `repo.ai_no_part_directives`
(#4079) covers only `colonizethis_ai`; this rule mirrors that pattern for the
contracts package so selection / heuristics / localization sub-files cannot
reintroduce `part` coupling.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_ai_no_part_directives.dart` | Shared parameterized scanner (`runCheckAiContractsNoPartDirectives`) |
| `tool/check_ai_contracts_no_part_directives.dart` | CLI entrypoint for this rule |
| `tool/ct_repo_lint_manifest.yaml` (`repo.ai_contracts_no_part_directives`) | Rule registration |

## Scan scope

The checker scans all files returned by `collectRepoLintDomainDartFiles` and
evaluates only those whose repo-relative path begins with
`packages/colonizethis_ai_contracts/lib/`. Generated Dart and test files stay
excluded by the shared repo-lint scan contract.

## What is a `part` directive

Same definition as `SPEC/program/ai-no-part-directives.md`: after trimming
leading whitespace and excluding blank and line-comment (`//`) lines, a line
matching `part '<file>';` or `part of '<file>';` (single- or double-quoted) is
a forbidden directive. Identifiers such as `participants` or `partition` are
not directives.

## Acceptance criteria

- Given a Dart file under `packages/colonizethis_ai_contracts/lib/` that
  contains a line `part 'foo.dart';`, when the checker runs, then the checker
  fails and the violation text names that file's repo-relative path and the
  1-based line number of the directive.
- Given a Dart file under `packages/colonizethis_ai_contracts/lib/` that
  contains a line `part of 'foo.dart';`, when the checker runs, then the
  checker fails and the violation text names that file's repo-relative path
  and the 1-based line number of the directive.
- Given a Dart file under `packages/colonizethis_ai_contracts/lib/` that
  contains no `part` / `part of` directive, when the checker runs, then the
  checker does not fail for that file.
- Given a Dart file outside `packages/colonizethis_ai_contracts/lib/` that
  contains a `part of` directive, when the checker runs, then the checker does
  not evaluate that file for this rule and does not fail because of it.
- Given a line `final participants = <String>[];` in an in-scope file, when the
  checker runs, then the checker does not treat that line as a `part`
  directive and does not fail because of it.
