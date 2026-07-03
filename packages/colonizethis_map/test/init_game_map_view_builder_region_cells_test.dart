import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
group('buildInitGameMapViewData region data', () {
    test('returns InitGameMapViewData with oldWorld and newWorld regions', () {
      final owMap = mapTileGrid([
        ['p1', 's1'],
        ['s1', 's1'],
      ]);
      final nwMap = mapTileGrid([
        ['p1', 's1'],
        ['s1', 's1'],
      ]);
      final owTopology = regionTopology(
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
      final game = minimalGame(
        id: 'test',
        turnNumber: 1,
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            displayName: 'OW P1',
            ownerId: 'gp1',
          ),
        ],
        newWorldProvinces: const [
          Province(
            id: 'newWorld|p1',
            regionId: 'newWorld',
            displayName: 'NW P1',
          ),
        ],
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
      );

      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 16,
      );

      expect(viewData.oldWorld.regionId, 'oldWorld');
      expect(viewData.newWorld.regionId, 'newWorld');
      expect(viewData.oldWorld.width, 2);
      expect(viewData.oldWorld.height, 2);
      expect(viewData.oldWorld.cells.length, 4);
      expect(viewData.oldWorld.cells[0].regionCellId, 'p1');
      expect(viewData.oldWorld.cells[0].isSea, false);
      expect(viewData.oldWorld.cells[1].regionCellId, 's1');
      expect(viewData.oldWorld.cells[1].isSea, true);
      expect(viewData.oldWorld.factionColors, isNotEmpty);
      expect(viewData.oldWorld.greatPowerFactionIds, {'gp1'});
      expect(viewData.newWorld.greatPowerFactionIds, {'gp1'});
      expect(
        viewData
            .oldWorld
            .provincePoliticalOwnerByPrefixedProvinceId['oldWorld|p1'],
        'gp1',
      );
      expect(
        viewData
            .newWorld
            .provincePoliticalOwnerByPrefixedProvinceId['newWorld|p1'],
        isNull,
      );
      expect(viewData.newWorld.cells.length, 4);
    });

    test('copies seaZoneDisplayNameById into RegionMapViewData.seaZoneDisplayNameByPrefixedId', () {
      final owMap = mapTileGrid([
        ['p1', 's1'],
        ['s1', 's1'],
      ]);
      final nwMap = mapTileGrid([
        ['p1', 's1'],
        ['s1', 's1'],
      ]);
      final owTopology = regionTopology(
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
      final game = minimalGame(
        id: 'test',
        turnNumber: 1,
        seaZoneDisplayNameById: const {
          'oldWorld|s1': 'Adriatic Sea',
          'newWorld|s1': 'Caribbean Sea',
        },
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            displayName: 'OW P1',
            ownerId: 'gp1',
          ),
        ],
        newWorldProvinces: const [
          Province(
            id: 'newWorld|p1',
            regionId: 'newWorld',
            displayName: 'NW P1',
          ),
        ],
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
      );

      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 16,
      );

      expect(
        viewData.oldWorld.seaZoneDisplayNameByPrefixedId['oldWorld|s1'],
        'Adriatic Sea',
      );
      expect(
        viewData.newWorld.seaZoneDisplayNameByPrefixedId['newWorld|s1'],
        'Caribbean Sea',
      );
    });

    test('invokes with seed configSummary and greatPowerColorOverride', () {
      final owMap = mapTileGrid([
        ['p1'],
      ]);
      final nwMap = mapTileGrid([
        ['p1'],
      ]);
      final owTopology = regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['p1'],
      );
      final nwTopology = regionTopology(
        regionId: 'newWorld',
        provinceIds: const ['p1'],
      );
      final game = minimalGame(
        id: 'g',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
        newWorldProvinces: const [
          Province(id: 'newWorld|p1', regionId: 'newWorld'),
        ],
        players: const [Player(id: 'gp1', displayName: 'GP', isHuman: false)],
      );
      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
        seed: 123,
        configSummary: 'test config',
      );
      expect(viewData.seed, 123);
      expect(viewData.configSummary, 'test config');
      expect(viewData.oldWorld.factionColors['gp1'], isNotNull);
      expect(
        viewData.oldWorld.cells.singleWhere((c) => !c.isSea).ownerFactionId,
        'gp1',
      );
    });
  });

group('buildInitGameMapViewData extracted slice coverage', () {
    test(
      'region setup maps owner/display and terrain palette from minimal data',
      () {
        final tileMap = mapTileGrid(
          [
            ['p1'],
          ],
          terrainGrid: [
            [TerrainType.hardwoodForest],
          ],
        );
        final seaOnly = mapTileGrid([
          ['s1'],
        ]);
        final topology = singleProvinceAndSeaTopology('oldWorld');
        final newWorldTopology = singleProvinceAndSeaTopology('newWorld');
        final game = minimalGame(
          id: 'slice-test',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
              displayName: 'Alpha',
            ),
          ],
          newWorldProvinces: const [],
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: false),
          ],
        );

        final view = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap, 'newWorld': seaOnly},
          topologyByRegion: {
            'oldWorld': topology,
            'newWorld': newWorldTopology,
          },
          cellSize: 8,
        );

        final cell = view.oldWorld.cells.single;
        expect(cell.ownerFactionId, 'gp1');
        expect(cell.provinceDisplayName, 'Alpha');
        expect(
          view.oldWorld.terrainColors.containsKey(TerrainType.hardwoodForest),
          isTrue,
        );
        expect(
          view
              .oldWorld
              .provincePoliticalOwnerByPrefixedProvinceId['oldWorld|p1'],
          'gp1',
        );
      },
    );

    test('overlay setup counts regiments, civilians, and in-port ships', () {
      final tileMap = mapTileGrid([
        ['p1'],
      ]);
      final seaOnly = mapTileGrid([
        ['s1'],
      ]);
      final topology = singleProvinceAndSeaTopology('oldWorld');
      final newWorldTopology = singleProvinceAndSeaTopology('newWorld');
      final game = minimalGame(
        id: 'slice-test',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
        ],
        newWorldProvinces: const [],
        oldWorldUnits: [
          Unit(
            id: 'u-builder',
            type: kUnitTypeBuilder,
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
          ),
          Unit(
            id: 'u-regiment',
            type: 'pikemen',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
          ),
        ],
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'gp1',
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|p1',
            ships: const [ShipInstance(id: 'ship-1', typeId: 'frigate')],
          ),
        ],
      );

      final view = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': seaOnly},
        topologyByRegion: {'oldWorld': topology, 'newWorld': newWorldTopology},
        cellSize: 8,
      );

      final presence =
          view.oldWorld.provinceUnitPresenceByProvinceId['oldWorld|p1']!;
      expect(presence.civilianCount, 1);
      expect(presence.regimentCount, 1);
      expect(presence.shipCount, 1);
      expect(presence.intelVisible, isTrue);
    });

    test('marker helpers expose capitals ports towns and warps', () {
      final tileMap = mapTileGrid([
        ['p1', 's1'],
      ]);
      final newWorldSea = mapTileGrid([
        ['s9'],
      ]);
      final topology = singleProvinceAndSeaTopology('oldWorld');
      final newWorldTopology = regionTopology(
        regionId: 'newWorld',
        seaZoneIds: const ['s9'],
      );
      final game = minimalGame(
        id: 'slice-test',
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            townTileKey: 'oldWorld|p1|0|0',
          ),
        ],
        newWorldProvinces: const [],
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
        portsByProvinceSeaboard: const {'oldWorld|p1|s1': 'oldWorld|p1|0|0'},
      );

      final view = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': newWorldSea},
        topologyByRegion: {'oldWorld': topology, 'newWorld': newWorldTopology},
        cellSize: 8,
        warpLinks: const [
          WarpLink(
            regionId: 'oldWorld',
            seaZoneId: 's1',
            otherRegionId: 'newWorld',
            otherSeaZoneId: 's9',
          ),
        ],
      );

      expect(view.oldWorld.capitalMarkers.length, 1);
      expect(view.oldWorld.capitalMarkers.single.factionId, 'gp1');
      expect(view.oldWorld.portMarkers.length, 1);
      expect(view.oldWorld.portMarkers.single.provinceId, 'p1');
      expect(view.oldWorld.townMarkers.length, 1);
      expect(view.oldWorld.townMarkers.single.isPort, isTrue);
      expect(view.oldWorld.townMarkers.single.touchesSea, isTrue);
      expect(view.oldWorld.warpMarkers.length, 1);
      expect(view.oldWorld.warpMarkers.single.seaZoneId, 's1');
      expect(view.oldWorld.warpMarkers.single.otherRegionId, 'newWorld');
    });

    test('cell helper applies visibility and extraction overlays', () {
      final tileMap = mapTileGrid([
        ['p1'],
      ]);
      final seaOnly = mapTileGrid([
        ['s1'],
      ]);
      final topology = singleProvinceAndSeaTopology('oldWorld');
      final newWorldTopology = singleProvinceAndSeaTopology('newWorld');
      final game = minimalGame(
        id: 'slice-test',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
        ],
        newWorldProvinces: const [],
      );

      final view = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': seaOnly},
        topologyByRegion: {'oldWorld': topology, 'newWorld': newWorldTopology},
        cellSize: 8,
        visibilityByTile: const {'oldWorld|p1|0|0': TileVisibility.fogged},
        resourceExtractionUnitsByTile: const {'oldWorld|p1|0|0': 9},
        resourceExtractionEffectiveUnitsByTile: const {'oldWorld|p1|0|0': 7},
        resourceExtractionBlockedUnitsByTile: const {'oldWorld|p1|0|0': 2},
      );

      final cell = view.oldWorld.cells.single;
      expect(cell.visibility, TileVisibility.fogged);
      expect(cell.resourceExtractionUnits, 9);
      expect(cell.resourceExtractionEffectiveUnits, 7);
      expect(cell.resourceExtractionBlockedUnits, 2);
    });

    test(
      'does not synthesize a Home Fleet marker when fleet entity is missing',
      () {
        final tileMap = mapTileGrid([
          ['p1', 's1'],
        ]);
        final newWorldSea = mapTileGrid([
          ['s9'],
        ]);
        final topology = singleProvinceAndSeaTopology('oldWorld');
        final newWorldTopology = regionTopology(
          regionId: 'newWorld',
          seaZoneIds: const ['s9'],
        );
        final game = minimalGame(
          id: 'slice-test',
          oldWorldProvinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          ],
          newWorldProvinces: const [],
          players: const [
            Player(
              id: 'gp1',
              displayName: 'GP1',
              isHuman: true,
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: 'oldWorld|p1',
                x: 0,
                y: 0,
              ),
            ),
          ],
          portsByProvinceSeaboard: const {'oldWorld|p1|s1': 'oldWorld|p1|0|0'},
        );

        final view = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap, 'newWorld': newWorldSea},
          topologyByRegion: {
            'oldWorld': topology,
            'newWorld': newWorldTopology,
          },
          cellSize: 8,
        );

        expect(view.oldWorld.fleetTileMarkers, isEmpty);
      },
    );

    test('keeps an empty Home Fleet marker when real fleet entity exists', () {
      final tileMap = mapTileGrid([
        ['p1', 's1'],
      ]);
      final newWorldSea = mapTileGrid([
        ['s9'],
      ]);
      final topology = singleProvinceAndSeaTopology('oldWorld');
      final newWorldTopology = regionTopology(
        regionId: 'newWorld',
        seaZoneIds: const ['s9'],
      );
      final game = minimalGame(
        id: 'slice-test',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
        newWorldProvinces: const [],
        fleets: [
          Fleet(
            id: 'fleet_gp1',
            ownerId: 'gp1',
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|p1',
            ships: [],
            mission: FleetMission.none,
          ),
        ],
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
        portsByProvinceSeaboard: const {'oldWorld|p1|s1': 'oldWorld|p1|0|0'},
      );

      final view = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': newWorldSea},
        topologyByRegion: {'oldWorld': topology, 'newWorld': newWorldTopology},
        cellSize: 8,
      );

      expect(view.oldWorld.fleetTileMarkers, hasLength(1));
      expect(view.oldWorld.fleetTileMarkers.single.fleetIds, ['fleet_gp1']);
      expect(view.oldWorld.fleetTileMarkers.single.stackCount, 1);
    });
  });
}
