/// View models for init_game map visualization (PNG and ctdev debug app).
/// SPEC/program/map-visualization.md § Tile map visualizers, Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import '../tile_key_util.dart';

import 'init_game_map_view_marker_types.dart';

export 'init_game_map_view_marker_types.dart';

/// Simple RGB tuple alias for readability.
typedef Rgb = (int r, int g, int b);

/// Visibility of a tile for a given player view.
enum TileVisibility {
  /// Tile is currently visible to the player this turn.
  visible,

  /// Tile has been seen before but is not currently visible (fog of war).
  fogged,

  /// Tile has never been seen by the player.
  unrevealed,
}

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
    this.improvementTechCap,
    this.roadLevel,
    this.resourceExtractionUnits,
    this.resourceExtractionEffectiveUnits,
    this.resourceExtractionBlockedUnits,
    this.capitalLinkDisconnected = false,
    this.visibility = TileVisibility.visible,
  });

  final int x;
  final int y;
  final String regionCellId;
  final bool isSea;
  final String? terrainTypeId;
  final TerrainType? terrainType;
  final String? resourceId;
  final String? ownerFactionId;
  final String? provinceDisplayName;
  final int? improvementLevel;

  /// Extraction cap. SPEC/program/map-visualization.md (Refs #4408).
  final int? improvementTechCap;
  final int? roadLevel;
  final int? resourceExtractionUnits;
  final int? resourceExtractionEffectiveUnits;
  final int? resourceExtractionBlockedUnits;

  /// Viewing-player land not in capital connected set (Refs #4370).
  final bool capitalLinkDisconnected;
  final TileVisibility visibility;
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
    required this.greatPowerFactionIds,
    required this.terrainColors,
    this.unitMarkers = const [],
    this.civilianTileMarkers = const [],
    this.fleetTileMarkers = const [],
    this.armyTileMarkers = const [],
    this.warpMarkers = const [],
    this.townMarkers = const [],
    this.provinceUnitPresenceByProvinceId = const {},
    this.provincePoliticalOwnerByPrefixedProvinceId = const {},
    this.seaZoneDisplayNameByPrefixedId = const {},
  });

  final String regionId;
  final int width;
  final int height;
  final int cellSize;
  final List<CellViewData> cells;
  final List<CapitalMarkerView> capitalMarkers;
  final List<PortMarkerView> portMarkers;
  final List<WarpMarkerView> warpMarkers;
  final List<TownMarkerView> townMarkers;
  final Map<String, Rgb> factionColors;

  /// GP ids for overlay tint. SPEC/program/map-visualization.md.
  final Set<String> greatPowerFactionIds;
  final Map<TerrainType, Rgb> terrainColors;
  final List<UnitMarkerView> unitMarkers;
  final List<CivilianTileMarkerView> civilianTileMarkers;
  final List<FleetTileMarkerView> fleetTileMarkers;
  final List<ArmyTileMarkerView> armyTileMarkers;
  final Map<String, ProvinceUnitPresenceView> provinceUnitPresenceByProvinceId;

  /// Prefixed province → [Province.ownerId]. SPEC/program/map-visualization.md.
  final Map<String, String?> provincePoliticalOwnerByPrefixedProvinceId;

  /// Sea-zone label names. SPEC/program/map-visualization.md.
  final Map<String, String> seaZoneDisplayNameByPrefixedId;

  CellViewData cellAt(int x, int y) => cells[y * width + x];
}

/// Harbor-cell tap → land province id. SPEC/ui/map-widget.md (#1761).
String? provinceDetailDisplayIdForPortHarborMapTile({
  required RegionMapViewData region,
  required String tileKey,
}) {
  final parsed = tryParseMapTileKey(tileKey);
  if (parsed == null || parsed.regionId != region.regionId) {
    return null;
  }
  final x = parsed.x;
  final y = parsed.y;
  for (final t in region.townMarkers) {
    if (!t.isPort) {
      continue;
    }
    final px = t.portIconX;
    final py = t.portIconY;
    if (px != null && py != null && px == x && py == y) {
      return '${region.regionId}|${t.provinceId}';
    }
  }
  return null;
}

/// Combined map view data for init_game (Old World + New World).
class InitGameMapViewData {
  const InitGameMapViewData({
    required this.oldWorld,
    required this.newWorld,
    required this.combinedTopology,
    this.seed,
    this.configSummary,
  });

  final RegionMapViewData oldWorld;
  final RegionMapViewData newWorld;
  final MapTopology combinedTopology;
  final int? seed;
  final String? configSummary;
}
