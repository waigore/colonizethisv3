/// Overture-stage human-input value types for the Diplomacy phase.
///
/// [OvertureOffer] is surfaced when a GP's overture targets a human GP that
/// must accept or reject it; [OvertureDecision] carries that target's reply.
/// Split out of `diplomacy_phase_result.dart` so each diplomacy-phase value
/// type lives in its own file (Refs #3419 step 9). SPEC/game/diplomacy.md
/// § Overtures; SPEC/program/turn-resolution-phases.md § Blocking human input.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// One overture offer awaiting the target's accept/reject decision.
class OvertureOffer {
  const OvertureOffer({
    required this.offererGpId,
    required this.targetFactionId,
    required this.stage,
  });

  final String offererGpId;
  final String targetFactionId;
  final OvertureStage stage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OvertureOffer &&
          offererGpId == other.offererGpId &&
          targetFactionId == other.targetFactionId &&
          stage == other.stage;

  @override
  int get hashCode => Object.hash(offererGpId, targetFactionId, stage);
}

/// Target's decision for one overture offer.
class OvertureDecision {
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OvertureDecision &&
          offererGpId == other.offererGpId &&
          targetFactionId == other.targetFactionId &&
          stage == other.stage &&
          accepted == other.accepted;

  @override
  int get hashCode =>
      Object.hash(offererGpId, targetFactionId, stage, accepted);
}
