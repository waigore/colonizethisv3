import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_event_logging.dart';
import 'diplomacy_shared_helpers.dart';

Game cancelSubsidiesBetweenGps(
  Game game,
  String id1,
  String id2,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);
  final cancelled = subsidyStates
      .where(
        (s) =>
            (s.payerId == id1 && s.targetId == id2) ||
            (s.payerId == id2 && s.targetId == id1),
      )
      .toList();
  if (cancelled.isEmpty) return game;
  subsidyStates = subsidyStates
      .where(
        (s) =>
            !((s.payerId == id1 && s.targetId == id2) ||
                (s.payerId == id2 && s.targetId == id1)),
      )
      .toList();
  var g = game.copyWith(subsidyStates: subsidyStates);
  for (final s in cancelled) {
    g = logDiplomaticEvent(
      g,
      turn,
      DiplomaticEventType.subsidyCancelled,
      {s.payerId, s.targetId},
      fromFactionId: s.payerId,
      toFactionId: s.targetId,
      reason: 'war',
      wasAiInitiator: isAiControlledForEvidence(g, s.payerId),
      eventTally: eventTally,
      logMessage:
          'diplomacy subsidies cancelled due to war ${s.payerId} vs ${s.targetId}',
    );
  }
  return g;
}
