# Game Setup

## Overview

Pre-game phases that configure, generate, and populate the game world before turn 0. Covers config loading, procedural map generation, province/capital assignment for Great Powers, Minor Nations, and Tribes, and initial state creation.

## Rules

**Phase order:** Config → World Generation → GP Assignment → Minor Nation Assignment → Tribe Assignment → Faction & Initial State → Capital-Choice Phase.

**Config:** Load Great Power count, continent count, Minor Nation count, Tribe count, minimum provinces per Minor Nation, and target province counts per region from the active ruleset or scenario.

**World Generation:** Generate procedural maps for Old World and New World (one per region). Fewer continents than Great Power count so provinces are shared across GPs per continent. Map seed: if configured seed is non-zero, use it directly; if zero or missing, derive from current time in milliseconds.

**GP Assignment:** Assign Old World provinces to Great Powers as contiguous land clusters with fair split (same or similar count per GP), using only OW provinces not reserved for Minor Nations. Contiguity defined by P–P edges in topology:

- Prefer a single landmass cluster per GP wherever possible.
- Expand each GP's cluster by walking unassigned neighbour provinces; only start new clusters on another landmass when no unassigned neighbours remain.
- Split across continents is a last resort.
- Each GP must receive at least one sea-bound province (P–S edge); this becomes its capital province for auto-choice.

**Minor Nation Assignment:** Assign remaining OW provinces to Minor Nations as contiguous clusters per minor. Per-minor count from even split of remaining OW total (within ±1); every minor receives at least one province. Capital assigned at setup (any owned province; sea-bound not required).

**Tribe Assignment:** Assign New World provinces to Tribes as contiguous clusters per tribe. Per-tribe count from even split of NW total (within ±1). Capital assigned at setup (any owned province; sea-bound not required).

**Faction & Initial State:** Create faction records (GPs, Minor Nations, Tribes). Set province ownership. Run capital auto-choice for each faction (see [capital-choice-phase.md](capital-choice-phase.md)). Apply province and capital naming from ruleset (see [naming.md](naming.md)). Create initial WorldState and Game. Province and capital ids use the prefixed format and lookup rules in [world-model-identity.md](world-model-identity.md).

**Capital-Choice Phase:** Runs after setup for Great Powers only — each GP may confirm or override its capital province + tile (sea-bound). Minor Nations and Tribes do not participate; their capitals come from setup.

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
