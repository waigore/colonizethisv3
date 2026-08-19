# Turn-start news dialog

**Screen ID:** `DLG50001` — stable; do not reassign.
**Source:** #1478 + product 2026-04-03. **Trigger:** `TurnResolutionCompleteEvent` with `turnNumber >= 1`, `turnNewsDigest != null`, and loaded game `victory == null`. **Not shown** on initial map entry at turn 0 with no completed resolution. **Victory:** if `victory != null`, omit news (victory flow first).

**Mockup:** [mockups/DLG50001-turn-news-dialog.html](mockups/DLG50001-turn-news-dialog.html)
## Behavior

- Modal dialog listing one bullet per `TurnNewsLine` (formatted with faction/province/sea labels from current `Game`).
- **Empty digest:** show dialog with “No major events last turn.” (or equivalent l10n); the empty-state copy renders with `EditorialMonoclePalette.muted` so the dialog visibly distinguishes "nothing happened" from a regular news entry. When the gazette is empty but a **Your court** block exists (see below), omit the empty gazette copy — the dialog must not claim the whole turn was quiet.
- **Your court block (Refs #4532):** When the committed human-filtered turn batch includes qualifying court families (order rejected; research complete; land/n naval combat the human fought; market / overseas-profit / economy summary; work-order completed), render a muted **Your court:** block below the gazette (same footer family as the spy line). At most **three** clauses joined by ` · ` in priority order: rejected orders → research complete → combat → market/economy → work finished; further families collapse to `{N} more`. Append tappable **open Events** (underline). Tap pops `DLG50001` and sets `mapViewState.showPlayerTurnEventsFeed = true` (same persistence path as the newspaper toggle); ordinary **Close** does **not** auto-open the feed. Omit spy-report lines and gazette duplicates (captures, war/peace, overtures, discoveries). Session-only snapshot passed in `OpenDialogEvent` params beside `digest` (built from the same batch as `OVL70001`).
- **Wiring:** `GameToUIBusListener` emits `OpenDialogEvent` with dialog id `turn_news` and params after reload; no cross-panel callbacks. See `SPEC/program/app-ui-wiring.md`. When the dialog route completes (Close or Intelligence tap that pops first), the handler emits `TurnNewsDialogClosedEvent` so `MAP10001` may start last-turn spatial playback (Refs #4486; [map-widget.md](map-widget.md) § Last-turn spatial playback).
- **Spy-report footer (Refs #4476):** When `Game.lastTurnIntelligenceDigest` has spy-report lines for the human (`N > 0`), a muted footer under the gazette reads **Your spies report N items — open Intelligence** and is tappable. Tap pops the dialog and emits `NavigateToRouteEvent(Routes.intelligence)`. Absent when `N == 0`. Closing the newspaper does **not** drop the briefing — `GAME30003` reopens the persisted digest until the next turn replaces it.

## Components

- **Dialog:** `TurnNewsDialog` — title references the resolved turn; scrollable list; **Your court** block when applicable; primary **Close** / OK.
- **Court snapshot:** `buildTurnNewsCourtSummary` / `TurnNewsCourtSummary` (`packages/colonizethis_app_ui_chrome/lib/event_feed/turn_news_court_summary.dart`); buffered in `GameToUIBusListener` via `PlayerTurnEventsSessionBuffer`.
- **Widgetbook:** Folder **Turn news** (`app/lib/widgetbook/catalog_part2.dart`). Use cases: **Sample lines**, **Empty digest**, **Empty digest + court**, **Gazette + court**, **Court + spy footer**, **Mobile viewport**. The **Mobile viewport** use case wraps the dialog in `mobileViewport(context, …)` so reviewers can verify the 360 × 640 dp narrow story without resizing the host window. The **Mobile viewport** use case must be pinned by `app/test/widgetbook_turn_news_mobile_viewport_test.dart` (Refs #2870 R22 / S9) so its removal or rename surfaces in CI before reviewers lose the narrow-viewport review surface.

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
- **Given** `TurnNewsDigest.lines` is empty and the court snapshot includes at least one qualifying family, **when** `DLG50001` opens, **then** the UI layer shows a **Your court** block and does **not** show **No major events last turn.**
- **Given** the player taps **open Events** on the court block, **when** the tap is handled, **then** the UI layer pops `DLG50001` and sets `showPlayerTurnEventsFeed == true` on the loaded game without opening the feed on ordinary **Close**.
- **Given** Widgetbook **Turn news** includes **Empty digest + court**, **Gazette + court**, and **Court + spy footer**, **when** `app/test/widgetbook_turn_news_court_variants_test.dart` runs, **then** each use case is wired into `turnNewsDialogDirectories` and pumps without exceptions (Refs #4532).
- **Given** `DLG50001` empty gazette with court block or court + spy footer under `AppThemes.editorialMonocle`, **when** `app/test/turn_news_dialog_goldens_test.dart` captures each keyed `RepaintBoundary`, **then** each `matchesGoldenFile` baseline under `app/test/goldens/turn_news_court*.png` matches the committed PNG (Refs #4532).

## Copy

Neutral diplomacy wording (no invented aggressor). Province ids in logic remain prefixed; UI may show `displayName` when present. **Province captured** bullets are only produced for **faction-to-faction** handovers (both previous and new owner non-empty); see [turn-news-digest.md](../program/turn-news-digest.md) and [world-model.md](../game/world-model.md) § Invariants.
