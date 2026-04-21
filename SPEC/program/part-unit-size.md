# Part-Unit Size (repo lint)

**SPEC/program** - repository lint gate for oversized `part`-based compilation
units in logic runtime code.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_part_unit_size.dart` | Checker and CLI entrypoint |
| `tool/part_unit_size_allowlist.yaml` | Shrink-only allowlist for existing oversized parent units and `part` files |

## Scan scope

The checker scans `collectRepoLintDomainDartFiles` and then scopes to
`packages/colonizethis_logic/lib/src/**`.

Generated and test files stay excluded by the shared repo-lint scan contract.

## Measurement contract

- `part` file size is measured as physical line count (split on `\n`).
- A parent unit size is measured as:
  - parent file physical lines
  - plus physical lines for each file referenced by `part '...';`.
- This phase is **allowlist-driven**: the checker enforces shrink-only maxima
  for files and parent units listed in `tool/part_unit_size_allowlist.yaml`.

## Allowlist contract (shrink-only)

`tool/part_unit_size_allowlist.yaml` format:

```yaml
allowed_parent_units:
  - file: packages/colonizethis_logic/lib/src/setup/game_setup.dart
    max_lines: 2425

allowed_part_files:
  - file: packages/colonizethis_logic/lib/src/setup/game_setup_helpers.dart
    max_lines: 1086
```

- Allowlisted rows only suppress failures while measured lines stay
  `<= max_lines`.
- If a file grows above its allowlisted `max_lines`, the checker fails.
- New allowlist rows are not a default fix; prefer reducing file sizes and
  replacing `part` with importable files.

## Acceptance criteria

- Given an allowlisted file/unit whose measured lines are less than or equal to
  `max_lines`, when the checker runs, then that file/unit does not fail.
- Given an allowlisted file/unit whose measured lines exceed `max_lines`, when
  the checker runs, then the checker fails for that file/unit.
