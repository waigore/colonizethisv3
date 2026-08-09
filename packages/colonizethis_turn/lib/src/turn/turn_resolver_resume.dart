import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_resolution_result.dart';
import 'turn_resolver.dart';

/// Resumes turn resolution after the app has collected overture accept/reject
/// decisions from the human target(s). Call with the [game] and
/// [pendingOvertures] from [TurnResolutionPendingOvertures], the [decisions]
/// from the user, and the [config] that matches the original
/// [resolveTurnForGameWithConfig] call (orders, topology, etc.). The resume
/// entry points re-enter resolution at [TurnPhase.diplomacy] (Refs #3416,
/// `SPEC/program/turn-resume-config-dispatch.md`).
TurnResolutionResult resumeTurnResolutionWithOvertureDecisions({
  required Game game,
  required List<OvertureOffer> pendingOvertures,
  required List<OvertureDecision> decisions,
  required TurnResolverConfig config,
}) {
  return _resumeTurnResolutionWithDiplomacyDecisions(
    game: game,
    config: config,
    overtureDecisions: decisions,
  );
}

/// Resumes turn resolution after human FTP accept/reject decisions (Diplomacy
/// phase). [config] must match the original resolve call. See
/// [resumeTurnResolutionWithOvertureDecisions].
TurnResolutionResult resumeTurnResolutionWithFtpDecisions({
  required Game game,
  required List<FtpDecision> decisions,
  required TurnResolverConfig config,
}) {
  return _resumeTurnResolutionWithDiplomacyDecisions(
    game: game,
    config: config,
    ftpDecisions: decisions,
  );
}

/// Resumes turn resolution after human intervention choices (Diplomacy phase).
/// [config] must match the original resolve call. See
/// [resumeTurnResolutionWithOvertureDecisions].
TurnResolutionResult resumeTurnResolutionWithInterventionDecisions({
  required Game game,
  required List<InterventionDecision> decisions,
  required TurnResolverConfig config,
}) {
  return _resumeTurnResolutionWithDiplomacyDecisions(
    game: game,
    config: config,
    interventionDecisions: decisions,
  );
}

/// Resumes turn resolution after human ally(ies) responded to call to arms.
/// [config] must match the original resolve call. See
/// [resumeTurnResolutionWithOvertureDecisions].
TurnResolutionResult resumeTurnResolutionWithCallToArmsDecisions({
  required Game game,
  required List<CallToArmsDecision> decisions,
  required TurnResolverConfig config,
}) {
  return _resumeTurnResolutionWithDiplomacyDecisions(
    game: game,
    config: config,
    callToArmsDecisions: decisions,
  );
}

/// Shared dispatch for the Diplomacy-phase resume entry points. All re-enter
/// [resolveTurnForGameWithConfig] at [TurnPhase.diplomacy] using the supplied
/// [config], overriding only [TurnResolverConfig.startFromPhase] and the one
/// decision list each wrapper carries. Threading a single [TurnResolverConfig]
/// (instead of every individual resolver parameter) keeps the resume entry
/// points free of duplicated parameter lists: a new resolver parameter is added
/// to [TurnResolverConfig] once and flows through here automatically (Refs
/// #3416, `SPEC/program/turn-resume-config-dispatch.md`).
TurnResolutionResult _resumeTurnResolutionWithDiplomacyDecisions({
  required Game game,
  required TurnResolverConfig config,
  List<OvertureDecision>? overtureDecisions,
  List<FtpDecision>? ftpDecisions,
  List<InterventionDecision>? interventionDecisions,
  List<CallToArmsDecision>? callToArmsDecisions,
}) {
  return resolveTurnForGameWithConfig(
    game: game,
    config: config.copyWith(
      startFromPhase: TurnPhase.diplomacy,
      overtureDecisions: overtureDecisions,
      ftpDecisions: ftpDecisions,
      interventionDecisions: interventionDecisions,
      callToArmsDecisions: callToArmsDecisions,
    ),
  );
}
