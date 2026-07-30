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
| Recommendation card | Read-only v1 | — | Highlight + detail copy only. |

Agree / apply actions: sibling issue #4191.

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

## Acceptance criteria

- Given the human opens Counsel from Production, when the screen builds, then title is **Counsel** and the Industry tab lists ≤3 recommendations or the empty-state copy.
- Given navigation with `highlightRecommendationId`, when the Industry tab opens, then that card is visually emphasized and detail copy is visible.
