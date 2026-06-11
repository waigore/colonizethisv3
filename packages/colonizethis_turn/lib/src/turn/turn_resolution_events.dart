import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

/// Emits game events after turn resolution phases. SPEC/program/game-events.md.
/// Keeps turn_resolver switch thin by moving event emission here.

Set<String> _techKeysUnlockedBefore(Game stateBefore) {
  final hadTechBefore = <String>{};
  for (final p in stateBefore.players) {
    final unlocked = p.techUnlocked ?? const <String, bool>{};
    for (final e in unlocked.entries) {
      if (e.value) hadTechBefore.add(e.key);
    }
  }
  return hadTechBefore;
}

void _emitResearchDialogueForNewlyUnlockedTech({
  required Game stateAfter,
  required Player player,
  required String tech,
  required int turn,
  required Set<String> hadTechBefore,
  required Set<String> firstDiscoveriesThisTurn,
  required void Function(DialogueEvent) onDialogue,
}) {
  final eventDialogue = dialogueEventsForTechDiscovered(
    stateAfter,
    discovererId: player.id,
    techId: tech,
    turnNumber: turn,
    seed: turn,
  );
  for (final e in eventDialogue) {
    onDialogue(e);
  }
  final isFirst =
      !hadTechBefore.contains(tech) && firstDiscoveriesThisTurn.add(tech);
  if (!isFirst) return;
  final reactive = dialogueEventsForReactiveTechFirst(
    stateAfter,
    discovererId: player.id,
    techId: tech,
    turnNumber: turn,
    seed: turn,
  );
  for (final e in reactive) {
    onDialogue(e);
  }
}

/// Emit research_complete for each tech newly unlocked in [stateAfter] vs [stateBefore].
void emitResearchCompleteEvents(
  Game stateBefore,
  Game stateAfter,
  int turn,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
  void Function(DialogueEvent)? onDialogue,
) {
  final hadTechBefore = _techKeysUnlockedBefore(stateBefore);
  final firstDiscoveriesThisTurn = <String>{};
  final sortedPlayers = List<Player>.from(stateAfter.players)
    ..sort((a, b) => a.id.compareTo(b.id));
  for (final player in sortedPlayers) {
    final unlocked = player.techUnlocked ?? {};
    final current = unlocked.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
    final previous = stateBefore.playerById(player.id)?.techUnlocked ?? {};
    final previousSet = previous.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
    for (final tech in current) {
      if (previousSet.contains(tech)) continue;
      final event = ResearchCompleteEvent(
        playerId: player.id,
        techId: tech,
        turnNumber: turn,
      );
      deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);
      if (onDialogue == null) continue;
      _emitResearchDialogueForNewlyUnlockedTech(
        stateAfter: stateAfter,
        player: player,
        tech: tech,
        turn: turn,
        hadTechBefore: hadTechBefore,
        firstDiscoveriesThisTurn: firstDiscoveriesThisTurn,
        onDialogue: onDialogue,
      );
    }
  }
}

/// Emit diplomacy_change for each relation that changed vs [previousRelations].
void emitDiplomacyChangeEvents(
  Map<String, Map<String, RelationState>> previousRelations,
  Game stateAfter,
  int turn,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
) {
  for (final rel in stateAfter.diplomacyRelations) {
    final prev1 = previousRelations[rel.factionId1]?[rel.factionId2];
    if (prev1 == null || prev1 != rel.state) {
      final event = DiplomacyChangeEvent(
        actorId: rel.factionId1,
        targetId: rel.factionId2,
        changeType: rel.state.name,
        turnNumber: turn,
      );
      deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);
    }
  }
}

/// Emit province_captured for each province whose owner changed vs [previousOwnership].
///
/// Only when **both** previous and new owners are non-empty faction ids (handover to
/// another faction). Null/empty `ownerId` is uncolonized frontier only, not a capture
/// outcome. SPEC/game/world-model.md § Invariants.
void emitProvinceCapturedEvents(
  Map<String, String?> previousOwnership,
  Game stateAfter,
  int turn,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
  void Function(DialogueEvent)? onDialogue,
) {
  for (final prov in stateAfter.worldState.allProvinces()) {
    final previousOwner = previousOwnership[prov.id];
    final newOwner = prov.ownerId;
    if (previousOwner != null &&
        previousOwner.isNotEmpty &&
        newOwner != null &&
        newOwner.isNotEmpty &&
        previousOwner != newOwner) {
      final event = ProvinceCapturedEvent(
        provinceId: prov.id,
        previousOwnerId: previousOwner,
        newOwnerId: newOwner,
        turnNumber: turn,
      );
      deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);
    }
    if (onDialogue == null) continue;
    if (prov.ownerId == null || prov.ownerId!.isEmpty) continue;
    final colonyDialogue = dialogueEventsForColonyFounded(
      stateAfter,
      provinceId: prov.id,
      previousOwnerId: previousOwner,
      newOwnerId: prov.ownerId!,
      turnNumber: turn,
      seed: turn,
    );
    for (final e in colonyDialogue) {
      onDialogue(e);
    }
  }
}

/// Emit victory_set if [state] has victory set.
void emitVictorySetEvent(
  Game state,
  int turn,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
) {
  if (state.victory != null) {
    final event = VictorySetEvent(
      winnerPlayerId: state.victory!.winnerPlayerId,
      victoryType: state.victory!.type.name,
      turnNumber: turn,
    );
    deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);
  }
}

String _prefixedProvinceId(Province province) => province.id.contains('|')
    ? province.id
    : ProvinceId.full(province.regionId, province.id);

Set<String> _seaZonesAtSeaForPlayer(Game game, String playerId) {
  final zones = <String>{};
  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId ||
        !fleet.isAtSea ||
        fleet.seaZoneId == null) {
      continue;
    }
    final localSeaZoneId = fleet.seaZoneId!;
    final prefixed = localSeaZoneId.contains('|')
        ? localSeaZoneId
        : ProvinceId.full(fleet.regionId, localSeaZoneId);
    zones.add(prefixed);
  }
  return zones;
}

/// Emit work_order_completed for units that finished deterministic build/work targets.
void emitWorkOrderCompletedEvents(
  Game stateBefore,
  Game stateAfter,
  int turn,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
) {
  final beforeById = stateBefore.worldState.allUnitsById;
  final afterById = stateAfter.worldState.allUnitsById;
  final supportedTargets = <String>{
    kWorkTargetBuildImprovement,
    kWorkTargetUpgradeTown,
    kWorkTargetBuildRoad,
    kWorkTargetBuildPort,
    kWorkTargetBuildFort,
    kWorkTargetBuildRail,
    kWorkTargetExplore,
  };
  for (final entry in beforeById.entries) {
    final beforeUnit = entry.value;
    final beforeWork = beforeUnit.currentWork;
    if (beforeWork == null ||
        beforeWork.remainingTurns > 1 ||
        !supportedTargets.contains(beforeWork.workTarget)) {
      continue;
    }
    final afterUnit = afterById[entry.key];
    if (afterUnit == null || afterUnit.currentWork != null) {
      continue;
    }
    final provinceId =
        Unit.provinceIdFromTileKey(beforeWork.tileKey) ??
        beforeUnit.locationProvinceId;
    final event = WorkOrderCompletedEvent(
      playerId: beforeUnit.ownerId,
      unitId: beforeUnit.id,
      workTarget: beforeWork.workTarget,
      targetTileKey: beforeWork.tileKey,
      provinceId: provinceId,
      turnNumber: turn,
    );
    deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);
  }
}

/// Emit player-scoped province/sea discovery outcomes for this resolved turn.
///
/// [beforeIndex]/[afterIndex] may be supplied by callers that already built the
/// per-state [ProvinceVisibilityIndex] (e.g. the turn-resolution pipeline reuses
/// the same indices for the news digest) so it is computed once per turn rather
/// than once here and again in `buildTurnNewsDigestForComplete`
/// (`SPEC/program/turn-resolution.md` and the turn-resolution budget rule). When
/// omitted, each index is built from the matching state, preserving prior
/// behaviour for standalone callers.
void emitPlayerDiscoveryEvents(
  Game stateBefore,
  Game stateAfter,
  int turn,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent, {
  ProvinceVisibilityIndex? beforeIndex,
  ProvinceVisibilityIndex? afterIndex,
}) {
  final resolvedBeforeIndex =
      beforeIndex ?? buildProvinceVisibilityIndex(stateBefore);
  final resolvedAfterIndex =
      afterIndex ?? buildProvinceVisibilityIndex(stateAfter);
  final sortedPlayers = List<Player>.from(stateAfter.players)
    ..sort((a, b) => a.id.compareTo(b.id));
  for (final player in sortedPlayers) {
    _emitPlayerProvinceDiscoveryEvents(
      stateAfter: stateAfter,
      playerId: player.id,
      turn: turn,
      beforeIndex: resolvedBeforeIndex,
      afterIndex: resolvedAfterIndex,
      eventBus: eventBus,
      onGameEvent: onGameEvent,
    );
    final beforeSea = _seaZonesAtSeaForPlayer(stateBefore, player.id);
    final afterSea = _seaZonesAtSeaForPlayer(stateAfter, player.id);
    final newlyDiscovered = afterSea.difference(beforeSea).toList()..sort();
    for (final seaZoneId in newlyDiscovered) {
      final event = PlayerSeaZoneDiscoveredEvent(
        playerId: player.id,
        seaZoneId: seaZoneId,
        turnNumber: turn,
      );
      deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);
    }
  }
}

void _emitPlayerProvinceDiscoveryEvents({
  required Game stateAfter,
  required String playerId,
  required int turn,
  required ProvinceVisibilityIndex beforeIndex,
  required ProvinceVisibilityIndex afterIndex,
  required GameEventBus? eventBus,
  required void Function(GameEvent)? onGameEvent,
}) {
  for (final province in stateAfter.worldState.allProvinces()) {
    final fullProvinceId = _prefixedProvinceId(province);
    final wasKnown = beforeIndex.isKnownToPlayer(playerId, fullProvinceId);
    final nowKnown = afterIndex.isKnownToPlayer(playerId, fullProvinceId);
    if (wasKnown || !nowKnown) {
      continue;
    }
    final event = PlayerProvinceDiscoveredEvent(
      playerId: playerId,
      provinceId: fullProvinceId,
      turnNumber: turn,
    );
    deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);
  }
}

/// Emit overture_advanced lines for stage increases in this resolved turn.
void emitOvertureAdvancedEvents(
  Game stateBefore,
  Game stateAfter,
  int turn,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
) {
  OvertureStage beforeStage(String gpId, String targetId) {
    for (final state in stateBefore.overtureStates) {
      if (state.gpId == gpId && state.targetId == targetId) {
        return state.stage;
      }
    }
    return OvertureStage.none;
  }

  for (final overture in stateAfter.overtureStates) {
    final previous = beforeStage(overture.gpId, overture.targetId);
    if (overture.stage.index <= previous.index) {
      continue;
    }
    final event = OvertureAdvancedEvent(
      offererGpId: overture.gpId,
      targetFactionId: overture.targetId,
      newStage: overture.stage.name,
      turnNumber: turn,
    );
    deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);
  }
}
