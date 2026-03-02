# Load Game

**SPEC/tui/screens** — Load Game screen for ctterm. Reference: SPEC/tui/ctterm.md §1, SPEC/ui/main-menu.md (Load Game), SPEC/program/save-load.md.

**Screen ID:** 100003

---

## Widget contract

The Load Game screen is presentational and receives the following parameters. The **shell** supplies callbacks and handles navigation.

| Parameter | Type | Description |
|-----------|------|-------------|
| `saves` | `List<SaveSummary>` | List of available saves (may be empty). |
| `onLoad` | `void Function(String gameId)` | Invoked when user selects a save and confirms Load. |
| `onDelete` | `void Function(String gameId)` | Invoked when user selects a save and confirms Delete. |
| `onBack` | callback | Invoked when user presses Back. |

`SaveSummary` contains: `gameId` (String), `turnNumber` (int), `year` (int), `humanPlayerName` (String), `lastPlayedAt` (DateTime?).

---

## How this spec satisfies the TUI spec

**User stories.** The user navigates here from Main Menu "Load Game" (only enabled when saves exist). They see a list of saved games with metadata (turn, year, human player's nation/leader). They can select one and Load or Delete it. Back returns to Main Menu.

**Keyboard-first.** Navigation: arrow keys to move selection up/down, Enter to confirm action, Escape for back. Actions: L key to Load selected save, D key to Delete selected save (with confirmation), B or Escape to go Back.

**Acceptance criteria (Given–When–Then).**

- **Empty state:** Given no saves exist (should not happen if Main Menu disables Load correctly), the screen shows "No saved games" message and Back button.
- **Save list displayed:** Given saves exist, when the screen loads, the UI shows each save with: game id (or "Game 1", "Game 2" in order), turn number, year, human player's nation/leader name. Most recent save is first (or sorted by lastPlayedAt descending).
- **Selection:** Given a save is highlighted/selected, when the user presses L (or Enter while Load is focused), the widget invokes `onLoad` with that save's gameId.
- **Delete:** Given a save is highlighted/selected, when the user presses D, the widget shows a confirmation prompt "Delete save? (y/n)". If user confirms (y), invokes `onDelete` with that gameId and removes the save from the list. If user declines (n), returns to list.
- **Back:** When the user presses B or Escape, the widget invokes `onBack` once; the shell navigates to Main Menu.
- **TUI-specific:** Given the terminal is narrow (< 80 columns), the save info is truncated or wrapped; layout adapts to available width.

---

## Wireframe

```
+------------------------------------------+
|              Load Game                   |
|                                          |
|  > Game 1   Turn 12, 1650   England      |
|    Game 2   Turn 8, 1648    France       |
|    Game 3   Turn 5, 1645    Spain        |
|                                          |
|  [L] Load  [D] Delete  [B] Back          |
+------------------------------------------+
```

- `>` indicates selected row.
- `L` = Load selected, `D` = Delete selected (with confirm), `B` = Back.

---

## Interaction

The widget maintains selected index state. It does not perform routing; it exposes `onLoad(gameId)`, `onDelete(gameId)`, and `onBack`. No routing logic lives in the widget.

---

## Logging

Log prefix: `tui:save:` for load/delete operations. `tui:menu:` for navigation.