import 'package:colonizethis_models/colonizethis_models.dart';

/// Shallow [Game] / [WorldState] mutation helpers (Refs #2560).
///
/// Call sites avoid `game.copyWith(worldState: game.worldState.copyWith(
/// turnState: game.worldState.turnState.copyWith(...)))` chains; nested
/// updates live inside these helpers instead.
extension GameWorldMutations on Game {
  /// Returns a copy of this game with [worldState] replaced by [update](worldState).
  Game updateWorldState(WorldState Function(WorldState current) update) =>
      copyWith(worldState: update(worldState));
}

extension WorldStateTurnMutations on WorldState {
  /// Returns a copy with [turnState] replaced by [update](turnState).
  WorldState updateTurnState(TurnState Function(TurnState current) update) =>
      copyWith(turnState: update(turnState));
}
