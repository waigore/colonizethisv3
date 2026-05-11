import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveTurnForGame', () {
    test('runs extraction, consumption, production, and movement phases', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
      );

      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'Regiment',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0')],
        },
      );

      final extractedByPlayerId = {
        'p1': {'grain': 3},
      };

      final defaultAssignments = const <AssignedRecipe>[];

      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: orders,
          extractedByPlayerId: extractedByPlayerId,
          defaultAssignments: defaultAssignments,
        ),
      );

      // Turn number advanced.
      expect(next.worldState.turnState.turnNumber, 1);
      // Unit moved to P2.
      expect(
        next.worldState.oldWorld.units.single.locationProvinceId,
        'oldWorld|P2',
      );
      // Extraction applied to player stockpile.
      expect(next.players.single.stockpile.quantityOf('grain'), 3);
    });

    test('army move within own provinces across regions is instantaneous', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );

      const ow = 'oldWorld';
      const nw = 'newWorld';
      final game = ensureMilitaryArmiesForGame(
        Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
              units: [
                Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                ),
              ],
            ),
            newWorld: RegionData(
              provinces: [Province(id: '$nw|P2', regionId: nw, ownerId: 'p1')],
              units: [],
            ),
            playerVisibilityByTile: const {
              'p1': {
                'oldWorld|P1|0|0': 'fullyVisible',
                'newWorld|P2|0|0': 'fullyVisible',
              },
            },
          ),
          players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
        ),
      );

      final orders = Orders(
        armyMoveOrdersByPlayerId: {
          'p1': [
            ArmyMoveOrder(
              armyId: fieldArmyIdFor('p1', '$ow|P1'),
              destinationProvinceId: '$nw|P2',
            ),
          ],
        },
      );

      final next = requireTurnResolutionComplete(
        resolveTurnForGame(game: game, topology: topology, orders: orders),
      );

      // Turn number advanced.
      expect(next.worldState.turnState.turnNumber, 1);
      // Unit moved from Old World to New World in a single movement phase.
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.worldState.newWorld.units.single.id, 'u1');
      expect(
        next.worldState.newWorld.units.single.locationProvinceId,
        '$nw|P2',
      );
    });

    test(
      'civilian move within own provinces across regions is instantaneous and sets tileKey',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'P2',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );

        const ow = 'oldWorld';
        const nw = 'newWorld';
        const owProv = '$ow|P1';
        const nwProv = '$nw|P2';
        const nwTile = '$nw|P2|0|0';

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: owProv, regionId: ow, ownerId: 'p1')],
              units: [
                Unit(
                  id: 'c1',
                  type: kUnitTypeMerchant,
                  ownerId: 'p1',
                  locationProvinceId: owProv,
                  tileKey: '$ow|P1|0|0',
                ),
              ],
            ),
            newWorld: RegionData(
              provinces: [Province(id: nwProv, regionId: nw, ownerId: 'p1')],
              units: [],
            ),
            tileKeysByRegionAndProvince: {
              nw: {
                nwProv: [nwTile],
              },
            },
            playerVisibilityByTile: const {
              'p1': {
                'oldWorld|P1|0|0': 'fullyVisible',
                'newWorld|P2|0|0': 'fullyVisible',
              },
            },
          ),
          players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
        );

        final orders = Orders(
          moveOrdersByPlayerId: {
            'p1': [
              MoveOrder(unitId: 'c1', destinationTileKey: '$nwProv|0|0'),
            ],
          },
        );

        final next = requireTurnResolutionComplete(
          resolveTurnForGame(game: game, topology: topology, orders: orders),
        );

        expect(next.worldState.turnState.turnNumber, 1);
        expect(next.worldState.oldWorld.units, isEmpty);
        final moved = next.worldState.newWorld.units.single;
        expect(moved.id, 'c1');
        expect(moved.locationProvinceId, nwProv);
        expect(moved.tileKey, nwTile);
      },
    );

    test('riches to treasury phase converts riches in stockpile', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            treasury: 0,
            stockpile: Stockpile(quantities: {'gold': 2, 'grain': 1}),
          ),
        ],
      );
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: const Orders(),
        ),
      );
      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.players.single.treasury, greaterThan(0));
      expect(next.players.single.stockpile.quantityOf('gold'), lessThan(2));
    });

    test(
      'consumption and combat run with feeding coverage when player has no food',
      () {
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'P2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
        );
        final game = ensureMilitaryArmiesForGame(
          Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|P1', regionId: ow, ownerId: 'p2'),
                  Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
                ],
                units: [
                  Unit(
                    id: 'u1',
                    type: 'musketeers',
                    ownerId: 'p1',
                    locationProvinceId: '$ow|P2',
                  ),
                  Unit(
                    id: 'u2',
                    type: 'pikemen',
                    ownerId: 'p2',
                    locationProvinceId: '$ow|P1',
                  ),
                ],
              ),
              newWorld: const RegionData(),
            ),
            players: [
              Player(
                id: 'p1',
                displayName: 'P1',
                isHuman: true,
                stockpile: Stockpile.empty,
              ),
              Player(
                id: 'p2',
                displayName: 'P2',
                isHuman: true,
                stockpile: Stockpile(quantities: {'grain': 10, 'meat': 10}),
              ),
            ],
          ),
        );
        final orders = Orders(
          armyMoveOrdersByPlayerId: {
            'p1': [
              ArmyMoveOrder(
                armyId: fieldArmyIdFor('p1', '$ow|P2'),
                destinationProvinceId: '$ow|P1',
              ),
            ],
          },
        );
        final next = requireTurnResolutionComplete(
          resolveTurnForGame(game: game, topology: topology, orders: orders),
        );
        expect(next.worldState.turnState.turnNumber, 1);
        expect(next.worldState.oldWorld.units.length, lessThanOrEqualTo(2));
      },
    );
  });
}
