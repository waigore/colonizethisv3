import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('buildInitGameMapViewData', () {
    test('returns InitGameMapViewData with oldWorld and newWorld regions', () {
      final owMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 's1'],
          ['s1', 's1'],
        ],
      );
      final nwMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 's1'],
          ['s1', 's1'],
        ],
      );
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
      );
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
      );
      final game = Game(
        id: 'test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'OW P1',
                ownerId: 'gp1',
              ),
            ],
            units: const [],
          ),
          newWorld: RegionData(
            provinces: const [
              Province(
                id: 'newWorld|p1',
                regionId: 'newWorld',
                displayName: 'NW P1',
              ),
            ],
            units: const [],
          ),
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
        minorNations: const [],
        tribes: const [],
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
      final owMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 's1'],
          ['s1', 's1'],
        ],
      );
      final nwMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 's1'],
          ['s1', 's1'],
        ],
      );
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
      );
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
      );
      final game = Game(
        id: 'test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          seaZoneDisplayNameById: const {
            'oldWorld|s1': 'Adriatic Sea',
            'newWorld|s1': 'Caribbean Sea',
          },
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'OW P1',
                ownerId: 'gp1',
              ),
            ],
            units: const [],
          ),
          newWorld: RegionData(
            provinces: const [
              Province(
                id: 'newWorld|p1',
                regionId: 'newWorld',
                displayName: 'NW P1',
              ),
            ],
            units: const [],
          ),
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
        minorNations: const [],
        tribes: const [],
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
      final owMap = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['p1'],
        ],
      );
      final nwMap = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['p1'],
        ],
      );
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: const [],
          ),
          newWorld: RegionData(
            provinces: const [
              Province(id: 'newWorld|p1', regionId: 'newWorld'),
            ],
            units: const [],
          ),
        ),
        players: const [Player(id: 'gp1', displayName: 'GP', isHuman: false)],
        minorNations: const [],
        tribes: const [],
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

    test('uses full province ids for ownership and unit markers', () {
      final owMap = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['p1', 'p2'],
        ],
      );
      final nwMap = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['p1'],
        ],
      );
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );

      final game = Game(
        id: 'fullIds',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'Army',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p1',
                status: UnitStatus.idle,
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: const [
              Province(id: 'newWorld|p1', regionId: 'newWorld', ownerId: 'gp3'),
            ],
            units: const [],
          ),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          Player(id: 'gp3', displayName: 'GP3', isHuman: false),
        ],
        minorNations: const [],
        tribes: const [],
      );

      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
      );

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
        final owMap = TileMapResult(
          width: 2,
          height: 2,
          grid: [
            ['p1', 's1'],
            ['s1', 's1'],
          ],
        );
        final nwMap = TileMapResult(
          width: 2,
          height: 2,
          grid: [
            ['p1', 's1'],
            ['s1', 's1'],
          ],
        );
        final owTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 's1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
        );
        final nwTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 's1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
        );
        final game = Game(
          id: 'capitals',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'OW',
                ),
              ],
              units: const [],
            ),
            newWorld: RegionData(
              provinces: const [
                Province(
                  id: 'newWorld|p1',
                  regionId: 'newWorld',
                  displayName: 'NW',
                ),
              ],
              units: const [],
            ),
          ),
          players: const [],
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
      final owMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 's1'],
          ['s1', 's1'],
        ],
      );
      final nwMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 's1'],
          ['s1', 's1'],
        ],
      );
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
      );
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
      );
      final game = Game(
        id: 'ports',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
            ],
            units: const [],
          ),
          newWorld: RegionData(
            provinces: const [
              Province(id: 'newWorld|p1', regionId: 'newWorld'),
            ],
            units: const [],
          ),
          portsByProvinceSeaboard: {'oldWorld|p1|seaboard': 'oldWorld|p1|0|1'},
        ),
        players: const [],
        minorNations: const [],
        tribes: const [],
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

    test(
      'town markers: isPort with prefixed Province.id; port icon on port tile when separate from town',
      () {
        final owMap = TileMapResult(
          width: 3,
          height: 2,
          grid: [
            ['p1', 'p1', 'p1'],
            ['p1', 'p1', 's1'],
          ],
        );
        final nwMap = TileMapResult(
          width: 1,
          height: 1,
          grid: [
            ['p1'],
          ],
        );
        final owTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 's1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
        );
        final nwTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'townPortSep',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  townTileKey: 'oldWorld|p1|0|0',
                ),
              ],
              units: const [],
            ),
            newWorld: const RegionData(provinces: [], units: []),
            portsByProvinceSeaboard: {
              'oldWorld|p1|seaboard': 'oldWorld|p1|2|0',
            },
          ),
          players: const [],
          minorNations: const [],
          tribes: const [],
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
      final owMap = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['pPlayer', 'pMinor'],
        ],
      );
      final nwMap = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['p1'],
        ],
      );
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'pPlayer',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'pMinor',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'pPlayer', id2: 'pMinor')],
      );
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'town_non_player',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
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
            units: [],
          ),
          newWorld: const RegionData(provinces: [], units: []),
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
        tribes: const [],
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
        final owMap = TileMapResult(
          width: 2,
          height: 1,
          grid: [
            ['p1', 'p2'],
          ],
        );
        final nwMap = TileMapResult(
          width: 1,
          height: 1,
          grid: [
            ['p1'],
          ],
        );
        final owTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final nwTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'towns_non_player',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
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
              units: const [],
            ),
            newWorld: const RegionData(provinces: [], units: []),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'Player GP', isHuman: true),
          ],
          minorNations: const [
            MinorNation(id: 'ai_minor', displayName: 'AI Minor Nation'),
          ],
          tribes: const [],
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
        final owMap = TileMapResult(
          width: 2,
          height: 2,
          grid: [
            ['p1', 's1'],
            ['p1', 'p1'],
          ],
        );
        final nwMap = TileMapResult(
          width: 1,
          height: 1,
          grid: [
            ['p1'],
          ],
        );
        final owTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 's1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
        );
        final nwTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'townPortCap',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                  townTileKey: 'oldWorld|p1|1|1',
                ),
              ],
              units: const [],
            ),
            newWorld: const RegionData(provinces: [], units: []),
            portsByProvinceSeaboard: {'oldWorld|p1|sb': 'oldWorld|p1|0|0'},
          ),
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
          minorNations: const [],
          tribes: const [],
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
        final owMap = TileMapResult(
          width: 2,
          height: 2,
          grid: [
            ['p1', 'p1'],
            ['p1', 'p1'],
          ],
        );
        final nwMap = TileMapResult(
          width: 1,
          height: 1,
          grid: [
            ['p1'],
          ],
        );
        final owTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 's1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
        );
        final nwTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'townPortFall',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  townTileKey: 'oldWorld|p1|1|1',
                ),
              ],
              units: const [],
            ),
            newWorld: const RegionData(provinces: [], units: []),
            portsByProvinceSeaboard: {'oldWorld|p1|sb': 'oldWorld|p1|1|1'},
          ),
          players: const [],
          minorNations: const [],
          tribes: const [],
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
}
