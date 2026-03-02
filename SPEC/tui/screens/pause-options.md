# Pause/Options Screen — TUI Spec

**SPEC/tui/screens** — Pause menu and options panel in ctterm. Source of truth for pause/options screen behavior. Adapts from [SPEC/ui/main-menu.md](../../ui/main-menu.md) return flow. Reference: [ctterm.md](../ctterm.md).

**Screen ID:** 100018

---

## 1. What the Pause Menu Is

- **Purpose:** A modal-like screen shown during a running game that lets the player pause, change terminal settings, or quit the current game and return to the main menu.
- **When it appears:** Only when the player is in the **in-game shell** (screen 100006) and presses the open-pause keys. The game is not ended; turn resolution does not advance while the menu is open; orders remain queued.
- **When it closes:** The player either resumes the game (Back), goes to Settings then returns to Pause or game, or exits to Main Menu (with confirmation). Save files on disk are never modified by opening or closing the menu.

---

## 2. How to Open and Close

| Action | Keys | Result |
|--------|------|--------|
| Open Pause (from in-game shell only) | `Escape`, `O`, or `P` | Pause/Options screen is shown; game state preserved. |
| Close Pause and resume game | `Escape` or `B` | Pause closes; in-game shell (100006) is shown again. |
| Confirm selected menu item | `Enter` | Runs the action for the currently selected item (see §4). |

---

## 3. On-Screen Elements (in order, top to bottom)

| Element | Description | Behavior |
|---------|-------------|----------|
| **Header** | Single line: `=== PAUSE ===` | Title only; no interaction. |
| **Menu list** | Vertical list of selectable items (see §4). | One item is selected; `>` marks the selected row. |
| **Footer** | Short hint line(s). | Shows: `[Esc/B] Back to Game  [Enter] Select` and `[W/S or Up/Down] Navigate`. Display only. |

---

## 4. Menu Items and What Each Does

| # | Label | When selected and user presses Enter |
|---|--------|--------------------------------------|
| 1 | **Exit to Main Menu** | Show the exit-confirmation prompt (§5). Does not exit immediately. |
| 2 | **Settings** | Navigate to the Settings screen (100005). When the user leaves Settings (Back), they return to the Pause menu (game still paused). |

No other menu items are required for MVP. Additional options (e.g. Help) may be added later; see §9.

---

## 5. Exit-to–Main-Menu Confirmation

- **When shown:** Only when the user selects "Exit to Main Menu" and presses Enter.
- **Content:** Two lines of text plus one hint line:
  - `Exit to Main Menu?`
  - `Any unsaved progress will be lost.`
  - `[Y] Yes  [N] No`
- **Behavior:**
  - **Y** or **Enter:** Navigate to Main Menu; clear in-memory game state (world, orders, etc.). Save files on disk are not modified.
  - **N** or **Escape:** Close the confirmation; stay on Pause menu with "Exit to Main Menu" still selected.

---

## 6. Navigation Within the Menu

| Key | Action |
|-----|--------|
| `Up` or `W` | Select the previous menu item (wrap not required). |
| `Down` or `S` | Select the next menu item. |
| `Enter` | Execute the selected item’s action (§4). |
| `Escape` or `B` | Close Pause and return to in-game shell (resume game). |

---

## 7. Keyboard Shortcuts Summary

| Key | Context | Action |
|-----|---------|--------|
| `Escape` | In-game shell | Open Pause. |
| `Escape` | Pause menu | Back to game. |
| `Escape` | Exit confirmation | Cancel exit (stay in Pause). |
| `O` | In-game shell | Open Pause. |
| `P` | In-game shell | Open Pause. |
| `B` | Pause menu | Back to game. |
| `W` / `Up` | Pause menu | Previous menu item. |
| `S` / `Down` | Pause menu | Next menu item. |
| `Enter` | Pause menu | Execute selected item. |
| `Enter` | Exit confirmation | Confirm exit (Yes). |
| `Y` | Exit confirmation | Confirm exit (Yes). |
| `N` | Exit confirmation | Cancel exit (No). |

---

## 8. Acceptance Criteria (Given–When–Then)

### Opening and closing

- **Given** the player is in the in-game shell with the game map visible  
- **When** the player presses `Escape`, `O`, or `P`  
- **Then** the Pause/Options screen (100018) is shown and the game state is preserved.

- **Given** the Pause menu is open  
- **When** the player presses `Escape` or `B`  
- **Then** the Pause menu closes and the in-game shell is shown again.

### Menu navigation

- **Given** the Pause menu is open with "Exit to Main Menu" selected  
- **When** the player presses `Down` or `S`  
- **Then** "Settings" becomes selected and the `>` indicator moves to it.

- **Given** "Settings" is selected  
- **When** the player presses `Up` or `W`  
- **Then** "Exit to Main Menu" becomes selected.

### Exit to Main Menu

- **Given** the Pause menu is open with "Exit to Main Menu" selected  
- **When** the player presses `Enter`  
- **Then** the confirmation prompt is shown: "Exit to Main Menu? Any unsaved progress will be lost. [Y] Yes  [N] No".

- **Given** the confirmation prompt is shown  
- **When** the player presses `Y` or `Enter`  
- **Then** the app navigates to the Main Menu and in-memory game state is cleared; save files are unchanged.

- **Given** the confirmation prompt is shown  
- **When** the player presses `N` or `Escape`  
- **Then** the prompt closes and the Pause menu remains open with "Exit to Main Menu" selected.

### Settings from Pause

- **Given** the Pause menu is open  
- **When** the player selects "Settings" and presses `Enter`  
- **Then** the Settings screen (100005) is shown.

- **Given** the player opened Settings from the Pause menu  
- **When** the player presses Escape or Back on the Settings screen  
- **Then** the app returns to the Pause menu (100018), not the Main Menu, and the game remains paused.

### Narrow terminal

- **Given** the terminal is narrow (e.g. 40 columns)  
- **When** the Pause menu is open  
- **Then** the menu renders without horizontal overflow and all items remain selectable.

---

## 9. Game State and Future Options

- **While Pause is open:** Turn resolution does not advance; orders remain queued.
- **On "Exit to Main Menu":** The shell clears `Game`, `WorldState`, and loaded player data from memory; it does not delete or overwrite save files.

Future options (not in MVP): terminal theme from Pause (already reachable via Settings), sound toggle, help/controls reference.
