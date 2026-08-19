# Turn-start news dialog

**Screen ID:** `DLG50001` — stable; do not reassign.
**SPEC/ui** — Forced last-turn report after resolution. Implementation: `app/lib/features/game/widgets/dialogs/turn_news_dialog.dart`.
**Widgetbook:** **Turn news** → `widgetbook_host/lib/catalogs/catalog_dialogs_turn_news.dart`
**Mockup:** [mockups/DLG50001-turn-news-dialog.html](mockups/DLG50001-turn-news-dialog.html)

**Trigger:** `TurnResolutionCompleteEvent` with `turnNumber >= 1`, `turnNewsDigest != null`, and loaded game `victory == null`. **Not shown** on initial map entry at turn 0. **Victory:** if `victory != null`, omit news (victory flow first).

## Trigger conditions

`GameToUIBusListener` emits `OpenDialogEvent` id `turn_news` after reload with session params `digest`, `newTurnNumber`, and `courtSnapshot` (`TurnNewsCourtSnapshot`; not a GDD field). Wiring: `SPEC/program/app-ui-wiring.md`. When the route completes (Close, Intelligence, or **open Events**), the handler emits `TurnNewsDialogClosedEvent` so `MAP10001` may start last-turn spatial playback (Refs #4486).

## Layout / wireframe

```
CtDialogShell
  title_region          turnNews_title(newTurnNumber)  accent
  gazette_region        digest bullets (fg) OR empty copy (muted)
  court_region          optional muted Your court block (tappable)
  spies_region          optional muted spies footer (tappable)
  buttons_region        Close  CtNinePatchButton
```

## Behavior

- Modal listing one bullet per `TurnNewsLine` (faction/province/sea labels from current `Game`).
- **Empty digest:** muted **No major events last turn.** **Exception (Refs #4532):** when `courtSnapshot` is non-empty, omit that empty copy so the dialog does not claim the turn was quiet.
- **Your court block (Refs #4532):** Derived from the human-filtered feed batch at the same `TurnResolutionCompleteEvent` (qualifying families only: order rejected; research complete; land/naval combat the human fought; market / overseas-profit / economy summary; work-order completed). Omit gazette families (captures, war/peace, overture, discovery) and spy-report lines (those stay in the spies footer / `GAME30003`). At most **three** clauses in priority **rejected → research → combat → market/economy → work**, joined by ` · `; further families collapse to `N more`. Research clauses use the catalog **display name**, never a raw tech id. The block is muted, wrap-safe at 320–360 dp, and tappable. Tap pops `DLG50001` and sets `mapViewState.showPlayerTurnEventsFeed = true` (same persist path as the newspaper toggle) so `OVL70001` is revealed. Ordinary **Close** does not open the feed. The block is hidden when the snapshot is empty. Unused research seats and idle Spies are never listed.
- **Spy-report footer (Refs #4476):** When `Game.lastTurnIntelligenceDigest` has spy-report lines for the human (`N > 0`), muted **Your spies report N items — open Intelligence**. Tap pops the dialog and emits `NavigateToRouteEvent(Routes.intelligence)`. Absent when `N == 0`. Closing the newspaper does **not** drop the briefing.
- **UXD-001 / UXD-002 / P1:** This dialog is post-resolution reporting. `DLG60001` still does not warn about empty/unfunded research seats or idle Spies.

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `DLG50001` | Gazette | `digest.lines` non-empty | Bullet list; empty copy hidden |
| `DLG50001` | Empty gazette | `digest.lines` empty and court empty | Muted empty copy |
| `DLG50001` | Empty gazette + court | empty digest, non-empty court | Court block; empty copy omitted |
| `DLG50001` | Gazette + court | both non-empty | Gazette bullets + court block |
| `DLG50001` | Spy footer | `N > 0` | Spies line; coexists with court |

## Widgetbook

Folder **Turn news**. Use cases: **Sample lines**, **Empty digest**, **Empty gazette + court**, **Gazette + court**, **Spy footer coexistence**, **Mobile viewport**. **Mobile viewport** wraps in `mobileViewport` (360 × 640). Pinned by `app/test/widgetbook_turn_news_mobile_viewport_test.dart` and `app/test/widgetbook_turn_news_court_test.dart`.

## Styling (dark theme)

Editorial-monocle dark catalog. Host is `CtDialogShell` (no Material `AlertDialog`). Title = `EditorialMonoclePalette.accent`. Gazette lines = `fg`. Empty copy, court block, and spies footer = `muted`. Close is `CtNinePatchButton`.

## Copy

Neutral diplomacy wording. Province ids in logic remain prefixed; UI may show `displayName`. **Province captured** bullets only for faction-to-faction handovers; see [turn-news-digest.md](../program/turn-news-digest.md).

## Acceptance criteria

- **Given** the turn news dialog is built under `AppThemes.editorialMonocle` with a populated digest, **when** the widget tree is inspected, **then** the dialog uses `CtDialogShell` and contains no Material `AlertDialog` widget.
- **Given** the turn news dialog is built, **when** the title is inspected, **then** the resolved title text colour equals `EditorialMonoclePalette.accent`.
- **Given** the turn news dialog is built with an empty `TurnNewsDigest` and an empty court snapshot, **when** the empty-state line is inspected, **then** the resolved text colour equals `EditorialMonoclePalette.muted` and the dialog still shows the Close action.
- **Given** the turn news dialog is built, **when** the action row is inspected, **then** the Close button is a `CtNinePatchButton` (no Material `TextButton` / `ElevatedButton`).
- **Given** `TurnNewsDigest.lines` is empty and `courtSnapshot` has at least one qualifying family, **when** `DLG50001` opens, **then** the UI layer shows a **Your court** block and does not show only `turnNews_empty`.
- **Given** the same empty gazette and a human research-complete family, **when** the court block renders, **then** it names that technology finished using the catalog display name (not a raw tech id) as one of at most three default clauses.
- **Given** more than three qualifying families, **when** the block renders, **then** the UI layer shows three clauses in rejected → research → combat → market/economy → work order and an `N more` clause plus **open Events**.
- **Given** the player activates the court block / **open Events**, **when** the tap is handled, **then** the UI layer pops `DLG50001` and sets `showPlayerTurnEventsFeed` to `true` without opening the feed on ordinary **Close**.
- **Given** digest lines are empty and `courtSnapshot` is empty, **when** `DLG50001` opens, **then** the UI layer keeps the muted empty gazette copy and omits the court block.
- **Given** spy-report count `N > 0`, **when** `DLG50001` opens with or without a court block, **then** the spies footer still appears and still navigates to `GAME30003`.
- **Given** a 320–360 dp viewport, **when** the court block renders, **then** the line wraps without overflow and **Close** stays tappable.
