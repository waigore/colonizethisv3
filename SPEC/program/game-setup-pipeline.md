# Game Setup Pipeline

## Responsibility

Orchestrates game creation from config through map generation, province/capital assignment, and initial state construction. Implements the setup phases defined in [game-setup.md](../game/game-setup.md).

## Data Model

- **GameSetupConfig:** seed, selectedGreatPowerIds, continent count, minor/tribe counts, target province counts, min provinces per minor. Loaded from colonizethis_data (Base → Difficulty → Scenario merge per [ruleset-config.md](../game/ruleset-config.md)).
- **Effective seed:** if `config.seed ≠ 0`, use directly; if 0 or absent, derive from `DateTime.now().millisecondsSinceEpoch`.
- **Game / WorldState:** RegionData per region (OW, NW), Province list (id, regionId, ownerId), faction records (Players, Minor Nations, Tribes).
- **InitGameResult:** Game, mapPngBytes, markdown, InitGameMapViewData.

## Algorithm / Flow

Steps implement the phases from [game-setup.md](../game/game-setup.md):

1. **Load config** — Parse GameSetupConfig; compute effective seed.
2. **Generate OW map** — Call colonizethis_map with province count, continent count, region id `oldWorld`, effective seed, and resource rules. Output: tile map with terrain/resources and inferred topology.
3. **Generate NW map** — Same for `newWorld`; use deterministic seed offset (e.g. `effectiveSeed + 1`) and same resource rules.
4. **GP assignment** — Build province adjacency graph from P–P edges. Reserve `minorCount × minProvincesPerMinor` OW provinces for minors. Partition remainder among GPs via multi-source BFS per [game-setup.md](../game/game-setup.md) § GP Assignment.
5. **Minor Nation assignment** — Assign remaining OW provinces to minors via BFS per [game-setup.md](../game/game-setup.md) § Minor Nation Assignment.
6. **Tribe assignment** — Assign NW provinces to tribes via BFS per [game-setup.md](../game/game-setup.md) § Tribe Assignment.
7. **Build state:**
   - Construct WorldState with RegionData and Province list (ownerId set).
   - Construct Game with Players, Minor Nations, Tribes.
   - **7a. GP colour mapping** — Map semantic GP ids (e.g. `england`) onto runtime Player ids (`gp1`, `gp2`, …). Re-key any colour overrides from semantic → runtime id so map builders and the running game consume GP colours by runtime Player id.
   - **7b. Capital auto-choice** — Run per-faction capital algorithm from [capital-choice-phase.md](../game/capital-choice-phase.md). Apply border-avoidance heuristic; auto-build port/road at capital. Depends on: WorldState with Province.ownerId set; topology and tile map from steps 2–3.
   - **7c. Province naming** — Apply naming from active ruleset per [naming.md](../game/naming.md). Applies to all provinces owned at setup; provinces acquired later retain existing display name.
8. **Persist or pass** — Save via colonizethis_save or hand off to app. Tile maps and topology are static; store with game or regenerate from seed.

Entry point: `runInitGame(config, options)` in colonizethis_logic. CLI tool: [init-game-tool.md](init-game-tool.md).

## Integration

- **Phase:** Pre-game (before turn 0).
- **Upstream:** colonizethis_data (config, ruleset merge), colonizethis_map (map generation).
- **Downstream:** App (GameService.createNewGame), init_game CLI tool, ctdev debug views.

## Constraints

- Effective seed must be computed consistently across all entry points (CLI, ctdev, app).
- Tile maps include full terrain and resource data for visualization and extraction.
- Owned by colonizethis_logic (orchestration), colonizethis_map (generation), colonizethis_models (types).
