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
}
