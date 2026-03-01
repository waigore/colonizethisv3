# Academy Screen

**SPEC/tui/screens/academy.md** — TUI-specific Academy screen per SPEC/tui/ctterm.md.

## Overview

Academy screen for training military regiments. Displays available regiment types (based on researched tech), allows recruiting new units, and shows the training queue. Reference: [SPEC/game/military-units.md](../../game/military-units.md), [SPEC/game/research-state.md](../../game/research-state.md).

## UI/UX

- **Layout:** Split view - available regiments list on left, training queue/details on right (or stacked on narrow terminals).
- **Navigation:** Back to In-Game Shell via Escape key.
- **Training display:** Show available regiment types, costs, and current training progress.
- **Keyboard-first:** All actions via keyboard shortcuts.

## Functionality

### Available Regiment Types

- **Given** the user opens the Academy screen
- **When** viewing available regiment types
- **Then** display each regiment type showing:
  - Regiment name and category
  - Build cost (gold, gold-equivalent)
  - Tech requirement (if any)
  - Tactical stats (FPN, FPM, DEF)
  - "Available" or "Locked" status based on researched tech

### Tech-Based Availability

- **Given** the user's empire has researched certain military technologies
- **When** the Academy displays regiment types
- **Then** only show regiment types as "Available" if their unlocking tech is in the player's `techUnlocked` set per SPEC/game/military-units.md
- **And** show "Locked" with required tech name for unavailable regiments

### Select Regiment Type

- **Given** the user is on the Academy screen
- **When** they navigate to a regiment type and select it
- **Then** show detailed information:
  - Full tactical stats (FPN, FPM, RNG, DEF, MVR)
  - Category and era
  - Training cost
  - Required tech
  - Available actions (Train)

### Issue Train Order

- **Given** the user has selected an available regiment type
- **When** they issue a Train order for a specific province (with training facility)
- **Then** the order is validated:
  - Check tech unlock (must be researched)
  - Check gold/resources availability
  - Check training capacity in target province
- **And** display validation result (accepted/rejected with reason)

### Training Queue Display

- **Given** the user has active training orders
- **When** viewing the Academy
- **Then** display the training queue showing:
  - Province with training facility
  - Regiment being trained
  - Progress (turns remaining)
  - Queue position

### Cancel Training Order

- **Given** the user has a training order in the queue
- **When** they choose to cancel that order
- **Then** remove the order from the queue
- **And** refund resources if applicable
- **And** update the display

### Resource Validation

- **Given** the user attempts to train a regiment
- **When** checking resource availability
- **Then** verify gold and any other required resources
- **And** display error message if insufficient: "Insufficient gold: need X, have Y"

### Training Progress

- **Given** a regiment is training
- **When** turns progress
- **Then** show training progress in the queue
- **And** when complete, add the regiment to the province's military units

## Acceptance Criteria

- [ ] Academy screen displays title
- [ ] Available regiment types are listed with stats and costs
- [ ] Locked regiments show required tech
- [ ] Tech unlocks correctly filter available regiments
- [ ] User can select a regiment type via keyboard
- [ ] Selected regiment shows detailed stats panel
- [ ] User can issue Train order to valid province
- [ ] User can cancel training orders from queue
- [ ] Training queue shows progress
- [ ] Insufficient resources show error message
- [ ] Escape key returns to In-Game Shell
- [ ] Works on narrow terminals (stacked layout fallback)

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Arrow keys / j/k | Navigate regiment list |
| Enter / Space | Select regiment |
| t | Train selected regiment (prompts for province) |
| c | Cancel selected training order |
| Escape | Back to In-Game Shell |
