# In-Game Shell Screen Specification

**SPEC/tui** — In-game shell for ctterm. Reference: [ctterm.md](../ctterm.md).

**Screen ID:** 100006

## Overview

Display the main game view with a **topology-graph map area** (province graph with land connections), HUD, **province information panel**, and navigation to panels (units, development, production, academy, shipyard, diplomacy, technology, victory/progress).

## Map Area: Topology Graph

The map area is a **topology graph** of the current region’s **land provinces**, arranged in a grid-like pattern.

- **Nodes:** Each node is one **province** (land only; sea zones are not shown as nodes).
- **Edges:** Two provinces are connected by an edge if and only if they are **land-adjacent** (P–P) in the topology per [SPEC/game/map-topology.md](../../game/map-topology.md). Provinces separated by sea have no edge between them.
- **Layout:** The graph is arrayed in a **grid-like pattern** so that nodes occupy positions in a grid; connections between adjacent land provinces are shown (e.g. lines or explicit connection list).
- **Data source:** Topology comes from the game’s map data (e.g. combined topology from save/init). If topology is missing, the map area shows a fallback (e.g. “No topology” or a simple province list).

## Province Selection and Navigation

- The user can **navigate** the province graph: one province is **selected** (highlighted).
- **Movement:** The user moves the selection to a **neighbour** of the current province (a province connected by a land edge). Keys (e.g. arrow keys, number keys for neighbour index, or next/previous neighbour) move selection along the graph. If the current province has no land neighbours, movement does nothing.
- **Initial selection:** When the screen loads or the region changes, the first province (by a deterministic order) or the human player’s capital is selected, if any.

## Province Information Panel

- When a province is selected, the shell shows **basic information** for that province.
- **Content:** Reuse the same information as the Map Context screen’s province panel per [SPEC/tui/screens/map-context.md](map-context.md): province name (or prefixed id), owner (Great Power name or “Unclaimed”), terrain type, fort level, town/settlement level, visibility status (fog/revealed/fully visible). Omit tile-level detail; province-level only.

## Acceptance Criteria (Given-When-Then)

### G1: Topology Graph Map Area
- **Given** the player is in the in-game shell and topology is available for the current region
- **When** the screen renders
- **Then** the map area displays a topology graph of land provinces in a grid-like pattern, with edges only between land-adjacent provinces (no connections across sea).
- **Given** the player is in the in-game shell and topology is missing or empty
- **When** the screen renders
- **Then** the map area shows a fallback (e.g. “No topology” or a simple province list) so the screen remains usable.

### G2: Province Graph Navigation
- **Given** a province is selected in the in-game shell
- **When** the user presses the key(s) to move to a neighbour
- **Then** the selection moves to a land-adjacent province (if any); if there are multiple neighbours, keys choose among them (e.g. next/previous or 1–4).
- **Given** the selected province has no land neighbours
- **When** the user presses a neighbour-move key
- **Then** the selection does not change.

### G3: Province Information Panel
- **Given** a province is selected in the in-game shell
- **When** the screen renders
- **Then** the province information panel shows that province’s name/id, owner, terrain, fort level, town development level, and visibility (same content as Map Context province panel, province-level only).

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
- **Topology:** Use combined topology from game/save (passed into the screen). Filter to current region; use only province nodes and P–P edges for the graph. Province identity: [SPEC/game/world-model-identity.md](../../game/world-model-identity.md) (prefixed id, region-scoped lookup).
- **Layout:** Place province nodes in a grid (e.g. by row/column); draw or list connections between land-adjacent provinces. Neighbour-based navigation uses the same adjacency as movement (e.g. `neighborProvinceIdsInRegion` from colonizethis_logic).
- **Province info:** Reuse the same fields and layout as Map Context province panel (name, owner, terrain, fort, town dev, visibility); see [map-context.md](map-context.md).
- Keyboard-first navigation per ctterm conventions.
