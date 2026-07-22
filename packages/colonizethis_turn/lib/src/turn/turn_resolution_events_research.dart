import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'turn_event_sink.dart';
import 'turn_resolution_events_common.dart';

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
  required TurnEventSink sink,
}) {
  final eventDialogue = dialogueEventsForTechDiscovered(
    stateAfter,
    discovererId: player.id,
    techId: tech,
    turnNumber: turn,
    seed: turn,
  );
  for (final e in eventDialogue) {
    sink.dialogue(e);
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
    sink.dialogue(e);
  }
}

/// Emit research_complete for each tech newly unlocked in [stateAfter] vs [stateBefore].
void emitResearchCompleteEvents(
  Game stateBefore,
  Game stateAfter,
  int turn,
  TurnEventSink sink,
) {
  final hadTechBefore = _techKeysUnlockedBefore(stateBefore);
  final firstDiscoveriesThisTurn = <String>{};
  final sortedPlayerIds = sortedPlayerIdsForTurnEvents(stateAfter);
  for (final playerId in sortedPlayerIds) {
    final player = stateAfter.playerById(playerId);
    if (player == null) continue;
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
      sink.emit(event);
      if (!sink.hasDialogue) continue;
      _emitResearchDialogueForNewlyUnlockedTech(
        stateAfter: stateAfter,
        player: player,
        tech: tech,
        turn: turn,
        hadTechBefore: hadTechBefore,
        firstDiscoveriesThisTurn: firstDiscoveriesThisTurn,
        sink: sink,
      );
    }
  }
}
