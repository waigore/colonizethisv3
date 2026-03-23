# Game Setup

## Overview

Pre-game phases that configure, generate, and populate the game world before turn 0. Covers config loading, procedural map generation, province/capital assignment for Great Powers, Minor Nations, and Tribes, and initial state creation.

## Rules

**Phase order:** Config → World Generation → GP Assignment → Minor Nation Assignment → **GP land connectivity repair (Old World)** → Tribe Assignment → Faction & Initial State → Capital-Choice Phase.

**Config:** Load Great Power count, continent count, Minor Nation count, Tribe count, minimum provinces per Minor Nation, and target province counts per region from the active ruleset or scenario.

**World Generation:** Generate procedural maps for Old World and New World (one per region). Procedural **continent count** shapes land layout; it does not override GP assignment rules below. When continent count is less than Great Power count, multiple GPs **share** one continent (same P–P component) for their starting territory. Map seed: if configured seed is non-zero, use it directly; if zero or missing, derive from current time in milliseconds.

**GP Assignment:** Assign Old World provinces to Great Powers with a **fair split** (same or similar province count per GP), using only OW provinces not reserved for Minor Nations.

**One continent per Great Power (hard rule):** **Continent** = P–P connected land component in [map-topology.md](map-topology.md). Each GP’s OW provinces at end of GP Assignment lie in **one** component only (player phrasing “one continent per GP”).

- **Multiple GPs per continent:** If GP count exceeds OW continent count, several GPs share a continent; each GP still has **one** continent only.
- **Seeds:** Each GP gets ≥1 **sea-bound** province (P–S) **on that continent** for BFS seed and capital auto-choice.
- **Feasibility:** If targets, minor reservation, and sea-bound slots cannot be satisfied without violating the rule, setup **fails** with a clear error (no cross-continent GP fallback).

**Minor Nation Assignment:** Assign remaining OW provinces to Minor Nations as contiguous clusters per minor. Per-minor count from even split of remaining OW total (within ±1); every minor receives at least one province. Capital assigned at setup (any owned province; sea-bound not required).

**GP land connectivity repair (Old World only):** After GP and Minor Nation assignment, each Great Power’s owned provinces must form a **single P–P connected component** using only that GP’s provinces (no “island” exclaves; every pair of GP provinces must be joined by a land path through provinces that GP owns). Connectivity uses the same province adjacency graph as movement on land ([map-topology.md](map-topology.md) P–P edges). **Repair:** Run up to **10** rounds. Each round, repeat **inner sweeps** until a full sweep performs no legal swap (cap inner sweeps at a fixed maximum to avoid infinite loops). Each sweep considers Great Powers in **sorted `gp1`, `gp2`, …** order; for each GP that is not fully connected, try **1:1 province exchanges** with a Minor Nation or another Great Power in deterministic order (sorted province ids; partner provinces sorted by id). A **single** swap is **legal** only if afterward: (1) every GP still owns provinces on **exactly one** P–P landmass (same rule as GP Assignment); (2) every GP still owns **at least one sea-bound** province; (3) every GP’s provinces remain **one** P–P component; (4) Minor Nations may become **disconnected** (allowed). If no **single** legal swap repairs that GP, the sweep may try a **compound repair** of **two** 1:1 exchanges on **four distinct** province ids (GP ↔ minor or GP ↔ GP each time), applied in sequence and **legal** only if the **final** ownership satisfies (1)–(4) after both exchanges (intermediate states may temporarily violate them). Compound pairs are enumerated in deterministic order: first exchange `(a,b)` with `a` among the disconnected GP’s provinces (sorted), `b` among all provinces sorted by id, `b`’s owner not the disconnected GP; second exchange `(c,d)` over sorted distinct `c,d` disjoint from `{a,b}`. If an outer round performs no swap at all, stop early. If after up to 10 rounds any GP is still not connected, **re-run** Old World province assignment (GP + Minor steps only) on the **same** map/topology using a **new assignment perturbation** derived from the setup seed (implementation: salted pseudo-random shuffles in assignment order); repeat until success or a **maximum attempt** count. If all attempts fail, setup is **invalid** with reason `gp_land_connectivity_exhausted`. **Determinism:** Shuffles and scan order are fully determined by the seed and attempt index.

**Tribe Assignment:** Assign New World provinces to Tribes as contiguous clusters per tribe. Per-tribe count from even split of NW total (within ±1). Capital assigned at setup (any owned province; sea-bound not required).

**Faction & Initial State:** Create faction records (GPs, Minor Nations, Tribes). Set province ownership. Run capital auto-choice for each faction (see [capital-choice-phase.md](capital-choice-phase.md)). Apply province and capital naming from ruleset (see [naming.md](naming.md)). Create initial WorldState and Game. Province and capital ids use the prefixed format and lookup rules in [world-model-identity.md](world-model-identity.md).

**Capital-Choice Phase:** Runs **during** setup (after province assignment): each GP's capital is auto-chosen (sea-bound province + tile); a future UI may let GPs confirm or override. Minor Nations and Tribes do not participate; their capitals are assigned at setup.

## Configurable Values

| Parameter | Default | Source |
|---|---|---|
| Great Power count | 6 | Ruleset / scenario |
| Continent count | 3–4 | Ruleset / scenario |
| Minor Nation count | 3 | Ruleset / scenario |
| Tribe count | ~10 | Ruleset / scenario |
| Min provinces per Minor Nation | 3 | Ruleset / scenario |
| Old World province count | ~60 | Ruleset / scenario |
| New World province count | ~80 | Ruleset / scenario |
| Map seed | 0 (= time-based) | Ruleset / scenario |

## Interactions

- Province identity and lookup: [world-model-identity.md](world-model-identity.md)
- World model and topology: [world-model.md](world-model.md)
- Capital auto-choice and capital-choice phase: [capital-choice-phase.md](capital-choice-phase.md)
- Ruleset configuration: [ruleset-config.md](ruleset-config.md)
- Province naming: [naming.md](naming.md)

---

## Acceptance Criteria

- Given a ruleset or scenario defines Great Power count, continent count, Minor Nation count, Tribe count, and target province counts per region  
  When the System runs the Config phase of game setup  
  Then the System loads these values, validates that they are non-negative integers within sensible bounds, and either proceeds with world generation using them or surfaces a clear configuration error if validation fails.

- Given Old World and New World province counts and continent count are loaded and the tile-map generation and topology specs in [tile-map-and-generation.md](tile-map-and-generation.md) and [map-topology.md](map-topology.md) are implemented  
  When the System runs the World Generation phase  
  Then the System generates exactly one tile map per region with the requested total province counts (within tolerances), infers topology from those grids, and produces contiguous landmasses and province graphs suitable for GP, Minor, and Tribe assignment.

- Given world generation has completed successfully and Great Power, Minor Nation, and Tribe counts are known  
  When the System runs the GP Assignment, Minor Nation Assignment, Tribe Assignment, and Faction & Initial State phases  
  Then the System assigns contiguous clusters of Old World provinces to Great Powers and Minor Nations and New World provinces to Tribes as described in this document, ensures that each Great Power has at least one sea-bound province, sets up faction records and ownership, invokes the capital-choice phase per [capital-choice-phase.md](capital-choice-phase.md), applies naming per [naming.md](naming.md), and creates an initial `Game` and `WorldState` that satisfy all invariants in [world-model.md](world-model.md) and [world-model-identity.md](world-model-identity.md).

- Given GP Assignment has completed for the Old World  
  When ownership is checked against P–P continents per [map-topology.md](map-topology.md)  
  Then each Great Power’s provinces occupy **one** continent only; if GP count exceeds continent count, multiple GPs may share a continent but no GP spans two.

- Given fair targets, minor reservation, and sea-bound seeds cannot all be satisfied per the one-continent-per-GP rule  
  When the System runs GP Assignment  
  Then setup **fails** with an explicit error (no silent cross-continent assignment).

- Given Old World province ownership after GP Assignment and Minor Nation Assignment includes a Great Power whose provinces are not all mutually reachable by P–P paths through provinces that Great Power owns  
  When the System runs GP land connectivity repair  
  Then the System performs up to 10 rounds of repair as specified above (legal single 1:1 swaps, and when needed compound two 1:1 exchanges on four provinces) until every Great Power is connected or no further legal repair exists in a full round

- Given after 10 rounds of GP land connectivity repair at least one Great Power still has disconnected owned provinces on the Old World  
  When the System has not exceeded the maximum Old World assignment attempt count  
  Then the System re-runs GP Assignment and Minor Nation Assignment on the same generated Old World map with a new deterministic assignment perturbation and runs repair again

- Given the maximum Old World assignment attempt count is reached and after repair a Great Power still has disconnected owned provinces  
  When the System completes setup  
  Then setup **fails** with an explicit error identified as `gp_land_connectivity_exhausted`

