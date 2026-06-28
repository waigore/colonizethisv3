/// Intervention human-input value types for the Diplomacy phase.
///
/// [InterventionPrompt] is surfaced after a GP declares war on a Minor or Tribe
/// when a human-controlled GP may intervene; [InterventionDecision] carries the
/// human ally's choice. Split out of `diplomacy_phase_result.dart` so each
/// diplomacy-phase value type lives in its own file (Refs #3419 step 9).
/// SPEC/game/diplomacy.md § Intervention;
/// SPEC/program/turn-resolution-phases.md § Blocking human input.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'value_equality.dart';

/// Human intervention prompt after a GP declares war on a Minor or Tribe.
/// SPEC/game/diplomacy.md § Intervention.
class InterventionPrompt with ValueEquality {
  const InterventionPrompt({
    required this.aggressorGpId,
    required this.defenderMinorOrTribeId,
    required this.interveningGpId,
  });

  final String aggressorGpId;
  final String defenderMinorOrTribeId;
  final String interveningGpId;

  @override
  List<Object?> get equalityFields =>
      [aggressorGpId, defenderMinorOrTribeId, interveningGpId];
}

/// Human ally's decision for one intervention prompt.
class InterventionDecision with ValueEquality {
  const InterventionDecision({
    required this.aggressorGpId,
    required this.defenderMinorOrTribeId,
    required this.interveningGpId,
    required this.choice,
  });

  final String aggressorGpId;
  final String defenderMinorOrTribeId;
  final String interveningGpId;
  final InterventionChoice choice;

  @override
  List<Object?> get equalityFields =>
      [aggressorGpId, defenderMinorOrTribeId, interveningGpId, choice];
}
