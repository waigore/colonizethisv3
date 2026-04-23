# Part-Unit Size (repo lint)

**SPEC/program** — repository lint gate for oversized Dart **`part` fragment**
files in logic runtime code.

**Umbrella policy:** `SPEC/program/repo-lint.md` forbids violation allowlists for
any `repo.*` rule. This checker uses a single universal physical-line threshold
only (no keyed exemptions).

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_part_unit_size.dart` | Checker and CLI entrypoint |

## Scan scope

The checker scans `collectRepoLintDomainDartFiles` and then scopes to
`packages/colonizethis_logic/lib/src/**`.

Generated and test files stay excluded by the shared repo-lint scan contract.

## What is a part fragment file

A Dart source file is treated as a **part fragment** when the first
non-empty line that is not a line comment (`//`) begins with the `part of`
directive (for example `part of 'parent.dart';`).

Library files, `part 'child.dart';` parents, and other units without that
leading `part of` directive are out of scope for this rule.

## Measurement contract

- Physical line count is `content.split('\n').length` (same as other repo-lint
  size gates).
- **Threshold:** each in-scope part fragment file must have at most **1000**
  physical lines.

## Acceptance criteria

- Given a Dart file under `packages/colonizethis_logic/lib/src/` that is not a
  part fragment file per the definition above, when the checker runs, then the
  checker does not evaluate that file for this rule.
- Given a part fragment file whose physical line count is less than or equal to
  1000, when the checker runs, then the checker does not fail for that file.
- Given a part fragment file whose physical line count is greater than 1000,
  when the checker runs, then the checker fails and the violation text names that
  file’s repo-relative path and reports the measured line count and the max
  threshold.
