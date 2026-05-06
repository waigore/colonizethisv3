# Next turn confirmation dialog

**SPEC/ui** — Confirmation dialog when player clicks the "Next turn" button. Authority: GDD/TDD; derives from in-game-shell-narrow.md.

---

## Overview

When the player clicks the "Next turn" button in the top bar, a confirmation dialog appears asking them to confirm moving to the next turn. This prevents accidental clicks that trigger turn resolution.

---

## UI/UX

- **Trigger:** Player clicks "Next turn" button in the top bar (game_screen.dart line 677-682).
- **Dialog:** Uses `CtDialogShell` with pixel-art nine-patch frame (per buttons-nine-patch.md).
- **Content:**
  - Title: "End turn?" or "Proceed to next turn?"
  - Body text: "Turn {N} will end. Continue?"
  - Actions: "No" (abort), "Yes" (confirm)
- **Styling:** Matches existing confirm dialogs (e.g., civilian_units_panel.dart `_confirmCancel`). Uses `CtNinePatchButton` for actions. No Material chrome.

---

## Interaction flow

1. Player clicks "Next turn" button.
2. Confirmation dialog appears with "No" and "Yes" buttons.
3. Player clicks "No" → dialog closes, turn does not advance.
4. Player clicks "Yes" → dialog closes, the system enters turn-resolution active state.
5. During turn-resolution active state, the UI shows a non-dismissible modal titled `Processing Turn`.
6. After turn resolution completes or fails, the modal closes and controls return to normal.

### Turn-resolution active state (slice 1)

- Scope: this slice covers UI gating and completion/error handling around existing turn resolution execution.
- Deferred: worker-isolate execution and per-phase live text updates are handled in later slices.
- While active:
  - The top-bar Next Turn button is disabled.
  - Map interaction inputs are blocked.
  - Hamburger menu remains available from the top bar.
  - The modal cannot be dismissed by outside tap or back/escape.

---

## Acceptance criteria

- **Given** the player is on the game screen, **when** they click the "Next turn" button, **then** a confirmation dialog appears.
- **Given** the confirmation dialog is shown, **when** the player clicks "No", **then** the dialog closes and the turn does not advance.
- **Given** the confirmation dialog is shown, **when** the player clicks "Yes", **then** the dialog closes and the system enters turn-resolution active state.
- **Given** the dialog is shown, **when** the player presses Escape or taps outside the dialog, **then** it behaves as "No" (aborts).
- **Given** turn-resolution active state is true, **when** the game map is visible, **then** the UI shows a modal titled `Processing Turn` and the modal is not dismissible by outside tap or back/escape.
- **Given** turn-resolution active state is true, **when** the player attempts to press Next Turn, **then** the Next Turn button is disabled and no second resolution starts.
- **Given** turn-resolution active state is true, **when** the player interacts with map content, **then** the map interaction is blocked while the hamburger menu remains available.
- **Given** turn resolution reaches terminal success or terminal failure, **when** the terminal outcome is processed, **then** the processing modal closes and turn-resolution active state becomes false.

---

## Implementation notes

- Implementation: modify `_onNextTurn` in `app/lib/features/game/flame/game_screen.dart`.
- Use `showDialog<bool>` with `CtDialogShell` (same pattern as `_confirmCancel` in civilian_units_panel.dart).
- The existing turn number should be shown in the dialog body text.
