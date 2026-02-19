/// View models for init_game map visualization (PNG and ctdev debug app).
/// SPEC/program/map-data.md § Tile map visualizers, Map view model for tools.

import 'package:colonizethis_data/colonizethis_data.dart';

/// Simple RGB tuple alias for readability.
typedef Rgb = (int r, int g, int b);

/// Per-cell view data for a region map.
class CellViewData {
  const CellViewData({
    required this.x,
    required this.y,
    required this.regionCellId,
    required this.isSea,
    this.terrainTypeId,
    this.terrainType,
    this.resourceId,
    this.ownerFactionId,
    this.provinceDisplayName,
    this.improvementLevel,
    this.roadLevel,
  });

  final int x;
  final int y;

  /// Province or sea zone id from the tile map (local id, e.g. 'p12', 's3').
  final String regionCellId;

  /// True if this cell belongs to a sea zone; false for land provinces.
  final bool isSea;

  /// Terrain type identifier for land tiles, when available (for display/legend).
  final String? terrainTypeId;

  /// Terrain type for renderers; used for lookup in terrainColors. Optional for backward compatibility.
  final TerrainType? terrainType;

  /// Resource identifier for land tiles, when present.
  final String? resourceId;

  /// Owning faction id for land provinces, when set.
  final String? ownerFactionId;

  /// Assigned province display name for land provinces (e.g. "Wessex", "London"); null for sea cells.
  final String? provinceDisplayName;

  /// Improvement level 0–4 for land tiles. From WorldState.tileState.improvementByTile. Null for sea or when not populated.
  final int? improvementLevel;

  /// Road level 0/1/2/4 for land tiles. From WorldState.tileState.roadLevelByTile. Null for sea or when not populated.
  final int? roadLevel;
}

/// Capital marker location for a faction within a region.
class CapitalMarkerView {
  const CapitalMarkerView({
    required this.factionId,
    required this.displayName,
    required this.x,
    required this.y,
  });

  final String factionId;
  final String displayName;
  final int x;
  final int y;
}

/// Unit/army marker for the Units overlay. Province→representative tile.
class UnitMarkerView {
  const UnitMarkerView({
    required this.x,
    required this.y,
    required this.ownerFactionId,
  });

  final int x;
  final int y;
  final String ownerFactionId;
}

/// Port marker location for a province/sea zone tile.
class PortMarkerView {
  const PortMarkerView({
    required this.x,
    required this.y,
    required this.provinceId,
    required this.seaZoneId,
    this.seaboardKey,
  });

  final int x;
  final int y;
  final String provinceId;
  final String seaZoneId;

  /// Optional key or label describing the seaboard/port grouping.
  final String? seaboardKey;
}

/// View data for a single region (Old World or New World).
class RegionMapViewData {
  const RegionMapViewData({
    required this.regionId,
    required this.width,
    required this.height,
    required this.cellSize,
    required this.cells,
    required this.capitalMarkers,
    required this.portMarkers,
    required this.factionColors,
    required this.terrainColors,
    this.unitMarkers = const [],
  });

  /// Region identifier, e.g. 'oldWorld' or 'newWorld'.
  final String regionId;

  /// Grid width in cells.
  final int width;

  /// Grid height in cells.
  final int height;

  /// Logical cell size used for layout. Renderers may scale this.
  final int cellSize;

  /// Flattened list of cells (size = width * height).
  final List<CellViewData> cells;

  final List<CapitalMarkerView> capitalMarkers;
  final List<PortMarkerView> portMarkers;

  /// Faction id -> RGB color used for ownership fills and legend.
  final Map<String, Rgb> factionColors;

  /// Terrain type -> RGB color used for terrain fills when needed.
  final Map<TerrainType, Rgb> terrainColors;

  /// Unit/army markers (province→representative tile) for Units overlay.
  final List<UnitMarkerView> unitMarkers;

  /// Convenience accessor for cell at (x, y).
  CellViewData cellAt(int x, int y) => cells[y * width + x];
}

/// Combined map view data for init_game (Old World + New World).
class InitGameMapViewData {
  const InitGameMapViewData({
    required this.oldWorld,
    required this.newWorld,
    this.seed,
    this.configSummary,
  });

  final RegionMapViewData oldWorld;
  final RegionMapViewData newWorld;

  /// Optional RNG seed used for map generation.
  final int? seed;

  /// Optional short summary of the GameSetupConfig used.
  final String? configSummary;
}

