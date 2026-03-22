# Game Setup

## Overview

Pre-game phases that configure, generate, and populate the game world before turn 0. Covers config loading, procedural map generation, province/capital assignment for Great Powers, Minor Nations, and Tribes, and initial state creation.

## Rules

**Phase order:** Config → World Generation → GP Assignment → Minor Nation Assignment → Tribe Assignment → Faction & Initial State → Capital-Choice Phase.

**Config:** Load Great Power count, continent count, Minor Nation count, Tribe count, minimum provinces per Minor Nation, and target province counts per region from the active ruleset or scenario.

**World Generation:** Generate procedural maps for Old World and New World (one per region). Procedural **continent count** shapes land layout; it does not override GP assignment rules below. When continent count is less than Great Power count, multiple GPs **share** one continent (same P–P component) for their starting territory. Map seed: if configured seed is non-zero, use it directly; if zero or missing, derive from current time in milliseconds.

**GP Assignment:** Assign Old World provinces to Great Powers with a **fair split** (same or similar province count per GP), using only OW provinces not reserved for Minor Nations.

**One continent per Great Power (hard rule):** **Continent** = P–P connected land component in [map-topology.md](map-topology.md). Each GP’s OW provinces at end of GP Assignment lie in **one** component only (player phrasing “one continent per GP”).

- **Multiple GPs per continent:** If GP count exceeds OW continent count, several GPs share a continent; each GP still has **one** continent only.
- **Seeds:** Each GP gets ≥1 **sea-bound** province (P–S) **on that continent** for BFS seed and capital auto-choice.
- **Feasibility:** If targets, minor reservation, and sea-bound slots cannot be satisfied without violating the rule, setup **fails** with a clear error (no cross-continent GP fallback).

**Minor Nation Assignment:** Assign remaining OW provinces to Minor Nations as contiguous clusters per minor. Per-minor count from even split of remaining OW total (within ±1); every minor receives at least one province. Capital assigned at setup (any owned province; sea-bound not required).

**Tribe Assignment:** Assign New World provinces to Tribes as contiguous clusters per tribe. Per-tribe count from even split of NW total (within ±1). Capital assigned at setup (any owned province; sea-bound not required).

**Faction & Initial State:** Create faction records (GPs, Minor Nations, Tribes). Set province ownership. Run capital auto-choice for each faction (see [capital-choice-phase.md](capital-choice-phase.md)). Apply province and capital naming from ruleset (see [naming.md](naming.md)). Create initial WorldState and Game. Province and capital ids use the prefixed format and lookup rules in [world-model-identity.md](world-model-identity.md).

**Capital-Choice Phase:** Runs **during** setup (after province assignment): each GP's capital is auto-chosen (sea-bound province + tile); a future UI may let GPs confirm or override. Minor Nations and Tribes do not participate; their capitals are assigned at setup.

## Configurable Values

| Parameter | Default | Source |
|---|---|---|
| Great Power count | 6 | Ruleset / scenario |
| Continent count | 3–4 | Ruleset / scenario |
| Minor Nation count | 6 | Ruleset / scenario |
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
