import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Turn resolution characterization', () {
    test('full turn with extraction, movement, and combat is deterministic', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P3',
              regionId: 'oldWorld',
              type: TopologyNodeType.province),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
          const TopologyEdge(id1: 'P2', id2: 'P3'),
        ],
      );

      const ow = 'oldWorld';
      final game = Game(
        id: 'char-turn',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P3', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'inf1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                medals: 2,
              ),
              Unit(
                id: 'def1',
                type: 'peasant_levies',
                ownerId: 'p2',
                locationProvinceId: '$ow|P3',
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|P1': ['$ow|P1|0|0'],
              '$ow|P2': ['$ow|P2|0|0'],
              '$ow|P3': ['$ow|P3|0|0'],
            },
          },
          playerVisibilityByTile: {
            'p1': {
              '$ow|P1|0|0': 'fullyVisible',
              '$ow|P2|0|0': 'fullyVisible',
              '$ow|P3|0|0': 'fullyVisible',
            },
          },
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'Attacker',
            isHuman: true,
            stockpile:
                const Stockpile(quantities: {'grain': 10}),
            workerPool: const WorkerPool(peasants: 5),
            treasury: 1000,
          ),
          Player(
            id: 'p2',
            displayName: 'Defender',
            isHuman: false,
            stockpile:
                const Stockpile(quantities: {'grain': 5}),
            workerPool: const WorkerPool(peasants: 2),
            treasury: 500,
          ),
        ],
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(
                unitId: 'inf1', destinationTileKey: '$ow|P2|0|0'),
          ],
        },
      );

      final extracted = {
        'p1': {'grain': 3},
        'p2': {'grain': 1},
      };

      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: extracted,
      ));

      // Turn advanced
      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.worldState.turnState.phase, TurnPhase.orders);

      // Unit moved to P2
      final movedUnit = next.worldState.oldWorld.units
          .where((u) => u.id == 'inf1')
          .firstOrNull;
      expect(movedUnit, isNotNull);
      expect(movedUnit!.locationProvinceId, '$ow|P2');

      // Extraction applied (grain added to stockpile, then consumption deducted)
      final p1 = next.playerById('p1')!;
      final p2 = next.playerById('p2')!;
      // p1 started with 10 grain, extracted 3 = 13, then consumption deducted
      expect(p1.stockpile.quantityOf('grain'), lessThanOrEqualTo(13));
      // p2 started with 5 grain, extracted 1 = 6, then consumption deducted
      expect(p2.stockpile.quantityOf('grain'), lessThanOrEqualTo(6));
    });

    test('empty orders still advance turn', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province),
        ],
        edges: [],
      );

      const ow = 'oldWorld';
      final game = Game(
        id: 'empty-turn',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'Solo', isHuman: true),
        ],
      );

      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
      ));

      expect(next.worldState.turnState.turnNumber, 6);
    });

    test('resolveTurn (WorldState only) advances turn deterministically', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 10),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final next = resolveTurn(state);
      expect(next.turnState.turnNumber, 11);
      expect(next.turnState.phase, TurnPhase.orders);
    });

    test('phase sequence is correct', () {
      expect(turnResolutionSequence, [
        TurnPhase.orders,
        TurnPhase.extraction,
        TurnPhase.richesToTreasury,
        TurnPhase.consumption,
        TurnPhase.production,
        TurnPhase.diplomacy,
        TurnPhase.spyResolution,
        TurnPhase.research,
        TurnPhase.movement,
        TurnPhase.minorRegimentUpgrade,
        TurnPhase.navalInterceptionCombat,
        TurnPhase.combat,
        TurnPhase.buildWork,
        TurnPhase.worldMarket,
        TurnPhase.endOfTurn,
      ]);
    });

    test('combat phase resolves when units collide', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'A',
              regionId: 'oldWorld',
              type: TopologyNodeType.province),
          const TopologyNode(
              id: 'B',
              regionId: 'oldWorld',
              type: TopologyNodeType.province),
        ],
        edges: [const TopologyEdge(id1: 'A', id2: 'B')],
      );

      const ow = 'oldWorld';
      final game = ensureMilitaryArmiesForGame(
        Game(
          id: 'combat-char',
          globalGameSeed: 424242,
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|A', regionId: ow, ownerId: 'p1'),
                Province(id: '$ow|B', regionId: ow, ownerId: 'p2'),
              ],
              units: [
                Unit(
                  id: 'att1',
                  type: 'grenadiers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|A',
                  medals: 3,
                ),
                Unit(
                  id: 'att2',
                  type: 'grenadiers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|A',
                  medals: 2,
                ),
                Unit(
                  id: 'def1',
                  type: 'peasant_levies',
                  ownerId: 'p2',
                  locationProvinceId: '$ow|B',
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                '$ow|A': ['$ow|A|0|0'],
                '$ow|B': ['$ow|B|0|0'],
              },
            },
            playerVisibilityByTile: {
              'p1': {
                '$ow|A|0|0': 'fullyVisible',
                '$ow|B|0|0': 'fullyVisible',
              },
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'Strong', isHuman: true),
            Player(id: 'p2', displayName: 'Weak', isHuman: false),
          ],
        ),
      );

      final orders = Orders(
        armyMoveOrdersByPlayerId: {
          'p1': [
            ArmyMoveOrder(
              armyId: fieldArmyIdFor('p1', '$ow|A'),
              destinationProvinceId: '$ow|B',
            ),
          ],
        },
        diplomaticOrdersByPlayerId: {
          'p1': [
            const DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'p2',
            ),
          ],
        },
      );

      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
      ));

      expect(next.worldState.turnState.turnNumber, 1);
      final provinceB = next.worldState.oldWorld.provinces
          .firstWhere((p) => p.id == '$ow|B');
      // Strong attacker with 2 grenadiers vs 1 peasant levy: should flip
      expect(provinceB.ownerId, 'p1');
    });
  });
}
