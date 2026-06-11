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

/// Human intervention prompt after a GP declares war on a Minor or Tribe.
/// SPEC/game/diplomacy.md § Intervention.
class InterventionPrompt {
  const InterventionPrompt({
    required this.aggressorGpId,
    required this.defenderMinorOrTribeId,
    required this.interveningGpId,
  });

  final String aggressorGpId;
  final String defenderMinorOrTribeId;
  final String interveningGpId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterventionPrompt &&
          aggressorGpId == other.aggressorGpId &&
          defenderMinorOrTribeId == other.defenderMinorOrTribeId &&
          interveningGpId == other.interveningGpId;

  @override
  int get hashCode => Object.hash(
        aggressorGpId,
        defenderMinorOrTribeId,
        interveningGpId,
      );
}

/// Human ally's decision for one intervention prompt.
class InterventionDecision {
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterventionDecision &&
          aggressorGpId == other.aggressorGpId &&
          defenderMinorOrTribeId == other.defenderMinorOrTribeId &&
          interveningGpId == other.interveningGpId &&
          choice == other.choice;

  @override
  int get hashCode => Object.hash(
        aggressorGpId,
        defenderMinorOrTribeId,
        interveningGpId,
        choice,
      );
}
