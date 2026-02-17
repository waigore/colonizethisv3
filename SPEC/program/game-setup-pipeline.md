# Game Setup Pipeline

**SPEC/program** — Technical orchestration of game creation. Game design: [game-setup.md](../game/game-setup.md). Map generation: [tile-map-generation.md](tile-map-generation.md). Map data: [map-data.md](map-data.md).

---

## Flow

1. **Load config** — Great Power count (default 6), continent count, Minor Nation count (default 6), Tribe count, minimum provinces per Minor Nation (default 3), and target Old/New World province counts from ruleset base or scenario (colonizethis_data or equivalent). Defaults: Old World ≈60 provinces to support Great Powers and Minor Nations; New World ≈80 provinces so Tribes and later colonial play have a deeper frontier. Map generation uses a **configured seed** from `GameSetupConfig.seed`; orchestration computes an **effective seed** as follows: if `seed != 0`, use it directly; if `seed == 0` (or absent from external config), derive the effective seed from `DateTime.now().millisecondsSinceEpoch` at run time.
2. **Generate Old World map** — Call colonizethis_map (or generate_map) with province count, continent count, region id `oldWorld`, and map params constructed from the **effective seed** (e.g. `seed = effectiveSeed`). Obtain tile map and inferred topology for OW.
3. **Generate New World map** — Same for region id `newWorld`, typically using a **deterministic offset** from the effective seed (e.g. `seed = effectiveSeed + 1`) so that OW and NW are stable relative to the same base seed.
4. **Province and capital assignment — Great Powers** — From OW topology (and optionally NW if GPs get NW provinces at start), build a **province adjacency graph** from P–P edges and derive **landmass components** (connected components of that graph). First reserve `minorCount * minProvincesPerMinor` Old World provinces for Minor Nations at the aggregate level; partition the remaining OW provinces among GPs as **contiguous land clusters** with a fair split: select one **sea-bound seed province** per GP (spreading seeds across distinct landmasses where possible), then run a **multi-source BFS** over province neighbours to grow each GP’s cluster toward its per-GP target (derived from the non-reserved OW share), always preferring unassigned neighbours on the same landmass. Only start new seeds on other landmasses when no unassigned neighbours remain for that GP, and ensure each GP ends with at least one sea-bound province to serve as its capital province.
5. **Assignment — Minor Nations** — Assign remaining OW provinces (after Great Power assignment) to N minors as **contiguous clusters** using the same P–P adjacency graph: pick unassigned seed provinces and grow clusters by BFS over unassigned neighbours until all provinces are owned. Combined with the config defaults, this yields approximately three provinces per minor in the base ruleset. Assign capital per minor from setup (any owned province; sea-bound not required).
6. **Assignment — Tribes** — Assign NW provinces to M tribes as **contiguous clusters** per tribe using the NW topology P–P adjacency graph. Derive per-tribe province targets from an even split of the New World province total by Tribe count (within ±1), then seed and grow clusters by BFS so each tribe approaches its target while maintaining contiguity; assign capital per tribe from setup (any owned province; sea-bound not required).
7. **Build state** — Construct **WorldState**: RegionData for OW and NW with Province list (id, regionId, ownerId = faction id). Optionally initial Unit list. Construct **Game**: id, WorldState, list of Players (GPs), list of Minor Nations, list of Tribes. Each faction has placeholder capital (null or stub).
   - **7a. Capital auto-choice** — For each faction (GP then minor then tribe), run the **capital auto-choice** algorithm (see [capital-choice-phase.md](../game/capital-choice-phase.md)#auto-choice-game-setup). Inputs: faction’s owned provinces and region from assignment; topology and tile map per region from steps 2–3; current Game. When choosing a tile, apply the **border-avoidance heuristic** from the capital-choice spec (prefer coastal tiles not adjacent to other provinces, then interior tiles not adjacent to other provinces, then any tile). Apply result using the same port/road auto-build as setCapital and set the faction’s capital. Depends on: WorldState with Province.ownerId set; topologyByRegion and tileMapByRegion from steps 2–3; Game with players (and minors/tribes when implemented).
8. **Persist or pass** — Tile maps and topology are static per map; store with game or in colonizethis_data for load. Save Game via colonizethis_save or hand off to app.

**init_game tool:** Runs steps 1–7 via `runInitGame` in colonizethis_logic; exports visualization artifacts — `InitGameMapViewData` (for interactive debug views), faction setup markdown, and optionally a combined map PNG (with ownership and capitals) when `InitGameOptions.renderPng` is true; optionally saves game. See [init-game-tool.md](init-game-tool.md).

---

## Ownership

- **Implemented in:** colonizethis_logic (or app) for orchestration; colonizethis_map for map gen; colonizethis_models for Game/WorldState/Faction types.
- **Consumed by:** App (GameService.createNewGame) and init_game tool when starting or visualizing a new game.
- **Config:** colonizethis_data owns config; merge order Base → Difficulty → Scenario per ruleset-config.

---

## Tile Maps and Topology

Generated tile maps and inferred topology are not stored in WorldState (static per map/scenario). They are either stored alongside the game (e.g. scenario bundle) or regenerated from a stored seed when the game is loaded. Map-data.md: loaded at game creation; colonizethis_data owns loading.
