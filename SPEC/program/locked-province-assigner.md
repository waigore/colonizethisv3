# Locked province assigner

## Scope

Defines the **single** Old/New World province-painting path for current product setup: sequential growth with ranked legal neighbors, greedy **island / residual** feasibility, **depth-scoped tabu**, backtracking, and **capital-generation restart** when backtracks exceed a per-landmass limit. **Authority:** GitHub **#1830** / **#1822**; this file is the in-repo contract for `packages/colonizethis_logic/lib/src/setup/locked_province_assigner.dart` and related gates.

There is **no** post-pass GP Old World connectivity repair. For configs **other than** the locked full-init profile, each Old World landmass still paints GPs + any minors rostered on that landmass using **`assignTerritoriesByBfsGrowth`** (multi-source growth with the same seeds and fair targets) because strict sequential locked growth is only required for the **six minors on four continents / 60 OW** delivery (#1830). **New World** tribes normally use locked assigner on remainder components via `_assignFactionsOnRemainderAuto`; if multi-component greedy bin packing throws **`faction_component_bin_pack_failed`**, setup falls back to **`assignTerritoriesByBfsGrowth`** on the full NW province set (same fair targets and seed picking).

## Locked full-init profile

`GameSetupConfig.isLockedFullInitProfile` is **true** when all hold:

- Six Great Powers (`greatPowerCount == 6`), **six** minor nations, **four** continents, **ten** tribes.
- **60** Old World provinces, **30** New World provinces, `minProvincesPerMinor == 3`.

## Topology vs generator (current product)

The **design** locked full-init layout assumes four Old World P–P land components with province-count multiset **`[13, 13, 17, 17]`** and four New World components **`[6, 6, 9, 9]`**, with enough sea-bound provinces per continent for seeds (see GDD / #1830). **Current** procedural tile maps do not enforce those multisets at generation time; `runInitGame` performs **one** map generation per region (effective seed / NW offset per [game-setup-pipeline.md](game-setup-pipeline.md)). GitHub **#1830** also calls for generator-side regen until multisets hit; that work belongs in **`colonizethis_map`** (gated generation / rejection) and is **not** implemented in `runInitGame` until the map package exposes it—see pipeline doc. Painting then uses **`assignTerritoriesLockedOnLandmass`** only when `createGameFromGeneratedMaps` sees the locked full-init profile **and** OW topology matches the locked multiset **and** `lockedOldWorldRoleFeasibilityHolds`; otherwise it uses **`assignTerritoriesByBfsGrowth`** on each landmass as documented above.

## Assigner search

**API:** `assignTerritoriesLockedOnLandmass` — parameters include landmass province set, P–P `neighbours`, **growth order** (faction ids), `targetPerFaction`, optional **`mandatorySeedProvinceByFaction`** (faction id → province id that must be used when that faction is **seeded**), optional **`seedPickerRandom`** for shuffling non-mandatory seed candidates, **`backtrackLimitPerFaction`** (default **`kDefaultBacktrackLimitPerFaction` = 20**), and optional **`LockedAssignerObservation`** (backtrack / capital-restart counters for tests).

**Phased seeding:** Factions are grown **strictly in `growthOrder`**. When a faction becomes active (all earlier factions already at target), it receives a **seed** on the landmass: either its mandatory province (if provided) or a **non-mandatory** seed chosen from remaining unassigned provinces (sorted, then optionally shuffled). Earlier factions **do not** receive seed tiles until their turn; no multi-faction seed map is supplied up front.

**Growth:** Within a faction’s growth phase, only that faction may claim from the frontier of its already-owned tiles (same neighbor ranking as before: higher P–P degree, then fewer post-claim unassigned island components, then lexicographic province id).

**Island check:** Before committing a trial tile, `islandResidualsFeasibleGreedy` checks that sorted unfinished faction residuals can each fit on some unassigned island (greedy match on sizes sorted descending).

**Backtrack / tabu (per faction):** On failed subtree, undo placement, increment that faction’s per-search backtrack count, add `(capitalGeneration, depth, provinceId)` to tabu, remove tabu entries at same `capitalGeneration` with depth ≥ `depth + 1`. If backtracks for the **active** faction reach **`backtrackLimitPerFaction`**, search returns a budget-exhausted outcome: the outer loop **unwinds** the last **non-mandatory** province placed for the **previous** faction in `growthOrder` (and all later placements), clears tabu, and retries. If no such unwind exists (e.g. first faction), a **capital-generation restart** clears the landmass and retries (bounded; implementation cap).

If search still fails: **`StateError`** from assigner; orchestration maps assigner failure to **`SetupTopologyDataException`** with code **`assigner_exhausted`** where specified in the pipeline.

## Tests

- **AC-14 / AC-15:** `packages/colonizethis_logic/test/locked_assigner_mechanics_test.dart` — small hand-crafted topology; AC-14 asserts ≥1 backtrack; AC-15 asserts deterministic owner map and bounded backtracks across duplicate runs.
- **AC-11 / AC-12:** `init_game_orchestrator_test.dart` — twenty fixed seeds for locked profile; determinism of OW ownership string for one seed. When a run’s OW **and** NW topologies both match the locked multisets, tests assert **AC-1–AC-9** predicates (province quotas, P–P connectivity, sea-bound seeds, continent role counts, NW tribe layout); when multisets do not match procedural output, those ACs are out of scope for that run until generator gates land.

## Shared helpers

`province_assignment.dart` provides **`computeFairTargets`**, **`pickSimpleSeeds`**, and **`assignTerritoriesByBfsGrowth`** (used for non–full-init OW landmasses and NW tribe fallback when locked remainder bin packing is infeasible).
