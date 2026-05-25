# Player Turn Event Feed (map overlay + news toggle)

**Screen ID:** `OVL70001` — stable; do not reassign.
**SPEC/ui** - Human-player-scoped turn outcomes feed rendered over the in-game map. Uses existing bus wiring (`GameEventBus -> GameEventBridge -> AppEventBus`) and commits one batch per resolved turn.

---

## Responsibility

- Show significant outcomes relevant to the local human player as short "something happened!" lines.
- Wide and narrow layouts: hidden-by-default feed panel over the map.
- **News toggle placement (LTR):** The newspaper toggle lives in **[GameMapControls](../../app/lib/features/game/flame/game_map_controls.dart)** — the same vertical stack as the Next turn row and the **region chips / treasury / cargo** row — not as a sibling overlay on the map `Stack`. The chips/treasury/cargo cluster stays **horizontally centered** in the space left of the toggle (`LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minWidth: viewport)` + inner `Row` with `MainAxisAlignment.center`); when the cluster is wider than that space it scrolls horizontally. The toggle is **end-aligned on the trailing (right) edge** of the outer row. This keeps the control out of the **320 logical px** wide province / sea zone side column on wide layouts so it does not cover the province overlay close affordance. **RTL:** out of scope for this change; layout is LTR-only.
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
- Given a wide-layout map shell with the province side panel open, when the UI renders, then the news icon toggle is a descendant of **GameMapControls** and is not placed as a top-level overlay sibling on the map-area `Stack` that ignores the province column.
- Given a narrow-layout map shell with the province bottom sheet open, when the UI renders, then the news icon toggle remains inside **GameMapControls** (not a map-stack overlay), so The Player can reach the sheet’s close control without the toggle blocking it.
