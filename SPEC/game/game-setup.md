# Game Setup

## Overview

Pre-game phases that configure, generate, and populate the game world before turn 0. Covers config loading, procedural map generation, province/capital assignment for Great Powers, Minor Nations, and Tribes, and initial state creation.

## Rules

**Phase order:** Config → World Generation → GP Assignment → Minor Nation Assignment → Tribe Assignment → **Fair-assignment connectivity repair (OW+NW)** (optional; see below) → Faction & Initial State → Capital-Choice Phase.

**Config:** Old World setup is locked for all map-generating clients to one algorithm profile: **6 Great Powers**, **6 Minor Nations**, **60 Old World provinces**, and **4 continents**. Tribe count, New World province count, and seed remain configurable. Values are resolved into `GameSetupConfig` (colonizethis_data). **current product:** There is no Base → Difficulty → Scenario JSON merge yet; values come from **program defaults** plus client inputs, then the locked Old World profile is applied in setup orchestration. Full ruleset-backed resolution is specified in [ruleset-config.md](ruleset-config.md) and tracked with ruleset-loader work (e.g. #57 / #58). These locked Old World values apply whether **`enforceFairAssignment`** is **false** or **true**.

**World Generation:** Generate procedural maps for Old World and New World (one per region). Old World generation must produce exactly **four** P–P continents with sorted sizes **`13, 13, 17, 17`** (equivalently `17/17/13/13`, order-insensitive). Lake filling must consume enclosed inland seas by subsuming their cells into bordering landmass tiles so no enclosed lake pockets remain. Setup retries Old World generation with deterministic seed offsets for up to **50** retries (51 attempts total including initial). If no attempt yields that 4-continent layout, setup fails with explicit error `old_world_partition_retry_exhausted`. Map seed: if configured seed is non-zero, use it directly; if zero or missing, derive from current time in milliseconds.

**GP Assignment:** Assign Old World provinces to Great Powers in contiguous clusters, with each GP restricted to one continent. **Hard requirement:** each GP owns exactly **7** Old World provinces (6 GPs = 42 total). In continent-role allocation, two continents host **2 GPs + 1 Minor** each, and two continents host **1 GP + 2 Minors** each.

**One continent per Great Power (hard rule when fair assignment is on):** **Continent** = P–P connected land component in [map-topology.md](map-topology.md). When **`enforceFairAssignment`** is **true**, each GP’s OW provinces after GP Assignment, repair, and retries lie in **one** component only and form **one** P–P connected component among provinces that GP owns. When **`enforceFairAssignment`** is **false**, each GP still has provinces on **one** P–P landmass only (assignment constraint unchanged), but a GP may own **multiple disconnected** P–P components on that landmass until/unless the player enables fair assignment on a future run.

- **Multiple GPs per continent:** If GP count exceeds OW continent count, several GPs share a continent; each GP still has **one** continent only.
- **Seeds:** Each GP gets ≥1 **sea-bound** province (P–S) **on that continent** for BFS seed and capital auto-choice.
- **Feasibility:** If targets, minor reservation, and sea-bound slots cannot be satisfied without violating the rule, setup **fails** with a clear error (no cross-continent GP fallback).

**Minor Nation Assignment:** Assign the remaining **18** Old World provinces to Minor Nations as contiguous clusters with exact target **3 provinces per minor** (6 minors). Minor assignment must preserve the strict continent-role split (two continents with 1 minor each; two continents with 2 minors each). Capital assigned at setup (any owned province; sea-bound not required).

**Quota invariants (hard requirements):** Old World ownership quotas are fixed to **7 per GP** and **3 per minor**, totaling exactly **60** assigned Old World provinces. These invariants apply whether **`enforceFairAssignment`** is **false** or **true**.

**Fair-assignment connectivity repair (Old World + New World):** When **`enforceFairAssignment`** is **true**, after GP/Minor/Tribe assignment, each Great Power and Minor Nation in Old World and each Tribe in New World must form one P–P connected component. Repair uses deterministic **DFS over ownership swap states**, where each edge is one legal **same-landmass** 1:1 swap. In Old World, swaps may occur between any participating factions (GP or Minor) but must preserve GP hard rules (one-landmass-per-GP and at-least-one-sea-bound-per-GP). The DFS tracks visited ownership states and never revisits a seen configuration. A swap is legal only if it does not make a previously contiguous swap-partner disconnected. If DFS cannot reach a valid connected state within repair limits, setup fails with `fair_assignment_connectivity_exhausted`. The repair path does **not** trigger map regeneration or assignment regeneration loops.

**Tribe Assignment:** Assign New World provinces to Tribes as contiguous clusters per tribe. Per-tribe count from even split of NW total (within ±1). Capital assigned at setup (any owned province; sea-bound not required).

**Faction & Initial State:** Create faction records (GPs, Minor Nations, Tribes). Set province ownership. Run capital auto-choice for each faction (see [capital-choice-phase.md](capital-choice-phase.md)). Apply province and capital naming from ruleset (see [naming.md](naming.md)). Create initial WorldState and Game. Province and capital ids use the prefixed format and lookup rules in [world-model-identity.md](world-model-identity.md).

**Capital-Choice Phase:** Runs **during** setup (after province assignment): each GP's capital is **auto-chosen** (sea-bound province + tile) per [capital-choice-phase.md](capital-choice-phase.md). **current product:** There is **no** in-game UI for Great Powers to confirm or override capital after auto-choice; that UI is deferred. Minor Nations and Tribes do not participate; their capitals are assigned at setup.

## Configurable Values

| Parameter | Default | Source |
|---|---|---|
| Great Power count | 6 | current product: `GameSetupConfig` / CLI; future: ruleset merge |
| Continent count | 4 (locked for OW setup) | current product: enforced by setup orchestration; future: ruleset merge |
| Minor Nation count | 6 (locked for OW setup) | current product: enforced by setup orchestration; future: ruleset merge |
| Tribe count | ~10 | current product: `GameSetupConfig` / CLI; future: ruleset merge |
| Min provinces per Minor Nation | 3 | current product: `GameSetupConfig`; future: ruleset merge |
| Old World province count | 60 (locked) | current product: enforced by setup orchestration; future: ruleset merge |
| New World province count | ~80 | current product: `GameSetupConfig` / CLI; future: ruleset merge |
| Map seed | 0 (= time-based) | current product: `GameSetupConfig` / CLI `--seed`; future: ruleset merge |
| Enforce fair assignment | false | current product: `GameSetupConfig` / CLI; future: ruleset / UI |

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

- Given **`enforceFairAssignment`** is **true** and assigned ownership contains a GP/Minor/Tribe faction whose provinces are not mutually reachable by P–P paths through provinces that faction owns  
  When the System runs fair-assignment connectivity repair  
  Then the System performs up to 10 rounds of DFS-based same-landmass 1:1 swap-state repair (with visited-state dedupe) until every required faction is connected or no further legal repair exists

- Given **`enforceFairAssignment`** is **true** and after 10 rounds of fair-assignment connectivity repair at least one required faction remains disconnected  
  When the System completes setup  
  Then setup fails explicitly with `fair_assignment_connectivity_exhausted`

- Given **`enforceFairAssignment`** is **false** in config  
  When the System runs Old World GP and Minor Nation assignment and proceeds to Tribe Assignment  
  Then the System does not invoke fair-assignment connectivity repair

