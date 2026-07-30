# Industry Counsel ranking

**SPEC/program** — Shared human Industry Counsel ranking API (Refs #4189 / #4190).

## Package ownership

| Surface | Package | Path |
|---------|---------|------|
| Core scoring, labour allocation, DTOs | `colonizethis_economy` | `lib/src/economy/industry_counsel/` |
| `rankIndustryCounselRecommendations` | `colonizethis_orders` | `lib/src/orders/industry_counsel_ranking.dart` |
| App contract export | `colonizethis_logic` | `lib/industry_counsel_api.dart` |

## Rules

- Neutral agenda (`kIndustryCounselNeutralAgendaId`); no AI H8 / crisis boosts.
- Global top ≤3 among produce + train + optional feedstock unblock.
- Cross-kind sort: descending `rankScore`, then kind precedence `produceRecipe` < `trainWorker` < `unblockFeedstock`, then stable id.
- Stable ids: `produce:<recipeId>`, `train:<WorkerTier.name>`, `feedstock:<commodityId>`.
- **Agree apply:** `industryCounselCoreDesiredOutputByRecipe` supplies the full core assignment snapshot for produce Agree; `mergeIndustryCounselCoreDesiredOutput` preserves recipes outside the snapshot (Refs #4191).

## AI alignment

`colonizethis_ai` `recipe_scoring.dart` delegates core math to `colonizethis_economy` industry counsel modules.

When no AI-only boost wrappers are active (H8 regiment boost, feedstock reserve, military-rebuild crisis, supplier release, castIron fabric pre-pass), `economy_planner_labour.dart` `allocateLabour` delegates to `industryCounselAllocateLabourCore` with the same stockpile, labour, tech, agenda, and growth-stage inputs.
