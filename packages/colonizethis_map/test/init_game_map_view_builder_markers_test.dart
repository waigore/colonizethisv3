import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
  group('buildInitGameMapViewData markers', () {
    test('uses full province ids for ownership and unit markers', () {
      final scenario = dualRegionViewScenario(
        game: minimalGame(
          id: 'fullIds',
          oldWorldProvinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
          ],
          oldWorldUnits: [
            Unit(
              id: 'u1',
              type: 'Army',
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|p1',
              status: UnitStatus.idle,
            ),
          ],
          newWorldProvinces: const [
            Province(id: 'newWorld|p1', regionId: 'newWorld', ownerId: 'gp3'),
          ],
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: false),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
            Player(id: 'gp3', displayName: 'GP3', isHuman: false),
          ],
        ),
        oldWorldMap: mapTileGrid([
          ['p1', 'p2'],
        ]),
        newWorldMap: mapTileGrid([
          ['p1'],
        ]),
        oldWorldTopology: regionTopology(
          regionId: 'oldWorld',
          provinceIds: const ['p1', 'p2'],
          edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
        ),
        newWorldTopology: regionTopology(
          regionId: 'newWorld',
          provinceIds: const ['p1'],
        ),
      );
      final viewData = buildViewDataForScenario(scenario);

      final owCells = viewData.oldWorld.cells.where((c) => !c.isSea).toList();
      expect(owCells.length, 2);
      final p1Cell = owCells.singleWhere((c) => c.regionCellId == 'p1');
      final p2Cell = owCells.singleWhere((c) => c.regionCellId == 'p2');
      expect(p1Cell.ownerFactionId, 'gp1');
      expect(p2Cell.ownerFactionId, 'gp2');

      // Unit marker for gp1 is placed in province p1 (x = 0).
      expect(viewData.oldWorld.unitMarkers, hasLength(1));
      final marker = viewData.oldWorld.unitMarkers.single;
      expect(marker.ownerFactionId, 'gp1');
      expect(marker.x, 0);
      expect(marker.y, 0);
    });

    test(
      'includes capital markers for minor nations and tribes with null displayName',
      () {
        final game = minimalGame(
          id: 'capitals',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              displayName: 'OW',
            ),
          ],
          newWorldProvinces: const [
            Province(
              id: 'newWorld|p1',
              regionId: 'newWorld',
              displayName: 'NW',
            ),
          ],
          minorNations: [
            MinorNation(
              id: 'minor1',
              displayName: null,
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: 'oldWorld|p1',
                x: 0,
                y: 0,
              ),
            ),
          ],
          tribes: [
            Tribe(
              id: 'tribe1',
              displayName: null,
              capitalTile: CapitalTile(
                regionId: 'newWorld',
                provinceId: 'newWorld|p1',
                x: 0,
                y: 0,
              ),
            ),
          ],
        );
        final viewData = buildViewDataForScenario(
          provinceSeaDualRegionScenario(game: game),
        );

        expect(viewData.oldWorld.capitalMarkers, hasLength(1));
        expect(viewData.oldWorld.capitalMarkers.single.factionId, 'minor1');
        expect(viewData.oldWorld.capitalMarkers.single.displayName, 'minor1');

        expect(viewData.newWorld.capitalMarkers, hasLength(1));
        expect(viewData.newWorld.capitalMarkers.single.factionId, 'tribe1');
        expect(viewData.newWorld.capitalMarkers.single.displayName, 'tribe1');
      },
    );

    test('includes port markers from portsByProvinceSeaboard', () {
      final game = minimalGame(
        id: 'ports',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
        ],
        newWorldProvinces: const [
          Province(id: 'newWorld|p1', regionId: 'newWorld'),
        ],
        portsByProvinceSeaboard: const {
          'oldWorld|p1|seaboard': 'oldWorld|p1|0|1',
        },
      );
      final viewData = buildViewDataForScenario(
        provinceSeaDualRegionScenario(game: game),
      );

      expect(viewData.oldWorld.portMarkers, hasLength(1));
      expect(viewData.oldWorld.portMarkers.single.x, 0);
      expect(viewData.oldWorld.portMarkers.single.y, 1);
      expect(viewData.oldWorld.portMarkers.single.provinceId, 'p1');
      expect(
        viewData.oldWorld.portMarkers.single.seaboardKey,
        'oldWorld|p1|seaboard',
      );
    });
  });

  group('buildInitGameMapViewData warp zone markers', () {
    test('includes warp zone markers from warpLinks (bidirectional)', () {
      final game = minimalGame(id: 'warp');
      final warpLinks = [
        WarpLink(
          regionId: 'oldWorld',
          seaZoneId: 's1',
          otherRegionId: 'newWorld',
          otherSeaZoneId: 's3',
        ),
        WarpLink(
          regionId: 'oldWorld',
          seaZoneId: 's2',
          otherRegionId: 'newWorld',
          otherSeaZoneId: 's2',
        ),
      ];
      final viewData = buildViewDataForScenario(
        dualRegionScenario(
          game: game,
          oldWorldGrid: const [
            ['s1', 's2', 's3'],
          ],
          oldWorldTopology: regionTopology(
            regionId: 'oldWorld',
            seaZoneIds: const ['s1', 's2', 's3'],
          ),
          newWorldGrid: const [
            ['s1', 's2', 's3'],
          ],
          newWorldTopology: regionTopology(
            regionId: 'newWorld',
            seaZoneIds: const ['s1', 's2', 's3'],
          ),
        ),
        warpLinks: warpLinks,
      );

      // Old World should have 2 warp markers (s1 and s2).
      expect(viewData.oldWorld.warpMarkers, hasLength(2));
      final s1Marker = viewData.oldWorld.warpMarkers.singleWhere(
        (m) => m.seaZoneId == 's1',
      );
      expect(s1Marker.x, 0); // s1 is at tile index 0
      expect(s1Marker.y, 0);
      expect(s1Marker.otherRegionId, 'newWorld');
      expect(s1Marker.otherSeaZoneId, 's3');

      final s2Marker = viewData.oldWorld.warpMarkers.singleWhere(
        (m) => m.seaZoneId == 's2',
      );
      expect(s2Marker.x, 1); // s2 is at tile index 1
      expect(s2Marker.y, 0);
      expect(s2Marker.otherRegionId, 'newWorld');
      expect(s2Marker.otherSeaZoneId, 's2');

      // New World should have 2 warp markers (s3 and s2) via reverse lookup.
      expect(viewData.newWorld.warpMarkers, hasLength(2));
      final nwS3Marker = viewData.newWorld.warpMarkers.singleWhere(
        (m) => m.seaZoneId == 's3',
      );
      expect(nwS3Marker.x, 2); // s3 is at tile index 2
      expect(nwS3Marker.y, 0);
      expect(nwS3Marker.otherRegionId, 'oldWorld');
      expect(nwS3Marker.otherSeaZoneId, 's1');

      final nwS2Marker = viewData.newWorld.warpMarkers.singleWhere(
        (m) => m.seaZoneId == 's2',
      );
      expect(nwS2Marker.x, 1); // s2 is at tile index 1
      expect(nwS2Marker.y, 0);
      expect(nwS2Marker.otherRegionId, 'oldWorld');
      expect(nwS2Marker.otherSeaZoneId, 's2');
    });

    test('empty warpMarkers when warpLinks is null', () {
      final viewData = buildViewDataForScenario(
        dualRegionScenario(
          game: minimalGame(id: 'no-warp'),
          oldWorldGrid: const [
            ['s1'],
          ],
          oldWorldTopology: regionTopology(
            regionId: 'oldWorld',
            seaZoneIds: const ['s1'],
          ),
          newWorldGrid: const [
            ['s1'],
          ],
          newWorldTopology: regionTopology(
            regionId: 'newWorld',
            seaZoneIds: const ['s1'],
          ),
        ),
        warpLinks: null,
      );

      expect(viewData.oldWorld.warpMarkers, isEmpty);
      expect(viewData.newWorld.warpMarkers, isEmpty);
    });
  });
}
