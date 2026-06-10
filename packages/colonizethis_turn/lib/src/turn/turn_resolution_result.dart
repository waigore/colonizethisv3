/// Result of turn resolution. SPEC/program/turn-resolution-phases.md § Blocking human input.
/// When the Diplomacy phase needs a human target to accept/reject an overture,
/// resolution returns [TurnResolutionPendingOvertures] and blocks until the app
/// supplies decisions and calls the resume API.
/// When the Diplomacy phase needs intervention choices, resolution returns
/// [TurnResolutionPendingIntervention] and blocks until [resumeTurnResolutionWithInterventionDecisions].
/// When call to arms requires a human ally, resolution returns
/// [TurnResolutionPendingCallToArms].
///
/// The diplomacy-domain offer/decision value types these variants carry
/// ([OvertureOffer], [FtpOffer], [InterventionPrompt], [CallToArmsPending], and
/// related decisions plus [DiplomacyPhaseResult]) live in the diplomacy domain
/// (`diplomacy/diplomacy_phase_result.dart`) so the dependency runs one-way
/// turn -> diplomacy (Refs #3290 Phase 0). They are re-exported here so existing
/// consumers of this file keep seeing them unchanged.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

export 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_phase_result.dart';

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

/// Turn resolution suspended: FTP proposals need human target accept/reject.
class TurnResolutionPendingFtp extends TurnResolutionResult {
  const TurnResolutionPendingFtp({
    required this.game,
    required this.pendingFtpOffers,
  });

  @override
  final Game game;
  final List<FtpOffer> pendingFtpOffers;
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
