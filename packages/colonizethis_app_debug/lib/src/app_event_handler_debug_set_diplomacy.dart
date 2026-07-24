import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'app_event_handler_debug_set_diplomacy_alliance.dart';
import 'app_event_handler_debug_set_diplomacy_clear_overture.dart';
import 'app_event_handler_debug_set_diplomacy_ftp.dart';
import 'app_event_handler_debug_set_diplomacy_no_alliance.dart';
import 'app_event_handler_debug_set_diplomacy_no_ftp.dart';
import 'app_event_handler_debug_set_diplomacy_overtures.dart';
import 'app_event_handler_debug_set_diplomacy_peace.dart';
import 'app_event_handler_debug_set_diplomacy_war_peace.dart';
import 'debug_set_diplomacy_common.dart';
import 'debug_command_helpers.dart';

/// Applies an immediate, direct diplomacy-relation mutation between two factions
/// from the debug console (`/set_diplomacy`).
///
/// Bypasses normal diplomacy resolution: it mutates `Game` state directly,
/// enforces hard-incompatibility validation, a per-pair-per-turn quota, the
/// `TurnPhase.orders` gate, `war` side effects (clearing overtures + FTP), and
/// appends [DiplomaticEvent] history. Debug tool only.
/// SPEC/ui/debug-console-panel.md, SPEC/program/debug-console-internals.md.
DebugCommandResult applyDebugSetDiplomacyRelation({
  required Game? currentGame,
  required SetDebugDiplomacyRelationEvent event,
}) {
  if (currentGame == null) {
    return debugNoActiveGame(DebugCommandLabel.setDiplomacy);
  }
  final game = currentGame;
  if (game.worldState.turnState.phase != TurnPhase.orders) {
    return debugOrdersPhaseRejected(DebugCommandLabel.setDiplomacy);
  }

  final resolvedA = resolveDebugDiplomacyFaction(
    game,
    event.factionA ?? event.humanPlayerId,
  );
  if (resolvedA.error != null) {
    return (game: null, message: resolvedA.error!);
  }
  final resolvedB = resolveDebugDiplomacyFaction(game, event.factionB);
  if (resolvedB.error != null) {
    return (game: null, message: resolvedB.error!);
  }
  final factionA = resolvedA.id!;
  final factionB = resolvedB.id!;

  if (factionA == factionB) {
    return (
      game: null,
      message: '$kDebugSetDiplomacyPrefix rejected: a faction cannot set a relation with '
          'itself.',
    );
  }

  final key = pairKey(factionA, factionB);
  if (game.debugDiplomacyUsedPairKeys.contains(key)) {
    return (
      game: null,
      message: '$kDebugSetDiplomacyPrefix rejected: already used debug diplomacy for this pair '
          'this turn.',
    );
  }

  final outcome = _applyAction(
    game: game,
    factionA: factionA,
    factionB: factionB,
    action: event.action,
  );
  if (outcome.error != null) {
    return (game: null, message: outcome.error!);
  }
  final mutated = outcome.game!;
  final nextGame = mutated.copyWith(
    debugDiplomacyUsedPairKeys: {...mutated.debugDiplomacyUsedPairKeys, key},
  );
  return (game: nextGame, message: outcome.message!);
}

DebugDiplomacyActionOutcome _applyAction({
  required Game game,
  required String factionA,
  required String factionB,
  required DebugDiplomacyAction action,
}) {
  final turn = game.worldState.turnState.turnNumber;
  return switch (action) {
    DebugDiplomacyAction.war => applyDebugDiplomacyWar(game, factionA, factionB, turn),
    DebugDiplomacyAction.peace => applyDebugDiplomacyPeace(game, factionA, factionB, turn),
    DebugDiplomacyAction.alliance =>
      applyDebugDiplomacyAlliance(game, factionA, factionB, turn),
    DebugDiplomacyAction.noAlliance =>
      applyDebugDiplomacyNoAlliance(game, factionA, factionB, turn),
    DebugDiplomacyAction.consulate => applyDebugDiplomacyOverture(
      game,
      factionA,
      factionB,
      turn,
      OvertureStage.tradeConsulate,
    ),
    DebugDiplomacyAction.embassy => applyDebugDiplomacyOverture(
      game,
      factionA,
      factionB,
      turn,
      OvertureStage.embassy,
    ),
    DebugDiplomacyAction.nap => applyDebugDiplomacyOverture(
      game,
      factionA,
      factionB,
      turn,
      OvertureStage.nap,
    ),
    DebugDiplomacyAction.joinEmpire => applyDebugDiplomacyOverture(
      game,
      factionA,
      factionB,
      turn,
      OvertureStage.joinEmpire,
    ),
    DebugDiplomacyAction.clearOverture =>
      applyDebugDiplomacyClearOverture(game, factionA, factionB),
    DebugDiplomacyAction.ftp => applyDebugDiplomacyFtp(game, factionA, factionB, turn),
    DebugDiplomacyAction.noFtp => applyDebugDiplomacyNoFtp(game, factionA, factionB, turn),
  };
}
