import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_event_logging.dart';
import 'diplomacy_shared_helpers.dart';
import 'overture_establish_types.dart';

/// Applies an accepted overture: debits the offerer, upserts the overture stage,
/// records the acceptance event, and returns the advanced step.
OvertureOrderStep applyAcceptedOverture({
  required Game state,
  required List<Player> players,
  required List<OvertureState> overtures,
  required int playerIdx,
  required String gpId,
  required String targetId,
  required OvertureStage stage,
  required int cost,
  required int turn,
  IntraTurnEventTally? eventTally,
}) {
  final nextPlayers = debitPlayerTreasury(players, playerIdx, cost);
  final nextPlayer = nextPlayers[playerIdx];

  var nextOvertures = overtures;
  final osIdx = indexOfOvertureForGpTarget(nextOvertures, gpId, targetId);
  if (osIdx >= 0) {
    nextOvertures = List<OvertureState>.from(nextOvertures);
    nextOvertures[osIdx] = nextOvertures[osIdx].copyWith(
      stage: stage,
      sinceTurn: turn,
    );
  } else {
    nextOvertures = [
      ...nextOvertures,
      OvertureState(
        gpId: gpId,
        targetId: targetId,
        stage: stage,
        sinceTurn: turn,
      ),
    ];
  }
  var nextState = state.copyWith(
    players: nextPlayers,
    overtureStates: nextOvertures,
  );
  nextState = logDiplomaticEvent(
    nextState,
    turn,
    DiplomaticEventType.overtureAccepted,
    {gpId, targetId},
    fromFactionId: gpId,
    toFactionId: targetId,
    overtureStage: stage,
    wasAiInitiator: isAiControlledForEvidence(nextState, gpId),
    eventTally: eventTally,
    logMessage: 'diplomacy overture $gpId -> $targetId $stage (accepted)',
  );
  return (
    players: nextPlayers,
    overtures: nextOvertures,
    state: nextState,
    player: nextPlayer,
    earlyExit: null,
  );
}
