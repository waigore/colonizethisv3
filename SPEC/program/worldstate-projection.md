# WorldState projection / cache layer

**SPEC/program** — Read-only projection layer over `WorldState` for hot
turn-resolution paths. Phase 6 of the `colonizethis_logic` barrel-refactor
umbrella (Refs #3393). Companion to `SPEC/program/turn-resolution.md`,
`SPEC/program/logic-package-barrel-contracts.md`, and the
`colonizethis-turn-resolution-budget.mdc` rule.

## Motivation

Domain packages repeatedly recompute the same deterministic ownership
groupings by scanning every province
(`provincesForRegion(...).where((p) => p.ownerId == playerId)`,
`allProvinces().where(...)`). These uncapped global scans inside per-player /
per-target loops are a recognised next-turn-budget risk
(`colonizethis-turn-resolution-budget.mdc` § "Duplicate global scans"). A
read-only projection that memoises these groupings once per turn-resolution
pass removes the redundant scans without changing turn-resolution semantics.

## Scope (Phase 6a — projection component)

Phase 6a adds the **read-only projection component only**; the
`run_observer_game` 15 s-budget profiling (Phase 6c) is a follow-up slice.
Phase 6a is behaviour-neutral by construction (no resolution path calls it).

## Scope (Phase 6b — call-site migrations)

Phase 6b migrates redundant owner scans to `ProvinceOwnerCache`. Every
migration is **behaviour-preserving**: the projection accessors return exactly
the provinces whose non-null `ownerId == id` (a `null` owner never equals an
id), and each migrated site uses the result for membership/count only
(iteration order irrelevant or re-sorted). AI sites reach the projection
through the narrow contract — `package:colonizethis_logic/ai_api.dart`
re-exports `ProvinceOwnerCache`, `kRegionOldWorld`, and `kRegionNewWorld` at the
`colonizethis_world` barrel level — preserving the one-way decoupling boundary
(`colonizethis-logic-ai-decoupling.mdc`).

Per-region accessors group by the region a province was visited in
(`kRegionOldWorld` first, then `kRegionNewWorld`), exactly matching the migrated
`world.oldWorld.provinces` / `world.newWorld.provinces` lists.

- **Slice 1 — `colonizethis_orders` full-world fallbacks** (`allProvinces(world)
  .where((p) => p.ownerId == playerId)` → `provincesOwnedBy`):
  `armyMoveCandidateDestinationProvinceIds`, `armyMovePickerDestinations`,
  `rawCandidateTilesForWorkTarget`.
- **Slice 2 — `colonizethis_diplomacy`:** `provinceCountOwnedBy` →
  `countOwnedBy(factionId)` (drops a duplicate per-`Game` `ExpandoIndex`);
  `_sortedFullProvinceIdsOwnedBy` seeds its re-sorted ids from
  `provincesOwnedBy(ownerId)`.
- **Slice 3 — `colonizethis_ai` `computeWarDesireScore`** (per nation × target
  faction): `_resourceNeedBonus` and `_invasionCapacityAdjustment` read
  `provincesOwnedBy(factionId)`.
- **Slice 4 — `colonizethis_ai` per-region scans:** old-world `.any` checks
  (`_minorOwnsOldWorldProvinces`, `minorsHoldOldWorldProvinces`,
  `hasUninvadedOldWorldMinor`, declare-war-target gathers) →
  `ownsAnyInRegion(minorId, kRegionOldWorld)`; `_newWorldProvinceCountOwnedBy`
  (`treasury_lock_recovery.dart`) →
  `countOwnedByInRegion(playerId, kRegionNewWorld)`.
- **Slice 5 — shared per-region count helpers:** `oldWorldProvinceCountOwnedBy`
  (`province_lookup.dart`) → `countOwnedByInRegion(factionId, kRegionOldWorld)`
  — the single definition called per faction by `war_resolver`, expand/colonial
  planners, the treasury planner, and feedstock gates, so one migration removes
  the Old-World rescan from every caller; `_newWorldProvinceCountOwnedBy`
  (`feedstock_extraction_targets.dart`) →
  `countOwnedByInRegion(playerId, kRegionNewWorld)`. Counts are order-insensitive.
- **Slice 6 — full-world owner map:** `getProvinceOwnerMap`
  (`order_suggestion_helpers.dart`) builds its full-province-id→owner map from
  the memoised cache by iterating `ownerIds` and each owner's
  `provincesOwnedBy(ownerId)`. The union is exactly the provinces with a
  non-null, non-empty `ownerId` (matching the prior `isNotEmpty` filter); ids
  are unique so the map is order-independent. The matching
  `tool/logic_all_provinces_sanctions.yaml` entry is removed.

- **Slice 7 — `colonizethis_ai` `anyMinorOwnsOldWorld`:** the nested
  `game.worldState.oldWorld.provinces.any((p) => p.ownerId != null &&
  p.ownerId!.isNotEmpty && game.minorNations.any((m) => m.id == p.ownerId))`
  predicate in `computeDiplomaticCandidateScores`
  (`diplomatic_candidate_scoring.dart`) — an O(provinces × minors) nested scan
  recomputed once per nation per diplomacy-scoring pass — becomes
  `game.minorNations.any((m) => _minorOwnsOldWorldProvinces(game, m.id))`, where
  the existing helper reads `ProvinceOwnerCache.ownsAnyInRegion(minorId,
  kRegionOldWorld)`. Behaviour-preserving: "some old-world province is owned by
  a minor" is logically equal to "some minor owns an old-world province"; minor
  ids are non-empty so an empty/`null` owner never matches.

- **Slice 8 — `colonizethis_ai` EXPAND-phase peace deciders:** the three
  remaining `O(provinces × minors)` nested old-world owner scans
  (`game.worldState.oldWorld.provinces.any((p) => p.ownerId is a minor id)`),
  recomputed per EXPAND-phase peace decider in
  `expand_phase_planner_peer_peace.dart` (`belowQuotaPeerGpPeaceTargets`),
  `expand_phase_planner_peace_targets.dart` (`canPivotFromSoleGpWarAfterPeace`),
  and `expand_phase_planner_gp_blocker_peace.dart`
  (`stalledStrongerGpBlockerPeaceTarget`), become a single shared
  `_anyMinorOwnsOldWorldProvince(game)` helper that reads
  `game.minorNations.any((m) => ProvinceOwnerCache.of(game.worldState)
  .ownsAnyInRegion(m.id, kRegionOldWorld))` — the same migration applied to
  `diplomatic_candidate_scoring.dart` in slice 7. Behaviour-preserving: "some
  old-world province is owned by a minor" is logically equal to "some minor owns
  an old-world province"; minor ids are non-empty so an empty/`null` owner never
  matches.

Phase 6c profiling and the remaining call sites stay follow-up slices.

### Phase 6b acceptance criteria

- **Given** a `Game` whose player `p1` owns one old-world and one new-world
  province and supplies no `playerOwnedFullProvinceIds`, **when**
  `armyMoveCandidateDestinationProvinceIds` runs, **then** its returned
  destinations include both owned full province ids (minus the army's current
  province), identical to the pre-migration `allProvinces` scan.
- **Given** the same `Game` and a non-home army of `p1`, **when**
  `armyMovePickerDestinations` runs with no `playerOwnedFullProvinceIds` and no
  `resolution`, **then** the owned-province seed set equals the set produced by
  the pre-migration `allProvinces` owner scan.
- **Given** the same `Game` and no `playerOwnedProvinceIds`, **when**
  `rawCandidateTilesForWorkTarget` runs, **then** the owned-province ids it
  derives equal `{p.id for p in ProvinceOwnerCache.of(world).provincesOwnedBy('p1')}`.
- **Given** a `Game` whose faction `m1` owns one old-world province and one
  new-world province and whose faction `m2` owns none, **when**
  `provinceCountOwnedBy(game, 'm1')` and `provinceCountOwnedBy(game, 'm2')` are
  read, **then** they return `2` and `0`, equal to
  `ProvinceOwnerCache.of(game.worldState).countOwnedBy(...)` for the same ids.
- **Given** a `Game` whose absorbed faction `m1` owns provinces
  `oldWorld|b` and `newWorld|a` (and other factions own the rest), **when**
  the absorption seed `_sortedFullProvinceIdsOwnedBy(game, 'm1')` is computed,
  **then** it returns `['newWorld|a', 'oldWorld|b']` (ascending id order),
  equal to the pre-migration `allProvinces` owner scan.
- **Given** a `Game` with attacker great power `gp1` and a minor target `m1`
  that owns one or more provinces hosting resource tiles, **when**
  `computeWarDesireScore(game, nationId: 'gp1', targetFactionId: 'm1', ...)` is
  evaluated, **then** the returned score equals the score produced when the
  underlying owned-province collection is taken from
  `ProvinceOwnerCache.of(game.worldState).provincesOwnedBy('m1')` rather than an
  `allProvinces` owner scan (behaviour-preserving migration).
- **Given** the same `Game`, **when** the attacker's and target's owned-province
  region-id sets are derived inside `_invasionCapacityAdjustment`, **then** each
  set equals `{p.regionId for p in ProvinceOwnerCache.of(game.worldState).provincesOwnedBy(factionId)}`
  for the corresponding faction id, equal to the pre-migration `allProvinces`
  owner scan.
- **Given** a `Game` whose minor `m1` owns one old-world province and minor
  `m2` owns only new-world provinces, **when** `_minorOwnsOldWorldProvinces`
  (and the other slice-4 old-world `.any` sites) are evaluated, **then** they
  return `true` for `m1` and `false` for `m2`, equal to
  `ProvinceOwnerCache.of(game.worldState).ownsAnyInRegion(id, kRegionOldWorld)`
  and to the pre-migration `world.oldWorld.provinces.any` scan.
- **Given** a `Game` whose player `p1` owns two new-world provinces and player
  `p2` owns none, **when** `_newWorldProvinceCountOwnedBy` runs with no matching
  snapshot, **then** it returns `2` for `p1` and `0` for `p2`, equal to
  `ProvinceOwnerCache.of(game.worldState).countOwnedByInRegion(id, kRegionNewWorld)`
  and to the pre-migration `world.newWorld.provinces` owner count.
- **Given** a `Game` whose faction `gp1` owns two old-world provinces and
  faction `gp2` owns none (slice 5), **when** `oldWorldProvinceCountOwnedBy`
  runs for each, **then** it returns `2` for `gp1` and `0` for `gp2`, equal to
  `ProvinceOwnerCache.of(game.worldState).countOwnedByInRegion(id, kRegionOldWorld)`
  and to the pre-migration `world.oldWorld.provinces` owner count.
- **Given** a `Game` whose minor `m1` owns one old-world province, minor `m2`
  owns only a new-world province, and a non-minor `gp1` owns another old-world
  province (slice 7), **when** the `anyMinorOwnsOldWorld` predicate
  `game.minorNations.any((m) => ProvinceOwnerCache.of(game.worldState)
  .ownsAnyInRegion(m.id, kRegionOldWorld))` is evaluated, **then** it returns
  `true`, equal to the pre-migration nested
  `oldWorld.provinces.any((p) => p.ownerId is a minor id)` scan.
- **Given** a `Game` whose only old-world owner is a non-minor `gp1` and whose
  minors `m1`/`m2` own only new-world provinces (or an empty-string owner sits
  in the old world) (slice 7), **when** the `anyMinorOwnsOldWorld` predicate is
  evaluated, **then** it returns `false`, equal to the pre-migration nested
  `oldWorld.provinces.any` scan.
- **Given** a `Game` whose minor `m1` owns one old-world province, minor `m2`
  owns only a new-world province, and a non-minor `gp1` owns another old-world
  province (slice 8), **when** the shared
  `_anyMinorOwnsOldWorldProvince(game)` helper used by
  `belowQuotaPeerGpPeaceTargets`, `canPivotFromSoleGpWarAfterPeace`, and
  `stalledStrongerGpBlockerPeaceTarget` is evaluated, **then** it returns
  `true`, equal to `game.minorNations.any((m) => ProvinceOwnerCache
  .of(game.worldState).ownsAnyInRegion(m.id, kRegionOldWorld))` and to the
  pre-migration nested `oldWorld.provinces.any` scan.
- **Given** a `Game` whose only old-world owner is a non-minor `gp1` and whose
  minors `m1`/`m2` own only new-world provinces (slice 8), **when**
  `_anyMinorOwnsOldWorldProvince(game)` is evaluated, **then** it returns
  `false`, equal to the pre-migration nested `oldWorld.provinces.any` scan.
- **Given** a `Game` whose faction `gp1` owns one old-world province and one
  new-world province, faction `gp2` owns one old-world province, and one
  province is unowned (slice 6), **when** `getProvinceOwnerMap(game)` is read,
  **then** it returns exactly `{ <gp1 old id>: 'gp1', <gp1 new id>: 'gp1',
  <gp2 old id>: 'gp2' }`, equal to
  `{ p.id: ownerId for ownerId in ProvinceOwnerCache.of(game.worldState).ownerIds
  for p in provincesOwnedBy(ownerId) }`, and excludes the unowned province.

## `ProvinceOwnerCache`

`ProvinceOwnerCache` is an immutable, read-only projection of province
ownership built from a single `WorldState`. It lives in `colonizethis_world`
(`lib/src/world/province_owner_cache.dart`) and is published through the
`colonizethis_world` barrel.

Ownership is read from `Province.ownerId` (`String?`; `null` = unowned). The
projection never mutates `WorldState` and holds no reference to mutable
collections it did not build.

### Determinism contract

- Province iteration order is **old-world provinces first, then new-world
  provinces**, each in `RegionData.provinces` list order — matching
  `WorldStateProvinceLookup.allProvinces()`.
- Per-owner province lists preserve that iteration order.
- Per-region groupings (`provincesOwnedByInRegion`) are keyed by the region a
  province was visited in (`kRegionOldWorld` / `kRegionNewWorld`) and preserve
  that region's `RegionData.provinces` list order.
- `ownerIds` is the set of distinct non-null owner ids in **first-seen**
  iteration order.
- For a fixed `WorldState`, every accessor returns the same ordering and the
  same values on every call.

### Memoisation

`ProvinceOwnerCache.of(WorldState)` returns a cache memoised per `WorldState`
**identity** via the shared `ExpandoIndex` pattern (the same mechanism as the
existing per-`WorldState` province-by-id index). The cache is built once on
first access and reused for the lifetime of that `WorldState` instance; a new
`WorldState` from `copyWith` gets a fresh cache. `ProvinceOwnerCache.build`
constructs an unmemoised instance for direct/test use.

### Public surface

Accessors (full doc comments live on the class): `ownerOf(fullProvinceId)`,
`isOwnedBy(fullProvinceId, ownerId)`, `provincesOwnedBy(ownerId)`,
`countOwnedBy(ownerId)`, `provincesOwnedByInRegion(ownerId, regionId)`,
`ownsAnyInRegion(ownerId, regionId)`, `countOwnedByInRegion(ownerId, regionId)`.
List accessors return unmodifiable, possibly empty views. `ownerIds` lists
distinct non-null owners in first-seen order; `unownedProvinces` lists provinces
with `ownerId == null` in iteration order.

## Acceptance criteria

- **Given** a `WorldState` whose old world has provinces `A` (owner `p1`) and
  `B` (unowned) and whose new world has province `C` (owner `p1`), **when**
  `ProvinceOwnerCache.build(world).provincesOwnedBy('p1')` is read, **then**
  it returns exactly `[A, C]` in that order.
- **Given** the same `WorldState`, **when** `ownerOf('<id of A>')` and
  `ownerOf('<id of B>')` are read, **then** they return `'p1'` and `null`
  respectively.
- **Given** the same `WorldState`, **when** `ownerOf` is called with a
  province id not present in either region, **then** it returns `null`.
- **Given** the same `WorldState`, **when** `countOwnedBy('p1')` and
  `countOwnedBy('p2')` are read, **then** they return `2` and `0`.
- **Given** the same `WorldState`, **when**
  `provincesOwnedByInRegion('p1', kRegionOldWorld)` and
  `provincesOwnedByInRegion('p1', kRegionNewWorld)` are read, **then** they
  return exactly `[A]` and `[C]` respectively.
- **Given** the same `WorldState`, **when** `ownsAnyInRegion('p1', kRegionOldWorld)`,
  `ownsAnyInRegion('p1', kRegionNewWorld)`, and `ownsAnyInRegion('p2', kRegionOldWorld)`
  are read, **then** they return `true`, `true`, and `false`.
- **Given** the same `WorldState`, **when**
  `countOwnedByInRegion('p1', kRegionOldWorld)` and
  `countOwnedByInRegion('p1', kRegionNewWorld)` are read, **then** they return
  `1` and `1`.
- **Given** the list returned by `provincesOwnedByInRegion('p1', kRegionOldWorld)`,
  **when** a caller attempts to add an element, **then** the operation throws
  `UnsupportedError` (the projection is read-only).
- **Given** the same `WorldState`, **when** `ownerIds` is read, **then** it
  returns exactly `['p1']` (distinct, first-seen order) and excludes the
  unowned province.
- **Given** the same `WorldState`, **when** `unownedProvinces` is read,
  **then** it returns exactly `[B]`.
- **Given** the same `WorldState`, **when** `provincesOwnedBy('p1')` is read
  twice, **then** both calls return equal ordering and values (deterministic
  for fixed input).
- **Given** the list returned by `provincesOwnedBy('p1')`, **when** a caller
  attempts to add or remove an element, **then** the operation throws
  `UnsupportedError` (the projection is read-only).
- **Given** a single `WorldState` instance `w`, **when** `ProvinceOwnerCache.of(w)`
  is called twice, **then** both calls return the **identical** cache instance
  (memoised per `WorldState` identity).
- **Given** a `WorldState` `w` and `w2 = w.copyWith(...)`, **when**
  `ProvinceOwnerCache.of(w)` and `ProvinceOwnerCache.of(w2)` are called,
  **then** they return distinct cache instances.
