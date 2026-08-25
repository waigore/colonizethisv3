/// Capital, unit, civilian, and province-presence marker DTOs.
/// SPEC/program/map-visualization.md § Map view model for tools. Refs #4654.
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

  ProvinceUnitPresenceView copyWith({
    int? civilianCount,
    int? regimentCount,
    int? shipCount,
    bool? intelVisible,
  }) {
    return ProvinceUnitPresenceView(
      civilianCount: civilianCount ?? this.civilianCount,
      regimentCount: regimentCount ?? this.regimentCount,
      shipCount: shipCount ?? this.shipCount,
      intelVisible: intelVisible ?? this.intelVisible,
    );
  }
}
