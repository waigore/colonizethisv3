import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Applies an immediate voluntary Break Alliance from the diplomacy panel.
///
/// Mutates `Game` inline during Orders phase (no pending diplomatic order).
/// SPEC/ui/diplomacy-panel.md § Submitting an action; Refs #3811.
({Game? game, String? message}) applyBreakAllianceImmediately({
  required Game? currentGame,
  required BreakAllianceImmediatelyEvent event,
}) {
  if (currentGame == null) {
    return (game: null, message: 'Break Alliance ignored: no active game.');
  }
  final game = currentGame;
  if (game.worldState.turnState.phase != TurnPhase.orders) {
    return (
      game: null,
      message:
          'Break Alliance rejected: allowed only during human Orders phase.',
    );
  }

  final rel = getRelation(game, event.playerId, event.targetFactionId);
  if (!(rel?.formalAlliance ?? false)) {
    return (
      game: null,
      message: 'Break Alliance rejected: no formal alliance with that faction.',
    );
  }

  final membership = DiplomacyFactionMembership.from(game);
  final turn = game.worldState.turnState.turnNumber;
  final next = applyVoluntaryAllianceBreak(
    game,
    breakerId: event.playerId,
    brokenWithAllyId: event.targetFactionId,
    turn: turn,
    factionMembership: membership,
  );
  if (identical(next, game)) {
    return (
      game: null,
      message: 'Break Alliance rejected: no formal alliance with that faction.',
    );
  }
  return (
    game: next,
    message: 'Alliance with ${event.targetFactionId} broken.',
  );
}
