# Military Counsel ranking

**SPEC/program** — Shared human Military Counsel ranking API (Refs #4307).

## Package ownership

| Surface | Package | Path |
|---------|---------|------|
| DTOs, neutral scoring, invasion intel | `colonizethis_orders` | `lib/src/orders/military_counsel_*.dart` |
| `rankMilitaryCounselRecommendations` | `colonizethis_orders` | `lib/src/orders/military_counsel_ranking.dart` |
| App contract export | `colonizethis_logic` | `lib/industry_counsel_api.dart` (Military Counsel section) |

## Rules

- Neutral agenda only: no AI personality weights, H8 crisis boosts, colonial-pressure cargo nudges, or weighted-random selection.
- Candidates come from `suggestBuildOrders` (military + naval only; civilians excluded) and invasion-oriented `armyMovePickerDestinations` (non-owned destinations; Home Army excluded).
- Global top ≤3 among train + invade cards.
- Each returned recommendation sets `isHighlight: true` for counsel-card and train-row ★ parity (Refs #4307 Slice C).
- Cross-kind sort: descending `rankScore`, then kind precedence `trainUnit` < `invade`, then stable id.
- Stable ids: `train:<unitType>`, `invade:<armyId>:<destinationProvinceId>`.
- **Train count:** greedy multi-count of the top affordable unit type while treasury, peasants, and stockpile remain sufficient after pending recruit/build/research orders (same sequential projection as `pendingTreasuryCostsForTurn`).
- **Invade intel:** fog-respecting defender summary using `provincePanelShowsFullTileDerivedIntel` (parity with `DLG20001` / #4216).
- **Agree apply (UI slice B):** stages validated `BuildUnitOrder`s or `ArmyMoveOrder` + declare-war confirm when required; not part of this ranking API.

## Scoring (neutral)

| Kind | Score |
|------|-------|
| Train regiment | `1000 / buildTreasuryCost` (prefer cheaper affordable types) |
| Train ship | `1 + cargoHold × 0.1` |
| Invade at-war target | `1 + kMovePreferEnemyTerritoryBonus` |
| Invade peace target (declare-war path) | `1.0` |
| Own-territory army moves | excluded from invade candidates |

## AI alignment

`colonizethis_ai` build and conquest planners may later delegate neutral subsets to these modules; human counsel must not import `colonizethis_ai`.

`tool/check_logic_ai_decoupling.sh` rejects `colonizethis_ai` in `colonizethis_logic` and `colonizethis_orders` pubspecs.
