import 'terrain_type.dart';
import 'resource.dart';

/// Result of tile-based map generation. SPEC/program/tile-map-gen-resources.md, SPEC/program/map-data.md.
/// Per-region 2D grid: each cell has a region id (province or sea zone).
/// Optionally terrain and resource per cell (Phase 1+).
class TileMapResult {
  TileMapResult({
    required this.width,
    required this.height,
    required this.grid,
    this.terrainGrid,
    this.resourceGrid,
  })  : assert(grid.length == height && (height == 0 || (grid.every((row) => row.length == width)))),
        assert(terrainGrid == null ||
            (terrainGrid.length == height &&
                (height == 0 || terrainGrid.every((row) => row.length == width)))),
        assert(resourceGrid == null ||
            (resourceGrid.length == height &&
                (height == 0 || resourceGrid.every((row) => row.length == width))));

  final int width;
  final int height;
  /// grid[row][col] = region id (province or sea zone)
  final List<List<String>> grid;
  /// Optional: terrain per cell; null = water or not set. Same dimensions as grid.
  final List<List<TerrainType?>>? terrainGrid;
  /// Optional: resource per cell; null = none. Same dimensions as grid.
  final List<List<Resource?>>? resourceGrid;

  String cell(int x, int y) => grid[y][x];

  TerrainType? terrainAt(int x, int y) =>
      terrainGrid != null ? terrainGrid![y][x] : null;

  Resource? resourceAt(int x, int y) =>
      resourceGrid != null ? resourceGrid![y][x] : null;

  /// Set of (id1, id2) where id1 < id2 and the two regions share a tile edge in the grid.
  Set<String> adjacentRegionPairs() {
    final pairs = <String>{};
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final id = grid[y][x];
        if (x + 1 < width) {
          final other = grid[y][x + 1];
          if (id != other) pairs.add(_pairKey(id, other));
        }
        if (y + 1 < height) {
          final other = grid[y + 1][x];
          if (id != other) pairs.add(_pairKey(id, other));
        }
      }
    }
    return pairs;
  }

  static String _pairKey(String a, String b) =>
      a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

  /// Serializes for save/load (e.g. ctdev Load Savegame). SPEC/project/plan-update-gp-colours-save-load.
  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'grid': grid,
      if (terrainGrid != null)
        'terrainGrid': terrainGrid!
            .map((row) => row.map((t) => t?.name).toList())
            .toList(),
      if (resourceGrid != null)
        'resourceGrid': resourceGrid!
            .map((row) => row.map((r) => r?.name).toList())
            .toList(),
    };
  }

  /// Deserializes from JSON. Returns a valid [TileMapResult] or throws.
  static TileMapResult fromJson(Map<String, dynamic> json) {
    final width = json['width'] as int;
    final height = json['height'] as int;
    final grid = (json['grid'] as List<dynamic>)
        .map((row) => (row as List<dynamic>).map((e) => e as String).toList())
        .toList();
    List<List<TerrainType?>>? terrainGrid;
    final tg = json['terrainGrid'] as List<dynamic>?;
    if (tg != null) {
      terrainGrid = tg
          .map((row) => (row as List<dynamic>)
              .map((e) => e == null ? null : TerrainType.values.byName(e as String))
              .toList())
          .toList();
    }
    List<List<Resource?>>? resourceGrid;
    final rg = json['resourceGrid'] as List<dynamic>?;
    if (rg != null) {
      resourceGrid = rg
          .map((row) => (row as List<dynamic>)
              .map((e) => e == null ? null : Resource.values.byName(e as String))
              .toList())
          .toList();
    }
    return TileMapResult(
      width: width,
      height: height,
      grid: grid,
      terrainGrid: terrainGrid,
      resourceGrid: resourceGrid,
    );
  }
}
