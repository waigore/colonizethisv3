// End-of-turn phase: victory check, era dialogue, Spy 5-turn fog decay, Explorer/Spy fog decay.
// SPEC/program/turn-resolution-phase-details.md § End-of-turn.
// Called from turn_resolver.resolveTurnForGame.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../dossier/event_dialogue.dart';
import '../world/player_view.dart';

final Logger _log = Logger();

/// Runs the end-of-turn phase: victory check, era-change dialogue, Spy timers, fog decay, advance turn.
Game runEndOfTurnPhase(Game game, {void Function(DialogueEvent)? onDialogue}) {
  if (game.victory != null) return game;

  final winnerId = findMilitaryVictoryWinner(game);
  if (winnerId != null) {
    final turnNumber = game.worldState.turnState.turnNumber;
    _log.i('logic: military victory set winner=$winnerId turn=$turnNumber');
    return game.copyWith(
      victory: VictoryState(
        winnerPlayerId: winnerId,
        type: VictoryType.military,
        turnNumber: turnNumber,
      ),
    );
  }

  _emitEraChangeDialogue(game, onDialogue);

  final (visibilityByTile, nextSpyTimers) =
      applySpyRevealTimerDecay(game.worldState.playerVisibilityByTile,
          game.worldState.spyRevealTurnsByPlayer,
          game.worldState.tileKeysByRegionAndProvince);
  var stateForFog = game.copyWith(
    worldState: game.worldState.copyWith(
      playerVisibilityByTile: visibilityByTile,
      spyRevealTurnsByPlayer: nextSpyTimers,
    ),
  );
  final nextVisibility = applyFogDecay(stateForFog);

  return game.copyWith(
    worldState: game.worldState.copyWith(
      turnState: game.worldState.turnState.copyWith(
        turnNumber: game.worldState.turnState.turnNumber + 1,
        phase: TurnPhase.orders,
      ),
      playerVisibilityByTile: nextVisibility,
      spyRevealTurnsByPlayer: nextSpyTimers,
    ),
  );
}

void _emitEraChangeDialogue(
    Game game, void Function(DialogueEvent)? onDialogue) {
  if (onDialogue == null) return;
  final currentTurn = game.worldState.turnState.turnNumber;
  final nextTurn = currentTurn + 1;
  final mapping = game.turnTimeMapping ?? TurnTimeMapping.gdd01;
  final previousEra = eraFromYear(mapping.yearAtTurn(currentTurn));
  final newEra = eraFromYear(mapping.yearAtTurn(nextTurn));
  if (previousEra == newEra) return;
  final seed = (game.globalGameSeed ?? 0) ^ (nextTurn * 0x9E3779B1);
  final events = dialogueEventsForEraChange(game, previousEra, newEra, seed);
  for (final e in events) onDialogue(e);
}

/// Spy 5-turn fog decay: decrement timers; where ≤1, set that province's tiles to fogged.
/// SPEC/program/fog-and-exploration-resolution.md.
(Map<String, Map<String, String>>, Map<String, Map<String, int>>)
    applySpyRevealTimerDecay(
  Map<String, Map<String, String>> playerVisibilityByTile,
  Map<String, Map<String, int>> spyRevealTurnsByPlayer,
  Map<String, Map<String, List<String>>> tileKeysByRegion,
) {
  var visibilityByTile = Map<String, Map<String, String>>.from(
    playerVisibilityByTile.map(
      (k, v) => MapEntry(k, Map<String, String>.from(v)),
    ),
  );
  final nextSpyTimers = <String, Map<String, int>>{};
  for (final entry in spyRevealTurnsByPlayer.entries) {
    final playerId = entry.key;
    final byProvince = entry.value;
    final newByProvince = <String, int>{};
    final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
    for (final provEntry in byProvince.entries) {
      final provinceId = provEntry.key;
      final turns = provEntry.value;
      if (turns <= 1) {
        final regionId = ProvinceId.regionIdFrom(provinceId);
        final tileKeys = tileKeysByRegion[regionId]?[provinceId] ?? [];
        for (final tk in tileKeys) {
          vis[tk] = VisibilityLevel.fogged.name;
        }
      } else {
        newByProvince[provinceId] = turns - 1;
      }
    }
    if (newByProvince.isNotEmpty) nextSpyTimers[playerId] = newByProvince;
    visibilityByTile[playerId] = vis;
  }
  return (visibilityByTile, nextSpyTimers);
}

/// For each player, set tiles in other-faction provinces to fogged when no Explorer/Spy in that province.
/// SPEC/program/fog-and-exploration-resolution.md.
Map<String, Map<String, String>> applyFogDecay(Game game) {
  const explorerTypes = {'explorer', 'spy'};
  final owOwnerByProvince = {
    for (final p in game.worldState.oldWorld.provinces) p.id: p.ownerId,
  };
  final nwOwnerByProvince = {
    for (final p in game.worldState.newWorld.provinces) p.id: p.ownerId,
  };

  final provincesWithExplorerByPlayer = <String, Set<String>>{};
  for (final u in game.worldState.oldWorld.units) {
    if (explorerTypes.contains(u.type.toLowerCase())) {
      provincesWithExplorerByPlayer
          .putIfAbsent(u.ownerId, () => <String>{})
          .add(u.locationProvinceId);
    }
  }
  final provincesWithSpyTimerByPlayer = <String, Set<String>>{};
  for (final entry in game.worldState.spyRevealTurnsByPlayer.entries) {
    final playerId = entry.key;
    final provinces = entry.value.keys;
    if (provinces.isEmpty) continue;
    provincesWithSpyTimerByPlayer[playerId] = provinces.toSet();
  }
  for (final u in game.worldState.newWorld.units) {
    if (explorerTypes.contains(u.type.toLowerCase())) {
      provincesWithExplorerByPlayer
          .putIfAbsent(u.ownerId, () => <String>{})
          .add(u.locationProvinceId);
    }
  }

  final result = <String, Map<String, String>>{};
  for (final entry in game.worldState.playerVisibilityByTile.entries) {
    final playerId = entry.key;
    final visibility = Map<String, String>.from(entry.value);
    final hasExplorerIn = provincesWithExplorerByPlayer[playerId] ?? const {};
    final hasSpyTimerIn = provincesWithSpyTimerByPlayer[playerId] ?? const {};

    for (final tileKey in visibility.keys.toList()) {
      final parts = tileKey.split('|');
      if (parts.length != 4) continue;
      final fullProvinceId = ProvinceId.full(parts[0], parts[1]);
      final ownerId = owOwnerByProvince[fullProvinceId] ??
          nwOwnerByProvince[fullProvinceId];
      if (ownerId == null || ownerId == playerId) continue;
      if (!hasExplorerIn.contains(fullProvinceId) &&
          !hasSpyTimerIn.contains(fullProvinceId)) {
        visibility[tileKey] = VisibilityLevel.fogged.name;
      }
    }
    result[playerId] = visibility;
  }
  return result;
}

/// Returns the id of a Great Power that controls 31+ Old World provinces, or null.
String? findMilitaryVictoryWinner(Game game) {
  const int requiredProvinces = 31;
  final countsByOwner = <String, int>{};
  for (final province in game.worldState.oldWorld.provinces) {
    final ownerId = province.ownerId;
    if (ownerId == null || ownerId.isEmpty) continue;
    countsByOwner.update(ownerId, (v) => v + 1, ifAbsent: () => 1);
  }

  final gpIds = game.players.map((p) => p.id).toSet();
  String? winnerId;
  for (final entry in countsByOwner.entries) {
    final ownerId = entry.key;
    final count = entry.value;
    if (!gpIds.contains(ownerId)) continue;
    if (count >= requiredProvinces) {
      if (winnerId == null || ownerId.compareTo(winnerId) < 0) {
        winnerId = ownerId;
      }
    }
  }
  return winnerId;
}
