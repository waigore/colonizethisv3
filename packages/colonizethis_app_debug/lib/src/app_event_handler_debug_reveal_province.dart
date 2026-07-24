import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

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

  final resolved = _resolveRevealTarget(game.worldState, event);
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
  final changedCount = _countNewlyVisibleTiles(
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

({Province? province, String? failureMessage}) _resolveRevealTarget(
  WorldState world,
  RevealDebugProvinceEvent event,
) {
  if (event.targetIsFullProvinceId) {
    final province = world.tryGetProvince(event.target);
    if (province == null) {
      return (
        province: null,
        failureMessage:
            'Debug reveal_province rejected: province "${event.target}" not found.',
      );
    }
    return (province: province, failureMessage: null);
  }

  final normalized = event.target.trim().toLowerCase();
  final matched = world
      .allProvinces()
      .where((p) => (p.displayName ?? '').trim().toLowerCase() == normalized)
      .toList(growable: false);
  if (matched.isEmpty) {
    return (
      province: null,
      failureMessage:
          'Debug reveal_province rejected: province "${event.target}" not found.',
    );
  }
  if (matched.length > 1) {
    final candidateIds = matched.map((p) => p.id).toList()..sort();
    return (
      province: null,
      failureMessage:
          'Debug reveal_province rejected: province "${event.target}" is ambiguous. '
          'Candidates: ${candidateIds.join(', ')}. Retry with /reveal_province <regionId|localId>.',
    );
  }
  return (province: matched.single, failureMessage: null);
}

int _countNewlyVisibleTiles({
  required Map<String, String> before,
  required Map<String, String> after,
}) {
  var count = 0;
  for (final MapEntry(key: tileKey, value: level) in after.entries) {
    if (level != VisibilityLevel.fullyVisible.name) continue;
    if (before[tileKey] != VisibilityLevel.fullyVisible.name) {
      count++;
    }
  }
  return count;
}
