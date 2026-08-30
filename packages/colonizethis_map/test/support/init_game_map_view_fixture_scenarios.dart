import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_fixtures.dart';

/// Dual-region view-builder / visualizer scenario wiring.
class DualRegionViewScenario {
  const DualRegionViewScenario({
    required this.game,
    required this.tileMapByRegion,
    required this.topologyByRegion,
  });

  final Game game;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, MapTopology> topologyByRegion;

  InitGameMapViewData buildViewData({
    int cellSize = 8,
    int? seed,
    String? configSummary,
    Map<String, (int r, int g, int b)>? greatPowerColorOverride,
    Map<String, TileVisibility>? visibilityByTile,
    List<WarpLink>? warpLinks,
    Map<String, int>? resourceExtractionUnitsByTile,
    Map<String, int>? resourceExtractionEffectiveUnitsByTile,
    Map<String, int>? resourceExtractionBlockedUnitsByTile,
    Set<String>? civilianMarkerOwnerIds,
    String? viewingFactionId,
    Map<String, bool>? viewingTechUnlocked,
  }) {
    return buildInitGameMapViewData(
      game: game,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      cellSize: cellSize,
      seed: seed,
      configSummary: configSummary,
      greatPowerColorOverride: greatPowerColorOverride,
      visibilityByTile: visibilityByTile,
      warpLinks: warpLinks,
      resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
      resourceExtractionEffectiveUnitsByTile:
          resourceExtractionEffectiveUnitsByTile,
      resourceExtractionBlockedUnitsByTile:
          resourceExtractionBlockedUnitsByTile,
      civilianMarkerOwnerIds: civilianMarkerOwnerIds,
      viewingFactionId: viewingFactionId,
      viewingTechUnlocked: viewingTechUnlocked,
    );
  }
}

DualRegionViewScenario dualRegionViewScenario({
  required Game game,
  required TileMapResult oldWorldMap,
  required TileMapResult newWorldMap,
  required MapTopology oldWorldTopology,
  required MapTopology newWorldTopology,
}) {
  return DualRegionViewScenario(
    game: game,
    tileMapByRegion: {'oldWorld': oldWorldMap, 'newWorld': newWorldMap},
    topologyByRegion: {
      'oldWorld': oldWorldTopology,
      'newWorld': newWorldTopology,
    },
  );
}

TileMapResult defaultNewWorldMap() => mapTileGrid([
  ['p1'],
]);

MapTopology defaultNewWorldTopology({List<String> provinceIds = const ['p1']}) {
  return regionTopology(regionId: 'newWorld', provinceIds: provinceIds);
}

DualRegionViewScenario dualRegionScenario({
  required Game game,
  required List<List<String>> oldWorldGrid,
  required MapTopology oldWorldTopology,
  List<List<String>>? newWorldGrid,
  MapTopology? newWorldTopology,
  List<List<TerrainType?>>? oldWorldTerrainGrid,
  List<List<Resource?>>? oldWorldResourceGrid,
}) {
  return dualRegionViewScenario(
    game: game,
    oldWorldMap: mapTileGrid(
      oldWorldGrid,
      terrainGrid: oldWorldTerrainGrid,
      resourceGrid: oldWorldResourceGrid,
    ),
    newWorldMap: mapTileGrid(
      newWorldGrid ??
          const [
            ['p1'],
          ],
    ),
    oldWorldTopology: oldWorldTopology,
    newWorldTopology: newWorldTopology ?? defaultNewWorldTopology(),
  );
}

DualRegionViewScenario oldWorldFocusedScenario({
  required Game game,
  required List<List<String>> oldWorldGrid,
  required MapTopology oldWorldTopology,
  List<List<String>> newWorldGrid = const [
    ['s1'],
  ],
  MapTopology? newWorldTopology,
  List<List<TerrainType?>>? oldWorldTerrainGrid,
}) {
  return dualRegionViewScenario(
    game: game,
    oldWorldMap: mapTileGrid(oldWorldGrid, terrainGrid: oldWorldTerrainGrid),
    newWorldMap: mapTileGrid(newWorldGrid),
    oldWorldTopology: oldWorldTopology,
    newWorldTopology:
        newWorldTopology ?? singleProvinceAndSeaTopology('newWorld'),
  );
}

DualRegionViewScenario provinceSeaDualRegionScenario({required Game game}) {
  final grid = [
    ['p1', 's1'],
    ['s1', 's1'],
  ];
  final topology = regionTopology(
    regionId: 'oldWorld',
    provinceIds: const ['p1'],
    seaZoneIds: const ['s1'],
    edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
  );
  final nwTopology = regionTopology(
    regionId: 'newWorld',
    provinceIds: const ['p1'],
    seaZoneIds: const ['s1'],
    edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
  );
  return dualRegionViewScenario(
    game: game,
    oldWorldMap: mapTileGrid(grid),
    newWorldMap: mapTileGrid(grid),
    oldWorldTopology: topology,
    newWorldTopology: nwTopology,
  );
}

InitGameMapViewData buildViewDataForScenario(
  DualRegionViewScenario scenario, {
  int cellSize = 8,
  int? seed,
  String? configSummary,
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,
  Map<String, TileVisibility>? visibilityByTile,
  List<WarpLink>? warpLinks,
  Map<String, int>? resourceExtractionUnitsByTile,
  Map<String, int>? resourceExtractionEffectiveUnitsByTile,
  Map<String, int>? resourceExtractionBlockedUnitsByTile,
  Set<String>? civilianMarkerOwnerIds,
  String? viewingFactionId,
  Map<String, bool>? viewingTechUnlocked,
}) {
  return scenario.buildViewData(
    cellSize: cellSize,
    seed: seed,
    configSummary: configSummary,
    greatPowerColorOverride: greatPowerColorOverride,
    visibilityByTile: visibilityByTile,
    warpLinks: warpLinks,
    resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
    resourceExtractionEffectiveUnitsByTile:
        resourceExtractionEffectiveUnitsByTile,
    resourceExtractionBlockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
    civilianMarkerOwnerIds: civilianMarkerOwnerIds,
    viewingFactionId: viewingFactionId,
    viewingTechUnlocked: viewingTechUnlocked,
  );
}
