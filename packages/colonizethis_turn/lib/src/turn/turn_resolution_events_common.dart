import 'package:colonizethis_models/colonizethis_models.dart';

/// Deterministically ordered player ids for [game], sorted ascending. Used by
/// the event emitters so per-player iteration order is stable across runs.
List<String> sortedPlayerIdsForTurnEvents(Game game) =>
    game.players.map((p) => p.id).toList()..sort();
