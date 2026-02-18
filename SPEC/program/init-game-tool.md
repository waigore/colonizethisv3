# init_game — Game Creation Tool

**SPEC/program** — CLI tool that runs the full game creation process (map generation, province/capital assignment, world state initialization) without running turns. Outputs visualization (PNG) and faction setup markdown. References: [game-setup.md](../game/game-setup.md), [game-setup-pipeline.md](game-setup-pipeline.md), [map-data.md](map-data.md).

---

## Purpose and Scope

- **Purpose:** Create a new game: generate Old World and New World maps, assign provinces and capitals to Great Powers, Minor Nations, and Tribes, build initial WorldState. Export a combined map PNG (with ownership and capitals) and concise faction setup markdown. Does not advance turns.
- **Orchestration in libraries:** The tool is thin; all orchestration lives in packages. `runInitGame(config, options)` in colonizethis_logic performs: generate OW and NW maps **with terrain and resources** (by passing resource rules to the tile map generator), `createGameFromGeneratedMaps`, build an `InitGameMapViewData` view model for visualization, render a combined PNG via colonizethis_map, and format markdown. Returns `InitGameResult(game, mapPngBytes, markdown, mapViewData)`. The generated tile maps thus have full terrain and resource data for `InitGameMapViewData`, ctdev geographic view, PNG export, and extraction.
- **Owner:** Program layer (Dart CLI under `tool/init_game`), implemented as thin facade over colonizethis_logic, colonizethis_map, colonizethis_data.

---

## Orchestration API

- **Entry point:** `InitGameResult runInitGame({ required GameSetupConfig config, InitGameOptions options })` in colonizethis_logic.
- **Options (InitGameOptions):**
  - `cellSize` (int, default 24): base pixel size of one tile when building the debug map view and PNG (visual only; does not affect simulation).
  - `skipFillLakes` (bool, default false): when true, forwards to the map generator as `TileMapParams.skipFillLakes` and causes Pass 4 — Fill lakes (see [tile-map-generation.md](tile-map-generation.md) § Multi-pass pipeline) to be skipped for both Old World and New World. When enabled, inland lakes remain sea; when false (default), lakes are converted to land except where they form cross-continent straits.
  - `renderPng` (bool, default true): when false, **skips the PNG rendering step** inside `runInitGame`. In this mode `InitGameResult.mapPngBytes` may be an empty `Uint8List` and must not be relied on by callers. `mapViewData` and `markdown` are always produced regardless of this flag so that ctdev and other tools can still visualize the result.

---

## CLI Interface

- Command: `melos run init_game -- [options]`.
- Arguments:
  - `--config <path>` (optional): path to JSON config overriding GameSetupConfig. If omitted, use defaults.
  - `--output-map <path>` (optional): path for writing the combined OW+NW map PNG. If omitted, no PNG file is written.
  - `--output-markdown <path>` (optional): path for writing the faction setup markdown. If omitted, no markdown file is written.
  - `--output-game <path>` (optional): path for saving the game (colonizethis_save format). If omitted and `--no-save` is not set, implementation may use a default path or skip save.
  - `--no-save`: do not save the game. Overrides `--output-game` if both are present.
  - `--seed <int>` (optional): RNG seed for map generation. Overrides config seed. When provided and **non-zero**, this value is used as the base RNG seed. When provided as **0**, or when omitted and the config seed is 0 or missing, orchestration derives an **effective seed** from the current time in milliseconds at run time.
  - `--great-powers id1,id2,...` (optional): comma-separated Great Power semantic ids (e.g. `england,france,spain`). Overrides `selectedGreatPowerIds`. Valid ids from `allGreatPowerIds` (colonizethis_data).
  - `--great-power-count N` (optional, backward compat): when `--great-powers` is not provided, uses the first N ids from the default order. Superseded by `--great-powers` when both are present.
  - `--minor-nation-count N`, `--tribe-count N`, `--num-provinces-old-world N`, `--num-provinces-new-world N` (optional): overrides for GameSetupConfig.

JSON config supports `selectedGreatPowerIds` (array of strings). If present, that array is used. If absent but `greatPowerCount` is present, the first N ids from the default order are used for backward compatibility.

When wiring the CLI to orchestration, callers SHOULD set `InitGameOptions.renderPng` based on whether `--output-map` (or an equivalent sink) is provided so that PNG rendering work is skipped entirely when no PNG artifact is needed. Seed handling is centralized in `runInitGame`: the CLI passes the parsed `--seed` (or config seed) through to `GameSetupConfig.seed`, and `runInitGame` computes the effective seed (explicit non-zero seed → reproducible run; zero/absent seed → time-based run). The tool **does not guarantee reproducibility** for runs that use a time-based effective seed unless that seed is captured and surfaced separately by the caller.

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
