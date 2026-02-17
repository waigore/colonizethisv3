import 'minor_nation.dart';
import 'player.dart';
import 'tribe.dart';
import 'turn_time_mapping.dart';
import 'world_state.dart';

/// Top-level game container. SPEC/game/world-model.
class Game {
  const Game({
    required this.id,
    required this.worldState,
    required this.players,
    this.minorNations = const [],
    this.tribes = const [],
    this.turnTimeMapping,
  });

  final String id;
  final WorldState worldState;
  final List<Player> players;
  final List<MinorNation> minorNations;
  final List<Tribe> tribes;

  /// Turn-to-calendar-year mapping. When null (legacy saves), use default per SPEC/game/turn-time-mapping.
  final TurnTimeMapping? turnTimeMapping;

  Map<String, dynamic> toJson() => {
        'id': id,
        'worldState': worldState.toJson(),
        'players': players.map((e) => e.toJson()).toList(),
        'minorNations': minorNations.map((e) => e.toJson()).toList(),
        'tribes': tribes.map((e) => e.toJson()).toList(),
        if (turnTimeMapping != null) 'turnTimeMapping': turnTimeMapping!.toJson(),
      };

  static Game fromJson(Map<String, dynamic> json) {
    final playersList = json['players'] as List<dynamic>? ?? [];
    final minorNationsList = json['minorNations'] as List<dynamic>? ?? [];
    final tribesList = json['tribes'] as List<dynamic>? ?? [];
    final turnTimeMappingJson = json['turnTimeMapping'] as Map<String, dynamic>?;
    return Game(
      id: json['id'] as String,
      worldState: WorldState.fromJson(Map<String, dynamic>.from(json['worldState'] as Map)),
      players: playersList.map((e) => Player.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      minorNations:
          minorNationsList.map((e) => MinorNation.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      tribes: tribesList.map((e) => Tribe.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      turnTimeMapping:
          turnTimeMappingJson != null ? TurnTimeMapping.fromJson(turnTimeMappingJson) : null,
    );
  }

  Game copyWith({
    String? id,
    WorldState? worldState,
    List<Player>? players,
    List<MinorNation>? minorNations,
    List<Tribe>? tribes,
    TurnTimeMapping? turnTimeMapping,
  }) {
    return Game(
      id: id ?? this.id,
      worldState: worldState ?? this.worldState,
      players: players ?? this.players,
      minorNations: minorNations ?? this.minorNations,
      tribes: tribes ?? this.tribes,
      turnTimeMapping: turnTimeMapping ?? this.turnTimeMapping,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          worldState == other.worldState &&
          _listEquals(players, other.players) &&
          _listEquals(minorNations, other.minorNations) &&
          _listEquals(tribes, other.tribes) &&
          turnTimeMapping == other.turnTimeMapping;

  @override
  int get hashCode => Object.hash(
        id,
        worldState,
        Object.hashAll(players),
        Object.hashAll(minorNations),
        Object.hashAll(tribes),
        turnTimeMapping,
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
