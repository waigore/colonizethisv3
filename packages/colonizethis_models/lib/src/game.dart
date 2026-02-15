import 'player.dart';
import 'world_state.dart';

/// Top-level game container. SPEC/game/world-model.
class Game {
  const Game({
    required this.id,
    required this.worldState,
    required this.players,
  });

  final String id;
  final WorldState worldState;
  final List<Player> players;

  Map<String, dynamic> toJson() => {
        'id': id,
        'worldState': worldState.toJson(),
        'players': players.map((e) => e.toJson()).toList(),
      };

  static Game fromJson(Map<String, dynamic> json) {
    final playersList = json['players'] as List<dynamic>? ?? [];
    return Game(
      id: json['id'] as String,
      worldState: WorldState.fromJson(Map<String, dynamic>.from(json['worldState'] as Map)),
      players: playersList.map((e) => Player.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  Game copyWith({
    String? id,
    WorldState? worldState,
    List<Player>? players,
  }) {
    return Game(
      id: id ?? this.id,
      worldState: worldState ?? this.worldState,
      players: players ?? this.players,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          worldState == other.worldState &&
          _listEquals(players, other.players);

  @override
  int get hashCode => Object.hash(id, worldState, Object.hashAll(players));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
