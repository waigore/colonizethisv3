/// View models for init_game map visualization (PNG and ctdev debug app).
/// SPEC/program/map-visualization.md § Tile map visualizers, Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'tile_key_util.dart';

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
    this.roadLevel,
    this.resourceExtractionUnits,
    this.resourceExtractionEffectiveUnits,
    this.resourceExtractionBlockedUnits,
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

  /// Per-tile visibility for the current player view. Defaults to [TileVisibility.visible].
  final TileVisibility visibility;
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

/// Tile-scoped player civilian marker payload for interactive map icons.
class CivilianTileMarkerView {
  const CivilianTileMarkerView({
    required this.tileKey,
    required this.x,
    required this.y,
    required this.localProvinceId,
    required this.unitIds,
    required this.unitTypes,
    required this.representativeUnitType,
    required this.stackCount,
    this.representativeIsAssigned = false,
    this.applyCivilianRevealHalo = false,
  });

  /// Canonical tile key `regionId|provinceId|x|y`.
  final String tileKey;
  final int x;
  final int y;

  /// Local province id from the tile key (`provinceId` segment).
  final String localProvinceId;

  /// Unit ids on this tile in deterministic order:
  /// icon-priority order first, then unit id lexical tie-break.
  final List<String> unitIds;

  /// Unit type keyed by unit id for tile-scoped civilian dialogs.
  final Map<String, String> unitTypes;

  /// Icon representative unit type for this tile stack.
  final String representativeUnitType;

  /// Number of player-owned civilians on this tile.
  final int stackCount;

  /// True when the representative unit is rendered on an assigned work tile.
  /// Used for grayscale map marker rendering in glyph-marker slices.
  final bool representativeIsAssigned;

  /// When true, renderer treats Chebyshev distance <= 2 around [tileKey] as
  /// fully visible while this marker represents a pending civilian assignment
  /// to a fogged tile (display-only).
  final bool applyCivilianRevealHalo;
}

/// Human-player fleet stack at one port or sea zone for interactive map markers.
/// SPEC/ui/map-widget.md § Fleet tile markers.
class FleetTileMarkerView {
  const FleetTileMarkerView({
    required this.tileKey,
    required this.x,
    required this.y,
    required this.locationScopeKey,
    required this.fleetIds,
    required this.stackCount,
    this.renderGrayscale = false,
    this.applyFleetRevealHalo = false,
  });

  /// Tile key `regionId|provinceOrSeaId|x|y` for marker anchor (may be projected).
  final String tileKey;
  final int x;
  final int y;

  /// Naval panel location scope (`port:…` / `sea:…`).
  final String locationScopeKey;

  /// Fleet ids at this marker, deterministic order (lexical by id).
  final List<String> fleetIds;

  /// Same as [fleetIds.length] when > 1 enables stack badge.
  final int stackCount;

  /// Grayscale ship icon when every fleet here has a pending naval move/mission draft.
  final bool renderGrayscale;

  /// When true, renderer treats Chebyshev distance ≤ 2 around [tileKey] as fully visible
  /// while any fleet here has a pending naval **move** draft (display-only).
  final bool applyFleetRevealHalo;
}

/// Province-level unit-presence counts for map labels.
class ProvinceUnitPresenceView {
  const ProvinceUnitPresenceView({
    required this.civilianCount,
    required this.regimentCount,
    required this.shipCount,
    required this.intelVisible,
  });

  final int civilianCount;
  final int regimentCount;
  final int shipCount;

  /// Whether the active player view is allowed to know class presence.
  final bool intelVisible;
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

/// Town marker location for a province's town.
class TownMarkerView {
  const TownMarkerView({
    required this.x,
    required this.y,
    required this.provinceId,
    required this.isCoastal,
    required this.isPort,
    required this.touchesSea,
    this.portIconX,
    this.portIconY,
  });

  final int x;
  final int y;

  /// Province id (local id, e.g. 'p12').
  final String provinceId;

  /// True if this province is coastal (touches sea) but is not a port.
  final bool isCoastal;

  /// True if this province is a port (trade hub with port access).
  final bool isPort;

  /// Province has a P↔S topology edge (sea-touching). Used for the town glyph
  /// on [x]/[y] (coastal vs inland) even when [isPort] is true.
  final bool touchesSea;

  /// When [isPort] is true, grid coordinates for the port icon (may differ from
  /// [x]/[y] when the port tile matches town or capital). SPEC/ui/town-port-icons.md.
  final int? portIconX;
  final int? portIconY;
}

/// Warp zone marker location for a sea zone that links to another region.
class WarpMarkerView {
  const WarpMarkerView({
    required this.x,
    required this.y,
    required this.seaZoneId,
    required this.otherRegionId,
    required this.otherSeaZoneId,
  });

  final int x;
  final int y;
  final String seaZoneId;
  final String otherRegionId;
  final String otherSeaZoneId;
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
