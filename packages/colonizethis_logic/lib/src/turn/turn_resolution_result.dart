/// Result of turn resolution. SPEC/program/turn-resolution-phases.md § Blocking human input.
/// When the Diplomacy phase needs a human target to accept/reject an overture,
/// resolution returns [TurnResolutionPendingOvertures] and blocks until the app
/// supplies decisions and calls the resume API.
/// When the Diplomacy phase needs intervention choices, resolution returns
/// [TurnResolutionPendingIntervention] and blocks until [resumeTurnResolutionWithInterventionDecisions].
/// When call to arms requires a human ally, resolution returns
/// [TurnResolutionPendingCallToArms].
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
  int get hashCode =>
      Object.hash(aggressorGpId, defenderMinorOrTribeId, interveningGpId);
}

/// Player's intervention choice for one [InterventionPrompt].
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
    this.pendingInterventions,
    this.pendingCallToArms,
  });

  final Game game;
  /// Non-null when phase suspended because an overture targets a human GP.
  final List<OvertureOffer>? pendingOvertures;
  /// Non-null when phase suspended for intervention choices (GP with embassy or purchased land).
  final List<InterventionPrompt>? pendingInterventions;
  /// Non-null when phase suspended because a human ally must accept/refuse call to arms.
  final List<CallToArmsPending>? pendingCallToArms;

  bool get isPending =>
      (pendingOvertures != null && pendingOvertures!.isNotEmpty) ||
      (pendingInterventions != null && pendingInterventions!.isNotEmpty) ||
      (pendingCallToArms != null && pendingCallToArms!.isNotEmpty);
}

/// Sealed result of turn resolution: complete or pending human input.
///
/// Every variant carries the [Game] state at the point resolution finished or
/// suspended, so callers that only need the snapshot (e.g. turn-trace exports,
/// preview tooling) can read [game] without destructuring each variant.
sealed class TurnResolutionResult {
  const TurnResolutionResult();

  /// State at resolution completion or suspension. Every variant supplies this.
  Game get game;
}

/// Turn resolution completed; [game] is the final state.
class TurnResolutionComplete extends TurnResolutionResult {
  const TurnResolutionComplete(this.game, {this.turnNewsDigest});
  @override
  final Game game;
  /// Null when [game.victory] was set this resolution (news dialog suppressed).
  final TurnNewsDigest? turnNewsDigest;
}

/// Turn resolution suspended: [game] is state at suspension; [pendingOvertures]
/// are offers that need the (human) target's accept/reject. App must prompt,
/// collect decisions, and call [resumeTurnResolutionWithOvertureDecisions].
class TurnResolutionPendingOvertures extends TurnResolutionResult {
  const TurnResolutionPendingOvertures({
    required this.game,
    required this.pendingOvertures,
  });

  @override
  final Game game;
  final List<OvertureOffer> pendingOvertures;
}

/// Turn resolution suspended: [game] is after war declarations; [pendingInterventions]
/// need the listed human GPs' choices. App calls [resumeTurnResolutionWithInterventionDecisions].
class TurnResolutionPendingIntervention extends TurnResolutionResult {
  const TurnResolutionPendingIntervention({
    required this.game,
    required this.pendingInterventions,
  });

  @override
  final Game game;
  final List<InterventionPrompt> pendingInterventions;
}

/// Turn resolution suspended: human ally must accept or refuse call to arms.
/// App prompts, then calls [resumeTurnResolutionWithCallToArmsDecisions].
class TurnResolutionPendingCallToArms extends TurnResolutionResult {
  const TurnResolutionPendingCallToArms({
    required this.game,
    required this.pendingCallToArms,
  });

  @override
  final Game game;
  final List<CallToArmsPending> pendingCallToArms;
}

/// Shared read of [TurnResolutionResult.game] for turn pipeline and resolver
/// call sites (Refs #2391 AC4).
Game gameFromTurnResolutionResult(TurnResolutionResult result) => result.game;
