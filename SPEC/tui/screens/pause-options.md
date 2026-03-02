# Pause/Options Screen — TUI Spec

**SPEC/tui/screens** — Pause menu and options panel in ctterm. Full specification for TUI layout, navigation, and Given–When–Then acceptance criteria. Source of truth for pause/options screen behavior; adapts from SPEC/ui/main-menu.md return flow.

**Screen ID:** 100018

---

## Layout

```
┌─────────────────────────────────────────┐
│            === PAUSE ===                │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ > Exit to Main Menu               │  │
│  │   Settings                        │  │
│  │   (more options coming soon)      │  │
│  └───────────────────────────────────┘  │
│                                         │
│  [Esc/B] Back to Game  [Enter] Select   │
└─────────────────────────────────────────┘
```

### Layout Details

- **Header:** Title "=== PAUSE ===", centered
- **Menu Items:** Vertical list of options:
  - "Exit to Main Menu" (primary, with `>` indicator for selected)
  - "Settings" (future: terminal theme settings)
- **Selection Indicator:** `>` prefix on selected item
- **Footer:** Keyboard shortcuts

### Responsive Behavior

- **Narrow terminal (<60 cols):** Same vertical layout; reduce padding; items remain selectable
- **Short terminal (<18 rows):** Scrollable if more options added; ensure "Exit to Main Menu" always visible

---

## Navigation

| From → To | Trigger | Behavior |
| ---------- | ------- | -------- |
| Shell → Pause | `Escape` or `P` key (global hotkey) | Open Pause/Options as overlay or screen |
| Pause → Shell | `Escape` or `B` | Close pause, resume game |
| Select item | `Up`/`Down` or `W`/`S` | Navigate menu items |
| Confirm | `Enter` | Execute selected action |
| Exit to Main Menu | Confirm on "Exit to Main Menu" | Navigate to Main Menu, clear game state |

---

## Given–When–Then Acceptance Criteria

### Opening Pause Menu

- **Given** the player is in the in-game shell with the game map visible
- **When** the player presses `Escape` or `P`
- **Then** the Pause/Options screen appears overlaying or replacing the map
- **And** the game state is preserved (paused)

- **Given** the terminal is narrow (e.g., 40 columns)
- **When** the player opens Pause menu
- **Then** the menu renders without horizontal overflow
- **And** all menu items remain selectable

### Navigating Menu

- **Given** the Pause menu is open with "Exit to Main Menu" selected
- **When** the player presses `Down` or `S`
- **Then** "Settings" becomes the selected item
- **And** the `>` indicator moves to "Settings"

- **Given** "Settings" is selected
- **When** the player presses `Up` or `W`
- **Then** "Exit to Main Menu" becomes selected again

### Exiting to Main Menu

- **Given** the Pause menu is open with "Exit to Main Menu" selected
- **When** the player presses `Enter`
- **Then** the game displays a confirmation prompt: "Exit to Main Menu? Any unsaved progress will be lost. [Y] Yes / [N] No"
- **And** the game waits for confirmation

- **Given** the confirmation prompt is shown
- **When** the player presses `Y` or `Enter`
- **Then** the game navigates to the Main Menu
- **And** the in-memory game state is cleared
- **And** any active saves remain unaffected

- **Given** the confirmation prompt is shown
- **When** the player presses `N` or `Escape`
- **Then** the confirmation prompt closes
- **And** the Pause menu remains open with "Exit to Main Menu" selected

### Returning to Game

- **Given** the Pause menu is open
- **When** the player presses `Escape` or `B`
- **Then** the Pause menu closes
- **And** the in-game shell resumes with the map visible
- **And** the game continues from where it left off

---

## Game State

- **Paused state:** When Pause menu is open, turn resolution does not advance. Orders remain queued but not processed.
- **Clear on exit:** When exiting to Main Menu, the shell clears `WorldState`, `Game`, and any loaded player data from memory. Save files on disk are not modified.

---

## Future Options (Not in MVP)

- Terminal theme selection (light/dark/palette name)
- Sound toggle (if TUI supports audio)
- Display mode (fullscreen terminal, etc.)
- Help/controls reference

---

## Keyboard Shortcuts Summary

| Key | Action |
| -----| ------- |
| `Escape` | Open Pause menu (from game) / Back (from pause) |
| `P` | Alternative: Open Pause menu |
| `B` | Alternative: Back to game |
| `Up` / `W` | Select previous menu item |
| `Down` / `S` | Select next menu item |
| `Enter` | Confirm / Execute selected action |
| `Y` | Confirm exit to Main Menu |
| `N` | Cancel exit to Main Menu |