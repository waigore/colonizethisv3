/// Result of turn resolution. SPEC/program/turn-resolution-phases.md § Blocking human input.
/// When the Diplomacy phase needs a human target to accept/reject an overture,
/// resolution returns [TurnResolutionPendingOvertures] and blocks until the app
/// supplies decisions and calls the resume API.

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

/// Result of the Diplomacy phase: either complete or pending overture decisions (human target).
class DiplomacyPhaseResult {
  const DiplomacyPhaseResult(this.game, [this.pendingOvertures]);

  final Game game;
  /// Non-null when phase suspended because an overture targets a human GP.
  final List<OvertureOffer>? pendingOvertures;

  bool get isPending => pendingOvertures != null && pendingOvertures!.isNotEmpty;
}

/// Sealed result of turn resolution: either complete or pending human overture decisions.
sealed class TurnResolutionResult {
  const TurnResolutionResult();
}

/// Turn resolution completed; [game] is the final state.
class TurnResolutionComplete extends TurnResolutionResult {
  const TurnResolutionComplete(this.game);
  final Game game;
}

/// Turn resolution suspended: [game] is state at suspension; [pendingOvertures]
/// are offers that need the (human) target's accept/reject. App must prompt,
/// collect decisions, and call [resumeTurnResolutionWithOvertureDecisions].
class TurnResolutionPendingOvertures extends TurnResolutionResult {
  const TurnResolutionPendingOvertures({
    required this.game,
    required this.pendingOvertures,
  });

  final Game game;
  final List<OvertureOffer> pendingOvertures;
}
