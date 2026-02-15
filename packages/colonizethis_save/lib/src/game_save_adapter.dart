import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:hive/hive.dart';

/// Saves and loads [Game] state to/from a Hive box. One entry per game, keyed by [Game.id].
/// SPEC/project/phase-1: save format and adapter.
class GameSaveAdapter {
  /// Saves [game] to [box]. Key = game.id, value = game.toJson().
  void save(Box<dynamic> box, Game game) {
    box.put(game.id, game.toJson());
  }

  /// Loads game by [gameId]. Returns null if not found or invalid.
  Game? load(Box<dynamic> box, String gameId) {
    final raw = box.get(gameId);
    if (raw == null) return null;
    try {
      final map = Map<String, dynamic>.from(raw as Map);
      return Game.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Lists all game ids stored in [box].
  List<String> listGameIds(Box<dynamic> box) {
    return box.keys.whereType<String>().toList();
  }

  /// Deletes game [gameId] from [box]. No-op if not present.
  void delete(Box<dynamic> box, String gameId) {
    box.delete(gameId);
  }
}
