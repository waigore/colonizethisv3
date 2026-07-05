// Unified work-tile candidacy module (Refs #3877 AC4).
// Spec: SPEC/program/order-suggestions.md § Pre-filtering by work target type.
export 'work_tile_candidate_index.dart' show WorkTileCandidateIndex;
export 'tile_keys_probe.dart'
    show
        getValidWorkOrderTileKeys,
        getValidWorkOrderTileKeysWithVisibility,
        rawCandidateTilesForWorkTarget,
        sortedVisibleWorkTargetCandidates;
