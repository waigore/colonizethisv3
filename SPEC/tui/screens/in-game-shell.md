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

### G4: HUD (Heads-Up Display)
- **Given** the player is in the in-game shell
- **When** the screen renders
- **Then** show at the top:
  - Current turn number and year
  - Current region (Old World / New World) and way to cycle (e.g. R)
  - Player's treasury/resources summary

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
- **Given** the player is in the in-game shell
- **When** pressing `Enter` or `E` to end turn
- **Then** simulate turn processing and update the display (show turn progress, then refresh map/HUD)

### G7: Pause/Options
- **Given** the player is in the in-game shell
- **When** pressing `Escape`, `O`, or `P`
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
|  [TOPOLOGY GRAPH]          |  Province Info              |
|  Nodes = provinces,        |  Name: ...                  |
|  edges = land-adjacent     |  Owner: ...                 |
|  (grid-like layout)        |  Terrain / Fort / Town      |
|  Selected node highlighted |  Visibility: ...            |
+----------------------------------------------------------+
|  [M]ap Context [R]egion [U]nits [D]ev [P]rod ...        |
+----------------------------------------------------------+
```

## Implementation Notes

- Use `Nocterm` for rendering (like other ctterm screens).
- **Topology:** Use combined topology from game/save (passed into the screen). Filter to current region; use only province nodes and P–P edges for the land graph. Province identity: [SPEC/game/world-model-identity.md](../../game/world-model-identity.md) (prefixed id, region-scoped lookup).
- **Layout:** Render a centered view: compute the selected province (human capital when available, otherwise first province) and show it as the center; compute its neighbours via `neighborProvinceIdsInRegion` from colonizethis_logic and render them to the right with index keys `1`–`9`. Neighbour-based navigation uses the same adjacency as movement.
- **Sea-bound detection:** A province is sea-bound when, in the combined topology, its node has at least one P–S edge to a sea zone node in the same region (per [SPEC/game/capital-choice-phase.md](../../game/capital-choice-phase.md)). The graph view appends `*` to the province name and the panel shows `Seabound: Yes` when this is true.
- **Great Power colours:** When `Game.greatPowerColorOverride` provides RGB triples for Great Powers, the TUI maps those colours to the nearest terminal palette colours and uses them to colour province names in the graph. When no override is present for an owner, the TUI may fall back to a neutral colour.
- **Province info:** Reuse the same fields and layout as Map Context province panel (name, owner, terrain, fort, town dev, visibility); see [map-context.md](map-context.md).
- Keyboard-first navigation per ctterm conventions.
