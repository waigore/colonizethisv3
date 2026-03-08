// Demo RegionMapViewData for Widgetbook and testing.
// SPEC/ui/map-widget.md — debug mode mockup with generated map.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

/// Solid RGB palette for debug terrain (distinct per terrain type).
const Map<TerrainType, Rgb> _debugTerrainColors = {
  TerrainType.plains: (200, 220, 160),
  TerrainType.forest: (34, 100, 34),
  TerrainType.hills: (160, 130, 90),
  TerrainType.mountain: (120, 120, 120),
  TerrainType.swamp: (70, 100, 90),
  TerrainType.desert: (210, 190, 140),
};

/// Solid RGB for demo factions.
const Map<String, Rgb> _debugFactionColors = {
  'gp1': (200, 80, 80),
  'gp2': (80, 140, 200),
  'gp3': (90, 160, 90),
};

/// Builds a small region map for Widgetbook debug-mode demonstration.
/// Grid: 14×10; mix of sea, land, terrains, resources, improvements, roads;
/// multiple provinces and factions; one capital.
RegionMapViewData buildDemoRegionMapViewData() {
  const int w = 14;
  const int h = 10;
  const int cellSize = 24;
  const String regionId = 'demo';

  // Layout: row 0 and row 9 = sea; col 0 and col 13 = sea; inner = land.
  // Provinces: p1 (left), p2 (center), p3 (right), p4 (bottom center). Sea zones s1, s2.
  final cells = <CellViewData>[];
  final landTerrains = [
    TerrainType.plains,
    TerrainType.plains,
    TerrainType.forest,
    TerrainType.hills,
    TerrainType.plains,
    TerrainType.mountain,
    TerrainType.swamp,
    TerrainType.plains,
    TerrainType.forest,
    TerrainType.desert,
    TerrainType.plains,
    TerrainType.hills,
  ];
  final landResources = [
    'grain',
    null,
    'timber',
    null,
    'iron',
    null,
    null,
    'grain',
    null,
    null,
    'timber',
    null,
  ];
  final landImprovements = [0, 1, 0, 2, 0, 0, 1, 3, 0, 0, 1, 0];
  final landRoads = [0, 0, 1, 2, 0, 0, 0, 1, 0, 0, 0, 0];
  var landIndex = 0;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final isSea = y == 0 || y == h - 1 || x == 0 || x == w - 1;
      String regionCellId;
      String? terrainTypeId;
      TerrainType? terrainType;
      String? resourceId;
      String? ownerFactionId;
      String? provinceDisplayName;
      int? improvementLevel;
      int? roadLevel;

      if (isSea) {
        regionCellId = y == 0 ? 's1' : (x < w / 2 ? 's1' : 's2');
      } else {
        if (x < 4) {
          regionCellId = 'p1';
          ownerFactionId = 'gp1';
          provinceDisplayName = 'Wessex';
        } else if (x >= 10) {
          regionCellId = 'p3';
          ownerFactionId = 'gp2';
          provinceDisplayName = 'Northumbria';
        } else if (y >= 7) {
          regionCellId = 'p4';
          ownerFactionId = 'gp2';
          provinceDisplayName = 'Mercia';
        } else {
          regionCellId = 'p2';
          ownerFactionId = 'gp1';
          provinceDisplayName = 'Kent';
        }
        final t = landTerrains[landIndex % landTerrains.length];
        terrainTypeId = t.name;
        terrainType = t;
        resourceId = landResources[landIndex % landResources.length];
        improvementLevel = landImprovements[landIndex % landImprovements.length];
        roadLevel = landRoads[landIndex % landRoads.length];
        landIndex++;
      }

      cells.add(CellViewData(
        x: x,
        y: y,
        regionCellId: regionCellId,
        isSea: isSea,
        terrainTypeId: terrainTypeId,
        terrainType: terrainType,
        resourceId: resourceId,
        ownerFactionId: ownerFactionId,
        provinceDisplayName: provinceDisplayName,
        improvementLevel: improvementLevel,
        roadLevel: roadLevel,
      ));
    }
  }

  final capitalMarkers = [
    CapitalMarkerView(
      factionId: 'gp1',
      displayName: 'England',
      x: 2,
      y: 4,
    ),
  ];
  final portMarkers = [
    PortMarkerView(
      x: 6,
      y: 8,
      provinceId: 'p2',
      seaZoneId: 's1',
      seaboardKey: 'east',
    ),
  ];

  return RegionMapViewData(
    regionId: regionId,
    width: w,
    height: h,
    cellSize: cellSize,
    cells: cells,
    capitalMarkers: capitalMarkers,
    portMarkers: portMarkers,
    factionColors: _debugFactionColors,
    terrainColors: _debugTerrainColors,
    unitMarkers: [],
  );
}
