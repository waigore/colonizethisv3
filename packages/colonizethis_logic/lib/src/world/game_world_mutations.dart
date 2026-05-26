import 'package:colonizethis_models/colonizethis_models.dart';

/// Shallow [Game] / [WorldState] mutation helpers (Refs #2560, #2836).
///
/// Call sites avoid `game.copyWith(worldState: game.worldState.copyWith(
/// turnState: game.worldState.turnState.copyWith(...)))` chains; nested
/// updates live inside these helpers instead.
///
/// Typed single-field shortcuts ([withWorldState], [withArmies], [withFleets],
/// [withPlayers], [withTileState]) collapse the repeated chained-`copyWith`
/// pattern documented in Issue #2836 item 7. Sites that mutate **multiple**
/// top-level `Game` or `WorldState` fields atomically remain as raw
/// `copyWith` calls so the atomic intent stays explicit (and the helper
/// surface stays small).
extension GameWorldMutations on Game {
  /// Returns a copy of this game with [worldState] replaced by [update](worldState).
  Game updateWorldState(WorldState Function(WorldState current) update) =>
      copyWith(worldState: update(worldState));

  /// Returns a copy with [worldState] replaced by [newWorldState].
  ///
  /// Single-field shortcut for `game.copyWith(worldState: newWorldState)`.
  /// Use raw `copyWith` when multiple top-level [Game] fields change
  /// atomically (e.g. `worldState` + `minorNations` in capital-choice
  /// flows).
  Game withWorldState(WorldState newWorldState) =>
      copyWith(worldState: newWorldState);

  /// Returns a copy with [WorldState.armies] replaced by [armies].
  ///
  /// Single-field shortcut for
  /// `game.updateWorldState((ws) => ws.copyWith(armies: armies))`.
  Game withArmies(List<Army> armies) =>
      updateWorldState((ws) => ws.copyWith(armies: armies));

  /// Returns a copy with [WorldState.fleets] replaced by [fleets].
  ///
  /// Single-field shortcut for
  /// `game.updateWorldState((ws) => ws.copyWith(fleets: fleets))`.
  Game withFleets(List<Fleet> fleets) =>
      updateWorldState((ws) => ws.copyWith(fleets: fleets));

  /// Returns a copy with [Game.players] replaced by [players].
  ///
  /// Single-field shortcut for `game.copyWith(players: players)`. Use raw
  /// `copyWith` when `players` is updated atomically with another top-level
  /// field (e.g. `players` + `diplomacyRelations` in the diplomacy
  /// resolver).
  Game withPlayers(List<Player> players) => copyWith(players: players);

  /// Returns a copy with [WorldState.tileState] replaced by [tileState].
  ///
  /// Single-field shortcut for
  /// `game.updateWorldState((ws) => ws.copyWith(tileState: tileState))`.
  Game withTileState(TileMapState tileState) =>
      updateWorldState((ws) => ws.copyWith(tileState: tileState));
}

extension WorldStateTurnMutations on WorldState {
  /// Returns a copy with [turnState] replaced by [update](turnState).
  WorldState updateTurnState(TurnState Function(TurnState current) update) =>
      copyWith(turnState: update(turnState));
}
