// Shared color and palette helpers for tile map and game world visualizers.
// SPEC/program/map-visualization.md § Tile map visualizers.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Distinct RGB colors for region/faction assignment. Deterministic order.
const List<(int r, int g, int b)> regionPalette = [
  (180, 80, 80), // red
  (80, 140, 200), // blue
  (90, 160, 90), // green
  (220, 180, 60), // yellow
  (160, 100, 180), // purple
  (60, 180, 180), // cyan
  (220, 140, 100), // orange
  (140, 100, 60), // brown
  (200, 100, 160), // pink
  (100, 120, 200), // lighter blue
  (120, 200, 120), // light green
  (200, 200, 100), // light yellow
  (180, 140, 200), // light purple
  (100, 200, 200), // light cyan
  (200, 160, 140), // peach
  (160, 160, 160), // gray
];

/// Fixed RGB per terrain type for map fill and legend.
const Map<TerrainType, (int r, int g, int b)> terrainColorRgb = {
  TerrainType.plains: (200, 220, 160),
  TerrainType.forest: (34, 100, 34),
  TerrainType.hills: (160, 130, 90),
  TerrainType.mountain: (120, 120, 120),
  TerrainType.swamp: (70, 100, 90),
  TerrainType.desert: (210, 190, 140),
};

/// Grey shades for minor nations (distinct from vibrant GP colours).
const List<(int r, int g, int b)> minorNationPalette = [
  (70, 70, 70),
  (90, 90, 90),
  (110, 110, 110),
  (130, 130, 130),
  (150, 150, 150),
  (170, 170, 170),
  (190, 190, 190),
  (210, 210, 210),
];

/// Land seed marker color (bright red).
const (int, int, int) landSeedMarkerRgb = (255, 0, 0);

/// Continent seed marker color (distinct from land seeds).
const (int, int, int) continentSeedMarkerRgb = (255, 255, 200);

/// Builds ownership colour map by faction type.
Map<String, (int r, int g, int b)> factionOwnershipColorMap({
  List<String> greatPowerIds = const [],
  List<String> minorNationIds = const [],
  List<String> tribeIds = const [],
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,
}) {
  final map = <String, (int r, int g, int b)>{};
  final gps = greatPowerIds.toList()..sort();
  final minors = minorNationIds.toList()..sort();
  final tribes = tribeIds.toList()..sort();
  for (var i = 0; i < gps.length; i++) {
    final id = gps[i];
    final override = greatPowerColorOverride?[id];
    final defaultColor = greatPowerDefaultColorRgb[id];
    map[id] =
        override ?? defaultColor ?? regionPalette[i % regionPalette.length];
  }
  for (var i = 0; i < minors.length; i++) {
    map[minors[i]] = minorNationPalette[i % minorNationPalette.length];
  }
  for (var i = 0; i < tribes.length; i++) {
    map[tribes[i]] = regionPalette[i % regionPalette.length];
  }
  return map;
}

/// Ownership colours for Old World maps (great powers + minor nations).
Map<String, (int r, int g, int b)> factionOwnershipColorMapForOldWorld(
  Game game, {
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,
}) {
  final greatPowerIds = game.players.map((player) => player.id).toList()
    ..sort();
  final minorNationIds = game.minorNations.map((nation) => nation.id).toList()
    ..sort();
  return factionOwnershipColorMap(
    greatPowerIds: greatPowerIds,
    minorNationIds: minorNationIds,
    greatPowerColorOverride: greatPowerColorOverride,
  );
}

/// Ownership colours for New World maps (tribes).
Map<String, (int r, int g, int b)> factionOwnershipColorMapForNewWorld(
  Game game,
) {
  final tribeIds = game.tribes.map((tribe) => tribe.id).toList()..sort();
  return factionOwnershipColorMap(tribeIds: tribeIds);
}

/// Combined ownership colours for init-game views (all faction types).
Map<String, (int r, int g, int b)> factionOwnershipColorMapForGame(
  Game game, {
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,
}) {
  final greatPowerIds = game.players.map((player) => player.id).toList();
  final minorNationIds = game.minorNations.map((nation) => nation.id).toList();
  final tribeIds = game.tribes.map((tribe) => tribe.id).toList();
  return factionOwnershipColorMap(
    greatPowerIds: greatPowerIds,
    minorNationIds: minorNationIds,
    tribeIds: tribeIds,
    greatPowerColorOverride: greatPowerColorOverride,
  );
}

/// Builds a map from region/faction id to (r, g, b) using deterministic palette.
Map<String, (int r, int g, int b)> colorMapFromIds(Iterable<String> ids) {
  final sorted = ids.toSet().toList()..sort();
  final map = <String, (int r, int g, int b)>{};
  for (var i = 0; i < sorted.length; i++) {
    map[sorted[i]] = regionPalette[i % regionPalette.length];
  }
  return map;
}
