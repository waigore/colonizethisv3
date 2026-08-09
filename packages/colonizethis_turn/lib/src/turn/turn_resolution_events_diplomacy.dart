import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'turn_event_sink.dart';
import 'turn_resolution_helpers.dart';

/// Emit diplomacy_change for each relation that changed vs [previousRelations].
void emitDiplomacyChangeEvents(
  Map<String, Map<String, RelationState>> previousRelations,
  Game stateAfter,
  int turn,
  TurnEventSink sink,
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
      sink.emit(event);
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
  TurnEventSink sink,
) {
  for (final prov in stateAfter.worldState.allProvinces()) {
    final previousOwner = previousOwnership[prov.id];
    final newOwner = prov.ownerId;
    if (isProvinceOwnershipCaptured(previousOwner, newOwner)) {
      final event = ProvinceCapturedEvent(
        provinceId: prov.id,
        previousOwnerId: previousOwner!,
        newOwnerId: newOwner!,
        turnNumber: turn,
      );
      sink.emit(event);
    }
    if (!sink.hasDialogue) continue;
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
      sink.dialogue(e);
    }
  }
}

/// Emit victory_set if [state] has victory set.
void emitVictorySetEvent(Game state, int turn, TurnEventSink sink) {
  if (state.victory != null) {
    final event = VictorySetEvent(
      winnerPlayerId: state.victory!.winnerPlayerId,
      victoryType: state.victory!.type.name,
      turnNumber: turn,
    );
    sink.emit(event);
  }
}

/// Emit overture_advanced lines for stage increases in this resolved turn.
void emitOvertureAdvancedEvents(
  Game stateBefore,
  Game stateAfter,
  int turn,
  TurnEventSink sink,
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
    sink.emit(event);
  }
}
