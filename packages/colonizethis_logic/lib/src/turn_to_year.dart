import 'package:colonizethis_models/colonizethis_models.dart';

/// Maps turn number to calendar year per SPEC/game/turn-time-mapping.
///
/// Uses [TurnTimeMapping.gdd01] when [mapping] is null (legacy saves).
int turnToYear(int turnNumber, TurnTimeMapping? mapping) {
  final m = mapping ?? TurnTimeMapping.gdd01;
  final turnsBeforeCutoff =
      (m.cutoffYear - m.startYear) ~/ m.yearsPerTurnBeforeCutoff;
  if (turnNumber <= turnsBeforeCutoff) {
    return m.startYear + (turnNumber - 1) * m.yearsPerTurnBeforeCutoff;
  }
  return m.cutoffYear +
      (turnNumber - turnsBeforeCutoff - 1) * m.yearsPerTurnAfterCutoff;
}
