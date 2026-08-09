// Shared advanced-start fraction selection and minor-buyer round-robin.
// SPEC/game/advanced-starts.md (steps 10–11). Refs #4054.

import 'package:colonizethis_models/colonizethis_models.dart';

/// Returns the first `ceil(n * [fraction])` items from an already-sorted
/// [sortedCandidates] list (empty in → empty out).
List<T> selectByFractionCeil<T>(List<T> sortedCandidates, double fraction) {
  if (sortedCandidates.isEmpty) return <T>[];
  final target = (sortedCandidates.length * fraction).ceil();
  return sortedCandidates.take(target).toList();
}

/// Round-robin Great Power buyer id for minor-nation index [index].
///
/// Callers must ensure [game.players] is non-empty (same precondition as the
/// previous inline `game.players[i % game.players.length].id` sites).
String minorBuyerIdRoundRobin(Game game, int index) {
  final players = game.players;
  return players[index % players.length].id;
}
