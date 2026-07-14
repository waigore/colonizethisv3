# World fog/connectivity — no parallel ownership map rebuild (repo lint)

**SPEC/program** — repository lint gate that forbids fog and connectivity
modules under `packages/colonizethis_world/lib/` from calling
`ownerByProvinceIdMap(...)` once `ProvinceOwnerCache` is the ownership
source of truth (Refs #3978). Companion to
`SPEC/program/worldstate-projection.md`.

## Motivation

Fog spy/decay and connectivity faction caches previously rebuilt dual-region
ownership maps via `ownerByProvinceIdMap` / `traverseProvinces`. Wave 4 routes
those paths through `ProvinceOwnerCache.of`. This gate keeps fog/connectivity
lib files from reintroducing the thin map helper on those hot paths.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_world_fog_connectivity_no_owner_map_rebuild.dart` | Checker and CLI |
| `tool/ct_repo_lint_manifest.yaml` (`repo.world_fog_connectivity_no_owner_map_rebuild`) | Rule registration |

## Scan scope

In-scope files under `packages/colonizethis_world/lib/src/world/` whose
basename starts with `fog_` or `connectivity_`.
`province_traversal.dart` (definition of the thin wrapper) and packages outside
world lib stay out of scope.

## Acceptance criteria

- Given an in-scope fog or connectivity lib file that contains a call
  `ownerByProvinceIdMap(...)`, when the checker runs, then the checker fails
  and the violation text names that file's repo-relative path.
- Given an in-scope fog or connectivity lib file that uses
  `ProvinceOwnerCache.of` and does not call `ownerByProvinceIdMap`, when the
  checker runs, then the checker does not fail for that file.
- Given `ownerByProvinceIdMap` defined or called only in
  `province_traversal.dart` or in a non-fog/connectivity world lib file, when
  the checker runs, then the checker does not fail because of that file.
