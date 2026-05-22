import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

const _kFlipProvinceRejectAlreadyHumanOwned =
    'Debug flip_province rejected: target province is already human-owned.';
const _kFlipProvinceTerminalFallResolved =
    'Immediate terminal outcome resolved: prior owner had no eligible replacement capital; terminal fall semantics applied.';

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

  final resolved = _resolveFlipTarget(currentGame, event);
  final failure = resolved.failureMessage;
  if (failure != null) {
    return (game: null, message: failure);
  }
  final province = resolved.province;
  if (province == null) {
    return (
      game: null,
      message: 'Debug flip_province rejected: target resolution failed.',
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
    return (game: null, message: _kFlipProvinceRejectAlreadyHumanOwned);
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
    final previousCapitalByPlayer = {
      for (final player in currentGame.players)
        player.id: player.capitalProvinceId,
    };
    final previousCapitalByMinor = {
      for (final minor in currentGame.minorNations)
        minor.id: minor.capitalProvinceId,
    };
    final previousCapitalByTribe = {
      for (final tribe in currentGame.tribes) tribe.id: tribe.capitalProvinceId,
    };
    final priorOwnerCapitalProvinceId = _capitalProvinceIdForFaction(
      currentGame,
      oldOwnerId,
    );
    final ownerLosesCapital = priorOwnerCapitalProvinceId == province.id;
    var noEligibleReplacementCapital = false;
    if (ownerLosesCapital) {
      final regionTopology =
          topologyByRegion?[province.regionId] ?? combinedTopology;
      final eligibility = evaluateCapitalReassignmentEligibility(
        state: currentGame,
        playerId: oldOwnerId,
        regionId: province.regionId,
        regionTopology: regionTopology,
        excludedProvinceId: province.id,
      );
      if (!eligibility.eligible) {
        noEligibleReplacementCapital = true;
      }
    }

    final out = applyCanonicalSingleProvinceOwnershipTransferWithResult(
      currentGame,
      targetProvinceId: province.id,
      oldOwnerId: oldOwnerId,
      newOwnerId: event.humanPlayerId,
    );
    final afterCapitalReassignment = applyCapitalReassignmentAfterCombat(
      out.game,
      combinedTopology,
      topologyByRegion: topologyByRegion,
    );
    final afterGreatPowerFall = applyGreatPowerFall(
      afterCapitalReassignment,
      previousCapitalByPlayer,
    );
    final afterFactionReassignment =
        applyFactionCapitalReassignmentAfterCombat(
          afterGreatPowerFall,
          combinedTopology,
          topologyByRegion: topologyByRegion,
        );
    final afterFactionFall = applyFactionTerminalFall(
      afterFactionReassignment,
      previousCapitalByMinor: previousCapitalByMinor,
      previousCapitalByTribe: previousCapitalByTribe,
    );
    final result = out.result;
    final visibilityBeforeCoastal =
        afterFactionFall.worldState.playerVisibilityByTile;
    final visibilityAfterCoastal = applyCoastalSeaZoneFullVisibility(
      afterFactionFall,
      visibilityBeforeCoastal,
      combinedTopology,
      topologyByRegion: topologyByRegion,
    );
    final coastalUpdatedTiles = _countNewlyVisibleTiles(
      before: visibilityBeforeCoastal,
      after: visibilityAfterCoastal,
    );
    final nextGame = afterFactionFall.copyWith(
      worldState: afterFactionFall.worldState.copyWith(
        playerVisibilityByTile: visibilityAfterCoastal,
      ),
    );
    final baseMessage =
        'Flipped province ${result.provinceId}: ${result.oldOwnerId} -> ${result.newOwnerId}. '
        'Regiments transferred: ${result.regimentsTransferred}; fleets transferred: '
        '${result.inPortFleetsTransferred}; visibility updates: +${result.visibilitySummary.tilesSetFullyVisibleForNewOwner} '
        'new-owner land tiles, -${result.visibilitySummary.tilesDowngradedForFormerOwner} former-owner land tiles, '
        '+$coastalUpdatedTiles coastal/sea-zone tiles.';
    final fullMessage = noEligibleReplacementCapital
        ? '$baseMessage $_kFlipProvinceTerminalFallResolved'
        : baseMessage;
    return (game: nextGame, message: fullMessage);
  } on StateError catch (error) {
    return (
      game: null,
      message: 'Debug flip_province rejected: ${error.message}',
    );
  }
}

({Province? province, String? failureMessage}) _resolveFlipTarget(
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

String? _capitalProvinceIdForFaction(Game game, String factionId) {
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
