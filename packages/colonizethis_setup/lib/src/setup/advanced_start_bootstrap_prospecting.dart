// Advanced-start GP and minor prospecting (step 9). SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'setup_logging.dart';

Set<String> _selectProspectFraction({
  required Iterable<String> prospectableTileKeys,
  required double prospectFraction,
}) {
  final prospectable = prospectableTileKeys.toList()..sort();
  if (prospectable.isEmpty) return const {};
  final target = (prospectable.length * prospectFraction).ceil();
  return prospectable.take(target).toSet();
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
      for (final tileKey in tileKeys) {
        final resourceId = resourceByTileKey[tileKey];
        if (resourceId != null &&
            kProspectRequiredResourceIds.contains(resourceId)) {
          keys.add(tileKey);
        }
      }
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
    final selected = _selectProspectFraction(
      prospectableTileKeys: pool,
      prospectFraction: prospectFraction,
    );
    if (selected.isEmpty) continue;
    prospectedByPlayer
        .putIfAbsent(player.id, () => <String>{})
        .addAll(selected);
  }

  if (game.players.isNotEmpty) {
    for (var i = 0; i < game.minorNations.length; i++) {
      final minor = game.minorNations[i];
      final buyerId = game.players[i % game.players.length].id;
      final pool = _ownedProspectableTileKeys(
        game: game,
        ownerId: minor.id,
        regionIds: const [kRegionOldWorld],
      );
      final selected = _selectProspectFraction(
        prospectableTileKeys: pool,
        prospectFraction: prospectFraction,
      );
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
