# ctdev — ColonizeThis Dev App

**SPEC/program** — Flutter dev-only application for debug/diagnostic visualization. Consumes init_game outputs and shared map view models; not player-facing.

---

## Purpose and Scope

- **Purpose:** Provide developers/designers with a lightweight way to:
  - Run init-game-style map generation and game creation from a UI.
  - Load existing savegames (e.g. from `tool/init_game`) and inspect Old/New World maps.
  - View rich debug overlays (ownership, capitals, ports) without the constraints of player UX.
- **Scope:** Dev tooling only; ctdev is not shipped to players and may expose internal structures.

---

## Main Flows

- **Init Game (UI-driven):**
  - Presents a form mirroring `GameSetupConfig` (greatPowerCount, minorNationCount, tribeCount, numProvincesOldWorld, numProvincesNewWorld, continentCount, seed).
  - Defaults are prefilled from `GameSetupConfig.defaultConfig`.
  - On submit:
    - Calls `runInitGame(config, options)` in colonizethis_logic.
    - Receives `InitGameResult` including `game`, `mapPngBytes`, `markdown`, and `mapViewData`.
    - Saves the game via colonizethis_save to a user-chosen or ctdev-managed directory.
    - Navigates to the Init Game Map Debug screen with `InitGameMapViewData`.

- **Load Savegame:**
  - Allows selecting a previously saved game directory/file (e.g. produced by `tool/init_game` or ctdev itself).
  - Loads `Game` via colonizethis_save.
  - Resolves per-region tile maps and topology via colonizethis_data.
  - Builds `InitGameMapViewData` using colonizethis_map’s builder.
  - Navigates to the same Init Game Map Debug screen.

---

## Init Game Map Debug Screen

- **Input:** `InitGameMapViewData` plus optional seed/config summary (for display).
- **Layout:**
  - Renders Old World and New World regions side by side.
  - Uses a `CustomPainter` over `RegionMapViewData` for each region, wrapped in `InteractiveViewer` for pan/zoom.
- **Overlays and inspection:**
  - Ownership colouring by faction type (Great Powers/Tribes vibrant, Minor Nations grey).
  - Province/sea borders, capitals (gold circles), ports (teal squares).
  - Per-cell inspection: tap/click shows province/sea id, region id, owner, terrain, resource, capital/port flags.
  - Toggleable layers for ownership, borders, capitals, ports, and on-tile labels (e.g. region ids).

---

## Relationship to init_game CLI

- `tool/init_game` remains a **headless CLI**:
  - Produces savegames (primary artifact), optional PNG, optional markdown.
  - Does **not** launch ctdev or any UI.
- ctdev is the **canonical visualization surface** for init_game outputs:
  - Developers can:
    - Run init-game flows directly inside ctdev, or
    - Generate saves via the CLI and load them into ctdev’s Load Savegame flow.

