import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../game_events.dart';

/// Emits game events after turn resolution phases. SPEC/program/game-events.md.
/// Keeps turn_resolver switch thin by moving event emission here.

/// Emit research_complete for each tech newly unlocked in [stateAfter] vs [stateBefore].
void emitResearchCompleteEvents(
  Game stateBefore,
  Game stateAfter,
  int turn,
  void Function(GameEvent) onGameEvent,
) {
  for (final player in stateAfter.players) {
    final unlocked = player.techUnlocked ?? {};
    final current = unlocked.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
    final previous = stateBefore.playerById(player.id)?.techUnlocked ?? {};
    final previousSet =
        previous.entries.where((e) => e.value).map((e) => e.key).toSet();
    for (final tech in current) {
      if (!previousSet.contains(tech)) {
        onGameEvent(ResearchCompleteEvent(
          playerId: player.id,
          techId: tech,
          turnNumber: turn,
        ));
      }
    }
  }
}

/// Emit diplomacy_change for each relation that changed vs [previousRelations].
void emitDiplomacyChangeEvents(
  Map<String, Map<String, RelationState>> previousRelations,
  Game stateAfter,
  int turn,
  void Function(GameEvent) onGameEvent,
) {
  for (final rel in stateAfter.diplomacyRelations) {
    final prev1 = previousRelations[rel.factionId1]?[rel.factionId2];
    if (prev1 == null || prev1 != rel.state) {
      onGameEvent(DiplomacyChangeEvent(
        actorId: rel.factionId1,
        targetId: rel.factionId2,
        changeType: rel.state.name,
        turnNumber: turn,
      ));
    }
  }
}

/// Emit province_captured for each province whose owner changed vs [previousOwnership].
void emitProvinceCapturedEvents(
  Map<String, String?> previousOwnership,
  Game stateAfter,
  int turn,
  void Function(GameEvent) onGameEvent,
) {
  for (final region in [
    stateAfter.worldState.oldWorld,
    stateAfter.worldState.newWorld,
  ]) {
    for (final prov in region.provinces) {
      final previousOwner = previousOwnership[prov.id];
      if (previousOwner != null && previousOwner != prov.ownerId) {
        onGameEvent(ProvinceCapturedEvent(
          provinceId: prov.id,
          previousOwnerId: previousOwner,
          newOwnerId: prov.ownerId ?? '',
          turnNumber: turn,
        ));
      }
    }
  }
}

/// Emit victory_set if [state] has victory set.
void emitVictorySetEvent(
  Game state,
  int turn,
  void Function(GameEvent)? onGameEvent,
) {
  if (onGameEvent != null && state.victory != null) {
    onGameEvent(VictorySetEvent(
      winnerPlayerId: state.victory!.winnerPlayerId,
      victoryType: state.victory!.type.name,
      turnNumber: turn,
    ));
  }
}
