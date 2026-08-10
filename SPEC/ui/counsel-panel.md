# Counsel panel

**Screen ID:** `GAME90001` — stable; do not reassign.
**SPEC/ui** — Counsel screen with **Industry**, **Trade**, and **Military** tabs. Implementation: `app/lib/features/game/screens/counsel/counsel_screen.dart`. Trade ranking: `SPEC/program/trade-counsel-ranking.md`. Military ranking: `SPEC/program/military-counsel-ranking.md`.
**Widgetbook:** `Counsel Panel` → `widgetbook_host/lib/catalogs/catalog_panels.dart`.

## Trigger conditions

- Production Allocation header **Counsel** button (`NavigateToRouteEvent` → `Routes.counsel`).
- Production allocation row counsel star (`highlightRecommendationId` in route args; Industry tab).
- Trade Market header **Counsel** button (`NavigateToRouteEvent` → `Routes.counsel` with `counselTab: 'trade'`).
- Trade Market commodity-row counsel star (`highlightRecommendationId` + `counselTab: 'trade'`).
- Military Units header **Counsel** button (`NavigateToRouteEvent` → `Routes.counsel` with `counselTab: 'military'`).

## Layout / wireframe

```
CtGameFeatureScreenShell
├── GameFeatureScreenTopBar (← Map, production icon, "Counsel")
└── DefaultTabController (Industry | Trade | Military)
    ├── TabBar (Industry, Trade, Military)
    └── TabBarView
        ├── CounselIndustryTabBody (scrollable list or empty state)
        │   └── CounselIndustryRecommendationCard (per rec)
        │       └── CtNinePatchButton primary action when editable
        ├── CounselTradeTabBody (scrollable list or empty state)
        │   ├── CtNinePatchButton "Apply recommended market book" (when book non-empty + editable)
        │   └── CounselTradeRecommendationCard (per line; full book may exceed three)
        │       └── CtNinePatchButton "Agree" when editable
        └── CounselMilitaryTabBody (scrollable list or empty state)
            └── CounselMilitaryRecommendationCard (per rec; ≤3)
                └── CtNinePatchButton "Agree" when editable
```

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Production header Counsel | Human GP on Production | Counsel Industry tab (`initialTab` default). |
| Allocation counsel star | Starred produce row tapped | Industry tab with `highlightRecommendationId`. |
| Trade Market header Counsel | Human GP on `GAME60001` Market | Trade tab (`counselTab: 'trade'`). |
| Trade Market counsel star | Highlight commodity star tapped | Trade tab with `highlightRecommendationId`. |
| Military Units header Counsel | Human GP on `UNIT20001` | Military tab (`counselTab: 'military'`). |

### User actions → outcomes

| Control | When enabled | Emits / calls | Side effects |
|---------|--------------|---------------|--------------|
| ← Map | Always | `Navigator.maybePop()` | Returns to prior route. |
| Tab **Industry** / **Trade** / **Military** | Always | `DefaultTabController` | Switches tab body. |
| **Apply recommended industry allocation** | Produce rec + `canMutateViaUi` | — | Merges `industryCounselCoreDesiredOutputByRecipe` into `productionDesiredOutputProvider`; recipes outside snapshot unchanged. |
| **Agree** (train) | Train rec + editable | — | Appends one `RecruitWorkerOrder` when `suggestRecruitWorkerOrders` still accepts tier; else `ShowSnackBarEvent` with failure copy. |
| **Open Development** | Feedstock unblock rec + editable | `NavigateToRouteEvent(Routes.development, …)` | Opens `GAME80001`; no auto-improve order. |
| **Apply recommended market book** | Non-empty trade book + `canMutateViaUi` | — | Replaces entire `tradeOrdersByPlayerId[human]` with counsel book snapshot. |
| **Agree** (trade line) | Trade rec + editable | — | Stages/replaces that commodity via `applyTradeOrderForPlayer`; clears opposite direction on same commodity; else `ShowSnackBarEvent`. |
| **Agree** (military train) | Train rec + editable | — | Appends that many `BuildUnitOrder`s when still affordable; else `ShowSnackBarEvent`. |
| **Agree** (military invade) | Invade rec + editable | `ArmyMoveRequestedEvent` or inline draft apply | Stages `ArmyMoveOrder`; when declare war required, shows existing invasion confirm dialog first; on proceed stages `declareWar` + move; on cancel no change. |

Read-only while turn resolution blocking (`canMutateViaUi == false`): no primary actions on any tab.

## Industry tab

- Lists ≤3 recommendations from `rankIndustryCounselRecommendations`.
- Deep-link highlights one card and shows detail copy.
- Empty state: “No pressing industry advice this turn.”

## Trade tab

- Lists the **full** AI-equivalent trade book from `rankTradeCounselRecommendationsForHuman` (may exceed three lines).
- Top ≤3 lines carry a ★ on the card (`isHighlight`); same ids drive Market stars on `GAME60001`.
- Each line: Bid or Offer · commodity display name · quantity · brief plain-language reason (no raw enum keys).
- **Apply recommended market book** replaces all staged trade orders for the human player.
- Per-line **Agree** stages that commodity only.
- Empty state: “No pressing market advice this turn.” (no Apply/Agree buttons.)

## Military tab

- Lists ≤3 recommendations from `rankMilitaryCounselRecommendations`.
- Train cards: unit display name, count, treasury/material/peasant cost summary, brief reason.
- Invade cards: army id, destination province display name, owner, invasion intel lines (DLG20001 parity), brief reason.
- Per-card **Agree** stages train builds or invasion move per validation rules above.
- Empty state: “No pressing military advice this turn.”

## Navigation payload

`Routes.counsel` args: `game`, `humanPlayerId`, optional `highlightRecommendationId`, optional `counselTab` (`'trade'` selects Trade; `'military'` selects Military; omitted → Industry).

## Widgetbook

- `Counsel Industry (default)` — full-availability demo player; live ranking.
- `Counsel Industry (highlight)` — same with `highlightRecommendationId` for first produce rec when present.
- `Counsel Industry (empty)` — player with no feasible industry advice fixture.
- `Counsel Industry (narrow 360)` — mobile viewport (`360×640` dp) with live ranking.
- `Counsel Trade (default)` — demo player with live trade counsel ranking; Trade tab selected.
- `Counsel Trade (highlight)` — Trade tab with `highlightRecommendationId` when a highlight exists.
- `Counsel Trade (empty)` — bare stockpile fixture; empty-state copy.
- `Counsel Trade (narrow 360)` — mobile viewport with Trade tab.
- `Counsel Military (default)` — demo player with live military counsel ranking; Military tab selected.
- `Counsel Military (empty)` — bare fixture; empty-state copy.
- `Counsel Military (narrow 360)` — mobile viewport with Military tab.

## Acceptance criteria

- Given the human opens Counsel from Production, when the screen builds, then title is **Counsel** and the Industry tab lists ≤3 recommendations or the empty-state copy.
- Given navigation with `highlightRecommendationId` and Industry tab, when the Industry tab opens, then that card is visually emphasized and detail copy is visible.
- Given a produce recommendation and editable state, when the player taps **Apply recommended industry allocation**, then all recipe desired outputs from the core assignment snapshot are written to `productionDesiredOutputProvider` and recipes outside the snapshot are unchanged.
- Given a train recommendation still affordable, when the player taps **Agree**, then one `RecruitWorkerOrder` for that tier is queued.
- Given a train recommendation no longer affordable, when the player taps **Agree**, then no order is queued and a plain-language snackbar is shown.
- Given unblock feedstock rec, when the player taps **Open Development**, then Development opens and no produce/train order is auto-committed.
- Given the human opens Counsel from Trade Market, when the screen builds, then the Trade tab is selected and lists the full trade book or the trade empty-state copy.
- Given navigation with `highlightRecommendationId` and Trade tab, when the Trade tab opens, then that line is visually emphasized.
- Given a non-empty trade book and editable state, when the player taps **Apply recommended market book**, then `tradeOrdersByPlayerId[human]` equals the counsel book exactly.
- Given a trade line and editable state, when the player taps **Agree**, then that commodity is staged per the line and any opposite-direction order on that commodity is cleared.
- Given the human opens Counsel from Military Units, when the screen builds, then the Military tab is selected and lists ≤3 recommendations or the military empty-state copy.
- Given a train recommendation still affordable and editable state, when the player taps **Agree**, then draft orders gain that many `BuildUnitOrder`s for that unit type.
- Given a train recommendation no longer affordable, when the player taps **Agree**, then no build orders are staged and a plain-language snackbar is shown.
- Given an invade recommendation requiring declare war, when the player taps **Agree** and confirms, then both diplomatic declare-war and army move are staged; cancel leaves drafts unchanged.
- Given an invade recommendation while already at war, when the player taps **Agree**, then only the army move is staged (no redundant war dialog).
