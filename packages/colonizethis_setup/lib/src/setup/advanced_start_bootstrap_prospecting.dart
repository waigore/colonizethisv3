// Advanced-start GP and minor prospecting (step 9). SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'advanced_start_selection.dart';
import 'setup_logging.dart';

Set<String> _prospectRequiredTileKeys(
  Iterable<String> tileKeys,
  Map<String, String> resourceByTileKey,
) {
  return tileKeys
      .where((tileKey) {
        final resourceId = resourceByTileKey[tileKey];
        return resourceId != null &&
            kProspectRequiredResourceIds.contains(resourceId);
      })
      .toSet();
}

Set<String> _ownedProspectableTileKeys({
  required Game game,
  required String ownerId,
  required List<String> regionIds,
}) {
  final resourceByTileKey = game.worldState.resourceByTileKey;
  final keys = <String>{};
  for (final regionId in regionIds) {
    final tileKeysByProvince =
        game.worldState.tileKeysByRegionAndProvince[regionId] ??
        const <String, List<String>>{};
    for (final province in game.worldState.provincesForRegion(regionId)) {
      if (province.ownerId != ownerId) continue;
      final tileKeys = tileKeysByProvince[province.id] ?? const [];
      keys.addAll(_prospectRequiredTileKeys(tileKeys, resourceByTileKey));
    }
  }
  return keys;
}

/// Prospects a tier fraction of mineral tiles in GP-owned OW+NW provinces and
/// minor-owned OW provinces (combined pool per faction).
Game applyAdvancedStartProspecting({
  required Game game,
  required AdvancedStartType startType,
}) {
  final prospectFraction = advancedStartProspectFraction(startType);
  if (prospectFraction <= 0) return game;

  final prospectedByPlayer = {
    for (final entry in game.worldState.playerProspectedTiles.entries)
      entry.key: Set<String>.from(entry.value),
  };

  for (final player in game.players) {
    final pool = _ownedProspectableTileKeys(
      game: game,
      ownerId: player.id,
      regionIds: const [kRegionOldWorld, kRegionNewWorld],
    );
    final selected = selectByFractionCeil(
      pool.toList()..sort(),
      prospectFraction,
    ).toSet();
    if (selected.isEmpty) continue;
    prospectedByPlayer
        .putIfAbsent(player.id, () => <String>{})
        .addAll(selected);
  }

  if (game.players.isNotEmpty) {
    for (var i = 0; i < game.minorNations.length; i++) {
      final minor = game.minorNations[i];
      final buyerId = minorBuyerIdRoundRobin(game, i);
      final pool = _ownedProspectableTileKeys(
        game: game,
        ownerId: minor.id,
        regionIds: const [kRegionOldWorld],
      );
      final selected = selectByFractionCeil(
        pool.toList()..sort(),
        prospectFraction,
      ).toSet();
      if (selected.isEmpty) continue;
      prospectedByPlayer
          .putIfAbsent(buyerId, () => <String>{})
          .addAll(selected);
    }
  }

  setupLog.i(
    'logic: advanced start prospecting applied fraction=$prospectFraction',
  );

  return game.copyWith(
    worldState: game.worldState.copyWith(
      playerProspectedTiles: prospectedByPlayer,
    ),
  );
}
