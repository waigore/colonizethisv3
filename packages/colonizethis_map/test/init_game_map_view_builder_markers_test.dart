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

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
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

      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
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
      final owMap = mapTileGrid([
        ['s1', 's2', 's3'],
      ]);
      final nwMap = mapTileGrid([
        ['s1', 's2', 's3'],
      ]);
      final owTopology = regionTopology(
        regionId: 'oldWorld',
        seaZoneIds: const ['s1', 's2', 's3'],
      );
      final nwTopology = regionTopology(
        regionId: 'newWorld',
        seaZoneIds: const ['s1', 's2', 's3'],
      );
      final game = minimalGame(id: 'warp');

      // Warp links as generated by the generator: one-directional from OW to NW.
      // The builder handles both directions (source and destination regions).
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

      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
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
      final owMap = mapTileGrid([
        ['s1'],
      ]);
      final nwMap = mapTileGrid([
        ['s1'],
      ]);
      final owTopology = regionTopology(
        regionId: 'oldWorld',
        seaZoneIds: const ['s1'],
      );
      final nwTopology = regionTopology(
        regionId: 'newWorld',
        seaZoneIds: const ['s1'],
      );
      final game = minimalGame(id: 'no-warp');

      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
        warpLinks: null,
      );

      expect(viewData.oldWorld.warpMarkers, isEmpty);
      expect(viewData.newWorld.warpMarkers, isEmpty);
    });
  });

group('buildInitGameMapViewData town markers', () {
    test(
      'town markers: isPort with prefixed Province.id; port icon on port tile when separate from town',
      () {
        final owMap = mapTileGrid([
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 's1'],
        ]);
        final nwMap = mapTileGrid([
          ['p1'],
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
        );
        final game = minimalGame(
          id: 'townPortSep',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              townTileKey: 'oldWorld|p1|0|0',
            ),
          ],
          portsByProvinceSeaboard: const {
            'oldWorld|p1|seaboard': 'oldWorld|p1|2|0',
          },
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.provinceId, 'p1');
        expect(tm.isPort, isTrue);
        expect(tm.isCoastal, isFalse);
        expect(tm.touchesSea, isTrue);
        expect(tm.x, 0);
        expect(tm.y, 0);
        expect(tm.portIconX, 2);
        expect(tm.portIconY, 1);
      },
    );


    test('town markers include non-player provinces with townTileKey', () {
      final owMap = mapTileGrid([
        ['pPlayer', 'pMinor'],
      ]);
      final nwMap = mapTileGrid([
        ['p1'],
      ]);
      final owTopology = regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['pPlayer', 'pMinor'],
        edges: const [TopologyEdge(id1: 'pPlayer', id2: 'pMinor')],
      );
      final nwTopology = regionTopology(
        regionId: 'newWorld',
        provinceIds: const ['p1'],
      );
      final game = minimalGame(
        id: 'town_non_player',
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|pPlayer',
            regionId: 'oldWorld',
            ownerId: 'gp1',
            townTileKey: 'oldWorld|pPlayer|0|0',
          ),
          Province(
            id: 'oldWorld|pMinor',
            regionId: 'oldWorld',
            ownerId: 'minor1',
            townTileKey: 'oldWorld|pMinor|1|0',
          ),
        ],
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
      );

      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
      );

      expect(viewData.oldWorld.townMarkers, hasLength(2));
      final ids = viewData.oldWorld.townMarkers
          .map((m) => m.provinceId)
          .toSet();
      expect(ids, containsAll({'pPlayer', 'pMinor'}));
    });

    test(
      'town markers include non-player provinces with valid townTileKey',
      () {
        final owMap = mapTileGrid([
          ['p1', 'p2'],
        ]);
        final nwMap = mapTileGrid([
          ['p1'],
        ]);
        final owTopology = regionTopology(
          regionId: 'oldWorld',
          provinceIds: const ['p1', 'p2'],
        );
        final nwTopology = regionTopology(
          regionId: 'newWorld',
          provinceIds: const ['p1'],
        );
        final game = minimalGame(
          id: 'towns_non_player',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
              townTileKey: 'oldWorld|p1|0|0',
            ),
            Province(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              ownerId: 'ai_minor',
              townTileKey: 'oldWorld|p2|1|0',
            ),
          ],
          players: const [
            Player(id: 'gp1', displayName: 'Player GP', isHuman: true),
          ],
          minorNations: const [
            MinorNation(id: 'ai_minor', displayName: 'AI Minor Nation'),
          ],
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        expect(viewData.oldWorld.townMarkers.length, equals(2));
        expect(
          viewData.oldWorld.townMarkers.any(
            (m) => m.provinceId == 'p1' && m.x == 0 && m.y == 0,
          ),
          isTrue,
        );
        expect(
          viewData.oldWorld.townMarkers.any(
            (m) => m.provinceId == 'p2' && m.x == 1 && m.y == 0,
          ),
          isTrue,
        );
      },
    );

    test(
      'town markers: port on capital tile places port drawable on sea by town',
      () {
        final owMap = mapTileGrid([
          ['p1', 's1'],
          ['p1', 'p1'],
        ]);
        final nwMap = mapTileGrid([
          ['p1'],
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
        );
        final game = minimalGame(
          id: 'townPortCap',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
              townTileKey: 'oldWorld|p1|1|1',
            ),
          ],
          players: const [
            Player(
              id: 'gp1',
              displayName: 'GP',
              isHuman: true,
              capitalProvinceId: 'oldWorld|p1',
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: 'oldWorld|p1',
                x: 0,
                y: 0,
              ),
            ),
          ],
          portsByProvinceSeaboard: const {'oldWorld|p1|sb': 'oldWorld|p1|0|0'},
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.isPort, isTrue);
        expect(tm.portIconX, 1);
        expect(tm.portIconY, 0);
      },
    );

    test(
      'town markers: co-located port with no orthogonal sea throws',
      () {
        final owMap = mapTileGrid([
          ['p1', 'p1'],
          ['p1', 'p1'],
        ]);
        final nwMap = mapTileGrid([
          ['p1'],
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
        );
        final game = minimalGame(
          id: 'townPortFall',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              townTileKey: 'oldWorld|p1|1|1',
            ),
          ],
          portsByProvinceSeaboard: const {'oldWorld|p1|sb': 'oldWorld|p1|1|1'},
        );

        expect(
          () => buildInitGameMapViewData(
            game: game,
            tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
            topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
            cellSize: 8,
          ),
          throwsA(isA<PortDrawableSeaCellException>()),
        );
      },
    );
  });

group('buildInitGameMapViewData civilian tile markers', () {
    test(
      'builds deterministic player-owned civilian tile markers with priority and stack counts',
      () {
        final owMap = mapTileGrid([
          ['p1', 'p2', 'p3'],
        ]);
        final nwMap = mapTileGrid([
          ['p1'],
        ]);
        final owTopology = regionTopology(
          regionId: 'oldWorld',
          provinceIds: const ['p1', 'p2', 'p3'],
        );
        final nwTopology = regionTopology(
          regionId: 'newWorld',
          provinceIds: const ['p1'],
        );
        final game = minimalGame(
          id: 'civilian_markers',
          oldWorldProvinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
            Province(id: 'oldWorld|p3', regionId: 'oldWorld'),
          ],
          oldWorldUnits: [
            // Same tile; representative should be Builder by priority.
            Unit(
              id: 'u_builder',
              type: kUnitTypeBuilder,
              ownerId: 'gp_human',
              locationProvinceId: 'oldWorld|p1',
              tileKey: 'oldWorld|p1|0|0',
              status: UnitStatus.working,
              assignedTileKey: 'oldWorld|p1|0|0',
            ),
            Unit(
              id: 'u_spy',
              type: kUnitTypeSpy,
              ownerId: 'gp_human',
              locationProvinceId: 'oldWorld|p1',
              tileKey: 'oldWorld|p1|0|0',
              status: UnitStatus.idle,
            ),
            Unit(
              id: 'u_engineer',
              type: kUnitTypeEngineer,
              ownerId: 'gp_human',
              locationProvinceId: 'oldWorld|p2',
              tileKey: 'oldWorld|p2|1|0',
              status: UnitStatus.idle,
            ),
            // Non-human civilian is excluded.
            Unit(
              id: 'u_ai_builder',
              type: kUnitTypeBuilder,
              ownerId: 'gp_ai',
              locationProvinceId: 'oldWorld|p3',
              tileKey: 'oldWorld|p3|2|0',
              status: UnitStatus.idle,
            ),
            // Human military is excluded.
            Unit(
              id: 'u_human_military',
              type: 'pikemen',
              ownerId: 'gp_human',
              locationProvinceId: 'oldWorld|p1',
              status: UnitStatus.idle,
            ),
            // Human civilian in other region is excluded from OW marker set.
            Unit(
              id: 'u_other_region',
              type: kUnitTypeMerchant,
              ownerId: 'gp_human',
              locationProvinceId: 'newWorld|p1',
              tileKey: 'newWorld|p1|0|0',
              status: UnitStatus.idle,
            ),
          ],
          newWorldProvinces: const [
            Province(id: 'newWorld|p1', regionId: 'newWorld'),
          ],
          players: const [
            Player(id: 'gp_human', displayName: 'Human', isHuman: true),
            Player(id: 'gp_ai', displayName: 'AI', isHuman: false),
          ],
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        final markers = viewData.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(2));

        final tile00 = markers.singleWhere(
          (m) => m.tileKey == 'oldWorld|p1|0|0',
        );
        expect(tile00.stackCount, 2);
        expect(tile00.representativeUnitType, kUnitTypeBuilder);
        expect(tile00.representativeIsAssigned, isTrue);
        expect(tile00.unitIds, equals(['u_builder', 'u_spy']));
        expect(tile00.unitTypes['u_builder'], kUnitTypeBuilder);
        expect(tile00.unitTypes['u_spy'], kUnitTypeSpy);

        final tile10 = markers.singleWhere(
          (m) => m.tileKey == 'oldWorld|p2|1|0',
        );
        expect(tile10.stackCount, 1);
        expect(tile10.representativeUnitType, kUnitTypeEngineer);
        expect(tile10.representativeIsAssigned, isFalse);
        expect(tile10.unitIds, equals(['u_engineer']));
      },
    );

    test(
      'capital marker and stacked civilian marker can co-exist on same tile key',
      () {
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
          id: 'capital_civilian_overlap',
          oldWorldProvinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          ],
          oldWorldUnits: [
            Unit(
              id: 'u_builder',
              type: kUnitTypeBuilder,
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|p1',
              tileKey: 'oldWorld|p1|0|0',
            ),
            Unit(
              id: 'u_explorer',
              type: kUnitTypeExplorer,
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|p1',
              tileKey: 'oldWorld|p1|0|0',
            ),
          ],
          newWorldProvinces: const [
            Province(id: 'newWorld|p1', regionId: 'newWorld'),
          ],
          players: const [
            Player(
              id: 'gp1',
              displayName: 'Human',
              isHuman: true,
              capitalProvinceId: 'oldWorld|p1',
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: 'oldWorld|p1',
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        expect(viewData.oldWorld.capitalMarkers, hasLength(1));
        final cap = viewData.oldWorld.capitalMarkers.single;
        expect(cap.x, 0);
        expect(cap.y, 0);

        expect(viewData.oldWorld.civilianTileMarkers, hasLength(1));
        final marker = viewData.oldWorld.civilianTileMarkers.single;
        expect(marker.tileKey, 'oldWorld|p1|0|0');
        expect(marker.stackCount, 2);
      },
    );
  });

// Regression coverage for SPEC/ui/observe-mode.md § Map civilian markers
  // (Refs #2685): the base map view filter must not depend on Player.isHuman
  // when an explicit civilianMarkerOwnerIds set is provided.
  group('buildInitGameMapViewData civilianMarkerOwnerIds', () {
    Game twoGpGame({required bool gp1Human, required bool gp2Human}) {
      return minimalGame(
        id: 'civilian_owner_ids',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
          Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
        ],
        oldWorldUnits: [
          Unit(
            id: 'gp1_builder',
            type: kUnitTypeBuilder,
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
            tileKey: 'oldWorld|p1|0|0',
            status: UnitStatus.idle,
          ),
          Unit(
            id: 'gp2_explorer',
            type: kUnitTypeExplorer,
            ownerId: 'gp2',
            locationProvinceId: 'oldWorld|p2',
            tileKey: 'oldWorld|p2|1|0',
            status: UnitStatus.idle,
          ),
        ],
        newWorldProvinces: const [
          Province(id: 'newWorld|p1', regionId: 'newWorld'),
        ],
        players: [
          Player(id: 'gp1', displayName: 'GP1', isHuman: gp1Human),
          Player(id: 'gp2', displayName: 'GP2', isHuman: gp2Human),
        ],
      );
    }

    InitGameMapViewData renderView({
      required Game game,
      required Set<String>? civilianMarkerOwnerIds,
    }) {
      final owMap = mapTileGrid(const [
        ['p1', 'p2'],
      ]);
      final nwMap = mapTileGrid(const [
        ['p1'],
      ]);
      final owTopology = regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['p1', 'p2'],
      );
      final nwTopology = regionTopology(
        regionId: 'newWorld',
        provinceIds: const ['p1'],
      );
      return buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
        civilianMarkerOwnerIds: civilianMarkerOwnerIds,
      );
    }

    test(
      'global observe owner set: every GP civilian gets a marker even when '
      'isHuman is false on every player (Refs #2685 AC global)',
      () {
        // Mirrors observe handoff: all players have isHuman=false.
        final game = twoGpGame(gp1Human: false, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: {'gp1', 'gp2'},
        );

        final markers = view.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(2));
        expect(
          markers.map((m) => m.tileKey).toList()..sort(),
          equals(['oldWorld|p1|0|0', 'oldWorld|p2|1|0']),
        );
      },
    );

    test(
      'player observe owner set: only the observed GP civilian gets a marker '
      '(Refs #2685 AC player)',
      () {
        final game = twoGpGame(gp1Human: false, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: {'gp2'},
        );

        final markers = view.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(1));
        expect(markers.single.tileKey, 'oldWorld|p2|1|0');
        expect(markers.single.unitIds, equals(['gp2_explorer']));
      },
    );

    test(
      'civilianMarkerOwnerIds null falls back to Player.isHuman (legacy '
      'single-player; observe-off no regression — Refs #2685 AC off)',
      () {
        final game = twoGpGame(gp1Human: true, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: null,
        );

        final markers = view.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(1));
        expect(markers.single.tileKey, 'oldWorld|p1|0|0');
        expect(markers.single.unitIds, equals(['gp1_builder']));
      },
    );

    test(
      'civilianMarkerOwnerIds null after observe handoff (no human) yields '
      'no markers — proves the legacy fallback is the documented bug '
      'callers must avoid (Refs #2685 root cause)',
      () {
        final game = twoGpGame(gp1Human: false, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: null,
        );

        expect(view.oldWorld.civilianTileMarkers, isEmpty);
      },
    );

    test(
      'civilianMarkerOwnerIds excludes non-civilian and other-owner units '
      '(negative coverage)',
      () {
        final game = twoGpGame(gp1Human: false, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: {'gp1'},
        );

        final markers = view.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(1));
        expect(markers.single.tileKey, 'oldWorld|p1|0|0');
        expect(
          markers.single.unitIds,
          isNot(contains('gp2_explorer')),
          reason: 'gp2 owner is excluded from the owner set',
        );
      },
    );
  });

group('buildInitGameMapViewData port/town co-location', () {
    test(
      'town markers: co-located port and town shifts port drawable to N sea cell',
      () {
        final owMap = mapTileGrid([
          ['p1', 's1'],
          ['p1', 'p1'],
        ]);
        final nwMap = mapTileGrid([
          ['p1'],
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
        );
        final game = minimalGame(
          id: 'townPortColoc',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              townTileKey: 'oldWorld|p1|1|1',
            ),
          ],
          portsByProvinceSeaboard: const {
            'oldWorld|p1|seaboard': 'oldWorld|p1|1|1',
          },
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.isPort, isTrue);
        expect(tm.x, 1);
        expect(tm.y, 1);
        expect(tm.portIconX, 1);
        expect(tm.portIconY, 0);
      },
    );
    test(
      'town markers: isPort from seaboard key when value province segment mismatches',
      () {
        final owMap = mapTileGrid([
          ['p2', 'p2', 'p2'],
          ['p2', 'p2', 's1'],
        ]);
        final nwMap = mapTileGrid([
          ['p1'],
        ]);
        final owTopology = regionTopology(
          regionId: 'oldWorld',
          provinceIds: const ['p2'],
          seaZoneIds: const ['s1'],
          edges: const [TopologyEdge(id1: 'p2', id2: 's1')],
        );
        final nwTopology = regionTopology(
          regionId: 'newWorld',
          provinceIds: const ['p1'],
        );
        final game = minimalGame(
          id: 'nonCapitalPortKey',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              townTileKey: 'oldWorld|p2|0|0',
            ),
          ],
          portsByProvinceSeaboard: const {
            'oldWorld|p2|sb': 'oldWorld|p1|2|0',
          },
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.provinceId, 'p2');
        expect(tm.isPort, isTrue);
        expect(tm.portIconX, 2);
        expect(tm.portIconY, 1);
        expect(viewData.oldWorld.portMarkers.single.provinceId, 'p2');
      },
    );
  });

group('buildInitGameMapViewData', () {
    test(
      'civilian markers include explicit owner ids when isHuman is false',
      () {
        final owMap = mapTileGrid([
          ['p1', 'p2', 'p3'],
        ]);
        final nwMap = mapTileGrid([
          ['p1'],
        ]);
        final owTopology = regionTopology(
          regionId: 'oldWorld',
          provinceIds: const ['p1', 'p2', 'p3'],
        );
        final nwTopology = regionTopology(
          regionId: 'newWorld',
          provinceIds: const ['p1'],
        );
        final game = minimalGame(
          id: 'observe_civilian_markers',
          oldWorldProvinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
            Province(id: 'oldWorld|p3', regionId: 'oldWorld'),
          ],
          oldWorldUnits: [
            Unit(
              id: 'u_gp1',
              type: kUnitTypeBuilder,
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|p1',
              tileKey: 'oldWorld|p1|0|0',
              status: UnitStatus.idle,
            ),
            Unit(
              id: 'u_gp2',
              type: kUnitTypeExplorer,
              ownerId: 'gp2',
              locationProvinceId: 'oldWorld|p3',
              tileKey: 'oldWorld|p3|2|0',
              status: UnitStatus.idle,
            ),
          ],
          newWorldProvinces: const [
            Province(id: 'newWorld|p1', regionId: 'newWorld'),
          ],
          players: const [
            Player(id: 'gp1', displayName: 'Spain', isHuman: false),
            Player(id: 'gp2', displayName: 'France', isHuman: false),
          ],
        );

        final defaultView = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );
        expect(defaultView.oldWorld.civilianTileMarkers, isEmpty);

        final observeView = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
          civilianMarkerOwnerIds: {'gp1', 'gp2'},
        );
        expect(observeView.oldWorld.civilianTileMarkers, hasLength(2));
      },
    );
  });
}
