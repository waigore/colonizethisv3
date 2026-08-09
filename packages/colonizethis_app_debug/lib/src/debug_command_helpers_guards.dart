import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers_types.dart';
import 'debug_command_helpers_game.dart';
import 'debug_command_helpers_messages.dart';

/// Outcome of the shared debug guard preamble: either a short-circuit
/// [DebugCommandResult] failure, or the resolved `(game, player)` context.
sealed class DebugGuardOutcome {
  const DebugGuardOutcome();
}

/// A guard preamble that short-circuited with [result].
final class DebugGuardFailure extends DebugGuardOutcome {
  const DebugGuardFailure(this.result);

  final DebugCommandResult result;
}

/// A guard preamble that passed, exposing the resolved [game] and [player].
final class DebugGuardPass extends DebugGuardOutcome {
  const DebugGuardPass({required this.game, required this.player});

  final Game game;
  final Player player;
}

/// Runs the shared guard preamble for credit-style and province debug handlers,
/// in this fixed order: active-game, optional Orders-phase gate, optional
/// credited-amount `>= 1`, then player resolution.
///
/// [label] composes ignore messages. When [ordersPhaseLabel] is non-null the
/// Orders-phase gate runs and composes its rejection message with that label
/// (some commands gate under a different label, e.g. treasury's `add_money`).
/// When [creditedAmount] is non-null the `>= 1` guard runs.
DebugGuardOutcome resolveDebugCommandGuards({
  required Game? currentGame,
  required String label,
  required String playerId,
  String? ordersPhaseLabel,
  int? creditedAmount,
}) {
  if (currentGame == null) {
    return DebugGuardFailure(debugNoActiveGame(label));
  }
  if (ordersPhaseLabel != null &&
      currentGame.worldState.turnState.phase != TurnPhase.orders) {
    return DebugGuardFailure(debugOrdersPhaseRejected(ordersPhaseLabel));
  }
  if (creditedAmount != null && creditedAmount < 1) {
    return DebugGuardFailure(debugCreditedAmountBelowMin(label));
  }
  final player = findPlayerById(currentGame, playerId);
  if (player == null) {
    return DebugGuardFailure(debugUnknownPlayer(label, playerId));
  }
  return DebugGuardPass(game: currentGame, player: player);
}

/// Runs the shared spawn guard preamble: active-game, player resolution, then an
/// optional human-player gate. Spawn handlers continue with their own
/// type/count/capital guards after this passes.
DebugGuardOutcome resolveSpawnDebugGuards({
  required Game? currentGame,
  required String label,
  required String playerId,
  bool requireHuman = false,
}) {
  if (currentGame == null) {
    return DebugGuardFailure(debugNoActiveGame(label));
  }
  final player = findPlayerById(currentGame, playerId);
  if (player == null) {
    return DebugGuardFailure(debugUnknownPlayer(label, playerId));
  }
  if (requireHuman && !player.isHuman) {
    return DebugGuardFailure(debugPlayerNotHuman(label, playerId));
  }
  return DebugGuardPass(game: currentGame, player: player);
}
