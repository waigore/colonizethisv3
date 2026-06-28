import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared helpers for updating every [Game.players] entry in one step.
///
/// Refactor slice for waigore/colonizethis#2071 Phase 1.
///
/// **Not used when** each player's update depends on a [Game] that is mutated
/// between iterations (e.g. extraction interception updating fleets, or
/// research updating shared state). Those call sites keep an explicit
/// `List<Player>` build plus [Game.copyWith] `players:`.
extension GameMapPlayers on Game {
  /// Returns a copy of this game with each player replaced by [update], in
  /// stable list order.
  Game mapPlayers(Player Function(Player player) update) {
    return copyWith(players: players.map(update).toList());
  }
}
