import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'spy_resolver.dart';
import 'turn_event_sink.dart';

/// Emit spy_caught / spy_defected for spy-resolution outcomes (Refs #3834 R9).
void emitSpyResolutionEvents(
  Game stateAfter,
  SpyResolutionResult result,
  int turn,
  TurnEventSink sink,
) {
  final caught = List<SpyCaughtDetail>.from(result.caughtSpies)
    ..sort((a, b) => a.unitId.compareTo(b.unitId));
  for (final detail in caught) {
    sink.emit(
      SpyCaughtEvent(
        unitId: detail.unitId,
        spyOwnerId: detail.spyOwnerId,
        territoryOwnerId: detail.territoryOwnerId,
        provinceId: detail.provinceId,
        turnNumber: turn,
      ),
    );
    if (!sink.hasDialogue) continue;
    final reactive = dialogueEventsForReactiveSpiesCaught(
      stateAfter,
      speakerId: detail.territoryOwnerId,
      caughtSpyOwnerId: detail.spyOwnerId,
      provinceId: detail.provinceId,
      turnNumber: turn,
      seed: turn,
    );
    for (final e in reactive) {
      sink.dialogue(e);
    }
  }

  final defected = List<SpyDefectedDetail>.from(result.defectedSpies)
    ..sort((a, b) => a.unitId.compareTo(b.unitId));
  for (final detail in defected) {
    sink.emit(
      SpyDefectedEvent(
        unitId: detail.unitId,
        previousOwnerId: detail.previousOwnerId,
        newOwnerId: detail.newOwnerId,
        provinceId: detail.provinceId,
        turnNumber: turn,
      ),
    );
    if (!sink.hasDialogue) continue;
    final reactive = dialogueEventsForReactiveSpiesDefected(
      stateAfter,
      newOwnerId: detail.newOwnerId,
      previousOwnerId: detail.previousOwnerId,
      provinceId: detail.provinceId,
      turnNumber: turn,
      seed: turn,
    );
    for (final e in reactive) {
      sink.dialogue(e);
    }
  }
}
