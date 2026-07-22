import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../turn_resolver_test_harness.dart';

void registerDiplomacyVictoryOverturesTests() {
  group('diplomacy victory', () {
    group('diplomacy victory overtures', () {
      test(
        'endOfTurn sets military victory when one GP controls enough OW provinces',
        () {
          for (final scenario in <({int count, int turnNumber})>[
            (count: 32, turnNumber: 5),
            (count: 31, turnNumber: 3),
          ]) {
            final fixture = turnTestOwProvinceStacksFixture(
              stacks: [
                (ownerId: 'p1', count: scenario.count, localIdPrefix: 'P'),
              ],
              turnNumber: scenario.turnNumber,
            );
            final next = resolveTurnComplete(
              game: fixture.game,
              topology: fixture.topology,
              orders: const Orders(),
            );
            expect(
              next.victory,
              isNotNull,
              reason: 'count=${scenario.count}',
            );
            expect(next.victory!.winnerPlayerId, 'p1');
            expect(next.victory!.type, VictoryType.military);
          }
        },
      );

      test(
        'endOfTurn tie-break: two GPs with ≥31 OW provinces wins lexicographically smallest id',
        () {
          final fixture = turnTestOwProvinceStacksFixture(
            stacks: [
              (ownerId: 'p1', count: 31, localIdPrefix: 'A'),
              (ownerId: 'p2', count: 31, localIdPrefix: 'B'),
            ],
            turnNumber: 1,
            players: const [
              Player(id: 'p1', displayName: 'P1', isHuman: true),
              Player(id: 'p2', displayName: 'P2', isHuman: true),
            ],
          );
          final next = resolveTurnComplete(
            game: fixture.game,
            topology: fixture.topology,
            orders: const Orders(),
          );
          expect(next.victory, isNotNull);
          expect(next.victory!.winnerPlayerId, 'p1');
        },
      );

      test(
        'endOfTurn no victory when only Minor/Tribe has ≥31 OW provinces',
        () {
          final fixture = turnTestOwProvinceStacksFixture(
            stacks: [
              (ownerId: 'minor1', count: 31, localIdPrefix: 'P'),
            ],
            turnNumber: 2,
            players: const [
              Player(id: 'p1', displayName: 'GP1', isHuman: true),
              Player(id: 'p2', displayName: 'GP2', isHuman: true),
            ],
          );
          final next = resolveTurnComplete(
            game: fixture.game,
            topology: fixture.topology,
            orders: const Orders(),
          );
          expect(next.victory, isNull);
        },
      );

      test('endOfTurn no victory when no GP has ≥31 OW provinces', () {
        final fixture = turnTestOwProvinceStacksFixture(
          stacks: [
            (ownerId: 'p1', count: 30, localIdPrefix: 'A'),
            (ownerId: 'p2', count: 30, localIdPrefix: 'B'),
          ],
          turnNumber: 1,
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: true),
          ],
        );
        final next = resolveTurnComplete(
          game: fixture.game,
          topology: fixture.topology,
          orders: const Orders(),
        );
        expect(next.victory, isNull);
      });

      test(
        'endOfTurn phase leaves game unchanged when victory already set',
        () {
          const ow = 'oldWorld';
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 10,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                ],
              ),
              newWorld: const RegionData(),
            ),
            players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
            victory: VictoryState(
              winnerPlayerId: 'p1',
              type: VictoryType.military,
              turnNumber: 10,
            ),
          );
          final next = resolveTurnComplete(
            game: game,
            topology: MapTopology(
              nodes: const [
                TopologyNode(
                  id: 'P1',
                  regionId: 'oldWorld',
                  type: TopologyNodeType.province,
                ),
              ],
              edges: const [],
            ),
            orders: const Orders(),
          );
          expect(next.victory, isNotNull);
          expect(next.victory!.winnerPlayerId, 'p1');
          expect(next.worldState.turnState.turnNumber, 10);
        },
      );

      test(
        'endOfTurn applies fog decay: other-faction tiles become fogged when no Explorer/Spy',
        () {
          const ow = turnTestOldWorldRegionId;
          const tileKeyP2 = 'oldWorld|P2|0|0';
          final game = adjacentOwP1P2Game(
            phase: TurnPhase.endOfTurn,
            turnNumber: 1,
            playerVisibilityByTile: {
              'p1': {tileKeyP2: VisibilityLevel.fullyVisible.name},
              'p2': {},
            },
            tileKeysByRegionAndProvince: {
              ow: {
                'P1': ['oldWorld|P1|0|0'],
                'P2': [tileKeyP2],
              },
            },
            players: const [
              Player(id: 'p1', displayName: 'P1', isHuman: true),
              Player(id: 'p2', displayName: 'P2', isHuman: false),
            ],
          );
          final next = resolveTurnComplete(
            game: game,
            topology: MapTopology(
              nodes: const [
                TopologyNode(
                  id: 'P1',
                  regionId: turnTestOldWorldRegionId,
                  type: TopologyNodeType.province,
                ),
                TopologyNode(
                  id: 'P2',
                  regionId: turnTestOldWorldRegionId,
                  type: TopologyNodeType.province,
                ),
              ],
              edges: const [],
            ),
            orders: const Orders(),
          );
          expect(
            next.worldState.playerVisibilityByTile['p1']?[tileKeyP2],
            VisibilityLevel.fogged.name,
          );
        },
      );
    });
  });
}
