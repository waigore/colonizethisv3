import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';
import 'debug_province_target_resolve.dart';

/// Apply immediate province reveal for debug console command `/reveal_province`.
DebugCommandResult applyDebugRevealProvince({
  required Game? currentGame,
  required RevealDebugProvinceEvent event,
  required MapTopology combinedTopology,
  Map<String, MapTopology>? topologyByRegion,
}) {
  final guard = resolveDebugCommandGuards(
    currentGame: currentGame,
    label: DebugCommandLabel.revealProvince,
    ordersPhaseLabel: DebugCommandLabel.revealProvince,
    playerId: event.humanPlayerId,
  );
  if (guard is DebugGuardFailure) return guard.result;
  guard as DebugGuardPass;
  final game = guard.game;

  final resolved = resolveDebugProvinceTarget(
    world: game.worldState,
    commandLabel: DebugCommandLabel.revealProvince,
    fullProvinceId: event.targetIsFullProvinceId ? event.target : null,
    provinceDisplayName: event.targetIsFullProvinceId ? null : event.target,
    searchAllRegionsByDisplayName: !event.targetIsFullProvinceId,
    ambiguousRetryHint: '/reveal_province <regionId|localId>',
  );
  if (resolved.failureMessage != null) {
    return (game: null, message: resolved.failureMessage!);
  }
  final province = resolved.province;
  if (province == null) {
    return (
      game: null,
      message: 'Debug reveal_province rejected: target resolution failed.',
    );
  }

  final landTileKeys = landTileKeysForProvinceBucket(
    game.worldState,
    province.regionId,
    province.id,
  );
  final beforeByPlayer =
      game.worldState.playerVisibilityByTile[event.humanPlayerId] ??
      const <String, String>{};
  final afterLand = Map<String, String>.from(beforeByPlayer);
  for (final tileKey in landTileKeys) {
    afterLand[tileKey] = VisibilityLevel.fullyVisible.name;
  }
  final afterWithCoastal = applyCoastalSeaZoneFullVisibilityForProvinceTargets(
    game: game,
    playerId: event.humanPlayerId,
    targetProvinceIds: [province.id],
    visibility: afterLand,
    topology: combinedTopology,
    topologyByRegion: topologyByRegion,
  );
  final changedCount = countNewlyFullyVisibleTiles(
    before: beforeByPlayer,
    after: afterWithCoastal,
  );
  if (changedCount == 0) {
    return (
      game: game,
      message:
          'Debug reveal_province no-op: ${province.id} is already fully revealed for ${event.humanPlayerId}.',
    );
  }
  final visibilityByPlayer = Map<String, Map<String, String>>.from(
    game.worldState.playerVisibilityByTile,
  )..[event.humanPlayerId] = afterWithCoastal;
  final nextGame = game.copyWith(
    worldState: game.worldState.copyWith(
      playerVisibilityByTile: visibilityByPlayer,
    ),
  );
  return (
    game: nextGame,
    message:
        'Revealed province ${province.id} for ${event.humanPlayerId}; fully visible tiles +$changedCount.',
  );
}
