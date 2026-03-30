import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../dossier/event_dialogue.dart';
import '../event_bus/game_event_bus.dart';
import '../game_events.dart';

/// Emits game events after turn resolution phases. SPEC/program/game-events.md.
/// Keeps turn_resolver switch thin by moving event emission here.

/// Emit research_complete for each tech newly unlocked in [stateAfter] vs [stateBefore].
void emitResearchCompleteEvents(
  Game stateBefore,
  Game stateAfter,
  int turn,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
  void Function(DialogueEvent)? onDialogue,
) {
  final hadTechBefore = <String>{};
  for (final p in stateBefore.players) {
    final unlocked = p.techUnlocked ?? const <String, bool>{};
    for (final e in unlocked.entries) {
      if (e.value) hadTechBefore.add(e.key);
    }
  }
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
      if (!previousSet.contains(tech)) {
        final event = ResearchCompleteEvent(
          playerId: player.id,
          techId: tech,
          turnNumber: turn,
        );
        deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);
        if (onDialogue != null) {
          final eventDialogue = dialogueEventsForTechDiscovered(
            stateAfter,
            discovererId: player.id,
            techId: tech,
            turnNumber: turn,
            seed: turn,
          );
          for (final e in eventDialogue) onDialogue(e);
          final isFirst =
              !hadTechBefore.contains(tech) &&
              firstDiscoveriesThisTurn.add(tech);
          if (isFirst) {
            final reactive = dialogueEventsForReactiveTechFirst(
              stateAfter,
              discovererId: player.id,
              techId: tech,
              turnNumber: turn,
              seed: turn,
            );
            for (final e in reactive) onDialogue(e);
          }
        }
      }
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
void emitProvinceCapturedEvents(
  Map<String, String?> previousOwnership,
  Game stateAfter,
  int turn,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
  void Function(DialogueEvent)? onDialogue,
) {
  for (final region in [
    stateAfter.worldState.oldWorld,
    stateAfter.worldState.newWorld,
  ]) {
    for (final prov in region.provinces) {
      final previousOwner = previousOwnership[prov.id];
      if (previousOwner != null && previousOwner != prov.ownerId) {
        final event = ProvinceCapturedEvent(
          provinceId: prov.id,
          previousOwnerId: previousOwner,
          newOwnerId: prov.ownerId ?? '',
          turnNumber: turn,
        );
        deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);
      }
      if (onDialogue != null &&
          prov.ownerId != null &&
          prov.ownerId!.isNotEmpty) {
        final colonyDialogue = dialogueEventsForColonyFounded(
          stateAfter,
          provinceId: prov.id,
          previousOwnerId: previousOwner,
          newOwnerId: prov.ownerId!,
          turnNumber: turn,
          seed: turn,
        );
        for (final e in colonyDialogue) onDialogue(e);
      }
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
