# Defeat Screen

**SPEC/tui/screens/defeat.md** — TUI-specific Defeat screen per SPEC/tui/ctterm.md.

## Overview

Defeat screen shown when another Great Power wins the game (human player loses). Reference: [SPEC/game/victory.md](../../game/victory.md).

## UI/UX

- **Layout:** Centered content with defeat message, winner info, and options.
- **Navigation:** Keyboard selection between options.
- **Keyboard-first:** All actions via keyboard shortcuts.

## Functionality

### G1: Defeat Message

- **Given** the game ends with an AI victory
- **When** the Defeat screen displays
- **Then** show:
  - "DEFEAT" banner (red color)
  - "You have been defeated!" message
  - Winner's name and that they conquered the New World

### G2: Victory Information

- **Given** the Defeat screen displays
- **When** showing winner information
- **Then** display:
  - Winner's display name
  - Victory type (e.g., "Military Victory")
  - Turn number when achieved

### G3: Final Standings

- **Given** the Defeat screen displays
- **When** showing final standings
- **Then** list all Great Powers:
  - Sorted by province count (descending)
  - Show rank, name, and province count
  - Highlight the winner (human is defeated)

### G4: Option Selection

- **Given** the Defeat screen displays
- **When** user navigates options
- **Then** allow selection between:
  - View Final Map
  - Return to Main Menu

### G5: Confirm Selection

- **Given** the user has selected an option
- **When** pressing Enter
- **Then** execute the selected action:
  - "View Final Map" → navigate to In-Game Shell
  - "Return to Main Menu" → exit to Main Menu and clear game state

### G6: Escape Navigation

- **Given** the Defeat screen displays
- **When** pressing Escape
- **Then** navigate to In-Game Shell (View Final Map)

## Acceptance Criteria

- [ ] Defeat screen displays "DEFEAT" banner in red
- [ ] Shows "You have been defeated!" message
- [ ] Displays winner's name and victory type
- [ ] Shows turn number when achieved
- [ ] Displays final standings (all GPs sorted by provinces)
- [ ] User can select "View Final Map" option
- [ ] User can select "Return to Main Menu" option
- [ ] Enter key confirms selection
- [ ] Escape key returns to In-Game Shell
- [ ] Game state is cleared when returning to Main Menu

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| v | Select "View Final Map" |
| m | Select "Return to Main Menu" |
| Enter / e | Confirm selection |
| Escape | Back to In-Game Shell |

## Data Source

- Winner information comes from `Game.victory` state set during End-of-turn phase per [SPEC/game/victory.md](../../game/victory.md)
- Final standings calculated from province ownership counts
- Tie-breaking uses lexicographically smallest player id per SPEC/game/victory.md
