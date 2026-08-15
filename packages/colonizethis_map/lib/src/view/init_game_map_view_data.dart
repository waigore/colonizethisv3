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

  /// Viewing-player extraction cap for this owned land cell (`extractionCapForResourceOnTerrain`).
  /// Null for sea, foreign/unowned land, global observe, or cells without resource/terrain.
  /// SPEC/program/map-visualization.md (Refs #4408).
  final int? improvementTechCap;

  /// Road level 0/1/2/4 for land tiles. From WorldState.tileState.roadLevelByTile. Null for sea or when not populated.
  final int? roadLevel;

  /// Human-player per-tile extraction units (integer >= 0) used by map
  /// extraction-disc overlays. Null for sea or when not populated.
  final int? resourceExtractionUnits;

  /// Human-player per-tile extracted units that are effectively transported.
  /// Null for sea or when not populated.
  final int? resourceExtractionEffectiveUnits;

  /// Human-player per-tile units blocked by transport/path bottlenecks.
  /// Null for sea or when not populated.
  final int? resourceExtractionBlockedUnits;

  /// True when this land tile is owned by the viewing player and is **not** in
  /// that player's capital `ConnectivityResult.connected` set (Refs #4370).
  /// Sea cells and tiles without a viewing-player connected set stay false.
  final bool capitalLinkDisconnected;

  /// Per-tile visibility for the current player view. Defaults to [TileVisibility.visible].
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
  final List<WarpMarkerView> warpMarkers;
  final List<TownMarkerView> townMarkers;

  /// Faction id -> RGB color used for ownership fills and legend.
  final Map<String, Rgb> factionColors;

  /// Runtime ids of Great Powers (`Game.players`). Restricts province-overlay
  /// ownership tint to GP-held land. SPEC/program/map-visualization.md,
  /// SPEC/ui/map-widget.md.
  final Set<String> greatPowerFactionIds;

  /// Terrain type -> RGB color used for terrain fills when needed.
  final Map<TerrainType, Rgb> terrainColors;

  /// Unit/army markers (province→representative tile) for Units overlay.
  final List<UnitMarkerView> unitMarkers;

  /// Tile-scoped player civilian markers for interactive map civilian icons.
  final List<CivilianTileMarkerView> civilianTileMarkers;

  /// Human-player fleet markers (port or sea-zone stacks).
  final List<FleetTileMarkerView> fleetTileMarkers;

  /// Human-player army stack markers (province town tiles). Distinct from
  /// [unitMarkers]. SPEC/program/map-visualization.md.
  final List<ArmyTileMarkerView> armyTileMarkers;

  /// Province full id -> class presence counts/intel gate for map labels.
  final Map<String, ProvinceUnitPresenceView> provinceUnitPresenceByProvinceId;

  /// Prefixed province id (`regionId|localId`) -> province-level [Province.ownerId]
  /// from world state (`null` if unowned). Used for province name label plate tint
  /// vs neutral (Minor/Tribe provinces with GP-purchased tiles). See
  /// SPEC/program/map-visualization.md § Map view model.
  final Map<String, String?> provincePoliticalOwnerByPrefixedProvinceId;

  /// Copy of [WorldState.seaZoneDisplayNameById] for sea zone map labels.
  /// Keys: `regionId|localSeaZoneId`. SPEC/program/map-visualization.md.
  final Map<String, String> seaZoneDisplayNameByPrefixedId;

  /// Convenience accessor for cell at (x, y).
  CellViewData cellAt(int x, int y) => cells[y * width + x];
}

/// `regionId|localProvinceId` for province / sea-zone detail when the user
/// selects a map tile.
///
/// When [tileKey] matches a port town's drawable harbor cell (`portIconX` /
/// `portIconY`), returns that **land province** id so the overlay stays in
/// province context instead of sea-zone-only. Otherwise returns `null`.
/// SPEC/ui/map-widget.md, SPEC/ui/province-sea-zone-detail-overlay.md,
/// GitHub #1761.
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

  /// OW + NW nodes/edges with prefixed ids, plus warp links (same shape as persisted map data).
  final MapTopology combinedTopology;

  /// Optional RNG seed used for map generation.
  final int? seed;

  /// Optional short summary of the GameSetupConfig used.
  final String? configSummary;
}
