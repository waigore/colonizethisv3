import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_event_logging.dart';
import 'diplomacy_phase_result.dart';
import 'overture_establish_order.dart';

export 'overture_establish_order.dart'
    show OvertureOrderStep, OverturePaymentsResult, ValidatedOverture;

OverturePaymentsResult processOverturePayments(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  List<OvertureDecision>? overtureDecisions,
  IntraTurnEventTally? eventTally,
}) {
  var players = List<Player>.from(game.players);
  var overtures = List<OvertureState>.from(game.overtureStates);
  var state = game;

  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    final playerIdx = players.indexWhere((p) => p.id == gpId);
    if (playerIdx < 0) continue;
    var player = players[playerIdx];

    for (final order in entry.value) {
      final step = processEstablishOvertureOrderIfApplicable(
        state: state,
        players: players,
        overtures: overtures,
        playerIdx: playerIdx,
        player: player,
        gpId: gpId,
        order: order,
        turn: turn,
        factionMembership: factionMembership,
        overtureDecisions: overtureDecisions,
        eventTally: eventTally,
      );
      if (step.earlyExit != null) return step.earlyExit!;
      players = step.players;
      overtures = step.overtures;
      state = step.state;
      player = step.player;
    }
  }

  state = state.copyWith(players: players, overtureStates: overtures);
  return OverturePaymentsResult(state);
}

Game advanceOvertures(Game game, int turn) {
  // Spec: "complete the turn after payment" - paid overtures are already advanced in step 1.
  // No additional turn delays in Phase 4 minimal implementation.
  return game;
}
