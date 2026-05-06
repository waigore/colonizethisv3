# Logic package: dual-region province field access (repo lint)

**SPEC/program** — Enforces GitHub [#2071](https://github.com/waigore/colonizethis/issues/2071) guidance: avoid scattered `RegionData.provinces` walks via `worldState.oldWorld` / `worldState.newWorld` in `colonizethis_logic` production sources.

## Policy

- **Canonical implementation:** `packages/colonizethis_logic/lib/src/world/province_lookup.dart` may use `oldWorld.provinces` and `newWorld.provinces` to implement `allProvinces`, `WorldState.allProvinces()`, region-scoped lookup, and related helpers.
- **Canonical region updates:** Prefer `WorldState.updateRegionById(...)` (for one-region updates) and `WorldState.mapBothRegions(...)` / `WorldState.mapBothRegionUnits(...)` (for two-region updates) over inline `if (regionId == oldWorld)` or `copyWith(oldWorld: ...)/copyWith(newWorld: ...)` branching in `lib/src/**`.
- **Elsewhere under** `packages/colonizethis_logic/lib/src/**`: prefer `allProvinces(world)` or the `WorldState` province lookup extension methods so dual-region iteration stays centralized.
- **Exceptions:** Old-World–only rules (e.g. military victory province counts, GP Old World redistribution) may still touch `oldWorld.provinces` directly when the GDD scope is explicitly Old World only. Such sites are counted toward the **global line budget** below so the total stays small and reviewable.

## CI rule

| Field | Value |
|-------|--------|
| `rule_id` | `repo.logic_dual_region_province_field_access` |
| Checker | `tool/check_logic_dual_region_province_field_access.dart` |
| Scan root | `packages/colonizethis_logic/lib/src/` (non-generated `.dart` only) |
| Excluded file | `packages/colonizethis_logic/lib/src/world/province_lookup.dart` |
| Budget | At most **10** physical source lines (total) outside the excluded file may contain the substring `oldWorld.provinces` or `newWorld.provinces`. |

Raising the budget requires a SPEC update in this file and a maintainer-reviewed PR (same PR as the checker constant change).

## Acceptance criteria

- Given the repository at `dev` with `packages/colonizethis_logic/lib/src/**` sources, when CI runs `dart run tool/ct_repo_lint.dart` including rule `repo.logic_dual_region_province_field_access`, then the checker counts matching lines outside `province_lookup.dart` and the run passes when the count is at most 10.
- Given a contributor adds an 11th matching line outside `province_lookup.dart` without updating the budget in this SPEC and the checker constant, when repo lint runs, then the run fails and lists each `path:line` hit.
