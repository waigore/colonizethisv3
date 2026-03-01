# Settings screen

**SPEC/tui/screens/settings.md** — TUI-specific Settings screen per SPEC/tui/ctterm.md.

## Overview

Settings screen for terminal-specific options. MVP includes only terminal theme selection.

## UI/UX

- **Layout:** Single column, vertically stacked. Title at top.
- **Navigation:** Back to Main Menu via Escape key or explicit Back option.
- **Theme options:** At minimum, offer Light and Dark themes.

## Functionality

### Terminal Theme

- **Given** the user opens the Settings screen
- **When** they view available terminal themes
- **Then** they see at least "Light" and "Dark" options

### Theme Selection

- **Given** the user is on the Settings screen
- **When** they select a theme (e.g., press key for the option)
- **Then** the theme is applied immediately
- **And** the selection is visually indicated (e.g., highlighted or checked)

### Back Navigation

- **Given** the user is on the Settings screen
- **When** they press Escape or select Back
- **Then** they return to the Main Menu

## Acceptance Criteria

- [ ] Settings screen displays title
- [ ] At least two theme options (Light, Dark) are shown
- [ ] User can select a theme via keyboard
- [ ] Selected theme is visually indicated
- [ ] Escape key returns to Main Menu
