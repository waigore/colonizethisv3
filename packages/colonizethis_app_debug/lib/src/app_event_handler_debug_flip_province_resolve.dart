import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

({Province? province, String? failureMessage}) resolveDebugFlipTarget(
  Game game,
  FlipDebugProvinceOwnershipEvent event,
) {
  final fullProvinceId = event.fullProvinceId;
  if (fullProvinceId != null) {
    final province = game.worldState.tryGetProvince(fullProvinceId);
    if (province == null) {
      return (
        province: null,
        failureMessage:
            'Debug flip_province rejected: province "$fullProvinceId" not found.',
      );
    }
    return (province: province, failureMessage: null);
  }

  final regionId = event.regionId;
  final provinceDisplayName = event.provinceDisplayName;
  if (regionId == null || provinceDisplayName == null) {
    return (
      province: null,
      failureMessage:
          'Debug flip_province rejected: invalid command target. Use region+name or full province id.',
    );
  }
  final regionData = regionDataForId(game.worldState, regionId);
  if (regionData == null) {
    return (
      province: null,
      failureMessage:
          'Debug flip_province rejected: unknown region "$regionId".',
    );
  }
  final normalizedDisplayName = provinceDisplayName.trim().toLowerCase();
  final matched = regionData.provinces
      .where(
        (p) =>
            (p.displayName ?? '').trim().toLowerCase() == normalizedDisplayName,
      )
      .toList(growable: false);
  if (matched.isEmpty) {
    return (
      province: null,
      failureMessage:
          'Debug flip_province rejected: province "$provinceDisplayName" not found in region "$regionId".',
    );
  }
  if (matched.length > 1) {
    final candidateIds = matched.map((p) => p.id).toList()..sort();
    return (
      province: null,
      failureMessage:
          'Debug flip_province rejected: province "$provinceDisplayName" is ambiguous in region "$regionId". '
          'Candidates: ${candidateIds.join(', ')}. Retry with /flip_province <regionId|localId>.',
    );
  }
  return (province: matched.single, failureMessage: null);
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
    for (final MapEntry(key: tileKey, value: level) in updated.entries) {
      if (level != VisibilityLevel.fullyVisible.name) continue;
      if (previous[tileKey] != VisibilityLevel.fullyVisible.name) {
        count++;
      }
    }
  }
  return count;
}
