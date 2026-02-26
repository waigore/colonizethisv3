import 'package:colonizethis_models/colonizethis_models.dart';

/// Maps turn number to calendar year per SPEC/game/turn-time-mapping.
///
/// Single source of truth: delegates to [TurnTimeMapping.yearAtTurn].
/// Uses [TurnTimeMapping.gdd01] when [mapping] is null (legacy saves).
int turnToYear(int turnNumber, TurnTimeMapping? mapping) {
  return (mapping ?? TurnTimeMapping.gdd01).yearAtTurn(turnNumber);
}
