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
  - From the home screen, navigates to an **Init Game Config Screen** that presents a form mirroring `GameSetupConfig` (Great Power multi-select via `selectedGreatPowerIds`, minorNationCount, tribeCount, numProvincesOldWorld, numProvincesNewWorld, continentCount, seed, and any exposed setup levers such as minimum provinces per Minor Nation). The Great Powers section shows checkboxes for each of the seven powers (England, France, Spain, Portugal, Netherlands, Prussia, Sweden); each GP can appear at most once; at least one must be selected. When **Prussia** is selected, a leader variant selector appears (Frederick the Great | Frederick William); the chosen variant is passed as `leaderVariantByGpId['prussia']`.
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
  - **Legend (ownership):** each faction is shown as **"displayName (factionId)"** (e.g. England (gp1), France (gp2), Savoy (minor1), Aztec (tribe1)) so both human-readable name and short code are visible.
  - Province/sea borders, capitals (gold circles), ports (teal squares).
  - In **Geographic view**, terrain fill uses the shared terrain palette and **resource glyphs** (g = grain, t = timber, i = iron) are drawn at tile centres. The geographic legend shows a **compact resource glyph reference** (all 18 letters in Resource.values order) and **per-region resource counts** (OW and NW) in format `OW: g12 m8 ...`, `NW: t8 s20 ...` (only resources with count > 0). Hovering over the resource glyph lines shows the **full resource legend** (letter = name for all 18 resources) in the right inspection panel.
  - **Per-cell inspection:** tap or hover shows region id, tile co-ordinates, **Province** (assigned province display name, or province/sea id if none), owner, terrain, resource. When the cell is a **capital tile**, the panel states **"Capital of [faction display name]."** and the Province line shows the capital name (e.g. London, Madrid).
  - Toggleable layers for ownership, borders, capitals, ports, and on-tile labels (e.g. region ids).

---

## Sim Game Integration

- **Init Game Map Debug Screen (pre–Start Game):**
  - Map (OW + NW), legend, toggles (Geographic, Ownership, Capitals, Ports), and **Start Game (Sim)** button only.
  - No Next Player, Resolve Turn, Next Turn, or Fast-forward 10 controls (those move to the Running Game Screen).

- **Start Game action:**
  - When an Init Game run completes (or a save is loaded), the Init Game Map Debug Screen shows a **Start Game (Sim)** button.
  - Pressing Start Game:
    - Takes the `Game` from the most recent `InitGameResult` (or loaded save).
    - Captures the current `MapTopology` and any tile-map data needed by `resolveTurnForGame`.
    - Chooses a deterministic `baseSeed` (from the init seed by default; optionally overridable via a small numeric field).
    - Creates a **Sim Game controller** in memory holding:
      - Current `Game`.
      - `MapTopology`.
      - `baseSeed`.
      - A small per-turn log (e.g. list of combat events and province flips).
    - **Navigates** to the **Running Game Screen** (separate route). The Sim Game controller and Game live in that screen's state.

---

## Running Game Screen

- **Entry:** Reached when the user presses Start Game (Sim) from the Init Game Map Debug Screen. The user may navigate back to Init Game Map Debug (e.g. via Back button) to inspect the map without running simulation.

- **Control bar (persistent):** Next Player | Resolve Turn | Next Turn | Fast-forward 10. Disabled while a turn or batch of turns is resolving.

- **Tabs:**

| Tab | Content |
|-----|---------|
| **Map** | OW + NW regions (as Init Map Debug). Sub-views: (1) **Default** — ownership/geographic, capitals, ports; (2) **Improvements** — per-tile improvement level and road level; (3) **Units** — army markers per province per player (province→representative tile mapping). Navy distinction deferred per mvp-scope. |
| **Game Overview** | Turn number, year; province counts per player; military strength per player (via [military-strength.md](military-strength.md)); diplomatic states (relations, overtures). |
| **Orders (AI history)** | Scrollable per-turn, per-Great Power view of orders generated for the sim run. For each GP (human or AI-controlled), lists movement, build, work, and diplomatic orders for that turn together with **order validation status** (accepted/rejected + reason) from [order-engine.md](order-engine.md). History is diagnostic only and does **not** affect turn resolution. |
| **Player (GP) tabs** | One tab per Great Power. Per player: stockpiles, research state (`techUnlocked`; stubs for `currentResearchTechId`, `researchableTechIds` — Phase 5); expected extraction + production (from [order-projections.md](order-projections.md) when available; otherwise current stockpile and worker count); pending orders for the current turn. |

- **Refresh:** All tabs read from `SimGameController.game` and `SimGameController.pendingOrdersByPlayerId`. On Next Player or Next Turn, the controller updates; the UI rebuilds and all tabs show updated data.

- **Research state (Phase 5 stubs):** Player tabs show `techUnlocked` (researched techs). `currentResearchTechId` (tech in progress) and `researchableTechIds` (next paths) are stubbed for Phase 5; display placeholder or empty until the full research system is implemented.

- **Sim Game controls** (on the Running Game Screen control bar):
  - **Player-by-player**:
      - A **Next Player** button that generates orders for the next Great Power using `defaultSimGameAi(...)`.
      - A **Resolve Turn** button that becomes enabled once all GPs have orders; it calls `resolveTurnForGame` once and advances the game by one full turn.
    - **Turn-by-turn**:
      - A **Next Turn** button that, when pressed, calls `defaultSimGameAi(...)` for every Great Power for the current turn, combines their orders, calls `resolveTurnForGame`, and refreshes the map and log.
    - **Fast-forward 10 turns**:
      - A **Fast-forward 10** button that runs 10 iterations of “AI for all GPs → resolveTurnForGame”, showing a simple in-UI progress indicator and then updating the map and an aggregated summary.

- **Display and logging:**
  - After each resolved turn, the screen updates:
    - The map, using the new `Game.worldState`.
    - A side or bottom panel listing:
      - Turn number and calendar year (if available).
      - Combat events (province, attacker, defender, winner, casualties, province flips).
  - For Fast-forward 10, the log may compress per-turn details into a short summary (e.g. “Turn 5–14: 7 battles, 3 province flips”).
  - Implementations may add a **Save sim log** button that writes the current run summary to a Markdown or JSON file in a chosen directory.
  - In addition, ctdev maintains an in-memory **AI order history** for the session: for each resolved turn and each Great Power, it records every generated order alongside the result of validating that order via `OrderEngine.validatePlayerOrdersWithContext(...)`. The **Orders (AI history)** tab renders this cumulative history grouped by turn and player, showing unit ids and types, origins/destinations or targets, and whether each order was accepted or rejected (with reason) by the validator.

---

## Relationship to init_game CLI

- `tool/init_game` remains a **headless CLI**:
  - Produces savegames (primary artifact), optional PNG, optional markdown.
  - Does **not** launch ctdev or any UI.
- ctdev is the **canonical visualization surface** for init_game outputs:
  - Developers can:
    - Run init-game flows directly inside ctdev, or
    - Generate saves via the CLI and load them into ctdev’s Load Savegame flow.

