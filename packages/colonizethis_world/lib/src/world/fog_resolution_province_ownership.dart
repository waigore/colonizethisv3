part of 'fog_resolution.dart';

/// Immediate visibility adjustment when province [provinceId] (prefixed id or
/// legacy short id from [resolveProvinceRowForOwnershipTransfer]) transfers from
/// [oldOwnerId] to [newOwnerId]: new owner gets land tiles in the province set
/// to fully visible; former owner's stored visibility for those tiles is
/// downgraded from fully visible to fogged where applicable (unknown unchanged).
/// Returns updated [game] and counts for structured transfer reporting.
/// SPEC/program/fog-and-exploration-resolution.md.
({Game game, ProvinceOwnershipVisibilitySummary visibilitySummary})
applyProvinceOwnershipChangeVisibility(
  Game game,
  String provinceId,
  String oldOwnerId,
  String newOwnerId,
) {
  final row = resolveProvinceRowForOwnershipTransfer(
    game.worldState,
    provinceId,
  );
  if (row == null) {
    return (
      game: game,
      visibilitySummary: const ProvinceOwnershipVisibilitySummary(
        tilesSetFullyVisibleForNewOwner: 0,
        tilesDowngradedForFormerOwner: 0,
      ),
    );
  }
  final canonicalId = row.canonicalProvinceId;
  final regionId = row.province.regionId;
  final tileKeys = landTileKeysForProvinceBucket(
    game.worldState,
    regionId,
    canonicalId,
  );
  if (tileKeys.isEmpty) {
    return (
      game: game,
      visibilitySummary: const ProvinceOwnershipVisibilitySummary(
        tilesSetFullyVisibleForNewOwner: 0,
        tilesDowngradedForFormerOwner: 0,
      ),
    );
  }

  final visMaps = game.worldState.playerVisibilityByTile.map(
    (k, v) => MapEntry(k, Map<String, String>.from(v)),
  );

  var setForNew = 0;
  final newVis = Map<String, String>.from(visMaps[newOwnerId] ?? {});
  for (final tk in tileKeys) {
    newVis[tk] = VisibilityLevel.fullyVisible.name;
    setForNew++;
  }
  visMaps[newOwnerId] = newVis;

  var downgradedForOld = 0;
  final oldVis = Map<String, String>.from(visMaps[oldOwnerId] ?? {});
  for (final tk in tileKeys) {
    final cur = oldVis[tk];
    if (cur == VisibilityLevel.fullyVisible.name) {
      oldVis[tk] = VisibilityLevel.fogged.name;
      downgradedForOld++;
    }
  }
  visMaps[oldOwnerId] = oldVis;

  final nextGame = game.updateWorldState(
    (ws) => ws.copyWith(playerVisibilityByTile: visMaps),
  );

  return (
    game: nextGame,
    visibilitySummary: ProvinceOwnershipVisibilitySummary(
      tilesSetFullyVisibleForNewOwner: setForNew,
      tilesDowngradedForFormerOwner: downgradedForOld,
    ),
  );
}

/// Per-province visibility counts after [applyProvinceOwnershipChangeVisibility].
class ProvinceOwnershipVisibilitySummary {
  const ProvinceOwnershipVisibilitySummary({
    required this.tilesSetFullyVisibleForNewOwner,
    required this.tilesDowngradedForFormerOwner,
  });

  final int tilesSetFullyVisibleForNewOwner;
  final int tilesDowngradedForFormerOwner;
}
