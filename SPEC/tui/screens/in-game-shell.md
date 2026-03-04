# In-Game Shell Screen Specification

**SPEC/tui** — In-game shell for ctterm. Reference: [ctterm.md](../ctterm.md).

**Screen ID:** 100006

## Overview

Display the main game view with a **topology-graph map area** (province graph with land connections), HUD, **province information panel**, and navigation to panels (units, development, production, academy, shipyard, diplomacy, technology, victory/progress).

## Map Area: Topology Graph

The map area is a **topology graph** of the current region’s **land provinces**, rendered as a **centered province + neighbour list** view.

- **Nodes:** Each node is one **province** (land only; sea zones are not shown as nodes).
- **Edges:** Two provinces are connected by an edge if and only if they are **land-adjacent** (P–P) in the topology per [SPEC/game/map-topology.md](../../game/map-topology.md). Provinces separated by sea have no edge between them.
- **Layout (centered view):**
  - One province is the **center** (the “currently viewed” province).
  - All **land neighbours** (P–P edges from the center) are listed to the **right** of the center as a **vertical neighbour list** (one neighbour per line).
  - Each neighbour entry shows a **hotkey index** (1–9) and the neighbour province name.
  - If a province is **sea-bound** (has at least one P–S edge in the topology per [SPEC/game/capital-choice-phase.md](../../game/capital-choice-phase.md)), its name in the graph has a trailing `*` (asterisk).
- **Colouring:** Province names in the graph are **colour-coded** by the owning Great Power’s colour:
  - When `Game.greatPowerColorOverride` provides a colour for the owner’s player id, the TUI uses a **nearest terminal colour** to that RGB triple (per [SPEC/program/map-visualization.md](../../program/map-visualization.md) ownership colours).
  - When no override is present, the TUI may fall back to a neutral default colour (e.g. gray/white) for that owner.
- **Data source:** Topology comes from the game’s map data (combined topology from save/init). If topology is missing, the map area shows a fallback (e.g. “No topology” plus a simple province count) so the screen remains usable.

## Province Selection and Navigation

- The user can **navigate** the province graph: one province is **selected** (highlighted as the center of the view).
- **Movement (neighbour cycling):** The user moves the selection to a **neighbour** of the current province (a province connected by a land edge). Keys `j` / `←` move to the **previous** neighbour; `l` / `→` move to the **next** neighbour around the neighbour list. If the current province has no land neighbours, these movement keys do nothing.
- **Movement (direct neighbour hotkeys):** Each neighbour in the list is assigned a **number key** `1`–`9` corresponding to its index in the list; pressing that digit moves selection directly to that neighbour province (if it exists).
- **Initial selection:** When the screen loads or the region changes, the **human player’s capital** in the current region is selected if it exists and is present in the land graph; otherwise the first province (by a deterministic order) is selected.

## Province Information Panel

- When a province is selected, the shell shows **basic information** for that province.
- **Content:** Reuse the same information as the Map Context screen’s province panel per [SPEC/tui/screens/map-context.md](map-context.md): province name (or prefixed id), owner (Great Power name or “Unclaimed”), terrain type, fort level, town/settlement level, visibility status (fog/revealed/fully visible). Omit tile-level detail; province-level only.
- **Sea-bound indicator:** The panel shows whether the selected province is **sea-bound** (has at least one P–S edge in the topology within the current region). When sea-bound, the panel labels it clearly (e.g. `Seabound: Yes (coastal)`); this matches the `*` marker used in the graph view.
- **Improved tiles count:** The panel shows how many **land tiles in the selected province** currently have an **improvement level > 0** in the world tile state (per [SPEC/game/tile-map-and-generation.md](../../game/tile-map-and-generation.md)). This is displayed as a simple numeric field (e.g. `Improved tiles: 3`) and updates as improvements are built or removed.

## Acceptance Criteria (Given-When-Then)

### G1: Topology Graph Map Area
- **Given** the player is in the in-game shell and topology is available for the current region
- **When** the screen renders
- **Then** the map area displays a topology graph of land provinces as a **centered province + neighbour list** view, with edges only between land-adjacent provinces (no connections across sea), and the selected province is rendered at the center with its neighbours listed to the right.
- **Given** the player is in the in-game shell and topology is missing or empty
- **When** the screen renders
- **Then** the map area shows a fallback (e.g. “No topology” or a simple province list) so the screen remains usable.

### G2: Province Graph Navigation
- **Given** a province is selected in the in-game shell
- **When** the user presses the key(s) to move to a neighbour
- **Then** the selection moves to a land-adjacent province (if any); if there are multiple neighbours, `j` / `←` move to the previous neighbour and `l` / `→` move to the next neighbour in the neighbour list.
- **Given** the selected province has no land neighbours
- **When** the user presses a neighbour-move key
- **Then** the selection does not change.
- **Given** a province is selected in the in-game shell and it has N land neighbours (1 ≤ N ≤ 9)
- **When** the user presses number key `k` where 1 ≤ k ≤ N
- **Then** the selection moves directly to the neighbour at index `k` in the neighbour list and the centered province updates accordingly.

### G3: Province Information Panel
- **Given** a province is selected in the in-game shell
- **When** the screen renders
- **Then** the province information panel shows that province’s name/id, owner, terrain, fort level, town development level, a **sea-bound indicator** (Yes/No, based on presence of at least one P–S edge in the topology for the current region), and visibility (same content as Map Context province panel, province-level only).

### G3b: Province Improvement Summary
- **Given** a province is selected in the in-game shell and the game world state includes tile-state data for that province
- **When** the screen renders the province information panel
- **Then** the panel shows a line `Improved tiles: N` where `N` is the number of land tiles whose full tile key belongs to that province (per `tileKeysByRegionAndProvince` and [SPEC/game/world-model-identity.md](../../game/world-model-identity.md)) and whose improvement level in the tile state is strictly greater than zero.

### G4: HUD (Heads-Up Display)
- **Given** the player is in the in-game shell
- **When** the screen renders
- **Then** show at the top:
  - Current turn number and year:
    - Turn number comes from `Game.worldState.turnState.turnNumber`
    - Year is derived via `turnToYear(Game.worldState.turnState.turnNumber, Game.turnTimeMapping)` per [SPEC/game/turn-time-mapping.md](../../game/turn-time-mapping.md), falling back to the default mapping when `turnTimeMapping` is null (legacy saves)
  - Current region (Old World / New World) and way to cycle (e.g. R)
  - Player's treasury/resources summary

- **Given** a game with a non-null `turnTimeMapping`
- **When** the HUD is shown for turn `N`
- **Then** the year displayed equals `turnToYear(N, Game.turnTimeMapping)` as defined in [SPEC/game/turn-time-mapping.md](../../game/turn-time-mapping.md)

### G5: Panel Navigation
- **Given** the player is in the in-game shell
- **When** pressing keyboard shortcuts
- **Then** navigate to respective panels:
  - `U` → Units screen
  - `D` → Development screen
  - `P` → Production screen
  - `A` → Academy screen
  - `S` → Shipyard screen
  - `I` → Diplomacy screen (I for Intl/Relations)
  - `T` → Technology screen
  - `V` → Victory/Progress screen

### G6: End Turn
- **Given** the player is in the in-game shell and there are **no idle civilian units** for the human player (all civilian units have a work order or none exist)
- **When** pressing `Enter` or `E` to end turn
- **Then** simulate turn processing and update the display (show turn progress, then refresh map/HUD)
-
- **Given** the player is in the in-game shell and there is **at least one idle civilian unit** for the human player (a Builder/Engineer-family unit owned by the human player with **no** work order in `Orders.workOrdersByPlayerId` for that player)
- **When** pressing `Enter` or `E` to end turn
- **Then** the shell does **not** immediately resolve the turn but instead shows a confirmation prompt indicating how many civilian units are idle and asking whether to end the turn anyway (e.g. `X civilian unit(s) are idle. End turn anyway? [Y]es [N]o`); only when the player confirms (e.g. `Y` or `Enter`) does the shell simulate turn processing and refresh the HUD/map.

### G6b: Idle Civilian Definition (In-game Shell)
- **Given** the in-game shell needs to determine whether civilian units are idle before ending the turn
- **When** evaluating the human player’s units
- **Then** a unit counts as a **civilian** when its type is treated as a Builder/Engineer family per the development spec (e.g. unit type string contains `builder` or `engineer`, case-insensitive), and it counts as **idle** when there is **no** corresponding entry for its `unitId` in `Orders.workOrdersByPlayerId[humanPlayerId]`.

### G7: Pause/Options
- **Given** the player is in the in-game shell
- **When** pressing `Escape`, `O`, or `X`
- **Then** navigate to Pause/Options screen

### G8: Main Menu Exit
- **Given** the player is in Pause/Options
- **When** selecting "Return to Main Menu"
- **Then** clear in-memory game state and navigate to Main Menu

## UI Layout (ASCII)

```
+----------------------------------------------------------+
| Turn: 3 | Year: 1850 | Treasury: $5000 | Region: OW [R] |
+----------------------------------------------------------+
|  [MAP GRID viewport]         |  Province Info              |
|  Layer: Terrain [ ]=layer; centered on selected province |  Name: ...                  |
|  [TOPOLOGY GRAPH]             |  Owner: ...                  |
|  (grid-like layout)        |  Terrain / Fort / Town      |
|  Selected node highlighted |  Visibility: ...            |
+----------------------------------------------------------+
|  [M]ap Context [R]egion [U]nits [D]ev [P]rod ...        |
+----------------------------------------------------------+
```

## Map Grid Widget (Empire Overview)

The map area **complements** the topology graph with a **map grid widget** that shows the current region as an ASCII tile grid. The grid uses a **viewport** that **centers on the selected province** (the same province shown as the center of the topology graph). Scrolling is **indirect**: when the user switches province via the graph (j/l or arrows to cycle neighbours, **1–9** to jump to a neighbour), the grid viewport updates to center on the newly selected province. There are **no keys for manual viewport scrolling**.

### Behaviour

- **Content:** The widget displays the **entire** region's tile map in ASCII (one character per tile). Data source: same as [SPEC/tui/map-tui-mapping.md](../map-tui-mapping.md) (terrain, ownership, resources, visibility). Province and tile identity: [SPEC/game/world-model-identity.md](../../game/world-model-identity.md) (prefixed province id, tile key `regionId|localId|x|y`).
- **Viewport:** The visible area is a rectangle of fixed size (e.g. terminal lines × columns). The full region may be larger. The viewport **centers on the selected province** when possible: the selected province’s tile centroid (from `tileKeysByRegionAndProvince`) is used to compute viewport offset so that province appears centered; offset is clamped so the viewport never shows out-of-bounds cells. When the user changes the selected province (via topology graph navigation), the grid viewport updates to center on the new province. There are **no manual scroll keys**.
- **Layers:** The user can switch between **four** display layers:
  - **Terrain** — terrain type per tile (sea, plains, forest, hills, mountain, swamp, desert) per map-tui-mapping.
  - **Political** — province ownership (Great Power / minor / tribe / unclaimed) per map-tui-mapping.
  - **Resources** — resource type per tile (when present) using resource glyphs per map-tui-mapping; empty tiles show terrain as fallback.
  - **Unit locations** — tiles that contain at least one unit show a unit symbol (e.g. `U` or type initial); other tiles show terrain as fallback. Units with `tileKey` are placed at that tile; units without `tileKey` use a representative tile of their province (e.g. first tile in `tileKeysByRegionAndProvince`).
- **Layer switching:** Keys **[** and **]** cycle the active layer (Terrain → Political → Resources → Units → Terrain). The current layer is indicated in the widget (e.g. "Layer: Terrain"). The topology graph uses **j**/**l** or **arrow keys** for neighbour cycle and **1–9** for direct neighbour selection so key bindings do not conflict.
- **Placement:** The map grid is shown **above** the topology graph in the same map area column so both are visible without switching screens.

### Acceptance criteria (Given–When–Then)

- **Given** the player is in the in-game shell and the current region has a tile map  
  **When** the screen renders  
  **Then** the map area shows the map grid widget above the topology graph, with the viewport displaying a subset of the region's tiles in ASCII centered (as much as possible) on the selected province, and the current layer label.

- **Given** the player is in the in-game shell with a province selected and the map grid is visible  
  **When** the user changes the selected province via the topology graph (e.g. j/l or arrows to cycle neighbours, or **1–9** to select a neighbour)  
  **Then** the map grid viewport updates to center on the newly selected province (using that province’s tile centroid from `tileKeysByRegionAndProvince`), so that the grid and graph stay in sync with no manual scroll keys.

- **Given** the user is viewing the map grid  
  **When** the user presses **[** or **]** to cycle layer  
  **Then** the active layer changes (Terrain → Political → Resources → Units → Terrain), and the grid and layer label update accordingly.

- **Given** the user is on the unit locations layer  
  **When** a tile contains one or more units  
  **Then** that tile displays a unit symbol (e.g. `U`); tiles without units show the terrain character.

## Implementation Notes

- Use `Nocterm` for rendering (like other ctterm screens).
- **Turn-time mapping:** HUD year uses the game's turn-time mapping (`Game.turnTimeMapping`) via `turnToYear` from `colonizethis_logic` per [SPEC/game/turn-time-mapping.md](../../game/turn-time-mapping.md). When `turnTimeMapping` is missing (legacy/older saves), the default mapping is used as defined in that spec.
- **Topology:** Use combined topology from game/save (passed into the screen). Filter to current region; use only province nodes and P–P edges for the land graph. Province identity: [SPEC/game/world-model-identity.md](../../game/world-model-identity.md) (prefixed id, region-scoped lookup).
- **Layout:** Render a centered view: compute the selected province (human capital when available, otherwise first province) and show it as the center; compute its neighbours via `neighborProvinceIdsInRegion` from colonizethis_logic and render them to the right with index keys `1`–`9`. Neighbour-based navigation uses the same adjacency as movement.
- **Sea-bound detection:** A province is sea-bound when, in the combined topology, its node has at least one P–S edge to a sea zone node in the same region (per [SPEC/game/capital-choice-phase.md](../../game/capital-choice-phase.md)). The graph view appends `*` to the province name and the panel shows `Seabound: Yes` when this is true.
- **Great Power colours:** When `Game.greatPowerColorOverride` provides RGB triples for Great Powers, the TUI maps those colours to the nearest terminal palette colours and uses them to colour province names in the graph. When no override is present for an owner, the TUI may fall back to a neutral colour.
- **Province info:** Reuse the same fields and layout as Map Context province panel (name, owner, terrain, fort, town dev, visibility); see [map-context.md](map-context.md).
- Keyboard-first navigation per ctterm conventions.
