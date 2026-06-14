# Game Setup

## Overview

Pre-game phases that configure, generate, and populate the game world before turn 0. Covers config loading, procedural map generation, province/capital assignment for Great Powers, Minor Nations, and Tribes, and initial state creation.

## Rules

**Phase order:** Config → World Generation → **Old World ownership (Great Powers + Minor Nations; locked assigner when the locked full-init profile and OW partition/role gates pass, otherwise BFS growth per pipeline)** → **New World tribe assignment (locked assigner on NW remainders; map+setup retries on documented topology failures)** → Faction & Initial State → Capital-Choice Phase.

**Human/AI slot assignment:** Which Great Power slots are human vs AI is configurable at creation via `GameSetupConfig.humanGreatPowerSlotIndices` (`Set<int>`, default `{0}` = slot 0 / `gp1` human, the rest AI). An empty set creates a fully-AI game (used by the Full-AI observer). Slot indices are validated against `[0, greatPowerCount)`; out-of-range indices fail setup. The player-app new-game flow leaves the default (one human, slot 0) — see `SPEC/ui/new-game-leader-selection-dialog.md`. Mechanics live in [game-setup-pipeline.md](../program/game-setup-pipeline.md) § Human/AI slot assignment.

**Tuned AI profiles (Refs #3444):** `GameSetupConfig.aiProfileByGpId` maps AI Great Power id → blessed profile name (`null` or absent entry = normal hardcoded personality). Chosen in the new-game leader dialog per AI slot; copied onto `Game.aiProfileByGpId` at game creation. Only personality parameter categories apply at runtime (not `victory_config`).

**Config:** Great Power count, continent count, Minor Nation count, Tribe count, minimum provinces per Minor Nation, target province counts per region, and map seed semantics are authoritative for a run once resolved into `GameSetupConfig` (colonizethis_data). **current product:** There is no Base → Difficulty → Scenario JSON merge yet; values come from **program defaults** (`GameSetupConfig` fields) plus **CLI/API overrides** (see [init-game-tool.md](../program/init-game-tool.md) JSON keys). Full ruleset-backed resolution is specified in [ruleset-config.md](ruleset-config.md) and tracked with ruleset-loader work (e.g. #57 / #58). Province painting follows [locked-province-assigner.md](../program/locked-province-assigner.md) and [game-setup-pipeline.md](../program/game-setup-pipeline.md): **locked** growth where the profile and topology gates apply; **`assignTerritoriesByBfsGrowth`** remains for non-gated Old World landmasses and tests/tools that inject a custom map generator. There is **no** optional “fair assignment” flag and **no** GP Old World connectivity repair pass after assignment.

**World Generation:** Generate procedural maps for Old World and New World (one per region). Procedural **continent count** shapes land layout; it does not override GP assignment rules below. When continent count is less than Great Power count, multiple GPs **share** one continent (same P–P component) for their starting territory. Map seed: if configured seed is non-zero, use it directly; if zero or missing, derive from current time in milliseconds.

**GP Assignment:** Assign Old World provinces to Great Powers with a **fair split** (same or similar province count per GP), using only OW provinces not reserved for Minor Nations, via the locked assigner on each OW P–P landmass.

**One P–P component per faction on its landmass:** **Continent** = P–P connected land component in [map-topology.md](map-topology.md). The locked assigner grows each faction’s territory so that, on completion, each Great Power’s and each Minor Nation’s assigned provinces on a landmass form **one** P–P connected set (and fair-ish province budgets come from `computeFairTargets` + growth order, not from a separate repair pass).

- **Multiple GPs per continent:** If GP count exceeds OW continent count, several GPs share a continent; each GP still has **one** continent only.
- **Seeds:** Each GP gets ≥1 **sea-bound** province (P–S) **on that continent** for assigner seeds and capital auto-choice.
- **Feasibility:** If targets, minor reservation, and sea-bound slots cannot be satisfied without violating the rule, setup **fails** with a clear error (no cross-continent GP fallback).

**Minor Nation Assignment:** Minor nations are painted on Old World landmasses by the same locked assigner as Great Powers (growth order and targets per program TDD). Per-minor count from even split of remaining OW total (within ±1); every minor receives at least one province. Capital assigned at setup (any owned province; sea-bound not required).

**Tribe Assignment:** Assign New World provinces to Tribes using the locked assigner on NW landmasses. Per-tribe count from even split of NW total (within ±1). Capital assigned at setup (any owned province; sea-bound not required).

**Faction & Initial State:** Create faction records (GPs, Minor Nations, Tribes). Set province ownership. Run capital auto-choice for each faction (see [capital-choice-phase.md](capital-choice-phase.md)). Apply province and capital naming from ruleset (see [naming.md](naming.md)). Create initial WorldState and Game. Province and capital ids use the prefixed format and lookup rules in [world-model-identity.md](world-model-identity.md).

**Capital-Choice Phase:** Runs **during** setup (after province assignment): each GP's capital is **auto-chosen** (sea-bound province + tile) per [capital-choice-phase.md](capital-choice-phase.md). **current product:** There is **no** in-game UI for Great Powers to confirm or override capital after auto-choice; that UI is deferred. Minor Nations and Tribes do not participate; their capitals are assigned at setup.

## Configurable Values

| Parameter | Default | Source |
|---|---|---|
| Great Power count | 6 | current product: `GameSetupConfig` / CLI; future: ruleset merge |
| Continent count | 3–4 | current product: `GameSetupConfig` / CLI; future: ruleset merge |
| Minor Nation count | 3 | current product: `GameSetupConfig` / CLI; future: ruleset merge |
| Tribe count | ~10 | current product: `GameSetupConfig` / CLI; future: ruleset merge |
| Min provinces per Minor Nation | 3 | current product: `GameSetupConfig`; future: ruleset merge |
| Old World province count | ~60 | current product: `GameSetupConfig` / CLI; future: ruleset merge |
| New World province count | ~80 | current product: `GameSetupConfig` / CLI; future: ruleset merge |
| Map seed | 0 (= time-based) | current product: `GameSetupConfig` / CLI `--seed`; future: ruleset merge |

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
  Then the System treats that `GameSetupConfig` as authoritative for Great Power count, continent count, Minor Nation count, Tribe count, minimum provinces per Minor Nation, target province counts per region, and map seed, validates non-negative integers and sensible bounds where applicable, and either proceeds with world generation or surfaces a clear configuration error if validation fails.

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

- Given fair targets, minor reservation, and sea-bound seeds cannot all be satisfied per the one-continent-per-GP rule  
  When the System runs GP Assignment  
  Then setup **fails** with an explicit error (no silent cross-continent assignment).

