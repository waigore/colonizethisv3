# Player Turn Event Feed (map overlay + news toggle)

**SPEC/ui** - Human-player-scoped turn outcomes feed rendered over the in-game map. Uses existing bus wiring (`GameEventBus -> GameEventBridge -> AppEventBus`) and commits one batch per resolved turn.

---

## Responsibility

- Show significant outcomes relevant to the local human player as short "something happened!" lines.
- Wide and narrow layouts: hidden-by-default feed panel over the map.
- Wide and narrow layouts: top-right news icon button toggles feed panel visibility.
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

- **Wide**: top-right news icon button row is always visible; feed card appears below when toggled on.
- **Narrow**: same top-right news icon button row and same floating feed card behavior as wide.
- **Feed card content**: no `Events` title row; render only event rows or empty-state text.

---

## Acceptance criteria (Given-When-Then)

- Given a running game map shell with human player `P`, when the app receives relevant forwarded app game events and then `TurnResolutionCompleteEvent` for game `G`, then the feed shows one ordered list containing only `P`-relevant lines from that resolved turn.
- Given the feed currently shows lines for resolved turn `T`, when the next `TurnResolutionCompleteEvent` for the same game commits turn `T+1`, then the UI replaces all prior lines with the new batch and does not retain `T` lines.
- Given a running game map shell with `mapViewState.showPlayerTurnEventsFeed = false`, when the UI renders on wide layout, then the feed card is hidden and the top-right news icon button is visible.
- Given a running game map shell with `mapViewState.showPlayerTurnEventsFeed = false`, when the UI renders on narrow layout, then the feed card is hidden and the top-right news icon button is visible.
- Given a running game map shell with `N` feed entries, when the UI renders, then the news icon button shows a badge with value `N`.
- Given feed visibility is false, when The Player taps the top-right news icon button, then the UI layer shows the floating feed card.
- Given feed visibility is true, when The Player taps the top-right news icon button, then the UI layer hides the floating feed card.
- Given the feed card is visible, when the feed renders, then the feed card does not display an `Events` title and renders only event rows or empty-state text.
- Given a tappable province-scoped line whose province anchor resolves to a tile key, when the user taps that row, then the app emits `LocateMapTileEvent` for that tile.
- Given a tappable naval-combat line whose sea-zone anchor resolves to a tile key, when the user taps that row, then the app emits `LocateMapTileEvent` for that tile.
- Given a non-tappable line or unresolved anchor, when the user taps the row, then no map-focus event is emitted and the app remains stable.
- Given a diplomacy feed line with `changeType` of `declare_war`, `peace`, `alliance`, or `break_alliance`, when rendered, then the line uses a concrete outcome template (not the generic "diplomacy changed" fallback).
- Given The Player toggles `showPlayerTurnEventsFeed` and saves the game, when the game is loaded, then `mapViewState.showPlayerTurnEventsFeed` restores with the same value.
- Given a legacy save where `mapViewState.showPlayerTurnEventsFeed` is absent, when the game loads, then the loaded value defaults to `false`.
