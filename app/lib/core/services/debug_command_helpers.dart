import 'package:colonizethis_logic/colonizethis_logic.dart' show kRegionNewWorld;
import 'package:colonizethis_models/colonizethis_models.dart';

typedef DebugCommandResult = ({Game? game, String message});

/// Canonical per-command labels used to compose debug-console handler messages.
///
/// Centralizes the `Debug <label>` prefixes so guard/short-circuit text stays
/// consistent across handlers (generalizes the prior `set_diplomacy` `_kPrefix`
/// approach to every handler). Refs #3655.
abstract final class DebugCommandLabel {
  static const spawn = 'spawn';
  static const treasuryCredit = 'treasury credit';
  static const addMoney = 'add_money';
  static const addWorker = 'add_worker';
  static const addResource = 'add_resource';
  static const revealProvince = 'reveal_province';
  static const flipProvince = 'flip_province';
  static const setDiplomacy = 'set_diplomacy';
}

/// Canonical `Debug <label>` message prefix shared by all debug handlers.
String debugCommandPrefix(String label) => 'Debug $label';

/// Short-circuit result for the no-active-game guard.
DebugCommandResult debugNoActiveGame(String label) => (
  game: null,
  message: '${debugCommandPrefix(label)} ignored: no active game.',
);

/// Short-circuit result for the human Orders-phase gate.
DebugCommandResult debugOrdersPhaseRejected(String label) => (
  game: null,
  message:
      '${debugCommandPrefix(label)} rejected: command is allowed only during '
      'human Orders phase.',
);

/// Short-circuit result for the credited-amount `>= 1` guard.
DebugCommandResult debugCreditedAmountBelowMin(String label) => (
  game: null,
  message:
      '${debugCommandPrefix(label)} ignored: credited amount must be >= 1.',
);

/// Short-circuit result for the count `>= 1` guard (spawn handlers).
DebugCommandResult debugCountBelowMin(String label) => (
  game: null,
  message: '${debugCommandPrefix(label)} ignored: count must be >= 1.',
);

/// Short-circuit result for the unknown-player guard.
DebugCommandResult debugUnknownPlayer(String label, String playerId) => (
  game: null,
  message: '${debugCommandPrefix(label)} ignored: unknown player $playerId.',
);

/// Short-circuit result for the human-player gate (spawn handlers).
DebugCommandResult debugPlayerNotHuman(String label, String playerId) => (
  game: null,
  message:
      '${debugCommandPrefix(label)} ignored: player $playerId is not human.',
);

/// Short-circuit result for the capital-province presence guard.
DebugCommandResult debugNoCapitalProvince(String label) => (
  game: null,
  message: '${debugCommandPrefix(label)} ignored: player has no capital '
      'province.',
);

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

/// Returns a copy of [game] with the player matching [playerId] replaced by
/// `mutate(player)`. Non-matching players are preserved in order.
Game updateDebugPlayer(
  Game game,
  String playerId,
  Player Function(Player player) mutate,
) {
  final updatedPlayers = game.players
      .map((p) => p.id == playerId ? mutate(p) : p)
      .toList(growable: false);
  return game.copyWith(players: updatedPlayers);
}

/// Formats the shared "requested vs credited" credit-success message.
///
/// Produces `'<subject> +<credited>. <balanceLabel>: <balanceValue>.'`, adding
/// a `(requested <r>, credited <c>)` clause only when the amounts differ.
String debugCreditedAmountMessage({
  required String subject,
  required int requestedAmount,
  required int creditedAmount,
  required String balanceLabel,
  required Object balanceValue,
}) {
  final creditedClause = requestedAmount != creditedAmount
      ? ' (requested $requestedAmount, credited $creditedAmount)'
      : '';
  return '$subject +$creditedAmount$creditedClause. '
      '$balanceLabel: $balanceValue.';
}

/// Appends [units] to the region-appropriate unit bucket (old/new world) of
/// [world], returning the updated [WorldState]. Used by spawn handlers to place
/// units in the correct region without duplicating the split-and-add idiom.
WorldState appendUnitsToRegion(
  WorldState world,
  String regionId,
  List<Unit> units,
) {
  final oldUnits = List<Unit>.from(world.oldWorld.units);
  final newUnits = List<Unit>.from(world.newWorld.units);
  if (regionId == kRegionNewWorld) {
    newUnits.addAll(units);
  } else {
    oldUnits.addAll(units);
  }
  return world.copyWith(
    oldWorld: RegionData(provinces: world.oldWorld.provinces, units: oldUnits),
    newWorld: RegionData(provinces: world.newWorld.provinces, units: newUnits),
  );
}

Player? findPlayerById(Game game, String playerId) {
  for (final candidate in game.players) {
    if (candidate.id == playerId) {
      return candidate;
    }
  }
  return null;
}

int nextCanonicalUnitSequence({required List<Unit> units}) {
  const prefix = 'unit_';
  var maxSeen = 0;
  for (final unit in units) {
    if (!unit.id.startsWith(prefix)) {
      continue;
    }
    final suffix = unit.id.substring(prefix.length);
    final seq = int.tryParse(suffix);
    if (seq != null && seq > maxSeen) {
      maxSeen = seq;
    }
  }
  return maxSeen + 1;
}

String mintCanonicalUnitId({
  required Set<String> usedUnitIds,
  required int nextSequence,
}) {
  var sequence = nextSequence;
  while (usedUnitIds.contains('unit_$sequence')) {
    sequence++;
  }
  final id = 'unit_$sequence';
  usedUnitIds.add(id);
  return id;
}
