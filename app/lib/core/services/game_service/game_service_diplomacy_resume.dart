import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'game_service.dart';
import 'game_service_turn_resume.dart';

/// Diplomacy-resume wrappers mixed into [GameService] (Refs #4582).
mixin GameServiceDiplomacyResume {
  /// Resumes turn resolution after the user has submitted call to arms decisions.
  TurnResolutionResult resumeCallToArmsDecisions(
    Game game,
    List<CallToArmsDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) => gameServiceResumeTurnFromDiplomacy(
    this as GameService,
    game,
    orders,
    onGameEvent: onGameEvent,
    callToArmsDecisions: decisions,
  );

  /// Resumes after overture accept/reject; may complete or pending. SPEC/program/dialogue-system.md.
  TurnResolutionResult resumeOvertureDecisions(
    Game game,
    List<OvertureOffer> pendingOvertures,
    List<OvertureDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) => gameServiceResumeTurnFromDiplomacy(
    this as GameService,
    game,
    orders,
    onGameEvent: onGameEvent,
    overtureDecisions: decisions,
  );

  /// Resumes turn resolution after FTP accept/reject decisions (Diplomacy phase).
  TurnResolutionResult resumeFtpDecisions(
    Game game,
    List<FtpOffer> pendingFtpOffers,
    List<FtpDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) => gameServiceResumeTurnFromDiplomacy(
    this as GameService,
    game,
    orders,
    onGameEvent: onGameEvent,
    ftpDecisions: decisions,
  );

  /// Resumes after human intervention choices (GP declared war on Minor/Tribe).
  TurnResolutionResult resumeInterventionDecisions(
    Game game,
    List<InterventionDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) => gameServiceResumeTurnFromDiplomacy(
    this as GameService,
    game,
    orders,
    onGameEvent: onGameEvent,
    interventionDecisions: decisions,
  );
}
