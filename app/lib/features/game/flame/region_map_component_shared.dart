
/// Fog overlay opacity when drawing a dark rect over tiles (0 = no overlay, 1 = full black).

part of 'region_map_component.dart';

const double _fogOverlayOpacity = 0.4;

/// Work-target valid tiles: opacity baseline in **linear 0–1** before sin pulse.
const double _kValidWorkTargetGlowOpacityBase = 0.4;

/// Work-target valid tiles: extra opacity added by sin pulse (peak = base + amplitude).
const double _kValidWorkTargetGlowOpacityAmplitude = 0.4;

/// Work-target pulse speed: sin argument is `t *` this factor ([_hoverAnimationT] domain).
const double _kValidWorkTargetGlowTimeScale = 3;

/// Hovered-province glow: midpoint opacity for stroke (linear 0–1).
const double _kHoveredProvinceGlowOpacityMid = 0.5;

/// Hovered-province glow: half-amplitude of sin oscillation (linear 0–1).
const double _kHoveredProvinceGlowOpacityAmplitude = 0.25;

/// Hovered-province glow: angular frequency (radians per unit [_hoverAnimationT]); one full cycle per t=1.
const double _kHoveredProvinceGlowAngularFrequency = 6.283185307179586;

/// Capital marker fill and warp-zone accent (gold).
const Color _kMapSelectionGold = Color(0xFFFFD700);

/// Outer warp-zone glow alpha (linear 0–1) over [_kMapSelectionGold].
const double _kWarpZoneOuterGlowAlpha = 0.3;

/// Inner warp-zone stroke (bright yellow).
const Color _kWarpZoneInnerHighlight = Color(0xFFFFEA00);

/// Valid work-target tile stroke (pure yellow channel; alpha applied per frame).
const Color _kValidWorkTargetStrokeYellow = Color(0xFFFFFF00);

/// Selected tile outline (orange).
const Color _kMapSelectedHighlightOrange = Color(0xFFFFAA00);

/// Secondary tile highlight outline (cyan).
const Color _kMapSecondarySelectionCyan = Color(0xFF66D9FF);

/// Hover selector rect: scale baseline (1 = cell fit).
const double _kHoverSelectorBounceBaseline = 1.0;

/// Hover selector rect: sin amplitude for subtle pulse (visual feedback).
const double _kHoverSelectorBounceAmplitude = 0.04;

/// Hover selector stroke when not in work-target mode (white).
const Color _kMapHoverSelectorIdle = Color(0xFFFFFFFF);

/// Normalized midpoint for mapping sin from [-1,1] to [0,1] before scaling opacity.
const double _kSinNormalizedMid = 0.5;

/// Political border stroke colors.
/// These are intentionally subtle so they don't overpower the terrain art.
const Color _provinceBorderLandColor = Color.fromRGBO(0, 0, 0, 0.35);
const Color _provinceBorderSeaLandColor = Color.fromRGBO(0, 0, 0, 0.25);
const Color _provinceBorderSeaZoneColor = Color.fromRGBO(130, 200, 255, 0.55);

/// Province name labels: text shadow (semi-transparent black, ARGB).
const Color _kProvinceLabelShadowColor = Color(0x8A000000);

/// Fogged land tiles: modulate alpha for resource icons (linear 0–1).
const double _kFoggedResourceIconModulateAlpha = 0.6;

const double _kExtractionIndicatorSizeBoostPx = 2.0;
const double _kExtractionIndicatorOverlapFactor = 0.45;
const double _kExtractionIndicatorStartInsetXPx = 2.0;

/// Blocked extraction throughput (not reaching the capital under transport rules).
const Color _kExtractionDiscBlockedBrown = Color(0xFF5C4033);

/// Political (faction) border stroke — indigo, visible over terrain.
const Color _kFactionPoliticalBorderColor = Color(0xFF1A237E);

/// Land province labels: max text width and font size in **logical pixels** (screen space).
const double _provinceLabelMaxWidthPx = 120;
const double _provinceLabelFontSizePx = 11;
const double _provinceLabelPlatePaddingPx = 4;
const Color _provinceLabelPlateColor = Color.fromRGBO(0, 0, 0, 0.55);
const double _provinceLabelIconRenderedPx = 12;
const double _provinceLabelIconGapPx = 3;
const double _provinceLabelTextIconGapPx = 4;
const String _provinceLabelCapitalIconId = 'map_capital_star';
const String _seaZoneLabelWarpIconId = 'map_warp_zone';

/// Sea zone name plates (light blue, black text). SPEC/ui/map-widget.md.
const Color _seaZoneLabelPlateColor = Color.fromRGBO(173, 216, 230, 0.55);
const Color _seaZoneLabelTextColor = Color(0xFF000000);

/// World-space center for a map label plate (inverse zoom applied to size).
///
/// Prefers placement above the centroid cell without overlapping the avoided
/// tile; if that would clip the map top, uses below. Clamps into the region
/// world rect and resolves residual overlap with the avoided tile.
///
/// By default, the avoided tile is the centroid tile. Callers may pass an
/// alternate avoided tile for reuse in province-label placement.
Offset resolveSeaZoneNamePlateCenterWorld({
  required int centroidTileX,
  required int centroidTileY,
  required double cellSize,
  required int gridWidth,
  required int gridHeight,
  required double plateWidthLogicalPx,
  required double plateHeightLogicalPx,
  required double cameraZoom,
  int? avoidedTileX,
  int? avoidedTileY,
}) {
  final avoidTileX = avoidedTileX ?? centroidTileX;
  final avoidTileY = avoidedTileY ?? centroidTileY;
  final invZ = 1.0 / cameraZoom.clamp(0.25, 4.0);
  final ww = plateWidthLogicalPx * invZ / 2;
  final hh = plateHeightLogicalPx * invZ / 2;
  final mapW = gridWidth * cellSize;
  final mapH = gridHeight * cellSize;
  final cellL = avoidTileX * cellSize;
  final cellT = avoidTileY * cellSize;
  final cellR = cellL + cellSize;
  final cellB = cellT + cellSize;
  const gap = 1.0;

  var cx = (centroidTileX + 0.5) * cellSize;

  bool overlapsCell(double pcx, double pcy) {
    final l = pcx - ww;
    final r = pcx + ww;
    final t = pcy - hh;
    final b = pcy + hh;
    return !(r <= cellL || l >= cellR || b <= cellT || t >= cellB);
  }

  ({double x, double y}) clampPlateCenter(double pcx, double pcy) {
    var x = pcx;
    var y = pcy;
    var l = x - ww;
    var r = x + ww;
    if (l < 0) {
      x -= l;
    }
    r = x + ww;
    if (r > mapW) {
      x -= r - mapW;
    }
    l = x - ww;
    if (l < 0) {
      x = ww;
    }
    var t = y - hh;
    var b = y + hh;
    if (t < 0) {
      y -= t;
    }
    b = y + hh;
    if (b > mapH) {
      y -= b - mapH;
    }
    t = y - hh;
    if (t < 0) {
      y = hh;
    }
    return (x: x, y: y);
  }

  // Above: plate bottom <= cell top - gap.
  final aboveY = cellT - gap - hh;
  final aboveTop = aboveY - hh;
  var useAbove = aboveTop >= 0;
  var cy = useAbove ? aboveY : cellB + gap + hh;

  var clamped = clampPlateCenter(cx, cy);
  cx = clamped.x;
  cy = clamped.y;

  if (overlapsCell(cx, cy)) {
    if (useAbove) {
      cy = cellB + gap + hh;
    } else if (aboveTop >= 0) {
      cy = aboveY;
    }
    clamped = clampPlateCenter(cx, cy);
    cx = clamped.x;
    cy = clamped.y;
  }

  for (var i = 0; i < 48 && overlapsCell(cx, cy); i++) {
    final midY = (cellT + cellB) / 2;
    if (cy < midY) {
      cy -= 1;
    } else {
      cy += 1;
    }
    clamped = clampPlateCenter(cx, cy);
    cx = clamped.x;
    cy = clamped.y;
  }

  return Offset(cx, cy);
}

/// True when `(x, y)` is within Chebyshev distance ≤ 2 of a fleet marker that
/// applies the naval move-draft reveal halo. SPEC/ui/map-widget.md.
bool isCellUnderFleetRevealHalo({
  required int x,
  required int y,
  required List<FleetTileMarkerView> fleetTileMarkers,
}) {
  for (final m in fleetTileMarkers) {
    if (!m.applyFleetRevealHalo) {
      continue;
    }
    if (math.max((x - m.x).abs(), (y - m.y).abs()) <= 2) {
      return true;
    }
  }
  return false;
}

/// True when `(x, y)` is within Chebyshev distance <= 2 of a civilian marker
/// that applies the draft assignment reveal halo.
bool isCellUnderCivilianRevealHalo({
  required int x,
  required int y,
  required List<CivilianTileMarkerView> civilianTileMarkers,
}) {
  for (final m in civilianTileMarkers) {
    if (!m.applyCivilianRevealHalo) {
      continue;
    }
    if (math.max((x - m.x).abs(), (y - m.y).abs()) <= 2) {
      return true;
    }
  }
  return false;
}

/// Effective terrain visibility for map painting (fog + reveal halos).
///
/// Used by the region map renderer and tests for sea zone label gating (#1756).
TileVisibility visibilityForTerrainForMapCell({
  required CtMapVisibilityMode visibilityMode,
  required CellViewData cell,
  required List<FleetTileMarkerView> fleetTileMarkers,
  required List<CivilianTileMarkerView> civilianTileMarkers,
}) {
  if (visibilityMode != CtMapVisibilityMode.playerConstrained) {
    return cell.visibility;
  }
  if (isCellUnderFleetRevealHalo(
    x: cell.x,
    y: cell.y,
    fleetTileMarkers: fleetTileMarkers,
  )) {
    return TileVisibility.visible;
  }
  if (isCellUnderCivilianRevealHalo(
    x: cell.x,
    y: cell.y,
    civilianTileMarkers: civilianTileMarkers,
  )) {
    return TileVisibility.visible;
  }
  return cell.visibility;
}

/// Resolves map province-label icon ids.
///
/// Capital icon is prepended, then optional presence icons follow.
List<String> resolveProvinceLabelIconIds({
  required bool isCapital,
  ProvinceUnitPresenceView? presence,
}) {
  final ids = <String>[if (isCapital) _provinceLabelCapitalIconId];
  ids.addAll(resolveProvinceLabelPresenceIconIds(presence));
  return ids;
}

/// Resolves optional prefix icon ids for sea-zone labels.
List<String> resolveSeaZoneLabelPrefixIconIds({required bool isWarpZone}) {
  if (!isWarpZone) {
    return const <String>[];
  }
  return const <String>[_seaZoneLabelWarpIconId];
}

/// Resolves map province-label presence icon ids from province presence data.
///
/// Order is always civilian, regiment, ship. Icons are suppressed when intel is
/// not visible or count is zero.
List<String> resolveProvinceLabelPresenceIconIds(
  ProvinceUnitPresenceView? presence,
) {
  final showPresenceIcons = presence != null && presence.intelVisible;
  if (!showPresenceIcons) {
    return const <String>[];
  }
  return <String>[
    if (presence.civilianCount > 0) 'map_presence_civilian',
    if (presence.regimentCount > 0) 'map_presence_regiment',
    if (presence.shipCount > 0) 'map_presence_ship',
  ];
}

/// Returns true when province-name text + icons should wrap icons to line 2.
bool shouldWrapProvinceLabelPresenceIcons({
  required double textWidthPx,
  required int iconCount,
  double maxWidthPx = _provinceLabelMaxWidthPx,
  double iconRenderedPx = _provinceLabelIconRenderedPx,
  double iconGapPx = _provinceLabelIconGapPx,
  double textIconGapPx = _provinceLabelTextIconGapPx,
}) {
  if (iconCount <= 0) {
    return false;
  }
  final iconsWidth =
      (iconCount * iconRenderedPx) + ((iconCount - 1) * iconGapPx);
  final singleLineContentWidth = textWidthPx + textIconGapPx + iconsWidth;
  return singleLineContentWidth > maxWidthPx;
}

/// Capital labels must keep full text + star visible; do not ellipsize.
bool shouldEllipsizeProvinceLabelText({required bool isCapital}) {
  return !isCapital;
}

/// Returns true when the land-base pass should apply fog darkening.
///
/// Feature terrain (forest/hills/mountain/swamp) is darkened in the feature
/// overlay pass, so land-base darkening must be skipped there to avoid
/// compounded fog attenuation on the same tile.
bool shouldApplyFogToLandBase({
  required CtMapVisibilityMode visibilityMode,
  required TileVisibility tileVisibility,
  required TerrainType? terrain,
}) {
  if (visibilityMode != CtMapVisibilityMode.playerConstrained) {
    return false;
  }
  if (tileVisibility != TileVisibility.fogged) {
    return false;
  }
  if (terrain == null) {
    return true;
  }
  return !_isFeatureTerrain(terrain);
}

/// Returns true when the feature-overlay pass should apply fog darkening.
///
/// Feature terrain should receive fog attenuation in the overlay pass only, so
/// fogged feature cells do not get darkened twice across base + overlay.
bool shouldApplyFogToFeatureOverlay({
  required CtMapVisibilityMode visibilityMode,
  required TileVisibility tileVisibility,
  required TerrainType? terrain,
}) {
  if (visibilityMode != CtMapVisibilityMode.playerConstrained) {
    return false;
  }
  if (tileVisibility != TileVisibility.fogged) {
    return false;
  }
  if (terrain == null) {
    return false;
  }
  return _isFeatureTerrain(terrain);
}

/// Returns true when the interior-plains variant base draw should apply fog.
///
/// For `tile_plains_*` composition, fog must be applied once across the final
/// composed result. The base pass intentionally stays un-fogged, and the
/// variant overlay pass receives fog attenuation when needed.
bool shouldApplyFogToInteriorPlainsVariantBase({
  required CtMapVisibilityMode visibilityMode,
  required TileVisibility tileVisibility,
}) {
  return false;
}

/// Returns true when the interior-plains variant overlay draw should apply fog.
///
/// This is the single fog attenuation point for fogged interior-plains
/// `tile_plains_*` composition to avoid double darkening.
bool shouldApplyFogToInteriorPlainsVariantOverlay({
  required CtMapVisibilityMode visibilityMode,
  required TileVisibility tileVisibility,
}) {
  if (visibilityMode != CtMapVisibilityMode.playerConstrained) {
    return false;
  }
  return tileVisibility == TileVisibility.fogged;
}

/// Returns true when transport sprites should render for the selected base mode.
bool shouldRenderTransportOverlay({
  required BaseLayerDisplayMode baseLayerDisplayMode,
}) {
  return baseLayerDisplayMode ==
      BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads;
}

/// Returns true when a road level should use the rail transport family.
///
/// Current v1 behavior uses rail sprites only for level 4.
bool isRailTransportLevel(int roadLevel) => roadLevel == 4;

/// Returns true when a given cell is eligible for transport overlay rendering.
///
/// Overlay is land-only, requires `roadLevel > 0`, and is hidden for unrevealed
/// cells in player-constrained visibility mode.
bool shouldPaintTransportOverlayForCell({
  required CellViewData cell,
  required CtMapVisibilityMode visibilityMode,
  required TileVisibility tileVisibility,
}) {
  if (cell.isSea || (cell.roadLevel ?? 0) <= 0) {
    return false;
  }
  if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
      tileVisibility == TileVisibility.unrevealed) {
    return false;
  }
  return true;
}

/// Check if a terrain type uses L2+ standalone tile rendering (features).
/// L0: Sea (Wang). L1: Plains/Desert (Wang). L2+: Features (standalone).
bool _isFeatureTerrain(TerrainType terrain) {
  return terrain == TerrainType.forest ||
      terrain == TerrainType.hills ||
      terrain == TerrainType.mountain ||
      terrain == TerrainType.swamp;
}

final class _PlainsDesertTally {
  int plains = 0;
  int desert = 0;
}

void _tallyDominantLandNeighbor(CellViewData? cell, _PlainsDesertTally tally) {
  if (cell == null || cell.isSea) {
    return;
  }
  final terrain = cell.terrainType;
  if (terrain == TerrainType.plains) {
    tally.plains++;
    return;
  }
  if (terrain == TerrainType.desert) {
    tally.desert++;
    return;
  }
  if (terrain != null && _isFeatureTerrain(terrain)) {
    tally.plains++; // Features have plains underneath
  }
}

/// Get the dominant adjacent land base type for coastline tileset selection.
/// Returns 'plains' or 'desert' based on which is more common among neighbors.
TerrainType? _getDominantAdjacentLandBase(
  int x,
  int y,
  CellViewData? Function(int, int) getCellAt,
) {
  final tally = _PlainsDesertTally();

  for (final dy in [-1, 0, 1]) {
    for (final dx in [-1, 0, 1]) {
      if (dx == 0 && dy == 0) {
        continue;
      }
      _tallyDominantLandNeighbor(getCellAt(x + dx, y + dy), tally);
    }
  }

  if (tally.plains >= tally.desert) {
    return TerrainType.plains;
  }
  return TerrainType.desert;
}

/// Visibility mode for the region map. SPEC/ui/map-widget.md.
enum CtMapVisibilityMode {
  /// Full visibility: ignore per-tile visibility and render all tiles as visible.
  full,

  /// Player-constrained visibility: honor [CellViewData.visibility] for each tile.
  playerConstrained,
}

/// [CtMapVisibilityMode.playerConstrained] requires [playerViewForResources].
void assertCtMapPlayerViewRequired({
  required CtMapVisibilityMode visibilityMode,
  required PlayerView? playerViewForResources,
}) {
  if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
      playerViewForResources == null) {
    throw StateError(
      'CtMapVisibilityMode.playerConstrained requires a non-null '
      'PlayerView (pass playerViewForResources), e.g. '
      'buildPlayerView(game, topology, humanPlayerId).',
    );
  }
}

/// Base layer display mode: terrain, resource icons, improvement labels, and
/// road/rail transport sprite overlays.
/// SPEC/ui/map-widget.md § Base layer display mode.
enum BaseLayerDisplayMode {
  /// Terrain only; no resource icons, improvement labels, or transport overlay.
  terrainOnly,

  /// Terrain + resource icons; no improvement labels or transport overlay.
  terrainAndResources,

  /// Terrain + resource icons + improvement labels (`I{n}` when n > 0); no
  /// transport overlay.
  terrainAndResourcesImprovementLabels,

  /// Terrain + resource icons + improvement labels + road/rail transport
  /// overlay (`roadLevel > 0`).
  terrainAndResourcesImprovementsRoads,
}

/// Returns true when extraction indicators are allowed for the current base mode.
bool shouldShowExtractionUnitIndicators({
  required BaseLayerDisplayMode baseLayerDisplayMode,
}) {
  return baseLayerDisplayMode != BaseLayerDisplayMode.terrainOnly;
}

/// On-map resource icon width/height in world/cell coordinates.
///
/// SPEC/ui/map-widget.md § Resource Icons: **one quarter** of [cellSize], capped
/// at [ResourceIconCache.iconSize] so 64×64 source assets are **never upscaled**
/// on the map (scale down only).
double resourceIconDisplaySizePx(double cellSize) {
  final quarter = cellSize * 0.25;
  return quarter < ResourceIconCache.iconSize
      ? quarter
      : ResourceIconCache.iconSize;
}

double extractionIndicatorDisplaySizePx(double resourceIconDisplaySizePx) {
  return math.min(
    ResourceIconCache.iconSize,
    resourceIconDisplaySizePx + _kExtractionIndicatorSizeBoostPx,
  );
}

List<Rect> extractionIndicatorRectsForIconRect({
  required Rect iconRect,
  required int units,
}) {
  if (units <= 0) {
    return const <Rect>[];
  }
  final indicatorSize = extractionIndicatorDisplaySizePx(iconRect.width);
  final stepX = indicatorSize * (1.0 - _kExtractionIndicatorOverlapFactor);
  final startX = iconRect.right + _kExtractionIndicatorStartInsetXPx;
  final top = iconRect.bottom - indicatorSize;
  return List<Rect>.generate(
    units,
    (i) =>
        Rect.fromLTWH(startX + (i * stepX), top, indicatorSize, indicatorSize),
    growable: false,
  );
}

/// Paints per-tile extraction throughput as **filled discs** (not commodity
/// sprites). Effective slots use [_kMapSelectionGold] (transported toward
/// capital); blocked slots use [_kExtractionDiscBlockedBrown].
/// [fogCompatibleOverlayPaint] supplies the same fog `ColorFilter` as resource
/// icons when the tile is fogged.
///
/// SPEC/ui/map-widget.md § Per-tile extraction throughput indicators;
/// SPEC/program/map-region-map-render.md (`_paintOverlay` extraction discs).
void paintResourceExtractionDiscIndicators({
  required Canvas canvas,
  required List<Rect> indicatorRects,
  required int effectiveCount,
  required Paint fogCompatibleOverlayPaint,
}) {
  if (indicatorRects.isEmpty) {
    return;
  }
  final fogFilter = fogCompatibleOverlayPaint.colorFilter;
  for (var i = 0; i < indicatorRects.length; i++) {
    final isEffective = i < effectiveCount;
    final fillColor = isEffective
        ? _kMapSelectionGold
        : _kExtractionDiscBlockedBrown;
    final discPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    if (fogFilter != null) {
      discPaint.colorFilter = fogFilter;
    }
    final r = indicatorRects[i];
    final radius = r.shortestSide * 0.5;
    canvas.drawCircle(r.center, radius, discPaint);
  }
}
