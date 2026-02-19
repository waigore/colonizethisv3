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
  - The Init Game Config form includes a **colour dropdown per selected Great Power** (section "Map colour (per Great Power)"), defaulting to the GDD default colour for that GP (see GDD 09 Great Powers & Leaders). The value is overridable. If the user selects a colour already assigned to another selected GP, the two GPs' colours are **swapped** to avoid clashes. The chosen map is passed as `greatPowerColorOverride` in `InitGameOptions` and stored in `InitGameResult` for use by the Init Game Map Debug and Running Game screens. Ownership colours in the map view use this override when present; otherwise GDD defaults apply.
  - On submit:
    - Validates basic constraints (e.g. OW provinces sufficient for configured Great Powers and Minor Nations, NW provinces sufficient for Tribes).
    - Calls `runInitGame(config, options)` in colonizethis_logic, passing an `InitGameOptions` instance that:
      - Uses a fixed `cellSize` suitable for debug visualization.
      - Forwards map-generation flags (e.g. `skipFillLakes`) when present.
      - Sets `renderPng` from the Render PNG checkbox so PNG rendering can be skipped entirely when not needed.
      - Sets `greatPowerColorOverride` from the Init form colour choices (subset for selected GPs).
    - Runs init_game on the **same isolate** as the UI but wraps it in a clear **loading/busy state**: the submit button is disabled and a lightweight overlay/spinner is shown while work runs. On desktop (macOS), this keeps the UX predictable while still allowing long-running generation; future versions may offload work to background isolates where platform support and message-safety constraints allow.
    - Receives `InitGameResult` including `game`, `mapPngBytes`, `markdown`, and `mapViewData`.
    - Saves the game via colonizethis_save to a user-chosen or ctdev-managed directory.
    - Navigates to the Init Game Map Debug screen with `InitGameMapViewData`.

- **Load Savegame:**
  - Allows selecting a previously saved game directory/file (e.g. produced by `tool/init_game` or ctdev itself).
  - Loads `Game` via colonizethis_save.
  - Resolves per-region tile maps and topology via colonizethis_data.
  - Builds `InitGameMapViewData` using colonizethis_map's builder, passing the game's `greatPowerColorOverride` (if any) so that ownership colours match the setup that was used when the game was created. When the save has no override (legacy or default setup), GDD default colours are used.
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
  - **Legend (ownership):** each faction is shown as **"displayName (factionId)"** (e.g. England (gp1), France (gp2), Italy (minor1), Aztec (tribe1)) so both human-readable name and short code are visible.
  - Province/sea borders, capitals (gold circles), ports (teal squares).
  - In **Geographic view**, terrain fill uses the shared terrain palette and **resource glyphs** (g = grain, t = timber, i = iron) are drawn at tile centres. The geographic legend shows a **compact resource glyph reference** (all 18 letters in Resource.values order) and **per-region resource counts** (OW and NW) in format `OW: g12 m8 ...`, `NW: t8 s20 ...` (only resources with count > 0). Hovering over the resource glyph lines shows the **full resource legend** (letter = name for all 18 resources) in the right inspection panel.
  - **Per-cell inspection:** tap or hover shows region id, tile co-ordinates, **Province** (assigned province display name, or province/sea id if none), owner, terrain, resource. When the cell is a **capital tile**, the panel states **"Capital of [faction display name]."** and the Province line shows the capital name (e.g. London, Madrid).
  - Toggleable layers for ownership, borders, capitals, ports, and on-tile labels (e.g. region ids).

---

## Sim Game Integration

- **Init Game Map Debug Screen (pre–Start Game):**
  - Map (OW + NW), legend, toggles (Geographic, Ownership, Capitals, Ports), a control to choose **which AI** for the sim run (**Sim Game AI** or **AI Planner**), and **Start Game (Sim)** button. When **AI Planner** is selected, the existing **Use full AI (Phase 6)** checkbox selects minimal vs full planner. This choice is passed to the Sim Game controller and applied to every GP.
  - No Next Player, Resolve Turn, Next Turn, or Fast-forward 10 controls (those move to the Running Game Screen).

- **Start Game action:**
  - When an Init Game run completes (or a save is loaded), the Init Game Map Debug Screen shows a **Start Game (Sim)** button.
  - Pressing Start Game:
    - Generates a **sim session ID** and creates a log file `logs/ctdev-sim-<sessionId>.log`. Any log events buffered since app start (e.g. init game, map) are written to this file; subsequent logging is appended to it. See [ctdev-logging.md](ctdev-logging.md).
    - Takes the `Game` from the most recent `InitGameResult` (or loaded save).
    - Sets `game.aiControlByGpId` so every Great Power is AI-controlled (e.g. `game.copyWith(aiControlByGpId: { for each GP: true })`), so sim has no human players.
    - Captures the current `MapTopology` and any tile-map data needed by `resolveTurnForGame`.
    - Chooses a deterministic `baseSeed` (from the init seed by default; optionally overridable via a small numeric field).
    - Ensures every Great Power has an `aiSeed` for seed derivation: if `game.aiSeedByGpId` is missing an entry for any GP, set it (e.g. from `baseSeed`) so that `turnSeed[P, T]` is well-defined for all Great Powers in sim (all are AI-controlled). This may require a one-time copy of the game with `aiSeedByGpId` populated for all players.
    - Creates a **Sim Game controller** in memory holding:
      - Current `Game` (with aiSeedByGpId filled as above).
      - `MapTopology`.
      - `baseSeed`.
      - A small per-turn log (e.g. list of combat events and province flips).
    - **Navigates** to the **Running Game Screen** (separate route). The Sim Game controller and Game live in that screen's state.
  - **Turn resolution in sim:** `resolveTurnForGame` runs the **full TurnResolver** (same phase order as the main game per [turn-resolution-phases.md](turn-resolution-phases.md)), including the **Naval Interception & Naval Combat** phase when naval is in scope. So naval movement, missions, interception, and sea battles are resolved in sim the same way as in the main game; naval features are fully usable by the sim game AI when Phase 6 naval and full AI are implemented.

---

## Running Game Screen

- **Entry:** Reached when the user presses Start Game (Sim) from the Init Game Map Debug Screen. The user may navigate back to Init Game Map Debug (e.g. via Back button) to inspect the map without running simulation.

- **Control bar (persistent):** The **session ID** and log file path (`logs/ctdev-sim-<sessionId>.log`) are shown so the user can locate the session log. Next Player | Resolve Turn | Next Turn | Fast-forward 10. Disabled while a turn or batch of turns is resolving.

- **Tabs:**

| Tab | Content |
|-----|---------|
| **Map** | OW + NW regions (as Init Map Debug). Sub-views: (1) **Default** — ownership/geographic, capitals, ports; (2) **Improvements** — per-tile improvement level and road level; (3) **Units** — army markers per province per player (province→representative tile mapping). When naval is in scope (Phase 6), the Units view also shows **fleet/navy** state (e.g. fleet locations by sea zone per player, mission icons) so developers can see AI naval positions and verify naval behaviour in sim. |
| **Game Overview** | Turn number, year; **owned province list per Great Power** (one line per GP, full list, comma-separated names, line wrap allowed); military strength per player (via [military-strength.md](military-strength.md)); diplomatic states (relations, overtures). **Monitored variables:** the **turn seed** used for AI order generation is displayed — for the current turn and for each Great Power, the value `turnSeed[P, T]` (e.g. per-player: gp1: 12345678, gp2: 87654321) so that developers can record it for reproducibility. |
| **Orders (AI history)** | Scrollable per-turn, per-Great Power view of orders generated for the sim run. For each GP, lists movement, build, work, diplomatic, and **naval orders** (fleet move, mission assignment: patrol/blockade/beachhead/defend) for that turn together with **order validation status** (accepted/rejected + reason) from [order-engine.md](order-engine.md). When naval combat occurs, naval combat outcomes (sea zone, sides, casualties) may be included in the same history or in the combat log. History is diagnostic only and does **not** affect turn resolution. |
| **Player (GP) tabs** | One tab per Great Power. Each tab shows a **per-player map** (OW + NW layout, same as Map tab) filtered by that player's knowledge via [player-view.md](player-view.md). **Per-player map:** Rendering by visibility — **Unknown:** tile black. **Revealed:** tile grey (boundary/owner known; terrain/resources not shown). **Fogged:** same colour scheme as full map (ownership/geographic), with a visible marker (e.g. grey diagonal stripes) to denote fogged; show capitals and ports. **Fully visible:** same as current map; show capitals and ports. Only the **viewing player's units** are shown (PlayerView exposes only that player's units). Capitals and ports are shown only for **fogged** and **fully visible** provinces, not for revealed. The Map tab remains the full (omniscient) debug view. Below the map: stockpiles, research state (`techUnlocked`; stubs for `currentResearchTechId`, `researchableTechIds` — Phase 5); expected extraction + production (from [order-projections.md](order-projections.md) when available; otherwise current stockpile and worker count); pending orders for the current turn; **available orders** (candidates from the [order suggestion API](order-engine.md) for the current turn, refreshed each turn). |

- **Refresh:** All tabs read from `SimGameController.game` and `SimGameController.pendingOrdersByPlayerId`. On Next Player or Next Turn, the controller updates; the UI rebuilds and all tabs show updated data.

- **Research state (Phase 5 stubs):** Player tabs show `techUnlocked` (researched techs). `currentResearchTechId` (tech in progress) and `researchableTechIds` (next paths) are stubbed for Phase 5; display placeholder or empty until the full research system is implemented.

- **Sim Game controls** (on the Running Game Screen control bar): The choice of which AI to use is made on the Init Game Map Debug screen before Start Game. Then:
  - **Player-by-player**:
      - A **Next Player** button that generates orders for the next Great Power using the **selected AI** (Sim Game AI or AI Planner) for that GP.
      - A **Resolve Turn** button that becomes enabled once all GPs have orders; it calls `resolveTurnForGame` once and advances the game by one full turn.
    - **Turn-by-turn**:
      - A **Next Turn** button that, when pressed, calls the **selected AI** for every Great Power for the current turn, combines their orders, calls `resolveTurnForGame`, and refreshes the map and log.
    - **Fast-forward 10 turns**:
      - A **Fast-forward 10** button that runs 10 iterations of “selected AI for all GPs → resolveTurnForGame”, showing a simple in-UI progress indicator and then updating the map and an aggregated summary.

- **Display and logging:**
  - After each resolved turn, the screen updates:
    - The map, using the new `Game.worldState`.
    - A side or bottom panel listing:
      - Turn number and calendar year (if available).
      - **Land combat events** (province, attacker, defender, winner, casualties, province flips).
      - **Naval combat events** (when naval is in scope): sea zone, attacking/defending fleets, winner, ship casualties, retreats.
  - For Fast-forward 10, the log may compress per-turn details into a short summary (e.g. “Turn 5–14: 7 battles, 3 province flips”; naval battles may be counted separately or combined).
  - **In-memory Sim Log panel:** Shows the **last 10 lines** at **info** level and above, **cleared at the start of each turn** (when resolving or stepping a full turn). Full detail (debug and above) is in the session log file; see [ctdev-logging.md](ctdev-logging.md).
  - In addition, ctdev maintains an in-memory **AI order history** for the session: for each resolved turn and each Great Power, it records every generated order alongside the result of validating that order via `OrderEngine.validatePlayerOrdersWithContext(...)`. The **Orders (AI history)** tab renders this cumulative history grouped by turn and player, showing unit ids and types, origins/destinations or targets, and whether each order was accepted or rejected (with reason) by the validator.
  - **Work orders** (civilian only): In both the **Available orders** (suggestion) list and the **Orders (AI history)** view, work orders must display the unit’s **current tile** (unit.tileKey) and **its province**; and the order’s **target tile** (WorkOrder.targetTileKey) and **its province**. Provinces are derived from the tileKey format (`regionId|provinceId|x|y`).

---

## Relationship to init_game CLI

- `tool/init_game` remains a **headless CLI**:
  - Produces savegames (primary artifact), optional PNG, optional markdown.
  - Does **not** launch ctdev or any UI.
- ctdev is the **canonical visualization surface** for init_game outputs:
  - Developers can:
    - Run init-game flows directly inside ctdev, or
    - Generate saves via the CLI and load them into ctdev’s Load Savegame flow.

