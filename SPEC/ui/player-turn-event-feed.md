# Player Turn Event Feed (map overlay + narrow dialog)

**SPEC/ui** - Human-player-scoped turn outcomes feed rendered over the in-game map. Uses existing bus wiring (`GameEventBus -> GameEventBridge -> AppEventBus`) and commits one batch per resolved turn.

---

## Responsibility

- Show significant outcomes relevant to the local human player as short "something happened!" lines.
- Wide layout: non-modal right-side overlay column over the map.
- Narrow/mobile layout: `Events` chip that opens an `Events` dialog with the same lines.
- Replace (not append) feed lines each time a new turn resolution completes.

---

## Data contract (v1 slice)

- Source: forwarded app game events (`AppCombatResultEvent`, `AppNavalCombatResultEvent`, `AppProvinceCapturedEvent`, `AppDiplomacyChangeEvent`, `AppResearchCompleteEvent`, `AppOrderRejectedEvent`) plus `TurnResolutionCompleteEvent`.
- Human-player filter:
  - Combat/naval when human id is a participating side id.
  - Province capture when human id equals previous or new owner.
  - Diplomacy when human id equals actor or target.
  - Research/order rejected when event `playerId` equals human id.
- Formatting lives in Flutter UI; logic payloads remain ids.

---

## Interaction

- Row tap:
  - Province-scoped lines (land combat, province capture) attempt map focus to that province.
  - Other lines are non-tappable in v1.
- Fallback: if no valid map anchor can be resolved for a tappable row, render it non-tappable and keep app stable.

---

## Layout

- **Wide**: right-side card over map, scrollable list body.
- **Narrow**: `Events` chip above map overlays; tapping opens dialog with identical list content/order.

---

## Acceptance criteria (Given-When-Then)

- Given a running game map shell with human player `P`, when the app receives relevant forwarded app game events and then `TurnResolutionCompleteEvent` for game `G`, then the feed shows one ordered list containing only `P`-relevant lines from that resolved turn.
- Given the feed currently shows lines for resolved turn `T`, when the next `TurnResolutionCompleteEvent` for the same game commits turn `T+1`, then the UI replaces all prior lines with the new batch and does not retain `T` lines.
- Given wide layout, when the feed has lines, then a right-side non-modal map overlay shows those lines and allows scrolling.
- Given narrow layout, when the user taps the `Events` chip, then a dialog opens and renders the same line texts in the same order as the current-turn feed.
- Given a tappable province-scoped line whose province anchor resolves to a tile key, when the user taps that row, then the app emits `LocateMapTileEvent` for that tile.
- Given a non-tappable line or unresolved anchor, when the user taps the row, then no map-focus event is emitted and the app remains stable.
