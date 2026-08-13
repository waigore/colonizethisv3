import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'diplomacy_event_logging.dart';
import 'diplomacy_phase_result.dart';
import 'diplomacy_shared_helpers.dart';
import 'overture_establish_accept.dart';
import 'overture_establish_apply.dart';
import 'overture_establish_types.dart';
import 'overture_establish_validate.dart';

export 'overture_establish_types.dart';
export 'overture_establish_validate.dart' show ValidatedOverture;

OvertureOrderStep processEstablishOvertureOrderIfApplicable({
  required Game state,
  required List<Player> players,
  required List<OvertureState> overtures,
  required int playerIdx,
  required Player player,
  required String gpId,
  required DiplomaticOrder order,
  required int turn,
  required DiplomacyFactionMembership factionMembership,
  List<OvertureDecision>? overtureDecisions,
  IntraTurnEventTally? eventTally,
}) {
  final unchanged = (
    players: players,
    overtures: overtures,
    state: state,
    player: player,
    earlyExit: null,
  );

  final validated = validateEstablishOvertureOrder(
    state: state,
    player: player,
    gpId: gpId,
    order: order,
    overtures: overtures,
    factionMembership: factionMembership,
  );
  if (validated == null) return unchanged;

  final targetId = order.targetFactionId;
  final resolution = resolveOvertureAcceptance(
    state: state,
    gpId: gpId,
    targetId: targetId,
    stage: validated.stage,
    targetIsMinorOrTribe: validated.targetIsMinorOrTribe,
    players: players,
    overtures: overtures,
    overtureDecisions: overtureDecisions,
  );
  if (resolution.pending != null) {
    return (
      players: players,
      overtures: overtures,
      state: state,
      player: player,
      earlyExit: resolution.pending,
    );
  }

  if (!resolution.accepted) {
    if (!validated.targetIsGp) return unchanged;
    final nextState = logDiplomaticEvent(
      state,
      turn,
      DiplomaticEventType.overtureRejected,
      {gpId, targetId},
      fromFactionId: gpId,
      toFactionId: targetId,
      overtureStage: validated.stage,
      wasAiInitiator: isAiControlledForEvidence(state, gpId),
      eventTally: eventTally,
      logMessage:
          'diplomacy overture $gpId -> $targetId ${validated.stage} (rejected)',
    );
    return (
      players: players,
      overtures: overtures,
      state: nextState,
      player: player,
      earlyExit: null,
    );
  }

  return applyAcceptedOverture(
    state: state,
    players: players,
    overtures: overtures,
    playerIdx: playerIdx,
    gpId: gpId,
    targetId: targetId,
    stage: validated.stage,
    cost: validated.cost,
    turn: turn,
    eventTally: eventTally,
  );
}
