# Logic package: dual-region province field access (repo lint)

**SPEC/program** — Enforces GitHub [#2071](https://github.com/waigore/colonizethis/issues/2071) guidance: avoid scattered direct dual-region field access (`RegionData.provinces` / `RegionData.units`) via `worldState.oldWorld` / `worldState.newWorld` across the split logic-domain package production sources (`colonizethis_world`, `colonizethis_combat`, `colonizethis_economy`, `colonizethis_diplomacy`, `colonizethis_setup`, `colonizethis_orders`, `colonizethis_turn`, `colonizethis_ai_contracts`, plus the thin `colonizethis_logic` core; post-split scan roots, Refs #3290). The budget-0 migration sites recorded in **Audit history** moved into `colonizethis_setup` and `colonizethis_orders` when the monolith was split, so a world-only scan would no longer guard them.

## Policy

- **Canonical implementation:** `packages/colonizethis_world/lib/src/world/province_lookup.dart` may use `oldWorld.provinces` and `newWorld.provinces` to implement `allProvinces`, `WorldState.allProvinces()`, region-scoped lookup, and related helpers.
- **Canonical implementation (units):** `packages/colonizethis_world/lib/src/world/unit_lookup.dart` may use `oldWorld.units` and `newWorld.units` to implement `allUnits`, `WorldState.allUnits()`, region-scoped lookup, and related helpers.
- **Canonical region updates:** Prefer `WorldState.updateRegionById(...)` (for one-region updates) and `WorldState.mapBothRegions(...)` / `WorldState.mapBothRegionUnits(...)` (for two-region updates) over inline `if (regionId == oldWorld)` or `copyWith(oldWorld: ...)/copyWith(newWorld: ...)` branching in `lib/src/**`.
- **Region-scoped lookups:** Prefer `WorldState.provincesForRegion(regionId)` (canonical helper in `world/province_lookup.dart`) over hand-rolled `if (regionId == kRegionOldWorld) return ws.oldWorld.provinces` branching in `lib/src/**`.
- **Elsewhere under any scanned split domain package** `lib/src/**` (`colonizethis_world`, `colonizethis_combat`, `colonizethis_economy`, `colonizethis_diplomacy`, `colonizethis_setup`, `colonizethis_orders`, `colonizethis_turn`, `colonizethis_ai_contracts`, and the thin `colonizethis_logic` core): prefer `allProvinces(world)` / `allUnits(world)` or the related `WorldState` lookup extension methods so dual-region iteration stays centralized.
- **Exceptions:** Old-World–only rules (e.g. military victory province counts, GP Old World redistribution) may still touch `oldWorld.provinces` directly when the GDD scope is explicitly Old World only. Such sites are counted toward the **global line budget** below so the total stays small and reviewable.

## CI rule

| Field | Value |
|-------|--------|
| `rule_id` | `repo.logic_dual_region_province_field_access` |
| Checker | `tool/check_logic_dual_region_province_field_access.dart` |
| Scan roots | `packages/colonizethis_world/lib/src/`, `packages/colonizethis_combat/lib/src/`, `packages/colonizethis_economy/lib/src/`, `packages/colonizethis_diplomacy/lib/src/`, `packages/colonizethis_setup/lib/src/`, `packages/colonizethis_orders/lib/src/`, `packages/colonizethis_turn/lib/src/`, `packages/colonizethis_ai_contracts/lib/src/`, `packages/colonizethis_logic/lib/src/` (non-generated `.dart` only). A missing tree fails the check. |
| Excluded files | `packages/colonizethis_world/lib/src/world/province_lookup.dart`, `packages/colonizethis_world/lib/src/world/unit_lookup.dart` |
| Budget | At most **0** physical source lines (total) outside the excluded files may contain `oldWorld.provinces`, `newWorld.provinces`, `oldWorld.units`, `newWorld.units`, `copyWith(oldWorld: ...)`, `copyWith(newWorld: ...)`, or manual `if (regionId == kRegionOldWorld)` / `else if (regionId == kRegionOldWorld)` branching. |

Raising the budget requires a SPEC update in this file and a maintainer-reviewed PR (same PR as the checker constant change). Lowering the budget tracks the smallest value the latest audit (Refs #2836 AC 5) confirms is achievable; future cleanup of remaining sites should drop the budget further in the same PR.

## Audit history

- Refs #2836 AC 5: introduced `WorldState.provincesForRegion(regionId)` canonical helper, replaced 7 region-scoped lookup hits across `init_town_roads.dart`, `init_game_orchestrator.dart`, and `game_setup_helpers_naming.dart`, lowering the budget from **28 → 21**. Remaining 21 hits were split between Old-World-only canonical exceptions (military victory province counts, GP Old World redistribution) and locally mutable dual-region `List.from(region.units)`/`List.from(region.provinces)` builds that pre-stage in-place mutation before applying — those mutable-list patterns are not addressed by `provincesForRegion` / `mapBothRegions` shapes without restructuring the calling resolvers and are tracked as follow-up for a future audit pass.
- Refs #2836 AC 5 (this PR): migrated 4 Old-World-only `oldWorld.provinces` iteration sites (`diplomacy_relation_lookup.dart` § `oldWorldProvinceCountOwnedBy`, `gp_old_world_resource_redistribution.dart` § `_ownerByLocalProvinceId`, `gp_old_world_terrain_redistribution.dart` § `_ownerByLocalProvinceId`, `end_of_turn_resolver.dart` § `findMilitaryVictoryWinner`) to `worldState.provincesForRegion(kRegionOldWorld)`, lowering the budget from **21 → 17**.
- Refs #2836 AC 5 (this PR, follow-up): migrated the read-only dual-region civilian-unit iteration in `per_player_work_target_selection_cache.dart` § `_humanCivilianUnits` to the cached `WorldState.allUnitsById.values.where((u) => u.ownerId == playerId)` canonical view, removing 2 dual-region `units` field hits and lowering the budget from **17 → 15**. Remaining 15 hits are the locally mutable `List<Province>.from(...)` / `List<Unit>.from(...)` pre-stage patterns (setup bootstrap, army migration, movement, orders application, game-setup helper naming) plus one `if (regionId == kRegionOldWorld)` branch in `game_setup_helpers_bootstrap.dart` § initial visibility seeding — these still require resolver-level restructuring before they can drop further.
- Refs #2836 AC 5 (this PR, follow-up): introduced canonical mutable-list helpers `WorldStateProvinceLookup.mutableProvinceListsByRegion()` (in `province_lookup.dart`) and `WorldStateUnitLookup.mutableUnitListsByRegion()` (in `unit_lookup.dart`) that return fresh per-region copies of the underlying lists keyed by `kRegionOldWorld` / `kRegionNewWorld`. Migrated the remaining 15 mutable pre-stage sites to consume those helpers and threaded the bootstrap regiment / civilian spawn helpers through a single `Map<String, List<Unit>>` keyed by canonical region id (replacing the trailing `if (regionId == kRegionOldWorld)` / `else` branch in `game_setup_helpers_bootstrap.dart`). Sites updated: `setup/game_setup_helpers_bootstrap.dart` (5), `setup/game_setup_helpers_naming.dart` (4), `orders/orders_application.dart` (2), `world/army_migration.dart` (2), `world/movement.dart` (2). Lowered the budget from **15 → 0**. Any future direct `oldWorld.units`/`newWorld.units`/`oldWorld.provinces`/`newWorld.provinces` access outside the two canonical lookup files now requires either (a) extending the helpers above, or (b) raising the budget in this SPEC with maintainer review.

## Acceptance criteria

- Given the repository at `dev` with the split domain package sources (`colonizethis_world`, `colonizethis_combat`, `colonizethis_economy`, `colonizethis_diplomacy`, `colonizethis_setup`, `colonizethis_orders`, `colonizethis_turn`, `colonizethis_ai_contracts`, and the `colonizethis_logic` core) `lib/src/**`, when CI runs `dart run tool/ct_repo_lint.dart` including rule `repo.logic_dual_region_province_field_access`, then the checker counts matching lines across all scan roots outside `province_lookup.dart` and `unit_lookup.dart` and the run passes when the count is at most 0.
- Given a contributor adds a 1st matching line in any scanned split domain package (for example `colonizethis_setup` or `colonizethis_orders`) outside `province_lookup.dart` and `unit_lookup.dart` without updating the budget in this SPEC and the checker constant, when repo lint runs, then the run fails and lists each `path:line` hit.
- Given any one of the scanned split domain package `lib/src` trees is absent, when repo lint runs, then the checker fails fast and reports the missing tree.

## `allProvinces(` call-site sanction gate (Refs **#2278**)

Broad iteration via the top-level helper `allProvinces(WorldState)` or the `WorldState.allProvinces()` extension method must stay **reviewable**: every production call site under the scanned roots below (excluding generated Dart suffixes per the shared repo-lint contract) is **explicitly listed** in `tool/logic_all_provinces_sanctions.yaml`, unless it lives in the canonical file below. The `colonizethis_orders` mid-layer package (extracted from the `colonizethis_logic` monolith, Refs #3290) is in scope because the order-suggestion sources that legitimately walk all provinces moved there; they remain sanctioned through the same single allowlist.

| Field | Value |
|-------|--------|
| `rule_id` | `repo.logic_all_provinces_sanctioned_calls` |
| Checker | `tool/check_logic_all_provinces_sanctioned_calls.dart` |
| Allowlist | `tool/logic_all_provinces_sanctions.yaml` |
| Scan roots | `packages/colonizethis_logic/lib/src/` and `packages/colonizethis_orders/lib/src/` (non-generated `.dart` only) |
| Excluded file | `packages/colonizethis_world/lib/src/world/province_lookup.dart` (definitions of `allProvinces` / `WorldState.allProvinces()` and internal uses) |

**Sanction workflow:** Any new `allProvinces(` / `*.allProvinces(` line in a scan root must add a `sanctions:` entry in the same PR: `path` (repo-relative), `line` (1-based physical line), short `rationale`, and pointer to this SPEC section or the approving issue. The checker fails on **unsanctioned** hits and on **stale** sanctions (YAML entry whose file/line no longer contains `allProvinces(`). Package tests under `packages/colonizethis_logic/test/**` and `packages/colonizethis_orders/test/**` are not scanned.

### Acceptance criteria

- Given the repository at `dev` with `packages/colonizethis_logic/lib/src/**` and `packages/colonizethis_orders/lib/src/**` production sources, when CI runs `dart run tool/ct_repo_lint.dart` including rule `repo.logic_all_provinces_sanctioned_calls`, then every line under those roots that contains `allProvinces(` has a matching `path` + `line` entry in `tool/logic_all_provinces_sanctions.yaml` and the run passes.

- Given a contributor adds a new `allProvinces(` call site under either scan root without extending `tool/logic_all_provinces_sanctions.yaml`, when repo lint runs, then the run fails and prints each unsanctioned `path:line`.

- Given a contributor removes or moves a sanctioned call (including relocating a call site between the scanned `colonizethis_logic` and `colonizethis_orders` trees) without updating the YAML entry, when repo lint runs, then the run fails and prints each stale `path:line` from the allowlist.
