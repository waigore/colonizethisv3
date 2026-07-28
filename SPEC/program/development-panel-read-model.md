# Development panel read model

**SPEC/program** — Pure projection for the empire Development panel (`GAME80001`). UI: [development-panel.md](../ui/development-panel.md). Improvable definition: [province-extraction-snapshot.md](province-extraction-snapshot.md). Refs #4175.

## Projection

`buildDevelopmentPanelModel` returns a non-persisted `DevelopmentPanelModel` with Old World and New World `DevelopmentPanelRegionModel` slices.

| Field | Meaning |
|-------|---------|
| `ownedScopes` | One row per province owned by the human player in the region (always listed; empty improvable → UI shows “No improvable resources”). |
| `purchasedScopes` | Purchased tiles grouped by source province; includes `provinceOwnerDisplayName` for the province owner. |
| `landExtractionByCommodity` | Post-resolution **effective** extraction projection for connected tiles in the region (same tile-yield math as Extraction phase; no stockpile net / Production Δ). |
| `idleBuilderCount` / `idleEngineerCount` | Civilians with `status == idle`, no `currentWork`, and no pending `WorkOrder` in `currentOrders`. |

## Improvable (definition A)

Owned provinces: `provinceImprovableResourceTileCounts` for `(provinceId, ownerId = player)`.

Purchased land: per purchased tile key owned by the player, same cap/prospect rules as Available; grouped under source province from tile key `region|localId|x|y`.

## Acceptance criteria

- Given owned province P with three improvable grain tiles, when the read model builds, then P’s owned scope lists grain count 3 with sorted tile keys.
- Given purchased tile T in foreign province P owned by GP B, when the read model builds, then a purchased scope under P lists owner display name for B and improvable commodities for T only.
- Given connected improved grain tiles in region R, when the read model builds extraction for R, then grain effective totals match per-tile extraction projection for tiles in R.
- Given two idle Builders and one with a pending work order, when idle counts compute, then `idleBuilderCount == 1`.

## Assign selection (Slice B)

`resolveDevelopmentAssignRowState` / `selectDevelopmentImproveAssignCandidate` in `colonizethis_orders`:

- Idle Builder: `status == idle`, no `currentWork`, no pending `WorkOrder` for that unit; first by stable unit id.
- Tile priority among valid targets for the commodity: capital-connected first, then lower `improvementLevel`, then stable tile key.
- Materials: affordability uses stockpile after deducting other pending material work orders (same order as economy preview).
- Disconnected targets: Assign enabled when improve is otherwise valid; warn dialog on commit (Slice C).

## Road first (Slice C)

`resolveDevelopmentRoadFirstState` / `selectDevelopmentRoadFirstCandidate` in `colonizethis_orders`:

- Idle Engineer: same idle/pending rules as Builder; first by stable unit id.
- Path: shortest owned-tile BFS from improve target to any capital-connected tile; neighbor expansion sorted by tile key.
- Road tile: first legal `build_road` candidate along the path from the connected endpoint back toward the improve target.
- Materials: same pending-work stockpile projection as improve assign.
