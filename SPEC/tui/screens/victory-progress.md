# Victory/Progress Screen

**SPEC/tui/screens/victory-progress.md** — TUI-specific Victory/Progress screen per SPEC/tui/ctterm.md.

## Overview

Victory/Progress screen showing human player's progress toward victory and standings of all Great Powers. Reference: [SPEC/game/victory.md](../../game/victory.md).

## UI/UX

- **Layout:** Progress table and legend, stacked on narrow terminals.
- **Navigation:** Back to In-Game Shell via Escape key.
- **Keyboard-first:** All actions via keyboard shortcuts.

## Functionality

### G1: Victory Condition Display

- **Given** the user opens the Victory/Progress screen
- **When** viewing the victory condition
- **Then** display:
  - Victory type (Military victory for MVP)
  - Threshold: 31 or more Old World provinces controlled

### G2: Great Power Progress Table

- **Given** the user is on the Victory/Progress screen
- **When** viewing the progress table
- **Then** show for each Great Power:
  - Great Power name
  - Number of Old World provinces controlled
  - Progress bar toward 31 threshold
  - Percentage complete

### G3: Progress Sorting

- **Given** the user is on the Victory/Progress screen
- **When** the progress table is displayed
- **Then** sort Great Powers by province count (descending)
- **And** highlight the human player

### G4: Human Player Highlight

- **Given** the user is on the Victory/Progress screen
- **When** displaying the progress table
- **Then** highlight the human player's row (e.g., different color)
- **And** indicate if the human is leading

### G5: Victory Detection

- **Given** the user is on the Victory/Progress screen
- **When** any Great Power reaches 31+ Old World provinces
- **Then** trigger the appropriate end-game screen:
  - If human wins → Victory Screen
  - If AI wins → Defeat Screen

### G6: Turn End Check

- **Given** a turn ends
- **When** victory conditions are checked per SPEC/game/victory.md
- **Then** display game events for victory/defeat
- **And** navigate to appropriate screen when triggered

## Acceptance Criteria

- [ ] Victory/Progress screen displays title
- [ ] Victory condition (31 OW provinces) is shown
- [ ] Progress table shows all Great Powers
- [ ] Each GP shows province count and progress bar
- [ ] Table is sorted by province count (descending)
- [ ] Human player is highlighted
- [ ] Leading GP is indicated
- [ ] Escape key returns to In-Game Shell
- [ ] Works on narrow terminals (stacked layout fallback)
- [ ] Victory triggers Victory Screen when human wins
- [ ] Defeat triggers Defeat Screen when AI wins

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Escape / b | Back to In-Game Shell |

## Data Source

- Province counts come from game state during End-of-turn phase per [SPEC/program/turn-resolution-phase-details.md](../../program/turn-resolution-phase-details.md)
- Victory check runs once per turn after all phases complete
- Use prefixed province id (`regionId|localId`) per [SPEC/game/world-model-identity.md](../../game/world-model-identity.md)
