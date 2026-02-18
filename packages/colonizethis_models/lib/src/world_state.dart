import 'region_data.dart';
import 'tile_map_state.dart';
import 'turn_state.dart';

/// Snapshot at a point in time. Turn state + region data + tile state. SPEC/game/world-model.
class WorldState {
  const WorldState({
    required this.turnState,
    required this.oldWorld,
    required this.newWorld,
    this.tileState = const TileMapState(),
    this.portsByProvinceSeaboard = const {},
    this.playerVisibilityByTile = const {},
    this.playerProspectedTiles = const {},
  });

  final TurnState turnState;
  final RegionData oldWorld;
  final RegionData newWorld;

  /// Mutable per-tile improvement and road level. Key: "regionId|provinceId|x|y".
  final TileMapState tileState;

  /// Port present per (province, seaboard). Key: "provinceId|seaZoneId", value: tile key.
  final Map<String, String> portsByProvinceSeaboard;

  /// Per-player tile visibility: playerId -> (tileKey -> visibility level name).
  /// Visibility level names correspond to the enum in SPEC/game/fog-and-exploration.md.
  final Map<String, Map<String, String>> playerVisibilityByTile;

  /// Per-player set of prospected tile keys: playerId -> set of tile keys.
  /// Stored as lists in JSON; converted to sets in logic as needed.
  final Map<String, Set<String>> playerProspectedTiles;

  Map<String, dynamic> toJson() => {
        'turnState': turnState.toJson(),
        'oldWorld': oldWorld.toJson(),
        'newWorld': newWorld.toJson(),
        'tileState': tileState.toJson(),
        'portsByProvinceSeaboard': portsByProvinceSeaboard,
        if (playerVisibilityByTile.isNotEmpty)
          'playerVisibilityByTile': playerVisibilityByTile,
        if (playerProspectedTiles.isNotEmpty)
          'playerProspectedTiles': playerProspectedTiles.map(
            (playerId, tiles) => MapEntry(playerId, tiles.toList()),
          ),
      };

  static WorldState fromJson(Map<String, dynamic> json) {
    final tileStateRaw = json['tileState'];
    final tileState = tileStateRaw is Map<String, dynamic>
        ? TileMapState.fromJson(tileStateRaw)
        : TileMapState.fromJson(
            tileStateRaw is Map ? Map<String, dynamic>.from(tileStateRaw) : null);

    final portsRaw = json['portsByProvinceSeaboard'];
    final ports = portsRaw is Map
        ? Map<String, String>.from(
            portsRaw.map((k, v) => MapEntry(k.toString(), v.toString())))
        : <String, String>{};

    final visRaw = json['playerVisibilityByTile'];
    final visibility = <String, Map<String, String>>{};
    if (visRaw is Map) {
      visRaw.forEach((playerId, value) {
        if (value is Map) {
          visibility[playerId.toString()] = Map<String, String>.from(
            value.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ),
          );
        }
      });
    }

    final prospectedRaw = json['playerProspectedTiles'];
    final prospected = <String, Set<String>>{};
    if (prospectedRaw is Map) {
      prospectedRaw.forEach((playerId, value) {
        if (value is List) {
          prospected[playerId.toString()] = value
              .map((e) => e.toString())
              .toSet();
        }
      });
    }

    return WorldState(
      turnState: TurnState.fromJson(Map<String, dynamic>.from(json['turnState'] as Map)),
      oldWorld: RegionData.fromJson(Map<String, dynamic>.from(json['oldWorld'] as Map)),
      newWorld: RegionData.fromJson(Map<String, dynamic>.from(json['newWorld'] as Map)),
      tileState: tileState,
      portsByProvinceSeaboard: ports,
      playerVisibilityByTile: visibility,
      playerProspectedTiles: prospected,
    );
  }

  WorldState copyWith({
    TurnState? turnState,
    RegionData? oldWorld,
    RegionData? newWorld,
    TileMapState? tileState,
    Map<String, String>? portsByProvinceSeaboard,
    Map<String, Map<String, String>>? playerVisibilityByTile,
    Map<String, Set<String>>? playerProspectedTiles,
  }) {
    return WorldState(
      turnState: turnState ?? this.turnState,
      oldWorld: oldWorld ?? this.oldWorld,
      newWorld: newWorld ?? this.newWorld,
      tileState: tileState ?? this.tileState,
      portsByProvinceSeaboard: portsByProvinceSeaboard ?? this.portsByProvinceSeaboard,
      playerVisibilityByTile: playerVisibilityByTile ?? this.playerVisibilityByTile,
      playerProspectedTiles: playerProspectedTiles ?? this.playerProspectedTiles,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldState &&
          runtimeType == other.runtimeType &&
          turnState == other.turnState &&
          oldWorld == other.oldWorld &&
          newWorld == other.newWorld &&
          tileState == other.tileState &&
          _mapEquals(portsByProvinceSeaboard, other.portsByProvinceSeaboard) &&
          _nestedStringMapEquals(playerVisibilityByTile, other.playerVisibilityByTile) &&
          _mapOfSetEquals(playerProspectedTiles, other.playerProspectedTiles);

  @override
  int get hashCode => Object.hash(
        turnState,
        oldWorld,
        newWorld,
        tileState,
        Object.hashAll(portsByProvinceSeaboard.entries),
        Object.hashAll(
          playerVisibilityByTile.entries.map(
            (e) => Object.hash(e.key, Object.hashAll(e.value.entries)),
          ),
        ),
        Object.hashAll(
          playerProspectedTiles.entries.map(
            (e) => Object.hash(e.key, Object.hashAll(e.value)),
          ),
        ),
      );

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  static bool _nestedStringMapEquals(
    Map<String, Map<String, String>> a,
    Map<String, Map<String, String>> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final otherInner = b[entry.key];
      if (otherInner == null || !_mapEquals(entry.value, otherInner)) {
        return false;
      }
    }
    return true;
  }

  static bool _mapOfSetEquals(
    Map<String, Set<String>> a,
    Map<String, Set<String>> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final otherSet = b[entry.key];
      if (otherSet == null || entry.value.length != otherSet.length) {
        return false;
      }
      for (final v in entry.value) {
        if (!otherSet.contains(v)) return false;
      }
    }
    return true;
  }
}

