# init_game — Game Creation Tool

**SPEC/program** — CLI tool that runs the full game creation process (map generation, province/capital assignment, world state initialization) without running turns. Outputs visualization (PNG) and faction setup markdown. References: [game-setup.md](../game/game-setup.md), [game-setup-pipeline.md](game-setup-pipeline.md), [map-data.md](map-data.md).

---

## Purpose and Scope

- **Purpose:** Create a new game: generate Old World and New World maps, assign provinces and capitals to Great Powers, Minor Nations, and Tribes, build initial WorldState. Export a combined map PNG (with ownership and capitals) and concise faction setup markdown. Does not advance turns.
- **Orchestration in libraries:** The tool is thin; all orchestration lives in packages. `runInitGame(config, options)` in colonizethis_logic performs: generate OW map, generate NW map, `createGameFromGeneratedMaps`, build an `InitGameMapViewData` view model for visualization, render a combined PNG via colonizethis_map, and format markdown. Returns `InitGameResult(game, mapPngBytes, markdown, mapViewData)`.
- **Owner:** Program layer (Dart CLI under `tool/init_game`), implemented as thin facade over colonizethis_logic, colonizethis_map, colonizethis_data.

---

## CLI Interface

- Command: `melos run init_game -- [options]`.
- Arguments:
  - `--config <path>` (optional): path to JSON config overriding GameSetupConfig. If omitted, use defaults.
  - `--output-map <path>` (optional): path for writing the combined OW+NW map PNG. If omitted, no PNG file is written.
  - `--output-markdown <path>` (optional): path for writing the faction setup markdown. If omitted, no markdown file is written.
  - `--output-game <path>` (optional): path for saving the game (colonizethis_save format). If omitted and `--no-save` is not set, implementation may use a default path or skip save.
  - `--no-save`: do not save the game. Overrides `--output-game` if both are present.
  - `--seed <int>` (optional): RNG seed for map generation. Overrides config seed.
  - `--great-power-count N`, `--minor-nation-count N`, `--tribe-count N`, `--num-provinces-old-world N`, `--num-provinces-new-world N` (optional): overrides for GameSetupConfig.

Paths in arguments are relative to the repo root per colonizethis-tools.

Validation errors (invalid config, insufficient provinces for GPs, etc.) are reported clearly and abort the run.

---

## Output

### Savegame

- **Primary artifact for visualization and further tooling.**
- Saved via colonizethis_save when `--output-game <path>` is provided (see CLI Interface). The resulting game can be:
  - Loaded by the main app for gameplay.
  - Loaded by the ctdev Flutter dev app for debug/diagnostic visualization (Init Game and Load Savegame flows).

### Map PNG

Combined Old World + New World map with:

- Terrain fill per region.
- Province and sea zone borders.
- Ownership overlay: one color per faction (Great Power, Minor Nation, Tribe).
- Capital markers: distinct marker at each faction’s capital tile.
- Legend: terrain/ownership, capitals (see [map-data.md](map-data.md) § Game world state map visualizer).

### Markdown

Two concise tables:

- **Faction Setup:** Faction | Type | Capital Province | Provinces Owned
- **Faction Starting State:** Faction | Stockpile | Workers | Treasury | Units

Great Powers: full row with stockpile, worker pool, treasury, units. Minor Nations and Tribes: capital and provinces; stockpile/workers/treasury/units shown as "—" where not applicable.

---

## Run

From repo root: `melos run init_game -- [options]`.
