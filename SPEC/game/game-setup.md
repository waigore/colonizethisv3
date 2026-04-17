# Game Setup

## Overview

Pre-game phases that configure, generate, and populate the game world before turn 0. Covers config loading, procedural map generation, province/capital assignment for Great Powers, Minor Nations, and Tribes, and initial state creation.

## Rules

**Phase order:** Config → World Generation → GP Assignment → Minor Nation Assignment → Tribe Assignment → Faction & Initial State → Capital-Choice Phase.

**Config:** Map-generating setup is locked to one algorithm profile in both regions: Old World = **6 Great Powers**, **6 Minor Nations**, **60 provinces**, **4 continents**; New World = **10 Tribes**, **30 provinces**, **4 continents**. Values are resolved into `GameSetupConfig` (colonizethis_data), then map-generating orchestration applies this locked profile before generation/assignment. **current product:** There is no Base → Difficulty → Scenario JSON merge yet; values come from program defaults plus client inputs and then are normalized by setup orchestration. Full ruleset-backed resolution is specified in [ruleset-config.md](ruleset-config.md) and tracked with ruleset-loader work (e.g. #57 / #58).

**World Generation:** Generate procedural maps for Old World and New World (one per region). Old World generation must produce exactly four P–P continents with sorted sizes **`13, 13, 17, 17`** and must pass a locked-role feasibility check: each 17-continent admits connected ownership groups sized `7+7+3` and each 13-continent admits connected ownership groups sized `7+3+3`, with each 7-group corresponding to a Great Power containing at least one sea-bound province. New World generation must produce exactly four P–P continents with sorted sizes **`6, 6, 9, 9`**. Lake filling must consume enclosed inland seas by subsuming their cells into bordering landmass tiles so no enclosed lake pockets remain. Setup retries each region generation with deterministic seed offsets for up to **50** retries (51 attempts total including initial). If no attempt yields the locked partition (and feasibility for OW), setup fails with explicit error (`old_world_partition_retry_exhausted` or `new_world_partition_retry_exhausted`). Map seed: if configured seed is non-zero, use it directly; if zero or missing, derive from current time in milliseconds.

**GP Assignment:** Assign Old World provinces to Great Powers in contiguous clusters, with each GP restricted to one continent. **Hard requirement:** each GP owns exactly **7** Old World provinces (6 GPs = 42 total). In continent-role allocation, two continents host **2 GPs + 1 Minor** each, and two continents host **1 GP + 2 Minors** each.

**One continent per Great Power (hard rule):** **Continent** = P–P connected land component in [map-topology.md](map-topology.md). Each GP’s OW provinces lie in one component only and form one P–P connected component among provinces that GP owns.

- **Multiple GPs per continent:** If GP count exceeds OW continent count, several GPs share a continent; each GP still has **one** continent only.
- **Seeds:** Each GP gets ≥1 **sea-bound** province (P–S) **on that continent** for BFS seed and capital auto-choice.
- **Feasibility:** If targets, minor reservation, and sea-bound slots cannot be satisfied without violating the rule, setup **fails** with a clear error (no cross-continent GP fallback).

**Minor Nation Assignment:** Assign the remaining **18** Old World provinces to Minor Nations as contiguous clusters with exact target **3 provinces per minor** (6 minors). Minor assignment must preserve the strict continent-role split (two continents with 1 minor each; two continents with 2 minors each). Capital assigned at setup (any owned province; sea-bound not required).

**Quota invariants (hard requirements):** Old World ownership quotas are fixed to **7 per GP** and **3 per minor**, totaling exactly **60** assigned Old World provinces. New World ownership quotas are fixed to **3 per tribe**, totaling exactly **30** assigned New World provinces.

**Tribe Assignment:** Assign New World provinces to Tribes as contiguous clusters with exact target **3 provinces per tribe** (10 tribes). New World role split is fixed by locked continent sizes: each 9-province continent hosts 3 tribes and each 6-province continent hosts 2 tribes (pattern **3+3+2+2**). Capital assigned at setup (any owned province; sea-bound not required).

**Faction & Initial State:** Create faction records (GPs, Minor Nations, Tribes). Set province ownership. Run capital auto-choice for each faction (see [capital-choice-phase.md](capital-choice-phase.md)). Apply province and capital naming from ruleset (see [naming.md](naming.md)). Create initial WorldState and Game. Province and capital ids use the prefixed format and lookup rules in [world-model-identity.md](world-model-identity.md).

**Capital-Choice Phase:** Runs **during** setup (after province assignment): each GP's capital is **auto-chosen** (sea-bound province + tile) per [capital-choice-phase.md](capital-choice-phase.md). **current product:** There is **no** in-game UI for Great Powers to confirm or override capital after auto-choice; that UI is deferred. Minor Nations and Tribes do not participate; their capitals are assigned at setup.

## Configurable Values

| Parameter | Default | Source |
|---|---|---|
| Great Power count | 6 | current product: `GameSetupConfig` / CLI; future: ruleset merge |
| Continent count | 4 (locked for OW setup) | current product: enforced by setup orchestration; future: ruleset merge |
| Minor Nation count | 6 (locked for OW setup) | current product: enforced by setup orchestration; future: ruleset merge |
| Tribe count | 10 (locked for map-generating setup) | current product: enforced by setup orchestration; future: ruleset merge |
| Min provinces per Minor Nation | 3 | current product: `GameSetupConfig`; future: ruleset merge |
| Old World province count | 60 (locked) | current product: enforced by setup orchestration; future: ruleset merge |
| New World province count | 30 (locked for map-generating setup) | current product: enforced by setup orchestration; future: ruleset merge |
| Map seed | 0 (= time-based) | current product: `GameSetupConfig` / CLI `--seed`; future: ruleset merge |
| Enforce fair assignment | false (ignored in locked map-generating setup) | reserved for compatibility |

## Interactions

- Province identity and lookup: [world-model-identity.md](world-model-identity.md)
- World model and topology: [world-model.md](world-model.md)
- Capital auto-choice and capital-choice phase: [capital-choice-phase.md](capital-choice-phase.md)
- Ruleset configuration: [ruleset-config.md](ruleset-config.md)
- Province naming: [naming.md](naming.md)
- CLI / JSON setup overrides (current product): [init-game-tool.md](../program/init-game-tool.md)

---

## Acceptance Criteria

- Given the setup run uses only current product configuration (a `GameSetupConfig` built from program defaults and optional CLI/API JSON per [init-game-tool.md](../program/init-game-tool.md), with no ruleset JSON merge)  
  When the System runs the Config phase of game setup  
  Then the System treats that `GameSetupConfig` as authoritative for Great Power count, continent count, Minor Nation count, Tribe count, minimum provinces per Minor Nation, target province counts per region, map seed, and `enforceFairAssignment`, validates non-negative integers and sensible bounds where applicable, and either proceeds with world generation or surfaces a clear configuration error if validation fails.

- Given a future implementation supplies Base → Difficulty → Scenario merge per [ruleset-config.md](ruleset-config.md)  
  When the System runs the Config phase of game setup  
  Then the System populates `GameSetupConfig` (or equivalent) from that merge and applies the same validation rules as in the current product case above.

- Given setup reaches the Capital-Choice Phase for Great Powers  
  When the System assigns each Great Power capital  
  Then the System performs **auto-choice only** per [capital-choice-phase.md](capital-choice-phase.md) and does **not** present an current product UI for the player to confirm or override that capital (deferred to a future UI).

- Given Old World and New World province counts and continent count are loaded and the tile-map generation and topology specs in [tile-map-and-generation.md](tile-map-and-generation.md) and [map-topology.md](map-topology.md) are implemented  
  When the System runs the World Generation phase  
  Then the System generates exactly one tile map per region with the requested total province counts (within tolerances), infers topology from those grids, and produces contiguous landmasses and province graphs suitable for GP, Minor, and Tribe assignment.

- Given world generation has completed successfully and Great Power, Minor Nation, and Tribe counts are known  
  When the System runs the GP Assignment, Minor Nation Assignment, Tribe Assignment, and Faction & Initial State phases  
  Then the System assigns contiguous clusters of Old World provinces to Great Powers and Minor Nations and New World provinces to Tribes as described in this document, ensures that each Great Power has at least one sea-bound province, sets up faction records and ownership, invokes the capital-choice phase per [capital-choice-phase.md](capital-choice-phase.md), applies naming per [naming.md](naming.md), and creates an initial `Game` and `WorldState` that satisfy all invariants in [world-model.md](world-model.md) and [world-model-identity.md](world-model-identity.md).

- Given GP Assignment has completed for the Old World  
  When ownership is checked against P–P continents per [map-topology.md](map-topology.md)  
  Then each Great Power’s provinces occupy **one** continent only; if GP count exceeds continent count, multiple GPs may share a continent but no GP spans two.

- Given setup completes Old World ownership assignment  
  When ownership counts are inspected  
  Then each Great Power owns exactly **7** Old World provinces, each Minor Nation owns exactly **3** Old World provinces, and the owned-province total is exactly **60**.

- Given fair targets, minor reservation, and sea-bound seeds cannot all be satisfied per the one-continent-per-GP rule  
  When the System runs GP Assignment  
  Then setup **fails** with an explicit error (no silent cross-continent assignment).

- Given map-generating setup runs with the locked profile and a non-zero seed  
  When the System completes assignment  
  Then each Great Power, Minor Nation, and Tribe ownership set is already one P–P connected component from assigner output, with no post-assignment connectivity repair step.

