part of 'region_map_component.dart';

/// Fog overlay opacity when drawing a dark rect over tiles (0 = no overlay, 1 = full black).
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

/// Check if a terrain type uses L2+ standalone tile rendering (features).
/// L0: Sea (Wang). L1: Plains/Desert (Wang). L2+: Features (standalone).
bool _isFeatureTerrain(TerrainType terrain) {
  return terrain == TerrainType.forest ||
      terrain == TerrainType.hills ||
      terrain == TerrainType.mountain ||
      terrain == TerrainType.swamp;
}

/// Get the dominant adjacent land base type for coastline tileset selection.
/// Returns 'plains' or 'desert' based on which is more common among neighbors.
TerrainType? _getDominantAdjacentLandBase(
  int x,
  int y,
  CellViewData? Function(int, int) getCellAt,
) {
  int plainsCount = 0;
  int desertCount = 0;

  for (final dy in [-1, 0, 1]) {
    for (final dx in [-1, 0, 1]) {
      if (dx == 0 && dy == 0) continue;
      final cell = getCellAt(x + dx, y + dy);
      if (cell != null && !cell.isSea) {
        final terrain = cell.terrainType;
        if (terrain == TerrainType.plains) {
          plainsCount++;
        } else if (terrain == TerrainType.desert) {
          desertCount++;
        } else if (terrain != null && _isFeatureTerrain(terrain)) {
          plainsCount++; // Features have plains underneath
        }
      }
    }
  }

  if (plainsCount >= desertCount) return TerrainType.plains;
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

/// Base layer display mode: terrain, resource icons, improvement/road labels.
/// SPEC/ui/map-widget.md § Base layer display mode.
enum BaseLayerDisplayMode {
  /// Terrain only; no resource icons or improvement/road labels.
  terrainOnly,

  /// Terrain + resource icons; no improvement or road labels.
  terrainAndResources,

  /// Terrain + resource icons + improvement labels (`I{n}` when n > 0); no road labels.
  terrainAndResourcesImprovementLabels,

  /// Terrain + resource icons + improvement labels + road/rail labels (`R{n}` when n > 0).
  /// Roads are painted after improvements (on top). Road labels require improvement mode on.
  terrainAndResourcesImprovementsRoads,
}
