# App package — no `part` / `part of` directives (repo lint)

**SPEC/program** — repository lint gate that forbids new Dart `part` / `part of`
file-splitting in `app/lib/**` outside a shrink-only grandfather allowlist while
wave-9 de-part slices land (Refs #4117).

## Motivation

`app/lib` was the last major Dart tree without a no-part CI gate. Wave 9 migrated
the six largest `part` clusters (`game_service`, `app_event_handler_scope`,
`trade_screen`, `province_sea_zone_detail_overlay`, `game_map_area`,
`region_map_component`) and dozens of residual part libraries to explicit-import
modules. The `part of` pattern couples fragments to a single library namespace
and makes helpers harder to test in isolation. This gate blocks new `part`
directives outside the grandfather while migration completes, matching peer
packages (`repo.orders_no_part_directives`, `repo.turn_no_part_directives`, etc.).

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_app_no_part_directives.dart` | Checker and CLI entrypoint |
| `tool/app_no_part_directives_grandfather.dart` | Shrink-only grandfather allowlist |
| `tool/ct_repo_lint_manifest.yaml` (`repo.app_no_part_directives`) | Rule registration |

## Scan scope

The checker scans all files returned by `collectRepoLintDomainDartFiles` and
evaluates only those whose repo-relative path begins with `app/lib/`. Generated
Dart and test files stay excluded by the shared repo-lint scan contract.

## Grandfather allowlist

Files listed in `tool/app_no_part_directives_grandfather.dart` may still contain
`part` / `part of` directives during migration. The allowlist is **shrink-only**:
stale entries (missing file or file no longer containing a part directive) fail
CI, and new part directives outside the allowlist fail CI.

As of wave-9 completion on PR #4135, the remaining grandfather entries are three
clusters held for open product issues (coordination boundaries in #4117):

| Cluster | Paths | Blocked by |
|---------|-------|------------|
| Terrain tileset | `app/lib/features/game/flame/tilesets/terrain_tileset*.dart` | #4088 (map theme) |
| CtDropdown | `app/lib/widgets/ct_dropdown*.dart` | #4062 (compact dropdown L&F) |
| CtResourceCell | `app/lib/widgets/ct_resource_cell*.dart` | #3999 (production Available alignment) |

Wave-9 de-part work does **not** edit these paths; each cluster shrinks from the
allowlist when its owning issue lands a behavior-preserving de-part slice.

## What is a `part` directive

A line is treated as a forbidden directive when, after trimming leading
whitespace and excluding blank and line-comment (`//`) lines, it matches the
Dart directive form `part '<file>';` or `part of '<file>';` (single- or
double-quoted). Identifiers such as `participants` or `partition` are not
directives and are out of scope.

## Acceptance criteria

- Given `app/lib/**` on `dev` where every `part` / `part of` directive is confined
  to the shrink-only grandfather allowlist in
  `tool/app_no_part_directives_grandfather.dart`, when
  `dart run tool/ct_repo_lint.dart` runs rule `repo.app_no_part_directives`,
  then the rule passes without violations and exits `0` (Refs #4117).
- Given an `app/lib/**` Dart file not on the grandfather allowlist that contains
  `part 'foo.dart';` or `part of 'foo.dart';`, when the checker runs, then the
  run fails listing each offending `path:line` and exits `1` (Refs #4117).
- Given a stale grandfather allowlist entry (missing file or file no longer
  containing a `part` directive), when the checker runs, then the run fails
  with a stale-entry message and exits `1` (Refs #4117).
- Given a line `final participants = <String>[];` in an in-scope file, when the
  checker runs, then the checker does not treat that line as a `part` directive
  and does not fail because of it.
