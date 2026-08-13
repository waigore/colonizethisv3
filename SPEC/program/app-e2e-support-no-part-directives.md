# App e2e support — no `part` / `part of` directives (repo lint)

**SPEC/program** — repository lint gate that forbids Dart `part` / `part of`
file-splitting in `packages/colonizethis_app_e2e_support/{lib,test}/**`.

## Motivation

Wave 3 (#4344) converted remaining `part` / `part of` clusters under
`colonizethis_app_e2e_support` into explicit-import libraries. Sibling packages
already gate `lib/` with `repo.*_no_part_directives`. This package also had
parts under `test/`, so the gate uses the **package-root** path prefix and
covers both trees so de-part debt cannot return.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_ai_no_part_directives.dart` | Shared parameterized scanner (`runCheckAppE2eSupportNoPartDirectives`) |
| `tool/check_app_e2e_support_no_part_directives.dart` | CLI entrypoint for this rule |
| `tool/ct_repo_lint_manifest.yaml` (`repo.app_e2e_support_no_part_directives`) | Rule registration |

## Scan scope

The checker scans files from `collectRepoLintDomainDartFiles` whose
repo-relative path begins with `packages/colonizethis_app_e2e_support/`
(both `lib/` and `test/`). Generated Dart stays excluded by the shared
repo-lint scan contract.

## What is a `part` directive

Same definition as `SPEC/program/ai-no-part-directives.md`: after trimming
leading whitespace and excluding blank and line-comment (`//`) lines, a line
matching `part '<file>';` or `part of '<file>';` (single- or double-quoted) is
a forbidden directive. Identifiers such as `participants` or `partition` are
not directives.

## Acceptance criteria

- Given a Dart file under `packages/colonizethis_app_e2e_support/lib/` that
  contains a line `part 'foo.dart';`, when the checker runs, then the checker
  fails and the violation text names that file's repo-relative path and the
  1-based line number of the directive.
- Given a Dart file under `packages/colonizethis_app_e2e_support/test/` that
  contains a line `part of 'foo.dart';`, when the checker runs, then the
  checker fails and the violation text names that file's repo-relative path
  and the 1-based line number of the directive.
- Given a Dart file under `packages/colonizethis_app_e2e_support/` that
  contains no `part` / `part of` directive, when the checker runs, then the
  checker does not fail for that file.
- Given a Dart file outside `packages/colonizethis_app_e2e_support/` that
  contains a `part of` directive, when the checker runs, then the checker does
  not evaluate that file for this rule and does not fail because of it.
- Given a line `final participants = <String>[];` in an in-scope file, when the
  checker runs, then the checker does not treat that line as a `part`
  directive and does not fail because of it.
