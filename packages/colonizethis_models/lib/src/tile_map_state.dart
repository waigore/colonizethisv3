/// Mutable per-tile state: improvement level and road level. SPEC/game/extraction-and-improvements.
///
/// Tile key format: "regionId|provinceId|x|y" (see [CapitalTile.tileKey]).
/// Road level: 0 = none, 1 = primitive, 2 = improved, 4 = port or railroad.
class TileMapState {
  const TileMapState({
    this.improvementByTile = const {},
    this.roadLevelByTile = const {},
  });

  /// improvement level 0-4 per tile key.
  final Map<String, int> improvementByTile;

  /// road level 0/1/2/4 per tile key.
  final Map<String, int> roadLevelByTile;

  int improvementLevel(String tileKey) => improvementByTile[tileKey] ?? 0;
  int roadLevel(String tileKey) => roadLevelByTile[tileKey] ?? 0;

  TileMapState setImprovement(String tileKey, int level) {
    final next = Map<String, int>.from(improvementByTile);
    if (level == 0) {
      next.remove(tileKey);
    } else {
      next[tileKey] = level.clamp(0, 4);
    }
    return TileMapState(
      improvementByTile: next,
      roadLevelByTile: roadLevelByTile,
    );
  }

  TileMapState setRoadLevel(String tileKey, int level) {
    final next = Map<String, int>.from(roadLevelByTile);
    if (level == 0) {
      next.remove(tileKey);
    } else {
      next[tileKey] = level;
    }
    return TileMapState(
      improvementByTile: improvementByTile,
      roadLevelByTile: next,
    );
  }

  Map<String, dynamic> toJson() => {
    'improvementByTile': improvementByTile,
    'roadLevelByTile': roadLevelByTile,
  };

  static TileMapState fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TileMapState();
    final imp = json['improvementByTile'];
    final road = json['roadLevelByTile'];
    return TileMapState(
      improvementByTile: imp is Map<String, int>
          ? imp
          : imp is Map<dynamic, dynamic>
          ? Map<String, int>.from(
              imp.map((k, v) => MapEntry(k.toString(), v is int ? v : 0)),
            )
          : const {},
      roadLevelByTile: road is Map<String, int>
          ? road
          : road is Map<dynamic, dynamic>
          ? Map<String, int>.from(
              road.map((k, v) => MapEntry(k.toString(), v is int ? v : 0)),
            )
          : const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileMapState &&
          runtimeType == other.runtimeType &&
          _mapEquals(improvementByTile, other.improvementByTile) &&
          _mapEquals(roadLevelByTile, other.roadLevelByTile);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(improvementByTile.entries),
    Object.hashAll(roadLevelByTile.entries),
  );

  static bool _mapEquals(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
