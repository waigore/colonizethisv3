/// Marker view types for init_game map visualization.
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

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
    required this.townDevelopmentLevel,
    required this.townIconStyle,
    this.portIconX,
    this.portIconY,
    this.worldFortLevel = 0,
    this.mapVisibleFortLevel,
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

  /// Province town development level (1–4) for level-aware town glyph. Refs #3870.
  final int townDevelopmentLevel;

  /// Town icon style id (`euro`, `colonial`, `tribal`). Refs #3870.
  final String townIconStyle;

  /// When [isPort] is true, grid coordinates for the port icon (may differ from
  /// [x]/[y] when the port tile matches town or capital). SPEC/ui/town-port-icons.md.
  final int? portIconX;
  final int? portIconY;

  /// Authoritative province fort level (0–3) from world state. Refs #4280.
  final int worldFortLevel;

  /// Fort level drawn on the map (1–3), or null when hidden (open field or
  /// intel-gated). Set by the map-view builder or post-process for player view.
  final int? mapVisibleFortLevel;

  TownMarkerView copyWith({
    int? worldFortLevel,
    int? mapVisibleFortLevel,
    bool clearMapVisibleFortLevel = false,
  }) {
    return TownMarkerView(
      x: x,
      y: y,
      provinceId: provinceId,
      isCoastal: isCoastal,
      isPort: isPort,
      touchesSea: touchesSea,
      townDevelopmentLevel: townDevelopmentLevel,
      townIconStyle: townIconStyle,
      portIconX: portIconX,
      portIconY: portIconY,
      worldFortLevel: worldFortLevel ?? this.worldFortLevel,
      mapVisibleFortLevel: clearMapVisibleFortLevel
          ? null
          : (mapVisibleFortLevel ?? this.mapVisibleFortLevel),
    );
  }
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
