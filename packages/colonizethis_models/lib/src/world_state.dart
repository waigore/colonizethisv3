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
  });

  final TurnState turnState;
  final RegionData oldWorld;
  final RegionData newWorld;

  /// Mutable per-tile improvement and road level. Key: "regionId|provinceId|x|y".
  final TileMapState tileState;

  /// Port present per (province, seaboard). Key: "provinceId|seaZoneId", value: tile key.
  final Map<String, String> portsByProvinceSeaboard;

  Map<String, dynamic> toJson() => {
        'turnState': turnState.toJson(),
        'oldWorld': oldWorld.toJson(),
        'newWorld': newWorld.toJson(),
        'tileState': tileState.toJson(),
        'portsByProvinceSeaboard': portsByProvinceSeaboard,
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

    return WorldState(
      turnState: TurnState.fromJson(Map<String, dynamic>.from(json['turnState'] as Map)),
      oldWorld: RegionData.fromJson(Map<String, dynamic>.from(json['oldWorld'] as Map)),
      newWorld: RegionData.fromJson(Map<String, dynamic>.from(json['newWorld'] as Map)),
      tileState: tileState,
      portsByProvinceSeaboard: ports,
    );
  }

  WorldState copyWith({
    TurnState? turnState,
    RegionData? oldWorld,
    RegionData? newWorld,
    TileMapState? tileState,
    Map<String, String>? portsByProvinceSeaboard,
  }) {
    return WorldState(
      turnState: turnState ?? this.turnState,
      oldWorld: oldWorld ?? this.oldWorld,
      newWorld: newWorld ?? this.newWorld,
      tileState: tileState ?? this.tileState,
      portsByProvinceSeaboard: portsByProvinceSeaboard ?? this.portsByProvinceSeaboard,
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
          _mapEquals(portsByProvinceSeaboard, other.portsByProvinceSeaboard);

  @override
  int get hashCode => Object.hash(
        turnState,
        oldWorld,
        newWorld,
        tileState,
        Object.hashAll(portsByProvinceSeaboard.entries),
      );

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
