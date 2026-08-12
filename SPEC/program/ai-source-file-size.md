# AI package — lib/src physical line size ratchet (repo lint)

**SPEC/program** — repository lint gate that keeps every hand-written Dart
file under `packages/colonizethis_ai/lib/src/` at or below **350 physical
lines**, with an optional shrink-only grandfather allowlist.

## Motivation

Phase 9 (#4079) concern-split planning modules that had grown past 500
physical lines. Phase 10 Slice B (#4104) concern-split the five near-cap
modules and ratcheted the ceiling to **450**. Phase 11 Slice A (#4239)
concern-split the eight remaining near-cap planning modules and ratcheted
the ceiling to **400**. Phase 13 Slice B (#4310) concern-split fourteen
near-cap modules (measured largest **316** physical) and ratcheted the
ceiling to **350** so additive planning work retains durable headroom.
This gate mirrors the save/data shrink-only allowlist pattern. AI is not
an extracted logic-domain package, so it is not listed under
`repo.domain_package_source_file_size` (still 500 elsewhere).

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

After #4079 Slice C / #4104 Slice B / #4239 Slice A / #4310 Slice B the
production allowlist is empty.

## Acceptance criteria

- Given every hand-written file under `packages/colonizethis_ai/lib/src/**` is
  at or below 350 physical lines and the grandfather allowlist is empty, when
  the System runs `runCheckAiSourceFileSize`, then the System exits `0`.
- Given a hand-written AI `lib/src` file with more than 350 physical lines and
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
- Given a generated AI `lib/src` file (for example `*.g.dart`) over 350
  physical lines, when the System runs `runCheckAiSourceFileSize`, then the
  System does not fail because of that generated file.
