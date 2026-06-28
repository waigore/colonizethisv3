/// Call-to-arms (mutual-defence) human-input value types for the Diplomacy
/// phase.
///
/// [CallToArmsPending] is surfaced when a human-controlled ally must choose to
/// join a defender against an aggressor; [CallToArmsDecision] carries that
/// ally's reply. Split out of `diplomacy_phase_result.dart` so each
/// diplomacy-phase value type lives in its own file (Refs #3419 step 9).
/// SPEC/game/diplomacy.md § Mutual defence;
/// SPEC/program/turn-resolution-phases.md § Blocking human input.
library;

import 'value_equality.dart';

/// One call-to-arms prompt: ally [allyGpId] must choose to join defender
/// [defenderGpId] against aggressor [aggressorGpId].
/// SPEC/game/diplomacy.md mutual defence.
class CallToArmsPending with ValueEquality {
  const CallToArmsPending({
    required this.allyGpId,
    required this.defenderGpId,
    required this.aggressorGpId,
  });

  final String allyGpId;
  final String defenderGpId;
  final String aggressorGpId;

  @override
  List<Object?> get equalityFields => [allyGpId, defenderGpId, aggressorGpId];
}

/// Human ally's decision for one call to arms.
class CallToArmsDecision with ValueEquality {
  const CallToArmsDecision({
    required this.allyGpId,
    required this.defenderGpId,
    required this.aggressorGpId,
    required this.accepted,
  });

  final String allyGpId;
  final String defenderGpId;
  final String aggressorGpId;
  final bool accepted;

  @override
  List<Object?> get equalityFields =>
      [allyGpId, defenderGpId, aggressorGpId, accepted];
}
