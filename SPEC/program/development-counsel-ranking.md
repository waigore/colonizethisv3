# Development Counsel ranking

**SPEC/program** — Shared human Development Counsel ranking API (Refs #4332 Slice 2).

## Package ownership

| Surface | Package | Path |
|---------|---------|------|
| Shared Engineer work score (road/port/fort) | `colonizethis_orders` | `lib/src/orders/engineer_work_scoring.dart` |
| DTOs + `rankDevelopmentCounselRecommendations` | `colonizethis_orders` | `lib/src/orders/development_counsel_*.dart` |
| App contract export | `colonizethis_logic` | `lib/industry_counsel_api.dart` (Development Counsel section) |

## Rules

- Neutral agenda only: no AI personality weights, H8 crisis boosts, or weighted-random selection.
- Candidates come from `suggestWorkOrders` Engineer targets (`build_road`, `build_port`, `build_fort`).
- Per idle Engineer (stable unit id), score that unit’s candidates with `engineerWorkScore` (same formulas as `SPEC/ai/civilian-work-planner.md` Engineer path, including connectivity overseas-linkage when `tileMapByRegion` is supplied).
- Emit a **Build port** recommendation only when that Engineer’s top-scoring candidate is `build_port`.
- Deduplicate by `targetTileKey` (keep highest `rankScore`); global top ≤3; each returned card sets `isHighlight: true`.
- Stable ids: `build_port:<targetTileKey>`.
- Sort: descending `rankScore`, then ascending tile key.
- Brief reason keys (player language): `resourceCoast`, `newWorldCoast`, `overseasLinkage`, else `coastalPort`.
- **Agree apply (UI):** stages one pending `WorkOrder(build_port)` on the preferred recommendation `unitId` when still idle/valid for that tile via `getValidWorkOrderTileKeysWithVisibility`, else the first idle Engineer (stable unit id) for which the recommended tile remains valid; else snackbar. Must not call broad `suggestWorkOrders` from `app/lib` (`repo.app_lib_no_broad_suggest_work_orders`).

## Scoring

Uses GA-tunable constants from `ai_victory_config.dart` (`kEngineerBuildPortBaseWorkScore`, resource / New World / overseas-linkage bonuses, and road/fort peers for cross-target selection). Full AI civilian-work selection **must** call the same `engineerWorkScore` / `bestEngineerWorkOrder` helpers so counsel and AI stay aligned.

## AI alignment

`colonizethis_ai_contracts` Engineer selection delegates to `colonizethis_orders` scoring. Human counsel must not import `colonizethis_ai`.

## Acceptance criteria

- Given fixtures where the shared Engineer ranker selects a valid `build_port` for an idle Engineer, when `rankDevelopmentCounselRecommendations` runs, then the System returns at least one Build port recommendation with plain reason key and tile/province display fields.
- Given fixtures where every Engineer’s top score is `build_road` or `build_fort` (or no Engineer candidates), when ranking runs, then the System returns no Build port recommendation.
- Given package dependency checks, when Development counsel ranking is built, then `colonizethis_orders` / `colonizethis_logic` do not depend on `colonizethis_ai`.
