# Game Setup Pipeline

## Responsibility

Orchestrates game creation from config through map generation, province/capital assignment, and initial state construction. Implements the setup phases defined in [game-setup.md](../game/game-setup.md).

## Data Model

- **GameSetupConfig:** seed, selectedGreatPowerIds, continent count, minor/tribe counts, target province counts, min provinces per minor, **`enforceFairGpOldWorldAssignment`** (bool, default **false**). When **true**, `createGameFromGeneratedMaps` runs GP land connectivity repair and assignment retries per [game-setup.md](../game/game-setup.md). When **false**, it uses one OW assignment pass without repair. **MVP:** Values come from program defaults and optional CLI/API JSON per [init-game-tool.md](init-game-tool.md); there is **no** Base → Difficulty → Scenario JSON merge yet (deferred per [ruleset-config.md](../game/ruleset-config.md) / #57 / #58). **Future:** Same fields resolved from ruleset merge as in ruleset-config.
- **Effective seed:** if `config.seed ≠ 0`, use directly; if 0 or absent, derive from `DateTime.now().millisecondsSinceEpoch`.
- **Game / WorldState:** RegionData per region (OW, NW), Province list (id, regionId, ownerId), faction records (Players, Minor Nations, Tribes).
- **InitGameResult:** Game, mapPngBytes, markdown, InitGameMapViewData, tileMapByRegion, topologyByRegion, **warpLinks**, combinedTopology (or equivalent for cross-region sea paths). Warp links are produced in step 4 and consumed when building combined topology / connectivity.
- **Province identity:** Province ids in Game, WorldState, InitGameResult, and capital/town assignment use the prefixed form (`regionId|localId`); topology and map lookups during setup are per-region. See [world-model-identity.md](../game/world-model-identity.md).

## Algorithm / Flow

Steps implement the phases from [game-setup.md](../game/game-setup.md):

1. **Load config** — Parse GameSetupConfig; compute effective seed.
2. **Generate OW map** — Call colonizethis_map with province count, continent count, region id `oldWorld`, effective seed, and resource rules. Output: tile map with terrain/resources and inferred topology.
3. **Generate NW map** — Same for `newWorld`; use deterministic seed offset (e.g. `effectiveSeed + 1`) and same resource rules.
4. **Generate warp zones and link them** — On **each** map the generator aims for **one warp zone per map edge**, each using a **sea zone on the edge** (a sea zone that has at least one tile on the grid boundary of that map). If that is not possible (e.g. no sea zone on an edge), the **number of warp zones on each map must still be equal** so that every warp zone links to exactly one warp zone on each counterpart map. Create 1:1 links between regions (OW↔NW). Output: **warp links** (e.g. list of `(regionId, seaZoneId, otherRegionId, otherSeaZoneId)`). Stored with init result and used for cross-region sea-path reachability. See [map-topology.md](../game/map-topology.md) § Warp zones, [map-data.md](map-data.md).
5. **GP assignment** — From OW **P–P** edges, derive continent ids (land subgraph components, [map-topology.md](../game/map-topology.md) § Continents). Reserve `minorCount × minProvincesPerMinor` for minors. **Before** BFS: assign each GP to **one** continent with capacity checks (targets summed per continent ≤ its province count; GPs per continent ≤ **sea-bound** provinces there for seeds). Multi-source BFS with strict per-GP continent map (`factionLandmassIds`); infeasible → clear error. [game-setup.md](../game/game-setup.md) § GP Assignment (one continent per GP).
6. **Minor Nation assignment** — Assign remaining OW provinces to minors via BFS per [game-setup.md](../game/game-setup.md) § Minor Nation Assignment.
6b. **GP land connectivity repair (OW)** — **Only if `config.enforceFairGpOldWorldAssignment` is true.** Up to 10 outer rounds; each round runs inner sweeps (quiescence, with an implementation cap) of deterministic 1:1 swaps (GP ↔ minor or GP ↔ GP), and if needed **two** 1:1 exchanges on four distinct provinces evaluated for legality **after** both (see GDD), so each GP’s OW provinces are one P–P component; preserve one landmass per GP, ≥1 sea-bound per GP, and connectivity for all GPs; minor contiguity may break. If still disconnected, re-run steps 5–6b on the **same** OW topology with a salted assignment perturbation until success or `gp_land_connectivity_exhausted`. If **false**, skip 6b entirely. [game-setup.md](../game/game-setup.md) § GP land connectivity repair.
7. **Tribe assignment** — Assign NW provinces to tribes via BFS per [game-setup.md](../game/game-setup.md) § Tribe Assignment.
8. **Build state:**
   - Construct WorldState with RegionData and Province list (ownerId set).
   - Construct Game with Players, Minor Nations, Tribes.
   - **7a. GP colour mapping** — Map semantic GP ids (e.g. `england`) onto runtime Player ids (`gp1`, `gp2`, …). Re-key any colour overrides from semantic → runtime id so map builders and the running game consume GP colours by runtime Player id.
  - **7b. Capital auto-choice** — (1) Run per-faction capital algorithm from [capital-choice-phase.md](../game/capital-choice-phase.md). Set `capitalProvinceId` and `capitalTile`; apply border-avoidance heuristic; place one capital port entry per seaboard (per adjacent sea zone): use capital tile when it is adjacent to that sea zone, otherwise choose nearest valid coastal tile for that seaboard. (2) **Then** for each Great Power (and optionally Minor/Tribe) seaboard port placed off-capital-tile, compute shortest path on the province tile graph from that port tile to capital and set road level on every tile along that path. Reference [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Capital Setup. **Implementation (DRY):** Use a shared capital-placement API used by both init and capital reassignment (Combat phase, see [turn-resolution-phase-details.md](turn-resolution-phase-details.md) § Combat). Init and reassignment must call the same logic: choose province + tile (e.g. `pickCapitalForFaction`), then apply per-seaboard port/road (e.g. `applyCapitalPortAndRoad`), then apply road paths from off-capital seaboard ports to capital (shortest path on province tiles; set road level on each tile). Pathfinding and road placement live in shared setup/capital modules. **MVP:** GP capital is auto-chosen only; no player confirm/override UI in this pipeline step (see [game-setup.md](../game/game-setup.md) § Capital-Choice Phase).
   - **7d. Province town assignment** — For each province, set the province's **town** tile: if the province is that faction's capital province, town = capital tile; else town = tile in that province with shortest path (on province tile graph) to (capital if same region, else a port in that province). Store in province (`townTileKey`) or in a region-level map (provinceId → townTileKey). Reference [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Town per province.
   - **7c. Province naming** — Apply naming from active ruleset per [naming.md](../game/naming.md). Applies to all provinces owned at setup; provinces acquired later retain existing display name.
   - **7e. Turn-time mapping** — Set `Game.turnTimeMapping` from the resolved ruleset when present; otherwise default to GDD 01 (`TurnTimeMapping.gdd01`) for MVP. See [turn-time-mapping.md](../game/turn-time-mapping.md) and [ruleset-config.md](ruleset-config.md).
- **7f. Starting resources and units** — For each Great Power, apply `config.startingResources` (program-level StartingResourcesConfig in `colonizethis_data`) to initialize economic state and bootstrap forces:
      - **Workers:** Set the player's WorkerPool to `initialPeasants` Peasants and 0 for higher tiers. Higher tiers remain locked until unlocked via tech and recruiting/training rules.
      - **Food and materials:** Seed the player's central stockpile with `grain = initialPeasants × initialGrainTurns` plus improvement materials for early development: add `initialImprovementSlots` units of `lumber` and `castIron` each (enough to build that many level-1 improvements per [extraction-and-improvements.md](../game/extraction-and-improvements.md)). Additionally, grant a small starting quantity of `wool` (default 4 units in the MVP ruleset) to every Great Power's central stockpile as early flexible cargo/production material, and `paper` (default 2 units) for civilian training per [civilian-units.md](../game/civilian-units.md). Default `initialImprovementSlots` is **5** so each player has enough resources to build 5 level-1 improvements as a bootstrap. The exact quantities for `grain`, `lumber`, `castIron`, `wool`, and `paper` are read from the active starting-resources config / ruleset; no other commodities are granted by default.
      - **Treasury:** Set the player's treasury to `initialTreasury` (ducats). Starting civilian, military, and naval units granted by this step do **not** deduct stockpile materials or treasury.
      - **Civilian units:** Spawn civilian units in each Great Power's capital province using `startingCivilianUnits` (unit type id → count). Defaults: 2 Explorers, 2 Builders, 1 Engineer; all with `status = idle` and `tileKey` on a tile in the capital province.
      - **Starting regiments:** Spawn `initialMilitaryRegiments` land units (default 5) in each Great Power's capital province. Regiment unit types are chosen from the global regiment catalog per [military-units.md](../game/military-units.md); when a military tech catalog is present, the System prefers the **most advanced buildable regiment type** for that faction (highest era allowed by tech; on ties, highest combined FPN+FPM from the catalog). MVP: with no tech catalog yet, this reduces to a fixed baseline regiment type defined in `colonizethis_data`.
      - **Starting home fleet:** For each Great Power whose capital province is sea-bound, create or extend a **home fleet** **in port at the capital province** per [ships-and-naval.md](../game/ships-and-naval.md) with `initialNavalShips` merchant ships (default 3). Ship types are chosen from the ship economy/naval stats catalogs: when naval tech is present, the System selects the buildable merchant ship type with the highest `cargoHold` value (ties broken deterministically); before naval tech is wired, the default baseline ship type is used. These ships start in the home fleet (in port, not at sea) and contribute to cargo capacity for overseas extraction and trade.
   - **7g. Initial visibility** — Apply per-player visibility state: (1) Old World land tiles: own provinces `fullyVisible`, other factions' provinces `fogged`; (2) Old World sea tiles: `fogged` initially, then **coastal sea zone full visibility** applied (below); (3) New World tiles: `unknown` for all players. Then apply **coastal sea zone full visibility**: for each Great Power, set all tiles in sea zones adjacent (P–S edge in topology) to provinces that player owns to `fullyVisible`. Reference: [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md) § Initial visibility and Coastal sea zone full visibility.
9. **Persist or pass** — Save via colonizethis_save or hand off to app. Tile maps, topology per region, and warp links are static; store with game or regenerate from seed. **Hidden agenda assignment:** When the app or ctdev will use Phase 6 full AI, hidden agenda assignment (`assignHiddenAgendasForGame`) must be performed before the first AI order generation; see [ai-planner.md](ai-planner.md) § Phase 6 (Hidden agenda assignment). **Where invoked:** Main game path: `runInitGame` (colonizethis_logic init_game_orchestrator) calls `assignHiddenAgendasForGame` after setting `aiSeedByGpId`, so the game in InitGameResult has hidden agendas populated for all AI-controlled GPs. Sim path: ctdev invokes it in `SimGameController` when starting a sim game with full AI (`useFullAI` true).

Entry point: `runInitGame(config, options)` in colonizethis_logic. CLI tool: [init-game-tool.md](init-game-tool.md).

## Integration

- **Phase:** Pre-game (before turn 0).
- **Upstream:** colonizethis_data (config, ruleset merge), colonizethis_map (map generation).
- **Downstream:** App (`GameService.createNewGame`, `GameService.createNewGameAsync` with coarse progress per SPEC/ui/game-initializing.md), init_game CLI tool, ctdev debug views.

## Constraints

- Effective seed must be computed consistently across all entry points (CLI, ctdev, app).
- Tile maps include full terrain and resource data for visualization and extraction.
- Owned by colonizethis_logic (orchestration), colonizethis_map (generation), colonizethis_models (types).
- Capital reassignment on loss is not part of init; it runs in the Combat phase of turn resolution (see [turn-resolution-phase-details.md](turn-resolution-phase-details.md)). Reassignment uses the same shared capital-placement API as init (DRY).

## Acceptance criteria (program / tests)

These criteria are implemented and covered by automated tests where noted.

- Given `runInitGame` is called with `GameSetupConfig` whose `seed` field equals a non-zero integer `K`  
  When initialization completes  
  Then `result.game.globalGameSeed` equals `K` (colonizethis_logic `init_game_orchestrator_test.dart`).

- Given `runInitGame` uses the default tile-map generator and `GameSetupConfig.seed` equals non-zero `K`  
  When Old World and New World maps are generated  
  Then Old World `TileMapParams.seed` equals `K` and New World `TileMapParams.seed` equals `K + 1` (same test file, injected generator).

- Given `runInitGame` is called with `GameSetupConfig(seed: 0)`  
  When initialization completes  
  Then `result.game.globalGameSeed` is non-zero (time-derived effective seed; same test file).

- Given `createGameFromGeneratedMaps` (or `runInitGame`) completes successfully  
  When the caller reads `result.game.worldState.turnState`  
  Then `turnState.phase` is `TurnPhase.orders` and `turnState.turnNumber` is `0` (`game_setup.dart` / orchestrator tests).

- Given `InitGameOptions(renderPng: true)`  
  When `runInitGame` completes  
  Then `InitGameResult.mapPngBytes` is non-empty (`init_game_orchestrator_test.dart`).

- Given the `init_game` CLI runs with `--output-markdown <file>`, `--output-map <file>`, `--output-game <dir>`, and **without** `--no-save`, using flags that yield a valid small game (e.g. reduced province counts)  
  When the process exits with code `0`  
  Then the markdown file contains `# Game Setup` and `## Faction Setup`, the map PNG file has length greater than zero, and the game directory contains at least one Hive artifact (`tool/init_game/test/cli_artifacts_test.dart`).
