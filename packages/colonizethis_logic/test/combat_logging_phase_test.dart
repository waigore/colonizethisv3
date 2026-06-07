import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import 'combat_logging_test_support.dart';

void main() {
  group('land combat logging (resolveTurnForGame phase)', () {
    final getCapture = setupCombatLogCapture();

    test(
      'Combat phase logs conflict_detection and battle_start for moved-in attack',
      () {
        final capture = getCapture();
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
        final game = ensureMilitaryArmiesForGame(
          Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                  Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
                ],
                units: [
                  Unit(
                    id: 'u1',
                    type: 'grenadiers',
                    ownerId: 'p1',
                    locationProvinceId: '$ow|P1',
                    medals: 2,
                  ),
                  Unit(
                    id: 'u2',
                    type: 'peasant_levies',
                    ownerId: 'p2',
                    locationProvinceId: '$ow|P2',
                  ),
                ],
              ),
              newWorld: const RegionData(),
            ),
            players: [
              Player(id: 'p1', displayName: 'A', isHuman: true, militaryLevel: 3),
              Player(id: 'p2', displayName: 'B', isHuman: true, militaryLevel: 1),
            ],
          ),
        );

        final orders = Orders(
          armyMoveOrdersByPlayerId: {
            'p1': [
              ArmyMoveOrder(
                armyId: fieldArmyIdFor('p1', '$ow|P1'),
                destinationProvinceId: '$ow|P2',
              ),
            ],
          },
        );

        requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: orders,
            extractedByPlayerId: const {},
            defaultAssignments: const [],
          ),
        );

        final combat = capture.combat;
        expect(
          combat.any(
            (m) => m.contains('logic: combat conflict_detection start'),
          ),
          isTrue,
        );
        expect(
          combat.any(
            (m) =>
                m.contains('logic: combat conflict_detection end') &&
                m.contains('battleContexts=1'),
          ),
          isTrue,
        );
        expect(
          combat.any(
            (m) =>
                m.contains('logic: combat battle_start') &&
                m.contains('attackerSides=1') &&
                m.contains('attackerUnitsTotal=1') &&
                m.contains('mode=autoResolve'),
          ),
          isTrue,
        );
        expect(
          combat.any((m) => m.contains('combat: combat engagement')),
          isTrue,
        );
        expect(
          combat.any(
            (m) =>
                m.contains('combat: combat battle_apply') &&
                m.contains('mode=autoResolve'),
          ),
          isTrue,
        );
        expect(
          capture.events.any(
            (e) =>
                e.level == Level.info &&
                e.message.contains('logic: phase combat start'),
          ),
          isTrue,
        );
        expect(
          capture.events.any(
            (e) =>
                e.level == Level.info &&
                e.message.contains('logic: phase combat end'),
          ),
          isTrue,
        );
      },
    );

    test(
      'Quick Battle path logs battle_apply quickBattle not auto engagement',
      () {
        final capture = getCapture();
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
        final game = ensureMilitaryArmiesForGame(
          Game(
            id: 'g1',
            defaultCombatMode: CombatMode.quickBattle,
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                  Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
                ],
                units: [
                  Unit(
                    id: 'u1',
                    type: 'grenadiers',
                    ownerId: 'p1',
                    locationProvinceId: '$ow|P1',
                    medals: 2,
                  ),
                  Unit(
                    id: 'u2',
                    type: 'peasant_levies',
                    ownerId: 'p2',
                    locationProvinceId: '$ow|P2',
                  ),
                ],
              ),
              newWorld: const RegionData(),
            ),
            players: [
              Player(id: 'p1', displayName: 'A', isHuman: true, militaryLevel: 3),
              Player(id: 'p2', displayName: 'B', isHuman: true, militaryLevel: 1),
            ],
          ),
        );

        final orders = Orders(
          armyMoveOrdersByPlayerId: {
            'p1': [
              ArmyMoveOrder(
                armyId: fieldArmyIdFor('p1', '$ow|P1'),
                destinationProvinceId: '$ow|P2',
              ),
            ],
          },
        );

        requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: orders,
            extractedByPlayerId: const {},
            defaultAssignments: const [],
          ),
        );

        final combat = capture.combat;
        expect(
          combat.any(
            (m) =>
                m.contains('logic: combat battle_start') &&
                m.contains('mode=quickBattle'),
          ),
          isTrue,
        );
        expect(
          combat.any(
            (m) =>
                m.contains('logic: combat battle_apply') &&
                m.contains('mode=quickBattle') &&
                m.contains('winner='),
          ),
          isTrue,
        );
        expect(
          combat.any((m) => m.contains('combat: combat engagement')),
          isFalse,
        );
      },
    );

    test(
      'no land battles still logs conflict_detection end with battleContexts=0',
      () {
        final capture = getCapture();
        final topology = MapTopology(
          nodes: [
            const TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );

        const ow = 'oldWorld';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
              units: [
                Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                  medals: 2,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(id: 'p1', displayName: 'A', isHuman: true, militaryLevel: 3),
          ],
        );

        requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: const Orders(),
            extractedByPlayerId: const {},
            defaultAssignments: const [],
          ),
        );

        final combat = capture.combat;
        expect(
          combat.any(
            (m) =>
                m.contains('logic: combat conflict_detection end') &&
                m.contains('battleContexts=0'),
          ),
          isTrue,
        );
        expect(
          combat.any((m) => m.contains('logic: combat battle_start')),
          isFalse,
        );
      },
    );
  });
}
