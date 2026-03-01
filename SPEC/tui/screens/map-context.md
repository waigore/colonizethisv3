# Map Context Screen

**SPEC/tui/screens/map-context.md** — TUI-specific Map/Province Context screen per SPEC/tui/ctterm.md.

## Overview

Map context screen showing detailed province information, map layers, visibility, and region navigation. Reference: [SPEC/program/player-view.md](../../program/player-view.md), [SPEC/program/map-visualization.md](../../program/map-visualization.md), [SPEC/game/world-model-identity.md](../../game/world-model-identity.md).

## UI/UX

- **Layout:** Split view - map on left/top, context panel on right/bottom (or stacked on narrow terminals).
- **Navigation:** Back to In-Game Shell via Escape key.
- **Keyboard-first:** All actions via keyboard shortcuts.

## Functionality

### G1: Province Selection

- **Given** the user is on the Map Context screen
- **When** navigating to a province on the map
- **Then** display province information:
  - Province name (using prefixed province id per SPEC/game/world-model-identity.md)
  - Owner (Great Power name or "Unclaimed")
  - Terrain type
  - Resource extraction (if any)
  - Town/settlement level (if any)
  - Visibility status (fog/revealed/fully visible)

### G2: Map Layers

- **Given** the user is on the Map Context screen
- **When** toggling map layers
- **Then** show/hide:
  - Terrain layer (default on)
  - Ownership layer (shows province control by Great Power)
  - Town/settlement markers (default on)
  - Visibility fog of war

### G3: Visibility Display

- **Given** the user is viewing a province
- **When** the province is in fog of war
- **Then** show "???" for unknown information and indicate fog status
- **When** the province is revealed but not owned
- **Then** show terrain and owner but indicate "revealed only"
- **When** the province is fully visible
- **Then** show all available information

### G4: Region Cycling

- **Given** the user is on a narrow terminal
- **When** cycling between regions
- **Then** allow navigation between:
  - Old World
  - New World
  - Any other defined regions
- **And** show current region indicator

### G5: Map Scrolling

- **Given** the user is on the Map Context screen
- **When** using arrow keys or vi keys (h/j/k/l)
- **Then** scroll the map viewport
- **And** maintain province selection if within visible area

### G6: Tile Information

- **Given** the user is viewing a specific tile within a province
- **When** selecting a tile
- **Then** display:
  - Tile coordinates (x, y within province)
  - Terrain type
  - Improvement (if any: roads, farms, mines)
  - Visible units on tile (if any)

## Acceptance Criteria

- [ ] Map Context screen displays ASCII/Unicode map
- [ ] User can navigate to provinces via keyboard
- [ ] Selected province shows detailed information
- [ ] Map layers can be toggled (terrain, ownership, towns, fog)
- [ ] Fog of war correctly shows/unshows information
- [ ] Region cycling works (Old World, New World, etc.)
- [ ] Map scrolling works on narrow terminals
- [ ] Tile-level information is displayable
- [ ] Escape key returns to In-Game Shell

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Arrow keys / h/j/k/l | Navigate/scroll map |
| Tab / w/s | Cycle selection (province/tile) |
| 1-4 | Toggle map layers |
| r | Cycle regions (OW/NW) |
| Enter / Space | Select province/tile |
| Escape | Back to In-Game Shell |
