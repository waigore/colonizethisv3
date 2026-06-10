# WorldState projection / cache layer

**SPEC/program** — Read-only projection layer over `WorldState` for hot
turn-resolution paths. Phase 6 of the `colonizethis_logic` barrel-refactor
umbrella (Refs #3393). Companion to `SPEC/program/turn-resolution.md`,
`SPEC/program/logic-package-barrel-contracts.md`, and the
`colonizethis-turn-resolution-budget.mdc` rule.

## Motivation

Domain packages repeatedly recompute the same deterministic
ownership groupings by scanning every province
(`worldState.provincesForRegion(...).where((p) => p.ownerId == playerId)`,
`allProvinces().where(...)`). These uncapped global scans inside per-player /
per-target loops are a recognised next-turn-budget risk
(`colonizethis-turn-resolution-budget.mdc` § "Duplicate global scans"). A
lightweight read-only projection that memoises these groupings once per
turn-resolution pass removes the redundant scans without changing any
turn-resolution semantics.

## Scope (Phase 6a — projection component)

Phase 6a adds the **read-only projection component only**. The
`run_observer_game` before/after profiling against the 15 s budget (Phase 6c)
is tracked as a follow-up slice of the same umbrella and is **out of scope
here**. Because Phase 6a adds no call to the projection from any existing
resolution path, it is behaviour-neutral by construction.

## Scope (Phase 6b — first call-site migrations)

Phase 6b begins migrating redundant full-province owner scans to
`ProvinceOwnerCache`. Each migrated site previously scanned **every** province
(`allProvinces(world).where((p) => p.ownerId == playerId)`) to collect the
caller's owned provinces; each now reads the same set from
`ProvinceOwnerCache.of(world).provincesOwnedBy(playerId)`.

Migrations in this slice are **behaviour-preserving**: every migrated site
collects results into a `Set` (membership-only; iteration order irrelevant),
and `provincesOwnedBy(playerId)` returns exactly the provinces whose
`ownerId == playerId` (a non-null owner). The migrated sites are the
owned-province fallback branches in `colonizethis_orders`:

- `armyMoveCandidateDestinationProvinceIds` (`order_suggestion_army_move.dart`)
  — fallback when no `playerOwnedFullProvinceIds` set is supplied.
- `armyMovePickerDestinations` (`order_suggestion_army_move.dart`) — fallback
  when neither `playerOwnedFullProvinceIds` nor a resolution snapshot is
  supplied.
- `rawCandidateTilesForWorkTarget` (`order_suggestion_work_tile_prefilter.dart`)
  — fallback when no `playerOwnedProvinceIds` set is supplied.

A second Phase 6b slice migrates the remaining **full-world** owner scans in
`colonizethis_diplomacy` onto the same projection:

- `provinceCountOwnedBy` (`diplomacy_relation_lookup.dart`) — previously backed
  by a **separate** per-`Game` `ExpandoIndex` that scanned every province to
  build an owner→count map. It now reads
  `ProvinceOwnerCache.of(game.worldState).countOwnedBy(factionId)`, removing the
  duplicate projection. Both count only provinces with a non-null
  `ownerId == factionId`, so every consumer (`greatPowerPowerScore`,
  `joinEmpireCostForMinorOrTribe`) is behaviour-preserved.
- `_sortedFullProvinceIdsOwnedBy` (`faction_absorption_engine.dart`) — the
  Join-Empire absorption province-transfer seed. It now derives ids from
  `ProvinceOwnerCache.of(game.worldState).provincesOwnedBy(ownerId)`; the result
  is sorted, so the projection's iteration order does not affect the output.

Only full-region scans are migrated; per-region scans
(`provincesForRegion(...)`) are **not** migrated to this whole-world projection
in this slice. Migrating the remaining call sites and the Phase 6c profiling
remain follow-up slices of the umbrella.

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

- `String? ownerOf(String fullProvinceId)` — owner id of the province, or
  `null` when the province is unowned or absent.
- `bool isOwnedBy(String fullProvinceId, String ownerId)`.
- `List<Province> provincesOwnedBy(String ownerId)` — unmodifiable; empty when
  the owner controls no province.
- `int countOwnedBy(String ownerId)`.
- `List<String> ownerIds` — unmodifiable; distinct non-null owners,
  first-seen order.
- `List<Province> unownedProvinces` — unmodifiable; provinces with
  `ownerId == null`, iteration order.

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
