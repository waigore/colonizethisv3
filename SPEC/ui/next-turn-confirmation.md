# Next turn confirmation dialog

**Screen ID:** `DLG60001` — stable; do not reassign.
**SPEC/ui** — Confirmation dialog when player clicks the "Next turn" button. Authority: GDD/TDD; derives from in-game-shell-narrow.md.

**Mockup:** [mockups/DLG60001-next-turn-confirmation.html](mockups/DLG60001-next-turn-confirmation.html)
---

## Overview

When the player clicks the "Next turn" button in the top bar, a confirmation dialog appears asking them to confirm moving to the next turn. This prevents accidental clicks that trigger turn resolution.

---

## UI/UX

- **Trigger:** Player clicks "Next turn" in the top bar (`game_screen.dart` when the map overlay is hidden, and the map control when the map is shown).
- **Dialog:** Uses `CtDialogShell` with pixel-art nine-patch frame (per buttons-nine-patch.md).
- **Content:**
  - Title: "End turn?" or "Proceed to next turn?"
  - Body text: "Turn {N} will end. Continue?"
  - Actions: "No" (abort), "Yes" (confirm)
- **Styling:** Matches the editorial-monocle dark theme catalog (`SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette) and the universal dialog pattern under #2867:
  - Title text colour resolves to `EditorialMonoclePalette.accent` (display font slot from the dark theme).
  - Body text colour resolves to `EditorialMonoclePalette.fg` (body font slot from the dark theme).
  - Actions use `CtNinePatchButton`. The primary "Yes" (confirm) action keeps the default brass styling; the secondary "No" (cancel) action also uses `CtNinePatchButton` with default brass styling so both options are visually equivalent — confirm is the inferred default, but neither is destructive.
  - No Material chrome (`AlertDialog`, `TextButton`, `ElevatedButton`) anywhere in the dialog tree.

---

## Interaction flow

1. Player clicks "Next turn" button.
2. Confirmation dialog appears with "No" and "Yes" buttons.
3. Player clicks "No" → dialog closes, turn does not advance.
4. Player clicks "Yes" → dialog closes, the system enters turn-resolution active state.
5. During turn-resolution active state, the UI shows a non-dismissible modal titled `Processing Turn`.
6. After the worker isolate delivers a **terminal** success or error to the app runner (`session.done` resolves), the **`Processing Turn` modal closes immediately** so the UI does not linger on a late resolver label (for example “Finalizing turn…”) while the main isolate still performs synchronous persistence and `TurnResolutionResult` application. If that follow-up work fails, error handling still applies; `turnResolutionBlocking` ends with the same `finally` path as before. Refs **#2277**.

### Turn-resolution active state (slice 1)

- Scope: this slice covers UI gating and completion/error handling around existing turn resolution execution.
- Deferred: any remaining entry points that still run Full AI or trusted resolution on the main isolate are migrated incrementally (Refs **#2277**).
- While active:
  - The top-bar Next Turn button is disabled.
  - Map interaction inputs are blocked.
  - Hamburger menu remains available from the top bar.
  - The modal cannot be dismissed by outside tap or back/escape.

### Turn-resolution active state (slice 2)

- Scope: this slice moves heavy turn-resolution execution to a worker isolate and streams live phase labels into the processing modal.
- **Map and Flame-canvas next-turn paths (`TurnResolutionRunner`):** Full AI order generation and **`mergeOrderLists`** run **inside the same worker isolate** as trusted-path resolution so the main UI thread only serializes inputs, spawns the worker, and applies the terminal result (Refs **#2277**). Any other entry points must be migrated the same way when added.
- After the shell schedules the non-dismissible `Processing Turn` dialog, it **awaits [SchedulerBinding.endOfFrame](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/endOfFrame.html)** via **`awaitTurnResolutionProcessingDialogFirstPaint`** (`turn_resolution_progress_labels.dart`) so the modal can paint **before** `TurnResolutionRunner.startResolution` begins main-isolate spawn-payload serialization.
- The worker emits per-phase start/end progress events through a typed callback (`TurnPhaseProgressMarker`) and the UI updates phase text on `start` (including synthetic **`aiPlanning`** before Full AI runs, then **`suggestionPools`**, **`aiStageA`**–**`aiStageG`**, **`aiMerge`**, and resolver phases).
- Terminal success and terminal failure both close the modal as soon as the terminal event is delivered; success then applies the resolved result on the main isolate (persist, providers) and failure shows the existing error snackbar.
- Existing pending-human-input outcomes (overture/intervention/call-to-arms) remain valid terminal outputs for post-resolution UI flow.

---

## Acceptance criteria

- **Given** the player is on the game screen, **when** they click the "Next turn" button, **then** a confirmation dialog appears.
- **Given** the confirmation dialog is shown, **when** the player clicks "No", **then** the dialog closes and the turn does not advance.
- **Given** the confirmation dialog is shown, **when** the player clicks "Yes", **then** the dialog closes and the system enters turn-resolution active state.
- **Given** the dialog is shown, **when** the player presses Escape or taps outside the dialog, **then** it behaves as "No" (aborts).
- **Given** turn-resolution active state is true, **when** the game map is visible, **then** the UI shows a modal titled `Processing Turn` and the modal is not dismissible by outside tap or back/escape.
- **Given** turn-resolution active state is true, **when** the Flame canvas is visible (map overlay hidden), **then** the UI shows the same non-dismissible `Processing Turn` modal until resolution completes or fails.
- **Given** turn-resolution active state is true, **when** the player attempts to press Next Turn, **then** the Next Turn button is disabled and no second resolution starts.
- **Given** turn-resolution active state is true, **when** the player interacts with map content, **then** the map interaction is blocked while the hamburger menu remains available.
- **Given** turn resolution reaches terminal success or terminal failure, **when** the terminal event is delivered to the UI handler, **then** the processing modal closes **before** synchronous main-isolate apply/persist work begins, and turn-resolution active state becomes false in the same cleanup path as today.
- **Given** the confirmation dialog is built under `AppThemes.editorialMonocle`, **when** the widget tree is inspected, **then** the dialog uses `CtDialogShell` (no Material `AlertDialog`), the title text colour resolves to `EditorialMonoclePalette.accent`, and the body text colour resolves to `EditorialMonoclePalette.fg`.
- **Given** the confirmation dialog is built, **when** the action row is inspected, **then** both the abort and confirm actions are rendered with `CtNinePatchButton` (no Material `TextButton` / `ElevatedButton`) and use the default brass label colour.

---

## Implementation notes

- Map next turn: `_onNextTurn` in `app/lib/features/game/flame/game_map_area_turn_resolution.dart` uses `TurnResolutionRunner` and `showNextTurnConfirmationDialog`.
- Flame canvas next turn: `game_screen.dart` uses the same runner, confirmation dialog, and `TurnResolutionProcessingDialog` pattern.
- Confirmation uses `showDialog<bool>` with `CtDialogShell` (same pattern as `_confirmCancel` in civilian_units_panel.dart).
- The existing turn number should be shown in the confirmation dialog body text.
