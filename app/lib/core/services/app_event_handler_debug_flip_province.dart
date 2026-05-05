import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Apply immediate canonical province ownership transfer from debug console.
DebugCommandResult applyDebugFlipProvinceOwnership({
  required Game? currentGame,
  required FlipDebugProvinceOwnershipEvent event,
  required MapTopology combinedTopology,
  Map<String, MapTopology>? topologyByRegion,
}) {
  if (currentGame == null) {
    return (
      game: null,
      message: 'Debug flip_province ignored: no active game.',
    );
  }
  if (currentGame.worldState.turnState.phase != TurnPhase.orders) {
    return (
      game: null,
      message:
          'Debug flip_province rejected: command is allowed only during human Orders phase.',
    );
  }
  final human = findPlayerById(currentGame, event.humanPlayerId);
  if (human == null) {
    return (
      game: null,
      message:
          'Debug flip_province ignored: unknown player ${event.humanPlayerId}.',
    );
  }

  final provinceId = event.provinceId;
  final regionId = event.regionId;
  final provinceDisplayName = event.provinceDisplayName;
  final province = switch ((provinceId, regionId, provinceDisplayName)) {
    (final id?, null, null) => currentGame.worldState.tryGetProvince(id),
    (null, final rid?, final displayName?) =>
      _resolveProvinceByDisplayNameInRegion(currentGame, rid, displayName),
    _ => null,
  };
  if (province == null) {
    if (provinceId != null) {
      return (
        game: null,
        message:
            'Debug flip_province rejected: province "$provinceId" not found.',
      );
    }
    if (regionId == null || provinceDisplayName == null) {
      return (
        game: null,
        message: 'Debug flip_province rejected: invalid command target.',
      );
    }
    final ambiguity = _ambiguousProvinceIdsInRegion(
      currentGame.worldState,
      regionId,
      provinceDisplayName,
    );
    if (ambiguity.length > 1) {
      return (
        game: null,
        message:
            'Debug flip_province rejected: province "$provinceDisplayName" is ambiguous in region "$regionId". '
            'Candidate ids: ${ambiguity.join(', ')}. Retry with /flip_province <regionId|localId>.',
      );
    }
    return (
      game: null,
      message:
          'Debug flip_province rejected: province "$provinceDisplayName" not found in region "$regionId".',
    );
  }
  final oldOwnerId = province.ownerId;
  if (oldOwnerId == null || oldOwnerId.isEmpty) {
    return (
      game: null,
      message:
          'Debug flip_province rejected: target province has no current owner.',
    );
  }
  if (oldOwnerId == event.humanPlayerId) {
    return (
      game: null,
      message:
          'Debug flip_province rejected: target province is already human-owned.',
    );
  }

  if (!_isProvinceKnownToPlayer(
    game: currentGame,
    playerId: event.humanPlayerId,
    province: province,
  )) {
    return (
      game: null,
      message:
          'Debug flip_province rejected: target province is unknown to human player.',
    );
  }

  try {
    final out = applyCanonicalSingleProvinceOwnershipTransferWithResult(
      currentGame,
      targetProvinceId: province.id,
      oldOwnerId: oldOwnerId,
      newOwnerId: event.humanPlayerId,
    );
    final result = out.result;
    final visibilityBeforeCoastal = out.game.worldState.playerVisibilityByTile;
    final visibilityAfterCoastal = applyCoastalSeaZoneFullVisibility(
      out.game,
      visibilityBeforeCoastal,
      combinedTopology,
      topologyByRegion: topologyByRegion,
    );
    final coastalUpdatedTiles = _countNewlyVisibleTiles(
      before: visibilityBeforeCoastal,
      after: visibilityAfterCoastal,
    );
    final nextGame = out.game.copyWith(
      worldState: out.game.worldState.copyWith(
        playerVisibilityByTile: visibilityAfterCoastal,
      ),
    );
    return (
      game: nextGame,
      message:
          'Flipped province ${result.provinceId}: ${result.oldOwnerId} -> ${result.newOwnerId}. '
          'Regiments transferred: ${result.regimentsTransferred}; fleets transferred: '
          '${result.inPortFleetsTransferred}; visibility updates: +${result.visibilitySummary.tilesSetFullyVisibleForNewOwner} '
          'new-owner land tiles, -${result.visibilitySummary.tilesDowngradedForFormerOwner} former-owner land tiles, '
          '+$coastalUpdatedTiles coastal/sea-zone tiles.',
    );
  } on StateError catch (error) {
    return (
      game: null,
      message: 'Debug flip_province rejected: ${error.message}',
    );
  }
}

Province? _resolveProvinceByDisplayNameInRegion(
  Game game,
  String regionId,
  String provinceDisplayName,
) {
  final regionData = regionDataForId(game.worldState, regionId);
  if (regionData == null) {
    return null;
  }
  final normalizedDisplayName = provinceDisplayName.trim().toLowerCase();
  final matched = regionData.provinces
      .where(
        (p) =>
            (p.displayName ?? '').trim().toLowerCase() == normalizedDisplayName,
      )
      .toList(growable: false);
  if (matched.length != 1) {
    return null;
  }
  return matched.single;
}

List<String> _ambiguousProvinceIdsInRegion(
  WorldState worldState,
  String regionId,
  String provinceDisplayName,
) {
  final regionData = regionDataForId(worldState, regionId);
  if (regionData == null) {
    return const [];
  }
  final normalizedDisplayName = provinceDisplayName.trim().toLowerCase();
  final ids = regionData.provinces
      .where(
        (p) =>
            (p.displayName ?? '').trim().toLowerCase() == normalizedDisplayName,
      )
      .map((p) => p.id)
      .toList(growable: false);
  ids.sort();
  return ids;
}

bool _isProvinceKnownToPlayer({
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

int _countNewlyVisibleTiles({
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
