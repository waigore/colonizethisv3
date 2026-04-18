# Locked province assigner

## Scope

Defines the **single** Old/New World province-painting path for current product setup: sequential growth with ranked legal neighbors, greedy **island / residual** feasibility, **depth-scoped tabu**, backtracking, and **capital-generation restart** when backtracks exceed a per-landmass limit. **Authority:** GitHub **#1830** / **#1822**; this file is the in-repo contract for `packages/colonizethis_logic/lib/src/setup/locked_province_assigner.dart` and related gates.

There is **no** post-pass GP Old World connectivity repair. For configs **other than** the locked full-init profile, each Old World landmass still paints GPs + any minors rostered on that landmass using **`assignTerritoriesByBfsGrowth`** (multi-source growth with the same seeds and fair targets) because strict sequential locked growth is only required for the **six minors on four continents / 60 OW** delivery (#1830). **New World** tribes normally use locked assigner on remainder components via `_assignFactionsOnRemainderAuto`; if multi-component greedy bin packing throws **`faction_component_bin_pack_failed`**, setup falls back to **`assignTerritoriesByBfsGrowth`** on the full NW province set (same fair targets and seed picking).

## Locked full-init profile

`GameSetupConfig.isLockedFullInitProfile` is **true** when all hold:

- Six Great Powers (`greatPowerCount == 6`), **six** minor nations, **four** continents, **ten** tribes.
- **60** Old World provinces, **30** New World provinces, `minProvincesPerMinor == 3`.

## Topology vs generator (current product)

The **design** locked full-init layout assumes four Old World P–P land components with province-count multiset **`[13, 13, 17, 17]`** and four New World components **`[6, 6, 9, 9]`**, with enough sea-bound provinces per continent for seeds (see GDD / #1830). **Current** procedural tile maps do not enforce those multisets at generation time; `runInitGame` performs **one** map generation per region (effective seed / NW offset per [game-setup-pipeline.md](game-setup-pipeline.md)). Painting then uses **`assignTerritoriesLockedOnLandmass`** only when `game_setup_ownership` detects the full six-minor / four-landmass / 60 OW layout; otherwise it uses **`assignTerritoriesByBfsGrowth`** on each landmass as documented above.

## Assigner search

**API:** `assignTerritoriesLockedOnLandmass` — parameters include landmass province set, P–P `neighbours`, **growth order** (faction ids), `targetPerFaction`, initial `seeds` (one seed province per faction in order), `backtrackLimitPerLandmass`, optional `LockedAssignerObservation` (backtrack / capital-restart counters for tests).

**Growth:** Active faction is the first in `growthOrder` under its target; only that faction may claim from the frontier of its already-owned tiles. Legal neighbors are ranked by higher P–P degree on the landmass, then fewer post-claim unassigned island components, then lexicographic province id.

**Island check:** Before committing a trial tile, `islandResidualsFeasibleGreedy` checks that sorted unfinished faction residuals can each fit on some unassigned island (greedy match on sizes sorted descending).

**Backtrack / tabu:** On failed subtree, undo placement, increment backtrack count, add `(capitalGeneration, depth, provinceId)` to tabu, remove tabu entries at same `capitalGeneration` with depth ≥ `depth + 1`. If backtracks exceed `backtrackLimitPerLandmass`, increment `capitalGeneration`, clear tabu, reset to seeds, and restart DFS (capital-generation restart), bounded (implementation cap).

If search fails: **`StateError`** from assigner; orchestration maps assigner failure to **`SetupTopologyDataException`** with code **`assigner_exhausted`** where specified in the pipeline.

## Tests

- **AC-14 / AC-15:** `packages/colonizethis_logic/test/locked_assigner_mechanics_test.dart` — small hand-crafted topology; AC-14 asserts ≥1 backtrack; AC-15 asserts deterministic owner map and bounded backtracks across duplicate runs.
- **AC-11 / AC-12:** `init_game_orchestrator_test.dart` — twenty fixed seeds for locked profile; determinism of OW ownership string for one seed.

## Shared helpers

`province_assignment.dart` provides **`computeFairTargets`**, **`pickSimpleSeeds`**, and **`assignTerritoriesByBfsGrowth`** (used for non–full-init OW landmasses and NW tribe fallback when locked remainder bin packing is infeasible).
