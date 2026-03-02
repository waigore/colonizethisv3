# In-Game Shell Screen Specification

**SPEC/tui** — In-game shell for ctterm. Reference: [ctterm.md](../ctterm.md).

**Screen ID:** 100006

## Overview

Display the main game view with ASCII map, HUD, and navigation to panels (units, development, production, academy, shipyard, diplomacy, technology, victory/progress).

## Acceptance Criteria (Given-When-Then)

### G1: Map Display
- **Given** the player is in the in-game shell
- **When** the screen renders
- **Then** display an ASCII representation of the game map showing:
  - Land provinces (letters/numbers for owned territories)
  - Sea (dots or spaces)
  - Region borders (ASCII lines where applicable)
  - Province names for player's territories

### G2: HUD (Heads-Up Display)
- **Given** the player is in the in-game shell
- **When** the screen renders
- **Then** show at the top:
  - Current turn number and year
  - Selected province info (if any)
  - Player's treasury/resources summary

### G3: Panel Navigation
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

### G4: End Turn
- **Given** the player is in the in-game shell
- **When** pressing `Enter` or `E` to end turn
- **Then** simulate turn processing and update the display (show turn progress, then refresh map/HUD)

### G5: Pause/Options
- **Given** the player is in the in-game shell
- **When** pressing `Escape` or `O`
- **Then** navigate to Pause/Options screen

### G6: Main Menu Exit
- **Given** the player is in Pause/Options
- **When** selecting "Return to Main Menu"
- **Then** clear in-memory game state and navigate to Main Menu

## UI Layout (ASCII)

```
+----------------------------------------------------------+
| Turn: 3 | Year: 1850 | Treasury: $5000 | [Selected: None]|
+----------------------------------------------------------+
|                                                          |
|  [ASCII MAP AREA]                                        |
|                                                          |
|     Province map with ownership indicators              |
|                                                          |
+----------------------------------------------------------+
| Commands: [U]nits [D]ev [P]rod [A]cademy [S]hipyard     |
|           [I]ntl [T]ech [V]ictory [E]nd Turn [O]ptions  |
+----------------------------------------------------------+
```

## Implementation Notes

- Use `Nocterm` for rendering (like other ctterm screens)
- Map rendering: simplified ASCII grid, focus on player-owned provinces
- For MVP: static map display with province indicators
- Panel screens remain stubs for now
- Keyboard-first navigation per ctterm conventions
