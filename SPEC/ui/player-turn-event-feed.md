# Player Turn Event Feed (map overlay + news toggle)

**Screen ID:** `OVL70001` — stable; do not reassign.
**SPEC/ui** - Human-player-scoped turn outcomes feed rendered over the in-game map. Uses existing bus wiring (`GameEventBus -> GameEventBridge -> AppEventBus`) and commits one batch per resolved turn.

---

## Responsibility

- Show significant outcomes relevant to the local human player as short "something happened!" lines.
- Wide and narrow layouts: hidden-by-default feed panel over the map.
- **Tab-bar row layout (LTR; mockup `.tabbar`, issue #2861 M1):** The newspaper toggle lives in the trailing slot of **[GameTabBar](../../app/lib/features/game/widgets/game_tab_bar.dart)** (inside [GameMapControls](../../app/lib/features/game/flame/game_map_controls.dart)) — not as a sibling overlay on the map `Stack`. The region tabs (`Old World`, `New World`) are **start-aligned** (left in LTR) inside an `Expanded` horizontal scroll view so they shrink without overflow on narrow viewports. A **flex spacer** (the `Expanded` region-tab area) separates the tabs from the trailing indicator group. The **treasury**, **cargo hold**, and **news toggle** are **end-aligned** on the trailing (right) edge in that order (treasury → cargo → news toggle), matching the mockup `.tabbar-spacer { flex:1 }` + trailing `.treasury` / `.cargo-hold` / `.news-toggle`. The toggle keeps a **4 dp leading margin** (`GameTabBar.clusterTrailingGap`) from the cargo hold indicator. This keeps the control out of the **320 logical px** wide province / sea zone side column on wide layouts so it does not cover the province overlay close affordance. **RTL:** out of scope for this change; layout is LTR-only.
- **Floating feed card (wide):** When the province detail side panel is open (`mapProvincePanelProvider.overlayOpen` on wide), map-stack overlays that must stay in the map column use the same horizontal clearance as the region minimap: `Positioned.right = gameMapWideOverlayRightInset(provincePanelOpen: …)` from `game_screen_shared.dart` — i.e. **`kGameMapWideStackRightGutter` (8)** plus **`kGameMapWideProvinceSidePanelWidth` (320)** when the panel is open, else **8** only. The feed card uses this inset so **feed + open panel** does not overlap the panel column. When the panel is closed, behavior matches the prior **8** gutter. Cross-ref: `SPEC/ui/in-game-shell-narrow.md` (wide side panel width), `SPEC/ui/province-sea-zone-detail-overlay.md` (close control).
- **Narrow:** Same toggle in **GameMapControls** (not over the map). The floating feed card remains `Positioned` on the map stack with the existing narrow inset; it must not obscure the bottom sheet’s primary chrome (including close). If both sheet and feed are open, verify stacking; relocate or inset only if a gap remains.
- News icon button shows a badge with the current feed-entry count.
- Replace (not append) feed lines each time a new turn resolution completes.
- Feed-panel visibility persists via `Game.mapViewState.showPlayerTurnEventsFeed`.

---

## Data contract (v1 slice)

- Source: forwarded app game events (`AppCombatResultEvent`, `AppNavalCombatResultEvent`, `AppProvinceCapturedEvent`, `AppDiplomacyChangeEvent`, `AppResearchCompleteEvent`, `AppOrderRejectedEvent`, `AppWorkOrderCompletedEvent`, `AppPlayerProvinceDiscoveredEvent`, `AppPlayerSeaZoneDiscoveredEvent`, `AppOvertureAdvancedEvent`) plus `TurnResolutionCompleteEvent`.
- Human-player filter:
  - Combat/naval when human id is a participating side id.
  - Province capture when human id equals previous or new owner.
  - Diplomacy when human id equals actor or target.
  - Research/order rejected when event `playerId` equals human id.
  - Work-order/province/sea discovery when event `playerId` equals human id.
  - Overture advanced when human id equals offerer GP id or target faction id.
- Formatting lives in Flutter UI; logic payloads remain ids.
- Diplomacy formatting (v1.1 slice): known `changeType` values render concrete outcome copy (`declare_war`, `peace`, `alliance`, `break_alliance`), with a safe generic fallback for unknown values.

---

## Interaction

- Row tap:
  - Province-scoped lines (land combat, province capture) attempt map focus to that province.
- Naval combat lines attempt map focus to a sea-zone anchor tile (centroid when available, otherwise an adjacent mapped port tile).
- Work-order completion lines tap-focus the target tile.
- Province-discovery lines tap-focus the discovered province.
- Sea-discovery lines tap-focus a sea-zone anchor tile.
- Other lines are non-tappable in v1.
- Fallback: if no valid map anchor can be resolved for a tappable row, render it non-tappable and keep app stable.

---

## Layout

Authoritative placement rules are under **Responsibility** (news toggle, wide feed inset vs open panel, narrow).

- **Feed card content**: no `Events` title row; render only event rows or empty-state text.

### Card chrome (dark editorial-monocle)

The floating card uses the canonical dark-theme primitives so it sits next to the empire rail / players bar / minimap with consistent chrome. Issue #2861 S7 anchors this contract:

- Card surface paints `CtGradients.panelGradient` (vertical `--surface` → `--bg`) framed by a `1` dp brass border resolved from `EditorialMonoclePalette.accentDim`. No hard-coded hex literals; no `Material(color: Colors.black…)` legacy chrome.
- **Wide layout** (host width `>= kNarrowBreakpoint`, i.e. >= 600 dp): card width is `kGameMapWideProvinceSidePanelWidth` (320 dp). The 320 dp anchor keeps feed + open province panel from sitting side-by-side without the wide inset.
- **Narrow layout** (host width `< kNarrowBreakpoint`, i.e. `< 600` dp; issue #2870 S3 / Req 11): card width is `clamp(180, viewport.width * 0.5, 260)` dp, mirroring the mockup `.news-feed-card @media (max-width:600px) { width:clamp(180px, 50vw, 260px); }` rule from `SPEC/ui/mockups/GAME10001-game-screen.html`. The lower bound (180 dp) preserves a readable two-line entry at 320 dp viewports; the upper bound (260 dp) keeps the card within the available map-stack right column. The province bottom sheet on narrow covers the card from the bottom (no wide inset applies).
- Inner padding is `10` dp on all sides; the scroll viewport is capped at `220` dp tall.
- Event rows: body text resolves to `EditorialMonoclePalette.fg`; tappable rows wrap in a `Material(color: Colors.transparent) + InkWell` whose press / hover / splash colour resolves to `EditorialMonoclePalette.surfaceLite`.
- Empty-state copy resolves to `EditorialMonoclePalette.muted` italic; renders the localized "No major events last turn." string (or `emptyLabel` host override) as one centred line without an `Events` title row.

### Toggle button chrome (dark editorial-monocle)

The newspaper toggle lives in [`GameTabBar`](../../app/lib/features/game/widgets/game_tab_bar.dart)'s trailing slot. Issue #2861 M3 anchors this mockup-fidelity contract (mockup `.news-toggle` in `SPEC/ui/mockups/GAME10001-game-screen.html`):

- The toggle surface is **28 × 22 dp** filled with `EditorialMonoclePalette.bgDeep` behind a **1 dp** border. The border resolves to `EditorialMonoclePalette.border` in the default (closed) state and lifts to `EditorialMonoclePalette.accentDim` on hover and while the feed is open (mockup `.news-toggle:hover` / `.news-toggle.active`).
- The newspaper glyph is a **14 × 14 dp** monochrome vector (`NewspaperGlyph`, a `CustomPaint`; **not** a Material `Icons.newspaper` at 20 dp), tinted via a single `currentColor`-style colour: `EditorialMonoclePalette.accentDim` closed, `EditorialMonoclePalette.accentBright` on hover, and `EditorialMonoclePalette.accent` while the feed is open (so the open state reads as "lit").
- Unread-count badge background resolves to `EditorialMonoclePalette.danger` at 0.95 alpha; badge text resolves to `EditorialMonoclePalette.bg`. The badge sits at the mockup `.news-badge` position (`top: -4`, `right: -6`). The pill renders 99+ overflow and never falls back to `Colors.redAccent` / `Colors.white`.

---

## Acceptance criteria (Given-When-Then)

- Given a running game map shell with human player `P`, when the app receives relevant forwarded app game events and then `TurnResolutionCompleteEvent` for game `G`, then the feed shows one ordered list containing only `P`-relevant lines from that resolved turn.
- Given the feed currently shows lines for resolved turn `T`, when the next `TurnResolutionCompleteEvent` for the same game commits turn `T+1`, then the UI replaces all prior lines with the new batch and does not retain `T` lines.
- Given a running game map shell with `mapViewState.showPlayerTurnEventsFeed = false`, when the UI renders on wide layout, then the feed card is hidden and the news icon toggle is visible inside **GameMapControls** (trailing end of the region/treasury/cargo row).
- Given a running game map shell with `mapViewState.showPlayerTurnEventsFeed = false`, when the UI renders on narrow layout, then the feed card is hidden and the news icon toggle is visible inside **GameMapControls** on the trailing end of that row.
- Given a running game map shell with `N` feed entries, when the UI renders, then the news icon button shows a badge with value `N`.
- Given feed visibility is false, when The Player taps the news icon toggle in **GameMapControls**, then the UI layer shows the floating feed card.
- Given feed visibility is true, when The Player taps the news icon toggle in **GameMapControls**, then the UI layer hides the floating feed card.
- Given the feed card is visible, when the feed renders, then the feed card does not display an `Events` title and renders only event rows or empty-state text.
- Given a tappable province-scoped line whose province anchor resolves to a tile key, when the user taps that row, then the app emits `LocateMapTileEvent` for that tile.
- Given a tappable naval-combat line whose sea-zone anchor resolves to a tile key, when the user taps that row, then the app emits `LocateMapTileEvent` for that tile.
- Given a non-tappable line or unresolved anchor, when the user taps the row, then no map-focus event is emitted and the app remains stable.
- Given a diplomacy feed line with `changeType` of `declare_war`, `peace`, `alliance`, or `break_alliance`, when rendered, then the line uses a concrete outcome template (not the generic "diplomacy changed" fallback).
- Given The Player toggles `showPlayerTurnEventsFeed` and saves the game, when the game is loaded, then `mapViewState.showPlayerTurnEventsFeed` restores with the same value.
- Given a legacy save where `mapViewState.showPlayerTurnEventsFeed` is absent, when the game loads, then the loaded value defaults to `false`.
- Given a wide-layout map shell with `mapViewState.showPlayerTurnEventsFeed = true` and `mapProvincePanelProvider.overlayOpen = true`, when The UI layer positions the floating feed card on the map stack, then the feed card’s enclosing `Positioned.right` equals **`kGameMapWideStackRightGutter + kGameMapWideProvinceSidePanelWidth`** logical pixels (same numeric rule as the region minimap for that state).
- Given a wide-layout map shell with `mapViewState.showPlayerTurnEventsFeed = true` and `mapProvincePanelProvider.overlayOpen = false`, when The UI layer positions the floating feed card on the map stack, then the feed card’s enclosing `Positioned.right` equals **`kGameMapWideStackRightGutter`** logical pixels.
- Given a wide-layout (`>= 600` dp host width) map shell with `mapViewState.showPlayerTurnEventsFeed = true`, when The UI layer renders the `PlayerTurnEventFeedCard`, then the card paints at width `kGameMapWideProvinceSidePanelWidth` (320 dp) (issue #2861 S7).
- Given a narrow-layout (`< 600` dp host width) map shell with `mapViewState.showPlayerTurnEventsFeed = true`, when The UI layer renders the `PlayerTurnEventFeedCard`, then the card paints at width `clamp(180, viewport.width * 0.5, 260)` dp per the mockup `.news-feed-card @media (max-width:600px)` rule (issue #2870 S3 / Req 11).
- Given a narrow-layout (`< 600` dp host width) map shell with `mapViewState.showPlayerTurnEventsFeed = true` and `mapProvincePanelProvider.overlayOpen = false`, when The UI layer positions the floating feed card on the map stack, then the feed card's enclosing `Positioned.right` equals **`kMapOverlayEdgeInset`** logical pixels (no wide inset applies on narrow; issue #2870 S3 / Req 11).
- Given a narrow-layout (`< 600` dp host width) map shell with `mapViewState.showPlayerTurnEventsFeed = true` and `mapProvincePanelProvider.overlayOpen = true`, when The UI layer positions the floating feed card on the map stack, then the feed card's enclosing `Positioned.right` still equals **`kMapOverlayEdgeInset`** logical pixels (the narrow province bottom sheet covers the card from the bottom, not the right, so `gameMapWideOverlayRightInset` MUST NOT apply on narrow; issue #2870 S3 / Req 11).
- Given a wide-layout map shell with the province side panel open, when the UI renders, then the news icon toggle is a descendant of **GameMapControls** and is not placed as a top-level overlay sibling on the map-area `Stack` that ignores the province column.
- Given a narrow-layout map shell with the province bottom sheet open, when the UI renders, then the news icon toggle remains inside **GameMapControls** (not a map-stack overlay), so The Player can reach the sheet’s close control without the toggle blocking it.
- Given a `GameTabBar` rendered with a trailing news toggle, when The UI layer lays out the bar, then the region tabs are start-aligned (left in LTR) inside an `Expanded` scroll area, the treasury, cargo hold, and news toggle are end-aligned in that order, and the news toggle has a `GameTabBar.clusterTrailingGap` (4 dp) leading gap from the cargo hold indicator (mockup `.tabbar` / `.tabbar-spacer`; issue #2861 M1).
- Given a wide-layout map shell with `mapViewState.showPlayerTurnEventsFeed = true`, `shell.showPlayerChrome = true`, and no victory set, when The UI layer builds the map `Stack`, then the `GameMapPlayersBar` child is positioned **earlier** in the `Stack.children` list than the `PlayerTurnEventFeedCard` child, so the open feed card paints **above** the players bar and player chips never obscure it (mockup z-order: news card 7 > players bar 5; issue #2861 M4).

### Card and toggle chrome (dark editorial-monocle; issue #2861 S7)

- Given the floating feed card renders with at least one entry, when the UI builds the card chrome, then the card’s `DecoratedBox` paints `CtGradients.panelGradient` and a 1 dp `Border.all(color: EditorialMonoclePalette.accentDim, width: 1)`; the legacy `Material(color: Colors.black…)` chrome does not paint inside the card subtree.
- Given the floating feed card renders with a non-empty entry list, when an event row builds, then the body `Text.style.color` resolves to `EditorialMonoclePalette.fg`; no row paints text in the legacy `Colors.white` token.
- Given the floating feed card renders with zero entries, when the empty-state copy builds, then the label `Text.style.color` resolves to `EditorialMonoclePalette.muted` and `Text.style.fontStyle == FontStyle.italic`; no row paints text in the legacy `Colors.white70` token.
- Given the floating feed card renders with at least one tappable entry, when the row builds, then the row is wrapped in a `Material(color: Colors.transparent) + InkWell` whose `splashColor`, `highlightColor`, and `hoverColor` resolve to `EditorialMonoclePalette.surfaceLite`.
- Given the newspaper toggle button renders, when the toggle surface paints, then the surface `Container` measures `28 × 22` dp, its `BoxDecoration.color` resolves to `EditorialMonoclePalette.bgDeep`, and it carries a `1` dp `Border.all` (issue #2861 M3); the glyph is a `NewspaperGlyph` and **not** a Material `Icon`.
- Given the newspaper toggle button renders with `showFeed == false` and is not hovered, when the glyph paints, then the `NewspaperGlyph.color` resolves to `EditorialMonoclePalette.accentDim` and the surface border resolves to `EditorialMonoclePalette.border`.
- Given the newspaper toggle button renders with `showFeed == true`, when the glyph paints, then the `NewspaperGlyph.color` resolves to `EditorialMonoclePalette.accent` and the surface border resolves to `EditorialMonoclePalette.accentDim`.
- Given the newspaper toggle button renders with `eventCount > 0`, when the badge paints, then the badge `Container` decoration uses a colour resolved from `EditorialMonoclePalette.danger` (alpha 0.95) and the badge `Text.style.color` resolves to `EditorialMonoclePalette.bg`; the badge does not paint with `Colors.redAccent` or `Colors.white`.
- Given any host renders `PlayerTurnEventFeedCard` or `PlayerTurnEventsFeedToggleButton`, when the widget tree is statically inspected for hard-coded `Color` literals (`Colors.black*`, `Colors.white*`, `Colors.redAccent`), then those legacy literals do not appear inside either widget’s source file.
