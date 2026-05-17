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

  /// Copy with [resource] at ([x], [y]). Requires an existing [resourceGrid].
  /// SPEC/game/tile-map-and-generation.md § Great Power starting grain (bootstrap).
  TileMapResult withTerrainAt(int x, int y, TerrainType terrain) {
    if (terrainGrid == null) {
      throw StateError('withTerrainAt requires terrainGrid');
    }
    if (x < 0 || x >= width || y < 0 || y >= height) {
      throw RangeError(
        'withTerrainAt out of bounds ($x,$y) for ${width}x$height',
      );
    }
    final next = <List<TerrainType?>>[
      for (var row = 0; row < height; row++)
        List<TerrainType?>.from(terrainGrid![row]),
    ];
    next[y][x] = terrain;
    return TileMapResult(
      width: width,
      height: height,
      grid: grid,
      terrainGrid: next,
      resourceGrid: resourceGrid,
    );
  }

  TileMapResult withResourceAt(int x, int y, Resource? resource) {
    if (resourceGrid == null) {
      throw StateError('withResourceAt requires resourceGrid');
    }
    if (x < 0 || x >= width || y < 0 || y >= height) {
      throw RangeError(
        'withResourceAt out of bounds ($x,$y) for ${width}x$height',
      );
    }
    final next = <List<Resource?>>[
      for (var row = 0; row < height; row++)
        List<Resource?>.from(resourceGrid![row]),
    ];
    next[y][x] = resource;
    return TileMapResult(
      width: width,
      height: height,
      grid: grid,
      terrainGrid: terrainGrid,
      resourceGrid: next,
    );
  }

  /// Set of (id1, id2) where id1 < id2 and the two regions share a tile edge in the grid.
  Set<String> adjacentRegionPairs() {
    final pairs = <String>{};
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final id = grid[y][x];
        _addAdjacentPairIfDistinct(pairs, id, grid[y], x + 1, width);
      }
      _addVerticalAdjacentPairsForRow(pairs, grid, y, width, height);
    }
    return pairs;
  }

  static void _addVerticalAdjacentPairsForRow(
    Set<String> pairs,
    List<List<String>> grid,
    int y,
    int width,
    int height,
  ) {
    if (y + 1 >= height) return;
    final rowBelow = grid[y + 1];
    for (var x = 0; x < width; x++) {
      final id = grid[y][x];
      final other = rowBelow[x];
      if (id != other) pairs.add(_pairKey(id, other));
    }
  }

  static void _addAdjacentPairIfDistinct(
    Set<String> pairs,
    String id,
    List<String> row,
    int x,
    int width,
  ) {
    if (x >= width) return;
    final other = row[x];
    if (id != other) pairs.add(_pairKey(id, other));
  }

  static String _pairKey(String a, String b) =>
      a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

  /// Serializes when optional map data is saved (ctdev, init_game). See SPEC/program/save-load.md, SPEC/program/map-data.md.
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
