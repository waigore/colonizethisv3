# Counsel panel

**Screen ID:** `GAME90001` — stable; do not reassign.
**SPEC/ui** — Industry counsel screen (Industry tab v1). Implementation: `app/lib/features/game/screens/counsel/counsel_screen.dart`.

## Trigger conditions

- Production Allocation header **Counsel** button.
- Production allocation row counsel star (deep-link with `highlightRecommendationId`).

## Industry tab

- Lists ≤3 recommendations from `rankIndustryCounselRecommendations`.
- Deep-link highlights one card and shows detail copy.
- Empty state: “No pressing industry advice this turn.”
- Agree / apply actions: sibling issue #4191.

## Navigation payload

`Routes.counsel` args: `game`, `humanPlayerId`, optional `highlightRecommendationId`.
