# Turn-start news dialog

**Screen ID:** `DLG50001` — stable; do not reassign.
**Source:** #1478 + product 2026-04-03. **Trigger:** `TurnResolutionCompleteEvent` with `turnNumber >= 1`, `turnNewsDigest != null`, and loaded game `victory == null`. **Not shown** on initial map entry at turn 0 with no completed resolution. **Victory:** if `victory != null`, omit news (victory flow first).

**Mockup:** [mockups/DLG50001-turn-news-dialog.html](mockups/DLG50001-turn-news-dialog.html)
## Behavior

- Modal dialog listing one bullet per `TurnNewsLine` (formatted with faction/province/sea labels from current `Game`).
- **Empty digest:** show dialog with “No major events last turn.” (or equivalent l10n); the empty-state copy renders with `EditorialMonoclePalette.muted` so the dialog visibly distinguishes "nothing happened" from a regular news entry.
- **Wiring:** `GameToUIBusListener` emits `OpenDialogEvent` with dialog id `turn_news` and params after reload; no cross-panel callbacks. See `SPEC/program/app-ui-wiring.md`.

## Components

- **Dialog:** `TurnNewsDialog` — title references the resolved turn; scrollable list; primary **Close** / OK.
- **Widgetbook:** at least one story with sample lines + empty state; mobile viewport if layout differs.

## Styling (dark theme)

The dialog renders under the editorial-monocle dark theme catalog (`SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette) and the universal dialog pattern under #2867:

- The dialog host is `CtDialogShell` (no Material `AlertDialog`).
- Title text colour resolves to `EditorialMonoclePalette.accent` (display font slot from the dark theme).
- Regular news lines render with the inherited body text colour (`EditorialMonoclePalette.fg`).
- The "No major events last turn." empty-state line uses `EditorialMonoclePalette.muted` so the dialog visibly distinguishes "no events" from a populated digest.
- The Close action uses `CtNinePatchButton` (default brass styling); no Material `TextButton` / `ElevatedButton` is used in the dialog tree.

## Acceptance criteria

- **Given** the turn news dialog is built under `AppThemes.editorialMonocle` with a populated digest, **when** the widget tree is inspected, **then** the dialog uses `CtDialogShell` and contains no Material `AlertDialog` widget.
- **Given** the turn news dialog is built, **when** the title is inspected, **then** the resolved title text colour equals `EditorialMonoclePalette.accent`.
- **Given** the turn news dialog is built with an empty `TurnNewsDigest`, **when** the empty-state line is inspected, **then** the resolved text colour equals `EditorialMonoclePalette.muted` and the dialog still shows the Close action.
- **Given** the turn news dialog is built, **when** the action row is inspected, **then** the Close button is a `CtNinePatchButton` (no Material `TextButton` / `ElevatedButton`).

## Copy

Neutral diplomacy wording (no invented aggressor). Province ids in logic remain prefixed; UI may show `displayName` when present. **Province captured** bullets are only produced for **faction-to-faction** handovers (both previous and new owner non-empty); see [turn-news-digest.md](../program/turn-news-digest.md) and [world-model.md](../game/world-model.md) § Invariants.
