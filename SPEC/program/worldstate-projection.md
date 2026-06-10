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

This slice adds the **read-only projection component only**. Migrating the
~49 redundant-scan call sites (Phase 6b) and the `run_observer_game`
before/after profiling against the 15 s budget (Phase 6c) are tracked as
follow-up slices of the same umbrella and are **out of scope here**. Because
this slice adds no call to the projection from any existing resolution path,
it is behaviour-neutral by construction.

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
