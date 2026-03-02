# Game Setup

**SPEC/tui/screens** — Game Setup screen for ctterm. Reference: SPEC/tui/ctterm.md §1, SPEC/ui/game-setup.md.

**Screen ID:** 100002

---

## Widget contract

The Game Setup screen is presentational and receives the following parameters. The **shell** supplies callbacks and handles navigation. There are **six player slots**; slot 0 is the **human player**, slots 1–5 are **AI**. For each slot the user selects **nation (GP)** then **leader**; leaders are tied to the selected nation. Nations already chosen in one slot are not available in another.

| Parameter | Type | Description |
|-----------|------|-------------|
| `onStartGame` | `void Function(List<String> orderedGpIdsForSlots, Map<String, String> leaderVariantByGpId)` | Invoked when user selects Start Game with all slots complete. Passes ordered list of 6 gpIds (slot 0 = human, 1–5 = AI) and leader map. |
| `onBack` | callback | Invoked when user presses Back. |

The screen uses `defaultNamingConfig` from `colonizethis_data` for nations and leaders.

---

## How this spec satisfies the TUI spec

**User stories.** The user navigates here from Main Menu "New Game". They see six player slots: Player 1 (You) and Players 2–6 (AI). For each slot they select a nation from a dropdown, then a leader for that nation. Start Game is disabled until every slot has both a nation and a leader selected. Back returns to Main Menu.

**Keyboard-first.** Navigation: Tab/Shift+Tab to move between slots and buttons. Arrow keys in dropdowns. Enter to confirm selection/start. Escape for back. `[A]` auto-assigns nations (and default leaders) to any empty slots from top to bottom using the first available nation per slot, without changing already-selected nations.

**Acceptance criteria (Given–When–Then).**

- **Display:** Given the user navigated from Main Menu via New Game, the screen shows "Game Setup", six player-slot rows, Start Game button, and Back button. Slot 1 is labeled "Player 1 (You)" (human); slots 2–6 are labeled "Player 2-6 (AI)". Each row has a nation dropdown and a leader dropdown.
- **Initial state unselected:** Given a fresh load, all nation/leader choices are unselected. Each slot shows "Select nation" and "Select leader" (or leader disabled). Start Game is disabled.
- **Start disabled until complete:** Given one or more slots have no nation or leader selected, Start Game remains disabled. When all six slots have both nation and leader selected, Start Game becomes enabled.
- **No duplicate nations:** When the user opens the nation dropdown for any slot, only nations not already selected in another slot are listed.
- **Leader follows nation:** When a slot's nation changes, the leader dropdown updates to that nation's leader variants and resets to the default leader for that nation.
- **Start:** Given all six slots have nation and leader selected, when the user presses Start Game (or Enter), the widget invokes `onStartGame` with (1) ordered list of six gpIds (index 0 = human) and (2) map gpId → leaderVariantId.
- **Back:** When the user presses B or Escape, the widget invokes `onBack` once; the shell navigates to Main Menu.
 - **Auto-assign empty slots:** Given one or more slots have no nation selected and at least one Great Power is not yet assigned to any slot, when the user presses A, then the UI layer assigns to each empty slot, in top-to-bottom slot order, the first Great Power from the naming config that is not already assigned in another slot and sets that nation's leader to its default leader variant.
 - **Auto-assign when no GP available:** Given a slot has no nation selected and all Great Powers from the naming config are already assigned in other slots, when the user presses A, then the UI layer leaves that slot's nation and leader unselected.
 - **Auto-assign with all slots filled:** Given all six slots already have a nation and leader selected, when the user presses A, then the UI layer leaves all slot selections unchanged.

---

## Wireframe

```
+------------------------------------------+
|              Game Setup                   |
|                                          |
|  Player 1 (You)  [Select nation    ▼]    |
|                  [Select leader    ▼]    |
|  Player 2 (AI)   [Select nation    ▼]    |
|                  [Select leader    ▼]    |
|  Player 3 (AI)   [Select nation    ▼]    |
|                  [Select leader    ▼]    |
|  ... (all six slots)                     |
|                                          |
|  [S] Start Game  (disabled until ready)  |
|  [B] Back                                 |
+------------------------------------------+
```

- Use `[S]` for Start Game, `[B]` for Back.
- Show `>` indicator on currently selected slot/row.
- Disabled Start Game shown grayed out.

---

## Interaction

The widget maintains per-slot state (ordered list of six gpIds and leader variant per gpId). It does not perform routing; it exposes `onStartGame(orderedGpIdsForSlots, leaderVariantByGpId)` and `onBack`. No routing logic lives in the widget.

---

## Logging

Log prefix: `tui:setup:` for game setup interactions. `tui:nav:` for navigation.
