# ctdev — ColonizeThis Dev App

**SPEC/program** — Flutter dev-only application for debug/diagnostic visualization. Consumes init_game outputs and shared map view models; not player-facing.

---

## Purpose and Scope

- **Purpose:** Provide developers/designers with a lightweight way to:
  - Run init-game-style map generation and game creation from a UI.
  - Load existing savegames (e.g. from `tool/init_game`) and inspect Old/New World maps.
  - View rich debug overlays (ownership, capitals, ports) without the constraints of player UX.
- **Scope:** Dev tooling only; ctdev is not shipped to players and may expose internal structures. It is primarily run as a **desktop app (macOS)** for heavy debug flows such as init_game; running on web is supported but may feel less responsive due to single-threaded execution.

---

## Main Flows

- **Init Game (UI-driven):**
  - From the home screen, navigates to an **Init Game Config Screen** that presents a form mirroring `GameSetupConfig` (greatPowerCount, minorNationCount, tribeCount, numProvincesOldWorld, numProvincesNewWorld, continentCount, seed, and any exposed setup levers such as minimum provinces per Minor Nation).
  - Defaults are prefilled from `GameSetupConfig.defaultConfig` for gameplay-related fields (counts and province totals). The **Seed** field is **blank by default** on each visit and is optional.
  - The **Seed** field accepts an optional integer map seed:
    - If the user enters a **positive integer**, that value is used as `GameSetupConfig.seed` and becomes the base for deterministic map generation.
    - If the user leaves the field **blank** or enters **0**, ctdev passes `0` to orchestration; `runInitGame` then derives the **effective seed** from the current time in milliseconds before invoking the map generator.
    - ctdev does **not** rewrite the Seed field with the derived time-based seed during the run; reproducibility for time-based runs is not guaranteed unless callers capture the effective seed separately.
  - The screen also exposes a **Render PNG snapshot** checkbox (dev-only, default unchecked) that controls whether a combined map PNG is rendered as part of init_game; this is separate from the interactive debug map view, which always uses `InitGameMapViewData`.
  - On submit:
    - Validates basic constraints (e.g. OW provinces sufficient for configured Great Powers and Minor Nations, NW provinces sufficient for Tribes).
    - Calls `runInitGame(config, options)` in colonizethis_logic, passing an `InitGameOptions` instance that:
      - Uses a fixed `cellSize` suitable for debug visualization.
      - Forwards map-generation flags (e.g. `skipFillLakes`) when present.
      - Sets `renderPng` from the Render PNG checkbox so PNG rendering can be skipped entirely when not needed.
    - Runs init_game on the **same isolate** as the UI but wraps it in a clear **loading/busy state**: the submit button is disabled and a lightweight overlay/spinner is shown while work runs. On desktop (macOS), this keeps the UX predictable while still allowing long-running generation; future versions may offload work to background isolates where platform support and message-safety constraints allow.
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
  - Applies a **debug map visual scale** (`kDebugMapScale`) of **1.0** on top of the logical `cellSize` from the view model so that tiles are easy to read by default; users can still zoom further via `InteractiveViewer`.
- **Overlays and inspection:**
  - Ownership colouring by faction type (Great Powers/Tribes vibrant, Minor Nations grey).
  - Province/sea borders, capitals (gold circles), ports (teal squares).
  - Per-cell inspection: tap/click shows province/sea id, region id, owner, terrain, resource, capital/port flags.
  - Toggleable layers for ownership, borders, capitals, ports, and on-tile labels (e.g. region ids).

---

## Sim Game Integration

- **Start Game action:**
  - When an Init Game run completes (or a save is loaded), the Init Game Map Debug Screen shows a **Start Game** button.
  - Pressing Start Game:
    - Takes the `Game` from the most recent `InitGameResult` (or loaded save).
    - Captures the current `MapTopology` and any tile-map data needed by `resolveTurnForGame`.
    - Chooses a deterministic `baseSeed` (from the init seed by default; optionally overridable via a small numeric field).
    - Creates a **Sim Game controller** in memory holding:
      - Current `Game`.
      - `MapTopology`.
      - `baseSeed`.
      - A small per-turn log (e.g. list of combat events and province flips).
    - Switches the screen into **Sim Game mode** while keeping the same map view.

- **Sim Game controls:**
  - A compact control bar appears above or below the map with:
    - **Player-by-player**:
      - A **Next Player** button that generates orders for the next Great Power using `defaultSimGameAi(...)`.
      - A **Resolve Turn** button that becomes enabled once all GPs have orders; it calls `resolveTurnForGame` once and advances the game by one full turn.
    - **Turn-by-turn**:
      - A **Next Turn** button that, when pressed, calls `defaultSimGameAi(...)` for every Great Power for the current turn, combines their orders, calls `resolveTurnForGame`, and refreshes the map and log.
    - **Fast-forward 10 turns**:
      - A **Fast-forward 10** button that runs 10 iterations of “AI for all GPs → resolveTurnForGame”, showing a simple in-UI progress indicator and then updating the map and an aggregated summary.
  - Sim Game controls are disabled while a turn or batch of turns is resolving to prevent overlapping runs.

- **Display and logging:**
  - After each resolved turn, the screen updates:
    - The map, using the new `Game.worldState`.
    - A side or bottom panel listing:
      - Turn number and calendar year (if available).
      - Combat events (province, attacker, defender, winner, casualties, province flips).
  - For Fast-forward 10, the log may compress per-turn details into a short summary (e.g. “Turn 5–14: 7 battles, 3 province flips”).
  - Implementations may add a **Save sim log** button that writes the current run summary to a Markdown or JSON file in a chosen directory.

---

## Relationship to init_game CLI

- `tool/init_game` remains a **headless CLI**:
  - Produces savegames (primary artifact), optional PNG, optional markdown.
  - Does **not** launch ctdev or any UI.
- ctdev is the **canonical visualization surface** for init_game outputs:
  - Developers can:
    - Run init-game flows directly inside ctdev, or
    - Generate saves via the CLI and load them into ctdev’s Load Savegame flow.

