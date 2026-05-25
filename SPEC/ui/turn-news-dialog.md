# Turn-start news dialog

**Screen ID:** `DLG50001` — stable; do not reassign.
**Source:** #1478 + product 2026-04-03. **Trigger:** `TurnResolutionCompleteEvent` with `turnNumber >= 1`, `turnNewsDigest != null`, and loaded game `victory == null`. **Not shown** on initial map entry at turn 0 with no completed resolution. **Victory:** if `victory != null`, omit news (victory flow first).

## Behavior

- Modal dialog listing one bullet per `TurnNewsLine` (formatted with faction/province/sea labels from current `Game`).
- **Empty digest:** show dialog with “No major events last turn.” (or equivalent l10n).
- **Wiring:** `GameToUIBusListener` emits `OpenDialogEvent` with dialog id `turn_news` and params after reload; no cross-panel callbacks. See `SPEC/program/app-ui-wiring.md`.

## Components

- **Dialog:** `TurnNewsDialog` — title references the resolved turn; scrollable list; primary **Close** / OK.
- **Widgetbook:** at least one story with sample lines + empty state; mobile viewport if layout differs.

## Copy

Neutral diplomacy wording (no invented aggressor). Province ids in logic remain prefixed; UI may show `displayName` when present. **Province captured** bullets are only produced for **faction-to-faction** handovers (both previous and new owner non-empty); see [turn-news-digest.md](../program/turn-news-digest.md) and [world-model.md](../game/world-model.md) § Invariants.
