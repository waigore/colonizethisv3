# Development Screen

**SPEC/tui/screens/development.md** — TUI-specific Development screen per SPEC/tui/ctterm.md.

**Screen ID:** 100009

## Overview

Development screen for managing civilian unit work orders (Builders, Engineers). Displays working units, allows assigning work tasks (improvements, roads, ports, forts, rails), and shows work progress. Reference: [SPEC/program/development-resolution.md](../../program/development-resolution.md), [SPEC/game/civilian-units.md](../../game/civilian-units.md).

## UI/UX

- **Layout:** Split view - civilian unit list on left, work assignment panel on right (or stacked on narrow terminals).
- **Navigation:** Back to In-Game Shell via Escape key.
- **Unit display:** Show civilian units with current work status and progress.
- **Keyboard-first:** All actions via keyboard shortcuts.

## Functionality

### Civilian Unit List Display

- **Given** the user opens the Development screen
- **When** viewing the civilian unit list
- **Then** display each civilian unit showing:
  - Province location (using prefixed province id per SPEC/game/world-model-identity.md)
  - Unit type (Builder, Engineer)
  - Current status (idle/working)
  - Current work target and progress (if working)

### Select Civilian Unit

- **Given** the user is on the Development screen
- **When** they navigate to a civilian unit and select it
- **Then** show detailed information:
  - Unit type and stats
  - Current position
  - Current work (if any) with remaining turns
  - Available work targets for this unit

### Assign Work Order

- **Given** the user has selected an idle civilian unit
- **When** they assign a work order (build_improvement, build_road, build_port, build_fort, build_rail, upgrade_town)
- **Then** the order is validated:
  - Check unit type eligibility for work target
  - Check target tile exists and is owned by player
  - Check terrain eligibility for the work type
  - Check tech prerequisites (e.g., Road Construction for transport level 2)
  - Check material availability (costs deducted on assignment)
- **And** display validation result (accepted/rejected with reason)

### Work Progress Display

- **Given** a civilian unit is working
- **When** viewing the unit in the list
- **Then** show:
  - Work target type
  - Target tile location
  - Progress: remaining turns / total turns
  - Visual indicator of completion percentage

### Cancel Work Order

- **Given** the user has selected a working civilian unit
- **When** they choose to cancel the current work
- **Then** clear the work order:
  - Set status to idle
  - Clear currentWork
  - Note: materials are NOT refunded (per SPEC/program/development-resolution.md)
- **And** update the display

### Work Completion

- **Given** a civilian unit completes its work
- **When** the Build/Work phase resolves
- **Then** the work effect is applied:
  - build_improvement: increase improvement level on tile
  - upgrade_town: increase province town development level
  - build_road: set/upgrade transport level (0→1→2)
  - build_port: create port mapping, set transport level 4
  - build_fort: increase province fort level
  - build_rail: upgrade road to railroad (transport level 4)
- **And** display completion notification via game events

### Order Validation Feedback

- **Given** the user assigns a work order
- **When** the order is validated
- **Then** show feedback:
  - Accepted: work started, materials deducted, visual confirmation with total turns
  - Rejected: error message with reason (e.g., "Invalid: insufficient lumber", "Invalid: Road Construction tech required for level 2 roads")

## Acceptance Criteria

- [ ] Development screen displays title
- [ ] Civilian units are listed with province, type, status
- [ ] Working units show progress (remaining/total turns)
- [ ] User can select a civilian unit via keyboard
- [ ] Selected unit shows detail panel with work info
- [ ] User can assign work order to idle unit
- [ ] Work order validation checks unit type, tile, tech, materials
- [ ] Validation feedback shown (accepted/rejected with reason)
- [ ] User can cancel working unit's orders (no refund)
- [ ] Work completion applies correct effect per work type
- [ ] Escape key returns to In-Game Shell
- [ ] Works on narrow terminals (stacked layout fallback)

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Arrow keys / j/k | Navigate civilian unit list |
| Enter / Space | Select unit |
| i | Assign build_improvement order |
| r | Assign build_road order |
| p | Assign build_port order |
| f | Assign build_fort order |
| R | Assign build_rail order |
| u | Assign upgrade_town order |
| x | Cancel current work order |
| Escape | Back to In-Game Shell |

## TUI-Specific Cases

- **Given** the terminal is 80×24
- **When** the user opens the Development screen
- **Then** the panel is shown and the map remains in the shell

- **Given** the terminal is narrow (< 60 columns)
- **When** the user opens the Development screen
- **Then** use stacked layout (unit list above detail panel) instead of split view
