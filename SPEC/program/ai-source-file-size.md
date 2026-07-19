# AI package — lib/src physical line size ratchet (repo lint)

**SPEC/program** — repository lint gate that keeps every hand-written Dart
file under `packages/colonizethis_ai/lib/src/` at or below **500 physical
lines**, with an optional shrink-only grandfather allowlist.

## Motivation

Phase 9 (#4079) concern-split planning modules that had grown past 500
physical lines (dispatch outcome builders, expand-peace arms, economy filter
expand resolvers, acquisition helpers, conquest stalled fallback, declare-war
bonus adjacency, observer stalled peace). Without a dedicated ratchet, those
siblings can silently re-merge. This gate mirrors the save/data shrink-only
allowlist pattern and uses the same **500 physical-line** ceiling as
`repo.domain_package_source_file_size` (AI is not an extracted logic-domain
package, so it is not listed there).

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_ai_source_file_size.dart` | Checker and CLI entrypoint |
| `tool/ct_repo_lint_manifest.yaml` (`repo.ai_source_file_size`) | Rule registration |

## Scan scope

Hand-written `.dart` files under `packages/colonizethis_ai/lib/src/**`.
Generated suffixes (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `*.gen.dart`)
are excluded. Test trees are out of scope (covered by separate soft suite-size
gates).

## Grandfather allowlist

`aiSourceFileSizeGrandfatheredForTests` may list repo-relative paths that
temporarily exceed the ceiling. The allowlist is **shrink-only**:

- Missing path → fail (stale entry; remove from allowlist).
- Path exists and is now ≤ ceiling → fail (stale entry; remove from allowlist).
- Path exists and is still over ceiling → skip size violation for that path.

After #4079 Slice C the production allowlist is empty.

## Acceptance criteria

- Given every hand-written file under `packages/colonizethis_ai/lib/src/**` is
  at or below 500 physical lines and the grandfather allowlist is empty, when
  the System runs `runCheckAiSourceFileSize`, then the System exits `0`.
- Given a hand-written AI `lib/src` file with more than 500 physical lines and
  an empty grandfather allowlist, when the System runs `runCheckAiSourceFileSize`,
  then the System exits non-zero and names that file.
- Given an over-cap AI `lib/src` file listed on the grandfather allowlist, when
  the System runs `runCheckAiSourceFileSize`, then the System does not treat
  that file as a size violation.
- Given a grandfather allowlist entry that names a file which does not exist,
  when the System runs `runCheckAiSourceFileSize`, then the System exits
  non-zero and reports a stale grandfather entry for that path.
- Given a grandfather allowlist entry that names a file now at or below the
  ceiling, when the System runs `runCheckAiSourceFileSize`, then the System
  exits non-zero and reports that the entry must be removed from the allowlist.
- Given a generated AI `lib/src` file (for example `*.g.dart`) over 500
  physical lines, when the System runs `runCheckAiSourceFileSize`, then the
  System does not fail because of that generated file.
