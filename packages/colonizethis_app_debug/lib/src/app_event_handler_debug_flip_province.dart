import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'app_event_handler_debug_flip_province_resolve.dart';
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
  final guard = resolveDebugCommandGuards(
    currentGame: currentGame,
    label: DebugCommandLabel.flipProvince,
    ordersPhaseLabel: DebugCommandLabel.flipProvince,
    playerId: event.humanPlayerId,
  );
  if (guard is DebugGuardFailure) return guard.result;
  guard as DebugGuardPass;
  final game = guard.game;

  final resolved = resolveDebugFlipTarget(game, event);
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

  if (!isDebugFlipProvinceKnownToPlayer(
    game: game,
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
      for (final player in game.players)
        player.id: player.capitalProvinceId,
    };
    final previousCapitalByMinor = {
      for (final minor in game.minorNations)
        minor.id: minor.capitalProvinceId,
    };
    final previousCapitalByTribe = {
      for (final tribe in game.tribes) tribe.id: tribe.capitalProvinceId,
    };
    final priorOwnerCapitalProvinceId = debugCapitalProvinceIdForFaction(
      game,
      oldOwnerId,
    );
    final ownerLosesCapital = priorOwnerCapitalProvinceId == province.id;
    var noEligibleReplacementCapital = false;
    if (ownerLosesCapital) {
      final regionTopology =
          topologyByRegion?[province.regionId] ?? combinedTopology;
      final eligibility = evaluateCapitalReassignmentEligibility(
        state: game,
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
      game,
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
    final coastalUpdatedTiles = countDebugFlipNewlyVisibleTiles(
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
