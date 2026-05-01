import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Apply immediate canonical province ownership transfer from debug console.
({Game? game, String message}) applyDebugFlipProvinceOwnership({
  required Game? currentGame,
  required FlipDebugProvinceOwnershipEvent event,
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
  final human = currentGame.players.where((p) => p.id == event.humanPlayerId);
  if (human.isEmpty) {
    return (
      game: null,
      message:
          'Debug flip_province ignored: unknown player ${event.humanPlayerId}.',
    );
  }

  final regionData = regionDataForId(currentGame.worldState, event.regionId);
  if (regionData == null) {
    return (
      game: null,
      message:
          'Debug flip_province rejected: unknown region "${event.regionId}".',
    );
  }

  final normalizedDisplayName = event.provinceDisplayName.trim().toLowerCase();
  final matched = regionData.provinces
      .where(
        (p) =>
            (p.displayName ?? '').trim().toLowerCase() == normalizedDisplayName,
      )
      .toList(growable: false);
  if (matched.isEmpty) {
    return (
      game: null,
      message:
          'Debug flip_province rejected: province "${event.provinceDisplayName}" not found in region "${event.regionId}".',
    );
  }
  if (matched.length > 1) {
    return (
      game: null,
      message:
          'Debug flip_province rejected: province "${event.provinceDisplayName}" is ambiguous in region "${event.regionId}".',
    );
  }

  final province = matched.single;
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
    return (
      game: out.game,
      message:
          'Flipped province ${result.provinceId}: ${result.oldOwnerId} -> ${result.newOwnerId}. '
          'Regiments transferred: ${result.regimentsTransferred}; fleets transferred: '
          '${result.inPortFleetsTransferred}; visibility updates: +${result.visibilitySummary.tilesSetFullyVisibleForNewOwner} '
          'new-owner land tiles, -${result.visibilitySummary.tilesDowngradedForFormerOwner} former-owner land tiles.',
    );
  } on StateError catch (error) {
    return (
      game: null,
      message: 'Debug flip_province rejected: ${error.message}',
    );
  }
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
