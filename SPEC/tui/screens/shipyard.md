# Shipyard Screen

**SPEC/tui/screens/shipyard.md** — TUI-specific Shipyard screen per SPEC/tui/ctterm.md.

**Screen ID:** 100012

## Overview

Shipyard screen for constructing naval units. Displays available ship types (merchant and warship based on researched tech), allows building new ships, and shows the construction queue. Reference: [SPEC/game/ships-and-naval.md](../../game/ships-and-naval.md), [SPEC/game/tech-tree-naval.md](../../game/tech-tree-naval.md).

## UI/UX

- **Layout:** Split view - available ship types list on left, construction queue/details on right (or stacked on narrow terminals).
- **Navigation:** Back to In-Game Shell via Escape key.
- **Ship display:** Show available ship types, costs, stats, and current construction progress.
- **Keyboard-first:** All actions via keyboard shortcuts.

## Functionality

### Available Ship Types

- **Given** the user opens the Shipyard screen
- **When** viewing available ship types
- **Then** display each ship type showing:
  - Ship name and category (Merchant or Warship)
  - Build cost (gold, resources)
  - Tech requirement (if any)
  - Key stats: FRP (firepower), RNG (range), ARM (armour), HULL, MV (movement), Cargo (merchant only)
  - "Available" or "Locked" status based on researched tech

### Tech-Based Availability

- **Given** the user's empire has researched certain naval technologies
- **When** the Shipyard displays ship types
- **Then** only show ship types as "Available" if their unlocking tech is in the player's `techUnlocked` set per SPEC/game/tech-tree-naval.md
- **And** show "Locked" with required tech name for unavailable ships

### Ship Categories

- **Given** the user is viewing available ship types
- **When** listing ships
- **Then** organize them by category:
  - **Merchant ships:** Carrack, Fluyte, Trader, Galleon, Indiaman, Clipper, Merchant Steamship
  - **Warships:** Sloop, Frigate, Ship-of-the-Line, Raider, Ironclad

### Select Ship Type

- **Given** the user is on the Shipyard screen
- **When** they navigate to a ship type and select it
- **Then** show detailed information:
  - Full stats (FRP, RNG, ARM, HULL, MV, Cargo if applicable)
  - Category and era
  - Build cost
  - Required tech
  - Available actions (Build)

### Issue Build Order

- **Given** the user has selected an available ship type
- **When** they issue a Build order for a specific province (with shipyard)
- **Then** the order is validated:
  - Check tech unlock (must be researched)
  - Check gold/resources availability
  - Check shipyard capacity in target province
- **And** display validation result (accepted/rejected with reason)
- **And** note that new ships spawn into the home fleet at the capital port

### Construction Queue Display

- **Given** the user has active build orders
- **When** viewing the Shipyard
- **Then** display the construction queue showing:
  - Province with shipyard
  - Ship being built
  - Progress (turns remaining)
  - Queue position

### Cancel Build Order

- **Given** the user has a build order in the queue
- **When** they choose to cancel that order
- **Then** remove the order from the queue
- **And** refund resources if applicable
- **And** update the display

### Resource Validation

- **Given** the user attempts to build a ship
- **When** checking resource availability
- **Then** verify gold and any other required resources
- **And** display error message if insufficient: "Insufficient gold: need X, have Y"

### Construction Progress

- **Given** a ship is under construction
- **When** turns progress
- **Then** show construction progress in the queue
- **And** when complete, add the ship to the province's naval units (spawns in home fleet)

### Home Fleet Display

- **Given** the user wants to see their home fleet
- **When** viewing the Shipyard
- **Then** optionally display the current home fleet composition:
  - Ships in port (home fleet)
  - Total cargo capacity (sum of cargoHold values)
  - Ships at sea (organized by fleet)

### Naval Mission Assignment (Future)

- **Given** the user has ships in a fleet
- **When** assigning missions (Patrol, Blockade, Beachhead, Defend)
- **Then** note: Shipyard handles construction; fleet missions are assigned in the Units screen
- **And** display a note or link indicating fleet management is in Units

## Acceptance Criteria

- [ ] Shipyard screen displays title
- [ ] Available ship types are listed with stats and costs
- [ ] Locked ships show required tech
- [ ] Tech unlocks correctly filter available ships
- [ ] User can select a ship type via keyboard
- [ ] Selected ship shows detailed stats panel
- [ ] User can issue Build order to valid province
- [ ] User can cancel build orders from queue
- [ ] Construction queue shows progress
- [ ] Insufficient resources show error message
- [ ] New ships spawn into home fleet
- [ ] Escape key returns to In-Game Shell
- [ ] Works on narrow terminals (stacked layout fallback)

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Arrow keys / j/k | Navigate ship list |
| Enter / Space | Select ship |
| b | Build selected ship (prompts for province) |
| c | Cancel selected build order |
| h | Toggle home fleet display |
| Escape | Back to In-Game Shell |
