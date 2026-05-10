# Logic package: dual-region province field access (repo lint)

**SPEC/program** — Enforces GitHub [#2071](https://github.com/waigore/colonizethis/issues/2071) guidance: avoid scattered direct dual-region field access (`RegionData.provinces` / `RegionData.units`) via `worldState.oldWorld` / `worldState.newWorld` in `colonizethis_logic` production sources.

## Policy

- **Canonical implementation:** `packages/colonizethis_logic/lib/src/world/province_lookup.dart` may use `oldWorld.provinces` and `newWorld.provinces` to implement `allProvinces`, `WorldState.allProvinces()`, region-scoped lookup, and related helpers.
- **Canonical implementation (units):** `packages/colonizethis_logic/lib/src/world/unit_lookup.dart` may use `oldWorld.units` and `newWorld.units` to implement `allUnits`, `WorldState.allUnits()`, region-scoped lookup, and related helpers.
- **Canonical region updates:** Prefer `WorldState.updateRegionById(...)` (for one-region updates) and `WorldState.mapBothRegions(...)` / `WorldState.mapBothRegionUnits(...)` (for two-region updates) over inline `if (regionId == oldWorld)` or `copyWith(oldWorld: ...)/copyWith(newWorld: ...)` branching in `lib/src/**`.
- **Elsewhere under** `packages/colonizethis_logic/lib/src/**`: prefer `allProvinces(world)` / `allUnits(world)` or the related `WorldState` lookup extension methods so dual-region iteration stays centralized.
- **Exceptions:** Old-World–only rules (e.g. military victory province counts, GP Old World redistribution) may still touch `oldWorld.provinces` directly when the GDD scope is explicitly Old World only. Such sites are counted toward the **global line budget** below so the total stays small and reviewable.

## CI rule

| Field | Value |
|-------|--------|
| `rule_id` | `repo.logic_dual_region_province_field_access` |
| Checker | `tool/check_logic_dual_region_province_field_access.dart` |
| Scan root | `packages/colonizethis_logic/lib/src/` (non-generated `.dart` only) |
| Excluded files | `packages/colonizethis_logic/lib/src/world/province_lookup.dart`, `packages/colonizethis_logic/lib/src/world/unit_lookup.dart` |
| Budget | At most **28** physical source lines (total) outside the excluded files may contain `oldWorld.provinces`, `newWorld.provinces`, `oldWorld.units`, `newWorld.units`, `copyWith(oldWorld: ...)`, `copyWith(newWorld: ...)`, or manual `if (regionId == kRegionOldWorld)` / `else if (regionId == kRegionOldWorld)` branching. |

Raising the budget requires a SPEC update in this file and a maintainer-reviewed PR (same PR as the checker constant change).

## Acceptance criteria

- Given the repository at `dev` with `packages/colonizethis_logic/lib/src/**` sources, when CI runs `dart run tool/ct_repo_lint.dart` including rule `repo.logic_dual_region_province_field_access`, then the checker counts matching lines outside `province_lookup.dart` and `unit_lookup.dart` and the run passes when the count is at most 28.
- Given a contributor adds a 29th matching line outside `province_lookup.dart` and `unit_lookup.dart` without updating the budget in this SPEC and the checker constant, when repo lint runs, then the run fails and lists each `path:line` hit.

## `allProvinces(` call-site sanction gate (Refs **#2278**)

Broad iteration via the top-level helper `allProvinces(WorldState)` or the `WorldState.allProvinces()` extension method must stay **reviewable**: every production call site under `packages/colonizethis_logic/lib/src/**` (excluding generated Dart suffixes per the shared repo-lint contract) is **explicitly listed** in `tool/logic_all_provinces_sanctions.yaml`, unless it lives in the canonical file below.

| Field | Value |
|-------|--------|
| `rule_id` | `repo.logic_all_provinces_sanctioned_calls` |
| Checker | `tool/check_logic_all_provinces_sanctioned_calls.dart` |
| Allowlist | `tool/logic_all_provinces_sanctions.yaml` |
| Scan root | `packages/colonizethis_logic/lib/src/` (non-generated `.dart` only) |
| Excluded file | `packages/colonizethis_logic/lib/src/world/province_lookup.dart` (definitions of `allProvinces` / `WorldState.allProvinces()` and internal uses) |

**Sanction workflow:** Any new `allProvinces(` / `*.allProvinces(` line in the scan root must add a `sanctions:` entry in the same PR: `path` (repo-relative), `line` (1-based physical line), short `rationale`, and pointer to this SPEC section or the approving issue. The checker fails on **unsanctioned** hits and on **stale** sanctions (YAML entry whose file/line no longer contains `allProvinces(`). Package tests under `packages/colonizethis_logic/test/**` are not scanned.

### Acceptance criteria

- Given the repository at `dev` with `packages/colonizethis_logic/lib/src/**` production sources, when CI runs `dart run tool/ct_repo_lint.dart` including rule `repo.logic_all_provinces_sanctioned_calls`, then every line outside `province_lookup.dart` that contains `allProvinces(` has a matching `path` + `line` entry in `tool/logic_all_provinces_sanctions.yaml` and the run passes.

- Given a contributor adds a new `allProvinces(` call site under the scan root without extending `tool/logic_all_provinces_sanctions.yaml`, when repo lint runs, then the run fails and prints each unsanctioned `path:line`.

- Given a contributor removes or moves a sanctioned call without updating the YAML entry, when repo lint runs, then the run fails and prints each stale `path:line` from the allowlist.
