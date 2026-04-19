# Locked province assigner

## Scope

Defines the **single** Old/New World province-painting path for current product setup: **phased** sequential growth with ranked legal neighbors, **phased feasibility pruning** (not the legacy parallel greedy island/residual pack on every future faction while only one faction grows), **depth-scoped tabu**, per-faction backtracking with **cross-faction unwind**, and **capital-generation restart** when search is stuck. **Authority:** GitHub **#1830** / **#1822** / **#1834**; this file is the in-repo contract for `packages/colonizethis_logic/lib/src/setup/locked_province_assigner.dart` and **colonizethis_data** topology gate helpers used before choosing locked vs BFS OW painting.

There is **no** post-pass GP Old World connectivity repair. For configs **other than** the locked full-init profile, each Old World landmass still paints GPs + any minors rostered on that landmass using **`assignTerritoriesByBfsGrowth`** (multi-source growth with the same seeds and fair targets) because strict sequential locked growth is only required for the **six minors on four continents / 60 OW** delivery (#1830). **New World** tribes use **`assignTerritoriesLockedOnLandmass`** on remainder components via `_assignFactionsOnRemainderAuto`; multi-component cases use **bounded DFS** component packing (`_tryPackFactionsOntoPpComponentsDfs`). **`faction_component_bin_pack_failed`** / **`assignment_remainder_not_connected`** propagate to callers; **`runInitGame`** may **regenerate tile maps** and retry the pipeline per [game-setup-pipeline.md](game-setup-pipeline.md)—there is **no** whole-map NW **`assignTerritoriesByBfsGrowth`** fallback inside `createGameFromGeneratedMaps` for locked failures.

**Exported helper:** **`islandResidualsFeasibleGreedy`** remains for unit tests and simple necessary checks; **search pruning** in production uses **`_phasedGrowthFeasibilityHolds`** (active faction reachability to full target, mandatory-seed component lower bounds for not-yet-started factions, necessary unassigned tile count).

## Locked full-init profile

`GameSetupConfig.isLockedFullInitProfile` is **true** when all hold:

- Six Great Powers (`greatPowerCount == 6`), **six** minor nations, **four** continents, **ten** tribes.
- **60** Old World provinces, **30** New World provinces, `minProvincesPerMinor == 3`.

## Topology vs generator (current product)

The **design** locked full-init layout assumes four Old World P–P land components with province-count multiset **`[13, 13, 17, 17]`** and four New World components **`[6, 6, 9, 9]`**, with enough sea-bound provinces per continent for seeds (see GDD / #1830). **Default `runInitGame` path:** **`generateLockedFullInitTileMapPair`** in **`colonizethis_map`** regen-until-pass with **`continentProvinceSizes`** hints plus **colonizethis_data** partition and role-feasibility gates (see [game-setup-pipeline.md](game-setup-pipeline.md) step 3). **`createGameFromGeneratedMaps`** then uses **`assignTerritoriesLockedOnLandmass`** for OW only when **`isLockedFullInitProfile`**, **`oldWorldPartitionMatchesLockedProfile`**, and **`lockedOldWorldRoleFeasibilityHolds`** all hold; otherwise it uses **`assignTerritoriesByBfsGrowth`** on each landmass as documented above (typical for non-default maps or injected test generators).

## Assigner search

**API:** `assignTerritoriesLockedOnLandmass` — parameters include landmass province set, P–P `neighbours`, **growth order** (faction ids), `targetPerFaction`, optional **`mandatorySeedProvinceByFaction`** (faction id → province id that must be used when that faction is **seeded**), optional **`seedPickerRandom`** for shuffling non-mandatory seed candidates, **`backtrackLimitPerFaction`** (default **`kDefaultBacktrackLimitPerFaction` = 20**), and optional **`LockedAssignerObservation`** (backtrack / capital-restart counters for tests).

**Phased seeding:** Factions are grown **strictly in `growthOrder`**. When a faction becomes active (all earlier factions already at target), it receives a **seed** on the landmass: either its mandatory province (if provided) or a **non-mandatory** seed chosen from remaining unassigned provinces (sorted, then optionally shuffled). Earlier factions **do not** receive seed tiles until their turn; no multi-faction seed map is supplied up front.

**Growth:** Within a faction’s growth phase, only that faction may claim from the frontier of its already-owned tiles (neighbor ranking: higher P–P degree, then fewer post-claim unassigned island components, then lexicographic province id).

**Phased feasibility (trial prune):** Before recursing after a trial assign, **`_phasedGrowthFeasibilityHolds`** requires: (1) the **active** faction can still reach enough unassigned+P–P territory to meet its **full** target; (2) every **not-yet-started** faction with a **mandatory** seed still has a P–P component around that seed large enough for its target; (3) **unassigned** tile count ≥ sum of all positive residuals. This replaces the older **`islandResidualsFeasibleGreedy`**-only prune, which over-pruned when only one faction was growing.

**Backtrack / tabu (per faction):** On failed subtree, undo placement, increment that faction’s local backtrack count, add `(capitalGeneration, depth, provinceId)` to tabu, remove tabu entries at same `capitalGeneration` with depth ≥ `depth + 1`. **Per-faction backtrack counters reset** at each outer DFS entry and after successful **cross-faction unwind**. If backtracks for the **active** faction reach **`backtrackLimitPerFaction`** (default **`kDefaultBacktrackLimitPerFaction` = 20**), search returns budget-exhausted: the outer loop **unwinds** the last **non-mandatory** province placed for the **previous** faction in `growthOrder` (and all later placements), clears tabu, and retries. If no such unwind exists (e.g. first faction), a **capital-generation restart** clears the landmass, bumps `capitalGeneration`, and retries; **ranked try-order rotates** with `capitalGeneration` so restarts are not identical when RNG is unused. **`capitalGeneration`** is capped at **512**; beyond that the assigner throws **`StateError`**. **`kMaxBacktracksPerLandmassBeforeCapitalRestart`** is a deprecated alias for the same per-faction default (**20**), not a separate 100-backtrack landmass counter.

If search still fails: **`StateError`** from assigner; orchestration maps assigner failure to **`SetupTopologyDataException`** with code **`assigner_exhausted`** where specified in the pipeline.

## Tests

- **AC-14 / AC-15:** `packages/colonizethis_logic/test/locked_assigner_mechanics_test.dart` — five-province hand-crafted topology (`a–m–{d,g}`, `d–w`) with mandatory seed `a`, targets `A:3` / `B:2`, ranked neighbor choice at depth **2** (stack length after `a` and `m`) so the first tried expansion is infeasible for `B` and the assigner performs **exactly one** undo (`LockedAssignerObservation.backtracks == 1`). **AC-14** asserts that map plus `backtracks >= 1` (golden `1`). **AC-15** runs the same call twice and asserts identical owner maps, identical `backtracks`, identical `capitalRestarts` (fixture expects `0`), and `backtracks < 50` (non-thrash guard), so duplicate runs exercise the same DFS / tabu bookkeeping surface as the single-run AC-14 test.
- **AC-11 / AC-12:** `init_game_orchestrator_test.dart` — twenty fixed seeds for locked profile; **AC-12** repeats full setup twice using **one of those same seeds** (currently `17011`) and asserts identical Old World `province id → owner id` strings. When a run’s OW **and** NW topologies both match the locked multisets, tests assert **AC-1–AC-9** predicates (province quotas, P–P connectivity, sea-bound seeds, continent role counts, NW tribe layout); when multisets do not match procedural output, those ACs are out of scope for that run until generator gates land.

## Shared helpers

`province_assignment.dart` provides **`computeFairTargets`**, **`pickSimpleSeeds`**, and **`assignTerritoriesByBfsGrowth`** (used for non–full-init OW landmasses and NW tribe fallback when locked remainder bin packing is infeasible).
