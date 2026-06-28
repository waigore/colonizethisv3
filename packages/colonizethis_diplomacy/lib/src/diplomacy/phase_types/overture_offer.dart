/// Overture-stage human-input value types for the Diplomacy phase.
///
/// [OvertureOffer] is surfaced when a GP's overture targets a human GP that
/// must accept or reject it; [OvertureDecision] carries that target's reply.
/// Split out of `diplomacy_phase_result.dart` so each diplomacy-phase value
/// type lives in its own file (Refs #3419 step 9). SPEC/game/diplomacy.md
/// § Overtures; SPEC/program/turn-resolution-phases.md § Blocking human input.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'value_equality.dart';

/// One overture offer awaiting the target's accept/reject decision.
class OvertureOffer with ValueEquality {
  const OvertureOffer({
    required this.offererGpId,
    required this.targetFactionId,
    required this.stage,
  });

  final String offererGpId;
  final String targetFactionId;
  final OvertureStage stage;

  @override
  List<Object?> get equalityFields => [offererGpId, targetFactionId, stage];
}

/// Target's decision for one overture offer.
class OvertureDecision with ValueEquality {
  const OvertureDecision({
    required this.offererGpId,
    required this.targetFactionId,
    required this.stage,
    required this.accepted,
  });

  final String offererGpId;
  final String targetFactionId;
  final OvertureStage stage;
  final bool accepted;

  @override
  List<Object?> get equalityFields =>
      [offererGpId, targetFactionId, stage, accepted];
}
