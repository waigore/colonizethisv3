
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
