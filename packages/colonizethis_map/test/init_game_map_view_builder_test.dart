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
        expect(tm.portIconY, 0);
      },
    );

    test(
      'town markers: co-located port and town shifts port drawable to N sea cell',
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
          id: 'townPortColoc',
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
            portsByProvinceSeaboard: {
              'oldWorld|p1|seaboard': 'oldWorld|p1|1|1',
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
        expect(tm.isPort, isTrue);
        expect(tm.x, 1);
        expect(tm.y, 1);
        expect(tm.portIconX, 1);
        expect(tm.portIconY, 0);
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
              capitalTile: const CapitalTile(
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
      'town markers: co-located with no orthogonal sea keeps port on port tile',
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

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.isPort, isTrue);
        expect(tm.portIconX, 1);
        expect(tm.portIconY, 1);
      },
    );

    test('applies visibilityByTile map to CellViewData.visibility', () {
      final owMap = TileMapResult(
        width: 2,
        height: 1,
        grid: [
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
        id: 'visibility',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(
            provinces: [
              Province(id: 'newWorld|p1', regionId: 'newWorld', ownerId: 'gp2'),
            ],
            units: [],
          ),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
        minorNations: const [],
        tribes: const [],
      );

      // Two tiles in OW: (0,0) and (1,0). One tile in NW: (0,0).
      final visibilityByTile = <String, TileVisibility>{
        'oldWorld|p1|0|0': TileVisibility.visible,
        'oldWorld|p1|1|0': TileVisibility.fogged,
        'newWorld|p1|0|0': TileVisibility.unrevealed,
      };

      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
        visibilityByTile: visibilityByTile,
      );

      // Old World visibility mapping.
      final owCells = viewData.oldWorld.cells;
      final firstOwCell = owCells.singleWhere((c) => c.x == 0 && c.y == 0);
      final secondOwCell = owCells.singleWhere((c) => c.x == 1 && c.y == 0);
      expect(firstOwCell.visibility, TileVisibility.visible);
      expect(secondOwCell.visibility, TileVisibility.fogged);

      // New World visibility mapping.
      final nwCell = viewData.newWorld.cells.single;
      expect(nwCell.visibility, TileVisibility.unrevealed);
    });

    test(
      'province unit presence shows own province counts and hides other province without visible intel',
      () {
        final owMap = TileMapResult(
          width: 2,
          height: 1,
          grid: [
            ['pOwn', 'pOther'],
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
              id: 'pOwn',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'pOther',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'pOwn', id2: 'pOther')],
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
          id: 'presence_hidden_other',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|pOwn',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|pOther',
                  regionId: 'oldWorld',
                  ownerId: 'gp2',
                ),
              ],
              units: [
                Unit(
                  id: 'u_builder',
                  type: 'Builder',
                  ownerId: 'gp1',
                  locationProvinceId: 'oldWorld|pOwn',
                  status: UnitStatus.idle,
                ),
                Unit(
                  id: 'u_pikemen',
                  type: 'pikemen',
                  ownerId: 'gp2',
                  locationProvinceId: 'oldWorld|pOther',
                  status: UnitStatus.idle,
                ),
              ],
            ),
            newWorld: const RegionData(provinces: [], units: []),
            fleets: [
              Fleet(
                id: 'f_other',
                ownerId: 'gp2',
                regionId: 'oldWorld',
                inPortAtProvinceId: 'oldWorld|pOther',
                ships: [ShipInstance(id: 'ship_1', typeId: 'frigate')],
              ),
            ],
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          ],
          minorNations: const [],
          tribes: const [],
        );

        final visibilityByTile = <String, TileVisibility>{
          'oldWorld|pOwn|0|0': TileVisibility.visible,
          'oldWorld|pOther|1|0': TileVisibility.unrevealed,
        };

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
          visibilityByTile: visibilityByTile,
        );

        final own =
            viewData.oldWorld.provinceUnitPresenceByProvinceId['oldWorld|pOwn'];
        final other = viewData
            .oldWorld
            .provinceUnitPresenceByProvinceId['oldWorld|pOther'];
        expect(own, isNotNull);
        expect(other, isNotNull);

        expect(own!.intelVisible, isTrue);
        expect(own.civilianCount, 1);
        expect(own.regimentCount, 0);
        expect(own.shipCount, 0);

        expect(other!.intelVisible, isFalse);
        expect(other.civilianCount, 0);
        expect(other.regimentCount, 1);
        expect(other.shipCount, 1);
      },
    );

    test(
      'province unit presence exposes other province counts when tile is visible',
      () {
        final owMap = TileMapResult(
          width: 1,
          height: 1,
          grid: [
            ['pOther'],
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
              id: 'pOther',
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
          id: 'presence_visible_other',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|pOther',
                  regionId: 'oldWorld',
                  ownerId: 'gp2',
                ),
              ],
              units: [
                Unit(
                  id: 'u_builder_other',
                  type: 'Builder',
                  ownerId: 'gp2',
                  locationProvinceId: 'oldWorld|pOther',
                  status: UnitStatus.idle,
                ),
                Unit(
                  id: 'u_pikemen_other',
                  type: 'pikemen',
                  ownerId: 'gp2',
                  locationProvinceId: 'oldWorld|pOther',
                  status: UnitStatus.idle,
                ),
              ],
            ),
            newWorld: const RegionData(provinces: [], units: []),
            fleets: [
              Fleet(
                id: 'f_other_visible',
                ownerId: 'gp2',
                regionId: 'oldWorld',
                inPortAtProvinceId: 'oldWorld|pOther',
                ships: [ShipInstance(id: 'ship_7', typeId: 'frigate')],
              ),
            ],
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          ],
          minorNations: const [],
          tribes: const [],
        );

        final visibilityByTile = <String, TileVisibility>{
          'oldWorld|pOther|0|0': TileVisibility.visible,
        };

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
          visibilityByTile: visibilityByTile,
        );

        final other = viewData
            .oldWorld
            .provinceUnitPresenceByProvinceId['oldWorld|pOther'];
        expect(other, isNotNull);
        expect(other!.intelVisible, isTrue);
        expect(other.civilianCount, 1);
        expect(other.regimentCount, 1);
        expect(other.shipCount, 1);
      },
    );

    test(
      'builds deterministic player-owned civilian tile markers with priority and stack counts',
      () {
        final owMap = TileMapResult(
          width: 3,
          height: 1,
          grid: [
            ['p1', 'p2', 'p3'],
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
            TopologyNode(
              id: 'p3',
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
          id: 'civilian_markers',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
                Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
                Province(id: 'oldWorld|p3', regionId: 'oldWorld'),
              ],
              units: [
                // Same tile; representative should be Builder by priority.
                Unit(
                  id: 'u_builder',
                  type: 'Builder',
                  ownerId: 'gp_human',
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: 'oldWorld|p1|0|0',
                  status: UnitStatus.working,
                  assignedTileKey: 'oldWorld|p1|0|0',
                ),
                Unit(
                  id: 'u_spy',
                  type: 'Spy',
                  ownerId: 'gp_human',
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: 'oldWorld|p1|0|0',
                  status: UnitStatus.idle,
                ),
                Unit(
                  id: 'u_engineer',
                  type: 'Engineer',
                  ownerId: 'gp_human',
                  locationProvinceId: 'oldWorld|p2',
                  tileKey: 'oldWorld|p2|1|0',
                  status: UnitStatus.idle,
                ),
                // Non-human civilian is excluded.
                Unit(
                  id: 'u_ai_builder',
                  type: 'Builder',
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
                  type: 'Merchant',
                  ownerId: 'gp_human',
                  locationProvinceId: 'newWorld|p1',
                  tileKey: 'newWorld|p1|0|0',
                  status: UnitStatus.idle,
                ),
              ],
            ),
            newWorld: const RegionData(
              provinces: [Province(id: 'newWorld|p1', regionId: 'newWorld')],
              units: [],
            ),
          ),
          players: const [
            Player(id: 'gp_human', displayName: 'Human', isHuman: true),
            Player(id: 'gp_ai', displayName: 'AI', isHuman: false),
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

        final markers = viewData.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(2));

        final tile00 = markers.singleWhere(
          (m) => m.tileKey == 'oldWorld|p1|0|0',
        );
        expect(tile00.stackCount, 2);
        expect(tile00.representativeUnitType, 'Builder');
        expect(tile00.representativeIsAssigned, isTrue);
        expect(tile00.unitIds, equals(['u_builder', 'u_spy']));
        expect(tile00.unitTypes['u_builder'], 'Builder');
        expect(tile00.unitTypes['u_spy'], 'Spy');

        final tile10 = markers.singleWhere(
          (m) => m.tileKey == 'oldWorld|p2|1|0',
        );
        expect(tile10.stackCount, 1);
        expect(tile10.representativeUnitType, 'Engineer');
        expect(tile10.representativeIsAssigned, isFalse);
        expect(tile10.unitIds, equals(['u_engineer']));
      },
    );

    test('includes warp zone markers from warpLinks (bidirectional)', () {
      final owMap = TileMapResult(
        width: 3,
        height: 1,
        grid: [
          ['s1', 's2', 's3'],
        ],
      );
      final nwMap = TileMapResult(
        width: 3,
        height: 1,
        grid: [
          ['s1', 's2', 's3'],
        ],
      );
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 's2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 's3',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 's1',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 's2',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 's3',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'warp',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(provinces: [], units: []),
          newWorld: const RegionData(provinces: [], units: []),
        ),
        players: const [],
        minorNations: const [],
        tribes: const [],
      );

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
      final owMap = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['s1'],
        ],
      );
      final nwMap = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['s1'],
        ],
      );
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 's1',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'no-warp',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(provinces: [], units: []),
          newWorld: const RegionData(provinces: [], units: []),
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
        warpLinks: null,
      );

      expect(viewData.oldWorld.warpMarkers, isEmpty);
      expect(viewData.newWorld.warpMarkers, isEmpty);
    });
  });
}
