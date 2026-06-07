/// Diplomacy-phase offer/decision value types and the diplomacy phase result.
///
/// These pure data types describe the human-input prompts the Diplomacy phase
/// can surface (overtures, FTP proposals, interventions, calls to arms) and the
/// per-phase [DiplomacyPhaseResult]. They live in the diplomacy domain so the
/// turn orchestrator's [TurnResolutionResult] (in `turn/turn_resolution_result.dart`)
/// can depend on them one-way (turn -> diplomacy) without the diplomacy domain
/// importing `turn/` (Refs #3290 Phase 0, eliminates the diplomacy -> turn edge).
/// SPEC/program/turn-resolution-phases.md § Blocking human input;
/// SPEC/game/diplomacy.md § Intervention.
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

/// One call-to-arms prompt: ally [allyGpId] must choose to join defender [defenderGpId]
/// against aggressor [aggressorGpId]. SPEC/game/diplomacy.md mutual defence.
class CallToArmsPending {
  const CallToArmsPending({
    required this.allyGpId,
    required this.defenderGpId,
    required this.aggressorGpId,
  });

  final String allyGpId;
  final String defenderGpId;
  final String aggressorGpId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallToArmsPending &&
          allyGpId == other.allyGpId &&
          defenderGpId == other.defenderGpId &&
          aggressorGpId == other.aggressorGpId;

  @override
  int get hashCode => Object.hash(allyGpId, defenderGpId, aggressorGpId);
}

/// One FTP proposal awaiting the target GP's accept/reject decision.
class FtpOffer {
  const FtpOffer({
    required this.proposerGpId,
    required this.targetGpId,
  });

  final String proposerGpId;
  final String targetGpId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FtpOffer &&
          proposerGpId == other.proposerGpId &&
          targetGpId == other.targetGpId;

  @override
  int get hashCode => Object.hash(proposerGpId, targetGpId);
}

/// Target GP's decision for one [FtpOffer].
class FtpDecision {
  const FtpDecision({
    required this.proposerGpId,
    required this.targetGpId,
    required this.accepted,
  });

  final String proposerGpId;
  final String targetGpId;
  final bool accepted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FtpDecision &&
          proposerGpId == other.proposerGpId &&
          targetGpId == other.targetGpId &&
          accepted == other.accepted;

  @override
  int get hashCode => Object.hash(proposerGpId, targetGpId, accepted);
}

/// Human ally's decision for one call to arms.
class CallToArmsDecision {
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallToArmsDecision &&
          allyGpId == other.allyGpId &&
          defenderGpId == other.defenderGpId &&
          aggressorGpId == other.aggressorGpId &&
          accepted == other.accepted;

  @override
  int get hashCode =>
      Object.hash(allyGpId, defenderGpId, aggressorGpId, accepted);
}

/// Result of the Diplomacy phase: complete or pending human input.
class DiplomacyPhaseResult {
  const DiplomacyPhaseResult(
    this.game, {
    this.pendingOvertures,
    this.pendingFtpOffers,
    this.pendingInterventions,
    this.pendingCallToArms,
  });

  final Game game;
  /// Non-null when phase suspended because an overture targets a human GP.
  final List<OvertureOffer>? pendingOvertures;
  /// Non-null when phase suspended because an FTP proposal targets a human GP.
  final List<FtpOffer>? pendingFtpOffers;
  /// Non-null when phase suspended for intervention choices (GP with embassy or purchased land).
  final List<InterventionPrompt>? pendingInterventions;
  /// Non-null when phase suspended because a human ally must accept/refuse call to arms.
  final List<CallToArmsPending>? pendingCallToArms;

  bool get isPending =>
      (pendingOvertures != null && pendingOvertures!.isNotEmpty) ||
      (pendingFtpOffers != null && pendingFtpOffers!.isNotEmpty) ||
      (pendingInterventions != null && pendingInterventions!.isNotEmpty) ||
      (pendingCallToArms != null && pendingCallToArms!.isNotEmpty);
}
