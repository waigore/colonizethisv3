import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';
import 'debug_province_target_resolve.dart';

({Province? province, String? failureMessage}) resolveDebugFlipTarget(
  Game game,
  FlipDebugProvinceOwnershipEvent event,
) {
  return resolveDebugProvinceTarget(
    world: game.worldState,
    commandLabel: DebugCommandLabel.flipProvince,
    fullProvinceId: event.fullProvinceId,
    regionId: event.regionId,
    provinceDisplayName: event.provinceDisplayName,
    searchAllRegionsByDisplayName: false,
    ambiguousRetryHint: '/flip_province <regionId|localId>',
  );
}

bool isDebugFlipProvinceKnownToPlayer({
  required Game game,
  required String playerId,
  required Province province,
}) {
  final tileKeys = landTileKeysForProvinceBucket(
    game.worldState,
    province.regionId,
    province.id,
  );
  if (tileKeys.isEmpty) {
    return false;
  }
  final visibility =
      game.worldState.playerVisibilityByTile[playerId] ??
      const <String, String>{};
  for (final tileKey in tileKeys) {
    if (visibility[tileKey] != VisibilityLevel.unknown.name) {
      return true;
    }
  }
  return false;
}

String? debugCapitalProvinceIdForFaction(Game game, String factionId) {
  final player = findPlayerById(game, factionId);
  if (player != null) return player.capitalProvinceId;
  for (final minor in game.minorNations) {
    if (minor.id == factionId) return minor.capitalProvinceId;
  }
  for (final tribe in game.tribes) {
    if (tribe.id == factionId) return tribe.capitalProvinceId;
  }
  return null;
}

int countDebugFlipNewlyVisibleTiles({
  required Map<String, Map<String, String>> before,
  required Map<String, Map<String, String>> after,
}) {
  var count = 0;
  for (final MapEntry(key: playerId, value: updated) in after.entries) {
    final previous = before[playerId] ?? const <String, String>{};
    count += countNewlyFullyVisibleTiles(before: previous, after: updated);
  }
  return count;
}
