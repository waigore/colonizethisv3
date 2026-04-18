# Repeated magic numbers (repo lint)

**SPEC/program** — AST check for **repeated integer literals** that should be **named constants** (issue #1747).

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_repeated_magic_numbers.dart` | Scanner and `runCheckRepeatedMagicNumbers` |
| `tool/ct_repo_lint_manifest.yaml` | Rule `repo.repeated_magic_numbers` |
| `test/check_repeated_magic_numbers_test.dart` | Unit tests for collection rules |

## What is counted

The checker **does not** flag routine UI sizes, diplomacy scores, or small game constants. It aggregates only literals that look like **algorithm / mixing** constants:

- **Hexadecimal** integer literals (`0x…`, `0X…`) in source, **except** values with **abs ≤ 2** (aligned with excluding −1, 0, 1, 2 in the issue).
- **Decimal** literals with **abs ≥ 0x1000000** (16_777_216).
- **Decimal** literals in the known LCG list: `1103515245`, `12345`.

**Excluded from aggregation:** test / generated paths (same contract as `collectRepoLintDomainDartFiles`), string interpolation, enum constant arguments, **const** variable initializers (definition site only).

## Thresholds

- **Warning:** same numeric value appears **≥ 3** times (stderr; exit **0**).
- **Fail:** same numeric value appears **≥ 5** times (stderr; exit **1**).

## Acceptance criteria

- Given domain `lib/` sources under the shared repo scan roots, when the checker runs, then literals matching “magic” rules above are aggregated and thresholds apply as specified.
- Given a **const** definition of a hex or large literal, when the same value appears in executable code, then the **definition site** does not increase the count.
