# Game Setup

**SPEC/game** — Pre-game phases before turn 0. Reference: [world-model.md](world-model.md), [capital-choice-phase.md](capital-choice-phase.md), [ruleset-config.md](ruleset-config.md). Technical pipeline: [game-setup-pipeline.md](../program/game-setup-pipeline.md).

---

## Overview

Game setup runs as **distinct phases before the game starts** (before turn 0). Order: config → world generation → province and capital assignment (Great Powers, then Minor Nations, then Tribes) → create all factions and initial state. Capital-choice phase applies to **Great Powers only**; Minor Nations and Tribes receive their capital from setup.

---

## Phase 1: Config

Load or derive: **Great Power count** (default 7), **continent count** (e.g. 3–4, fewer than GP count), **Minor Nation count** (e.g. 6), **Tribe count** (e.g. 10). Defined in ruleset base or scenario. See [ruleset-config.md](ruleset-config.md) for game/setup category.

---

## Phase 2: World Generation

Generate a **procedural map** for **Old World** and **New World** (run existing tile-map pipeline once per region). Inputs per region: province count, continent count, region id, map params (seed, tiles per province, sea fraction, etc.). Output: per-region tile map and inferred topology. Fewer continents than Great Power count so that provinces can be shared across GPs per continent.

---

## Phase 3: Province and Capital Assignment — Great Powers

Assign provinces to each Great Power as **contiguous land clusters** with a **fair split** (same or similar province count per GP). Contiguity is defined by P–P edges in the map topology (adjacent land provinces):

- Prefer a **single landmass cluster** per GP wherever possible.
- Expand each GP’s cluster by walking to **unassigned neighbour provinces**; only start new clusters on another landmass when no unassigned neighbours remain.
- Treat ownership that is split across continents as a **last resort** (e.g. when total provinces per GP cannot be met on one landmass).

Each Great Power must receive at least **one sea-bound province** (has a P–S edge); this becomes that GP’s **capital province** for auto-choice. Provinces and capitals are assigned from the generated map; the capital-choice phase may then allow the human player (and scenario) to confirm or override the GP’s capital.

---

## Phase 4: Assignment — Minor Nations

Assign **remaining Old World provinces** to Minor Nations using **contiguous clusters** per minor, again defined by P–P edges in topology. Start from unassigned seed provinces and grow clusters by walking to unassigned neighbours until all provinces are assigned. Minor Nation count from config. Each minor receives a capital (from its cluster) at setup (any owned province; sea-bound not required); no player choice.

---

## Phase 5: Assignment — Tribes

Assign **New World provinces** to Tribes as **contiguous clusters** per tribe using the same P–P connectivity rule. Tribe count from config. Each tribe receives a capital at setup (any owned province; sea-bound not required).

---

## Phase 6: Faction and Initial State

Create all **faction** records (7 Great Powers, N Minor Nations, M Tribes). Set **Province.ownerId** to the owning faction id for every province. Set **capital** (capitalProvinceId, capitalTile) for each faction via the **capital auto-choice** algorithm during the build-state step (see [game-setup-pipeline.md](../program/game-setup-pipeline.md), step 7a; algorithm in [capital-choice-phase.md](capital-choice-phase.md)#auto-choice-game-setup). Apply **province and capital naming** from the active ruleset after assignment so that provinces and capitals receive historically inspired display names. Create initial **WorldState** (provinces, units if any) and **Game** (WorldState, list of Players, list of Minor Nations, list of Tribes). Initial relations and overture state for diplomacy when in scope.

---

## Capital-Choice Phase

Runs after setup for **Great Powers only**. Each GP may confirm or choose capital province + tile (sea-bound). Minor Nations and Tribes do not participate; their capitals come from setup.
