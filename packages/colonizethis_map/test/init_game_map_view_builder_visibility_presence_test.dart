import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('buildInitGameMapViewData visibility and unit presence', () {
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
                  type: kUnitTypeBuilder,
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
                  type: kUnitTypeBuilder,
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
  });
}
