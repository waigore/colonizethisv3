# Units Screen

**SPEC/tui/screens/units.md** — TUI-specific Units screen per SPEC/tui/ctterm.md.

**Screen ID:** 100008

## Overview

Units screen for managing military and civilian unit orders. Displays unit stacks, allows issuing Move/Attack/Clear orders, and shows order validation feedback. Reference: [SPEC/program/order-engine.md](../../program/order-engine.md), [SPEC/game/combat.md](../../game/combat.md).

## UI/UX

- **Layout:** Split view - unit list on left, detail/orders panel on right (or stacked on narrow terminals).
- **Navigation:** Back to In-Game Shell via Escape key.
- **Unit display:** Show unit stacks per province with type, count, and status.
- **Keyboard-first:** All actions via keyboard shortcuts.

## Functionality

### Unit List Display

- **Given** the user opens the Units screen  
- **When** viewing the unit list  
- **Then** display each unit stack showing:
  - Province location using the province's human-friendly name (`Province.displayName`), or the prefixed province id per SPEC/game/world-model-identity.md when no display name is defined
  - Unit type (military/civilian)
  - Regiment count
  - Current orders (if any)

### Select Unit Stack

- **Given** the user is on the Units screen
- **When** they navigate to a unit stack and select it
- **Then** show detailed information:
  - Unit type and stats
  - Current position
  - Pending orders
  - Available actions

### Issue Move Order

- **Given** the user has selected a unit stack
- **When** they issue a Move order to a valid adjacent province
- **Then** the order is validated:
  - Check adjacency and ownership per movement rules
  - Check source and destination visibility per fog-of-war rules
- **And** display validation result (accepted/rejected with reason)

### Issue Attack Order

- **Given** the user has selected a military unit stack  
- **When** they issue an Attack order to an enemy-controlled province  
- **Then** the order is validated per combat rules:
  - Province must be enemy-controlled
  - Unit must have attack capability
  - Check visibility (fog of war rules)
- **And** display validation result

- **Given** the user has selected a non-military unit stack (e.g., Explorer, Builder, Engineer, Merchant, Spy)  
- **When** they attempt to issue an Attack order via the keyboard shortcut  
- **Then** the Units screen does not add or change any orders for that unit and instead shows a non-blocking error message explaining that the selected unit cannot attack

### Clear Order

- **Given** the user has selected a unit stack with pending orders
- **When** they choose to clear/remove orders
- **Then** remove all pending orders for that unit
- **And** update the display

### Order Validation Feedback

- **Given** the user issues an order
- **When** the order is validated
- **Then** show feedback:
  - Accepted: order added to queue, visual confirmation
  - Rejected: error message with reason (e.g., "Invalid: destination not adjacent", "Invalid: fog of war blocks target")

### Turn End

- **Given** the user ends the turn
- **When** orders are processed
- **Then** display combat results as game events per SPEC/program/game-events.md

## Acceptance Criteria

- [ ] Units screen displays title
- [ ] Unit stacks are listed with province (using province name or prefixed id), type, count
- [ ] User can select a unit stack via keyboard
- [ ] Selected unit shows detail panel
- [ ] Detail panel and any listed orders show provinces using province names (or prefixed ids when no name is defined), not opaque internal keys
- [ ] User can issue Move order to valid adjacent province
- [ ] User can issue Attack order to enemy province when the selected unit is military and can initiate combat
- [ ] User cannot successfully issue Attack orders for non-military units (Explorer, Builder, Engineer, Merchant, Spy); the screen instead shows a clear, non-blocking error message and leaves orders unchanged
- [ ] User can clear pending orders
- [ ] Order validation feedback is shown (accepted/rejected with reason)
- [ ] Escape key returns to In-Game Shell
- [ ] Works on narrow terminals (stacked layout fallback)

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Arrow keys / j/k | Navigate unit list |
| Enter / Space | Select unit |
| m | Issue Move order |
| a | Issue Attack order |
| c | Clear orders |
| Escape | Back to In-Game Shell |
