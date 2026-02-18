import 'combat_mode.dart';
import 'diplomacy.dart';
import 'minor_nation.dart';
import 'player.dart';
import 'tribe.dart';
import 'turn_time_mapping.dart';
import 'world_state.dart';

/// Victory type. Phase 5: military only (31+ OW provinces). SPEC/game/victory.md.
enum VictoryType {
  military,
}

extension VictoryTypeJson on VictoryType {
  static VictoryType fromJson(String value) {
    return VictoryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VictoryType.military,
    );
  }

  String toJson() => name;
}

/// Victory state for a finished game.
class VictoryState {
  const VictoryState({
    required this.winnerPlayerId,
    required this.type,
    required this.turnNumber,
  });

  final String winnerPlayerId;
  final VictoryType type;
  final int turnNumber;

  Map<String, dynamic> toJson() => {
        'winnerPlayerId': winnerPlayerId,
        'type': type.toJson(),
        'turnNumber': turnNumber,
      };

  static VictoryState fromJson(Map<String, dynamic> json) {
    return VictoryState(
      winnerPlayerId: json['winnerPlayerId'] as String,
      type: VictoryTypeJson.fromJson(json['type'] as String),
      turnNumber: json['turnNumber'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VictoryState &&
          runtimeType == other.runtimeType &&
          winnerPlayerId == other.winnerPlayerId &&
          type == other.type &&
          turnNumber == other.turnNumber;

  @override
  int get hashCode => Object.hash(winnerPlayerId, type, turnNumber);
}

/// Top-level game container. SPEC/game/world-model.
class Game {
  const Game({
    required this.id,
    required this.worldState,
    required this.players,
    this.minorNations = const [],
    this.tribes = const [],
    this.turnTimeMapping,
    this.defaultCombatMode,
    this.combatModeByProvinceId = const {},
    this.diplomacyRelations = const [],
    this.overtureStates = const [],
    this.aiControlByGpId = const {},
    this.aiSeedByGpId = const {},
    this.globalGameSeed,
    this.victory,
  });

  final String id;
  final WorldState worldState;
  final List<Player> players;
  final List<MinorNation> minorNations;
  final List<Tribe> tribes;

  /// Turn-to-calendar-year mapping. When null (legacy saves), use default per SPEC/game/turn-time-mapping.
  final TurnTimeMapping? turnTimeMapping;

  /// Default combat mode (Auto-Resolve vs Quick Battle). When null, use Auto-Resolve. Phase 4.
  final CombatMode? defaultCombatMode;

  /// Per-battle combat mode override by province id. Phase 4.
  final Map<String, CombatMode> combatModeByProvinceId;

  /// Per faction-pair relations. Phase 4.
  final List<DiplomacyRelation> diplomacyRelations;

  /// Overture state per Minor/Tribe per GP. Phase 4.
  final List<OvertureState> overtureStates;

  /// AI control: true = AI-controlled. When empty, use !player.isHuman. Phase 4.
  final Map<String, bool> aiControlByGpId;

  /// Per-AI seed for determinism. Phase 4.
  final Map<String, int> aiSeedByGpId;

  /// Global game seed for AI determinism. Phase 4.
  final int? globalGameSeed;

  /// Victory state when game has been won. Null when game is ongoing.
  final VictoryState? victory;

  Map<String, dynamic> toJson() => {
        'id': id,
        'worldState': worldState.toJson(),
        'players': players.map((e) => e.toJson()).toList(),
        'minorNations': minorNations.map((e) => e.toJson()).toList(),
        'tribes': tribes.map((e) => e.toJson()).toList(),
        if (turnTimeMapping != null) 'turnTimeMapping': turnTimeMapping!.toJson(),
        if (defaultCombatMode != null) 'defaultCombatMode': defaultCombatMode!.name,
        if (combatModeByProvinceId.isNotEmpty)
          'combatModeByProvinceId': combatModeByProvinceId.map(
            (k, v) => MapEntry(k, v.name),
          ),
        if (diplomacyRelations.isNotEmpty)
          'diplomacyRelations': diplomacyRelations.map((r) => r.toJson()).toList(),
        if (overtureStates.isNotEmpty)
          'overtureStates': overtureStates.map((o) => o.toJson()).toList(),
        if (aiControlByGpId.isNotEmpty) 'aiControlByGpId': aiControlByGpId,
        if (aiSeedByGpId.isNotEmpty) 'aiSeedByGpId': aiSeedByGpId,
        if (globalGameSeed != null) 'globalGameSeed': globalGameSeed,
        if (victory != null) 'victory': victory!.toJson(),
      };

  static Game fromJson(Map<String, dynamic> json) {
    final playersList = json['players'] as List<dynamic>? ?? [];
    final minorNationsList = json['minorNations'] as List<dynamic>? ?? [];
    final tribesList = json['tribes'] as List<dynamic>? ?? [];
    final turnTimeMappingJson = json['turnTimeMapping'] as Map<String, dynamic>?;
    final defaultCombatModeRaw = json['defaultCombatMode'] as String?;
    final defaultCombatMode = defaultCombatModeRaw != null
        ? CombatMode.values.firstWhere(
            (e) => e.name == defaultCombatModeRaw,
            orElse: () => CombatMode.autoResolve,
          )
        : null;
    final relationsList = json['diplomacyRelations'] as List<dynamic>? ?? [];
    final diplomacyRelations = relationsList
        .map((e) => DiplomacyRelation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final overtureList = json['overtureStates'] as List<dynamic>? ?? [];
    final overtureStates = overtureList
        .map((e) => OvertureState.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final aiControlRaw = json['aiControlByGpId'] as Map<dynamic, dynamic>? ?? {};
    final aiControlByGpId = aiControlRaw.map(
      (k, v) => MapEntry(k.toString(), v == true),
    );
    final aiSeedRaw = json['aiSeedByGpId'] as Map<dynamic, dynamic>? ?? {};
    final aiSeedByGpId = aiSeedRaw.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
    );
    final globalGameSeed = json['globalGameSeed'] as int?;

    final combatModeRaw = json['combatModeByProvinceId'] as Map<dynamic, dynamic>? ?? {};
    final combatModeByProvinceId = combatModeRaw.map(
      (k, v) => MapEntry(
        k.toString(),
        CombatMode.values.firstWhere(
          (e) => e.name == v.toString(),
          orElse: () => CombatMode.autoResolve,
        ),
      ),
    );
    return Game(
      id: json['id'] as String,
      worldState: WorldState.fromJson(Map<String, dynamic>.from(json['worldState'] as Map)),
      players: playersList.map((e) => Player.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      minorNations:
          minorNationsList.map((e) => MinorNation.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      tribes: tribesList.map((e) => Tribe.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      turnTimeMapping:
          turnTimeMappingJson != null ? TurnTimeMapping.fromJson(turnTimeMappingJson) : null,
      defaultCombatMode: defaultCombatMode,
      combatModeByProvinceId: combatModeByProvinceId,
      diplomacyRelations: diplomacyRelations,
      overtureStates: overtureStates,
      aiControlByGpId: aiControlByGpId,
      aiSeedByGpId: aiSeedByGpId,
      globalGameSeed: globalGameSeed,
      victory: json['victory'] is Map<String, dynamic>
          ? VictoryState.fromJson(json['victory'] as Map<String, dynamic>)
          : json['victory'] is Map
              ? VictoryState.fromJson(Map<String, dynamic>.from(json['victory'] as Map))
              : null,
    );
  }

  Game copyWith({
    String? id,
    WorldState? worldState,
    List<Player>? players,
    List<MinorNation>? minorNations,
    List<Tribe>? tribes,
    TurnTimeMapping? turnTimeMapping,
    CombatMode? defaultCombatMode,
    Map<String, CombatMode>? combatModeByProvinceId,
    List<DiplomacyRelation>? diplomacyRelations,
    List<OvertureState>? overtureStates,
    Map<String, bool>? aiControlByGpId,
    Map<String, int>? aiSeedByGpId,
    int? globalGameSeed,
    VictoryState? victory,
  }) {
    return Game(
      id: id ?? this.id,
      worldState: worldState ?? this.worldState,
      players: players ?? this.players,
      minorNations: minorNations ?? this.minorNations,
      tribes: tribes ?? this.tribes,
      turnTimeMapping: turnTimeMapping ?? this.turnTimeMapping,
      defaultCombatMode: defaultCombatMode ?? this.defaultCombatMode,
      combatModeByProvinceId: combatModeByProvinceId ?? this.combatModeByProvinceId,
      diplomacyRelations: diplomacyRelations ?? this.diplomacyRelations,
      overtureStates: overtureStates ?? this.overtureStates,
      aiControlByGpId: aiControlByGpId ?? this.aiControlByGpId,
      aiSeedByGpId: aiSeedByGpId ?? this.aiSeedByGpId,
      globalGameSeed: globalGameSeed ?? this.globalGameSeed,
      victory: victory ?? this.victory,
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
          turnTimeMapping == other.turnTimeMapping &&
          defaultCombatMode == other.defaultCombatMode &&
          _mapEquals(combatModeByProvinceId, other.combatModeByProvinceId) &&
          _listEquals(diplomacyRelations, other.diplomacyRelations) &&
          _listEquals(overtureStates, other.overtureStates) &&
          _mapEquals(aiControlByGpId, other.aiControlByGpId) &&
          _mapEquals(aiSeedByGpId, other.aiSeedByGpId) &&
          globalGameSeed == other.globalGameSeed &&
          victory == other.victory;

  @override
  int get hashCode => Object.hash(
        id,
        worldState,
        Object.hashAll(players),
        Object.hashAll(minorNations),
        Object.hashAll(tribes),
        turnTimeMapping,
        defaultCombatMode,
        Object.hashAll(combatModeByProvinceId.entries),
        Object.hashAll(diplomacyRelations),
        Object.hashAll(overtureStates),
        Object.hashAll(aiControlByGpId.entries),
        Object.hashAll(aiSeedByGpId.entries),
        globalGameSeed,
        victory,
      );

  static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
