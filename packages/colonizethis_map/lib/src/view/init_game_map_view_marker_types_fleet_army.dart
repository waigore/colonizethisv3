/// Fleet/army tile-marker DTOs and army hit-test layout.
/// SPEC/ui/map-widget.md. Refs #4654.
library;

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

/// Human-player army stack at one province town tile for interactive map markers.
/// Distinct from ctdev [UnitMarkerView]. SPEC/ui/map-widget.md § Human army markers.
class ArmyTileMarkerView {
  const ArmyTileMarkerView({
    required this.tileKey,
    required this.x,
    required this.y,
    required this.provinceId,
    required this.armyIds,
    required this.fieldArmyIds,
    required this.stackCount,
    required this.hasHomeArmy,
    this.renderGrayscale = false,
  });

  /// Town-tile key `regionId|localProvinceId|x|y` (may be draft-projected).
  final String tileKey;
  final int x;
  final int y;

  /// Prefixed stationed province id (`regionId|localId`).
  final String provinceId;

  /// Army ids at this marker, deterministic lexical order. Includes Home Army.
  final List<String> armyIds;

  /// Non-Home field army ids only — pass these to `showOverlayArmyMoveFlow`.
  final List<String> fieldArmyIds;

  /// Same as [armyIds.length]; Home Army counts toward the stack badge.
  final int stackCount;

  final bool hasHomeArmy;

  /// Grayscale when at least one field army exists and every field army has
  /// a pending [ArmyMoveOrder].
  final bool renderGrayscale;
}

/// Bottom-right sub-rect of the town cell used for army icon paint and hit-test.
abstract final class ArmyTileMarkerLayout {
  static const double originFrac = 0.55;

  static bool hitTestInCell({
    required double localX,
    required double localY,
    required double cellSize,
  }) {
    if (cellSize <= 0) return false;
    return localX / cellSize >= originFrac && localY / cellSize >= originFrac;
  }
}
