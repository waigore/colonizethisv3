import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import '../turn_phase_snapshot.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolution_events.dart';
import '../turn_resolution_result.dart';
import '../turn_resolver_config.dart';

/// Diplomacy phase handler — resolves overtures, interventions, calls to arms,
/// and relation updates; emits diplomacy events; may exit early with a pending
/// result. Refs #2560.
TurnPhaseStepOutcome diplomacyTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final stateBeforeDiplomacy = acc.game;
  final previousRelations = snapshotSymmetricPairs(
    acc.game.diplomacyRelations,
    (rel) => rel.factionId1,
    (rel) => rel.factionId2,
    (rel) => rel.state,
  );
  final diploResult = resolveDiplomacyPhase(
    acc.game,
    config.orders,
    onDialogue: config.onDialogue,
    overtureDecisions: config.overtureDecisions,
    ftpDecisions: config.ftpDecisions,
    interventionDecisions: config.interventionDecisions,
    callToArmsDecisions: config.callToArmsDecisions,
  );
  if (diploResult.isPending) {
    final po = diploResult.pendingOvertures;
    if (po != null && po.isNotEmpty) {
      return TurnPhaseStepExit(
        TurnResolutionPendingOvertures(
          game: diploResult.game,
          pendingOvertures: po,
        ),
      );
    }
    final pf = diploResult.pendingFtpOffers;
    if (pf != null && pf.isNotEmpty) {
      return TurnPhaseStepExit(
        TurnResolutionPendingFtp(
          game: diploResult.game,
          pendingFtpOffers: pf,
        ),
      );
    }
    final pi = diploResult.pendingInterventions;
    if (pi != null && pi.isNotEmpty) {
      return TurnPhaseStepExit(
        TurnResolutionPendingIntervention(
          game: diploResult.game,
          pendingInterventions: pi,
        ),
      );
    }
    final cta = diploResult.pendingCallToArms;
    if (cta != null && cta.isNotEmpty) {
      return TurnPhaseStepExit(
        TurnResolutionPendingCallToArms(
          game: diploResult.game,
          pendingCallToArms: cta,
        ),
      );
    }
    throw StateError('diplomacy pending but no pending lists populated');
  }
  final sink = config.eventSink;
  emitDiplomacyChangeEvents(previousRelations, diploResult.game, turn, sink);
  emitOvertureAdvancedEvents(stateBeforeDiplomacy, diploResult.game, turn, sink);
  return TurnPhaseStepContinue(acc.copyWith(game: diploResult.game));
}
