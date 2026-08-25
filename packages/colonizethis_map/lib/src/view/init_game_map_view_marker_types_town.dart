/// Town, port, and warp marker DTOs.
/// SPEC/program/map-visualization.md § Map view model for tools. Refs #4654.
library;

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
