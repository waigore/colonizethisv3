# Counsel panel

**Screen ID:** `GAME90001` — stable; do not reassign.
**SPEC/ui** — Industry counsel screen (Industry tab v1). Implementation: `app/lib/features/game/screens/counsel/counsel_screen.dart`.
**Widgetbook:** `Counsel Panel` → `widgetbook_host/lib/catalogs/catalog_panels.dart`.

## Trigger conditions

- Production Allocation header **Counsel** button (`NavigateToRouteEvent` → `Routes.counsel`).
- Production allocation row counsel star (`highlightRecommendationId` in route args).

## Layout / wireframe

```
CtGameFeatureScreenShell
├── GameFeatureScreenTopBar (← Map, production icon, "Counsel")
└── Column
    ├── Industry tab label (titleSmall)
    └── CounselIndustryTabBody (scrollable list or empty state)
        └── CounselIndustryRecommendationCard (per rec)
            └── CtNinePatchButton primary action when editable
```

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Production header Counsel | Human GP on Production | Counsel Industry tab without forced highlight. |
| Allocation counsel star | Starred produce row tapped | Counsel Industry tab with `highlightRecommendationId`. |

### User actions → outcomes

| Control | When enabled | Emits / calls | Side effects |
|---------|--------------|---------------|--------------|
| ← Map | Always | `Navigator.maybePop()` | Returns to prior route. |
| **Apply recommended industry allocation** | Produce rec + `canMutateViaUi` | — | Merges `industryCounselCoreDesiredOutputByRecipe` into `productionDesiredOutputProvider`; recipes outside snapshot unchanged. |
| **Agree** (train) | Train rec + editable | — | Appends one `RecruitWorkerOrder` when `suggestRecruitWorkerOrders` still accepts tier; else `ShowSnackBarEvent` with failure copy. |
| **Open Development** | Feedstock unblock rec + editable | `NavigateToRouteEvent(Routes.development, …)` | Opens `GAME80001`; no auto-improve order. |

Read-only while turn resolution blocking (`canMutateViaUi == false`): no primary actions.

## Industry tab

- Lists ≤3 recommendations from `rankIndustryCounselRecommendations`.
- Deep-link highlights one card and shows detail copy.
- Empty state: “No pressing industry advice this turn.”

## Navigation payload

`Routes.counsel` args: `game`, `humanPlayerId`, optional `highlightRecommendationId`.

## Widgetbook

- `Counsel Industry (default)` — full-availability demo player; live ranking.
- `Counsel Industry (highlight)` — same with `highlightRecommendationId` for first produce rec when present.
- `Counsel Industry (empty)` — player with no feasible industry advice fixture.
- `Counsel Industry (narrow 360)` — mobile viewport (`360×640` dp) with live ranking.

## Acceptance criteria

- Given the human opens Counsel from Production, when the screen builds, then title is **Counsel** and the Industry tab lists ≤3 recommendations or the empty-state copy.
- Given navigation with `highlightRecommendationId`, when the Industry tab opens, then that card is visually emphasized and detail copy is visible.
- Given a produce recommendation and editable state, when the player taps **Apply recommended industry allocation**, then all recipe desired outputs from the core assignment snapshot are written to `productionDesiredOutputProvider` and recipes outside the snapshot are unchanged.
- Given a train recommendation still affordable, when the player taps **Agree**, then one `RecruitWorkerOrder` for that tier is queued.
- Given a train recommendation no longer affordable, when the player taps **Agree**, then no order is queued and a plain-language snackbar is shown.
- Given unblock feedstock rec, when the player taps **Open Development**, then Development opens and no produce/train order is auto-committed.
