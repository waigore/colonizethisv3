import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../turn_resolver_test_harness.dart';

void registerSpyFogEndOfTurnVisibilityTests() {
  group('spy fog end-of-turn', () {
    group('spy fog end of turn visibility', () {
      test(
        'Spy leaving other-faction province fogs immediately at end-of-turn',
        () {
          const ow = turnTestOldWorldRegionId;
          final tileKeyP1 = turnTestOwTileKey('P1');
          final tileKeyP2 = turnTestOwTileKey('P2');

          final topology = twoAdjacentOldWorldProvinceTopology();

          final game = adjacentOwP1P2Game(
            globalGameSeed: turnTestSpyFogGameSeed,
            province1OwnerId: 'p2',
            province2OwnerId: 'p2',
            units: [
              Unit(
                id: 'spy1',
                type: kUnitTypeSpy,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: tileKeyP1,
              ),
            ],
            playerVisibilityByTile: {
              'p1': {tileKeyP1: 'fullyVisible', tileKeyP2: 'fogged'},
            },
            tileKeysByRegionAndProvince: {
              ow: {
                '$ow|P1': [tileKeyP1],
                '$ow|P2': [tileKeyP2],
              },
            },
            players: const [
              Player(id: 'p1', displayName: 'P1', isHuman: true),
              Player(id: 'p2', displayName: 'P2', isHuman: false),
            ],
          );

          final moveOrders = Orders(
            moveOrdersByPlayerId: {
              'p1': [
                MoveOrder(
                  unitId: 'spy1',
                  destinationTileKey: turnTestOwTileKey('P2'),
                ),
              ],
            },
          );

          final next = resolveTurnComplete(
            game: game,
            topology: topology,
            orders: moveOrders,
          );

          expect(next.worldState.spyRevealTurnsByPlayer['p1'], isNull);
          expect(
            next.worldState.playerVisibilityByTile['p1']?[tileKeyP1],
            VisibilityLevel.fogged.name,
          );
        },
      );

      test(
        'Spy leaving own province does not start fog decay timer and own tiles remain fully visible',
        () {
          const ow = turnTestOldWorldRegionId;
          final tileKeyP1 = turnTestOwTileKey('P1');
          final tileKeyP2 = turnTestOwTileKey('P2');

          final topology = twoAdjacentOldWorldProvinceTopology();

          final game = adjacentOwP1P2Game(
            globalGameSeed: turnTestSpyFogGameSeed,
            province1OwnerId: 'p1',
            province2OwnerId: 'p1',
            units: [
              Unit(
                id: 'spy1',
                type: kUnitTypeSpy,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: tileKeyP1,
              ),
            ],
            playerVisibilityByTile: {
              'p1': {tileKeyP1: 'fullyVisible', tileKeyP2: 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: {
              ow: {
                '$ow|P1': [tileKeyP1],
                '$ow|P2': [tileKeyP2],
              },
            },
            players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
          );

          final moveOrders = Orders(
            moveOrdersByPlayerId: {
              'p1': [
                MoveOrder(
                  unitId: 'spy1',
                  destinationTileKey: turnTestOwTileKey('P2'),
                ),
              ],
            },
          );

          final next = resolveTurnComplete(
            game: game,
            topology: topology,
            orders: moveOrders,
          );

          expect(next.worldState.spyRevealTurnsByPlayer['p1'], isNull);
          expect(
            next.worldState.playerVisibilityByTile['p1']?[tileKeyP1],
            VisibilityLevel.fullyVisible.name,
          );
        },
      );

      test(
        'Spy timers for own provinces do not affect visibility at end-of-turn',
        () {
          const ow = kRegionOldWorld;
          final tileKeyP1 = turnTestOwTileKey('P1');
          final base = turnTestOwSingleProvinceGame();

          final game = base.copyWith(
            globalGameSeed: turnTestSpyFogGameSeed,
            worldState: base.worldState.copyWith(
              turnState: const TurnState(
                phase: TurnPhase.endOfTurn,
                turnNumber: 1,
              ),
              playerVisibilityByTile: {
                'p1': {tileKeyP1: 'fullyVisible'},
              },
              tileKeysByRegionAndProvince: {
                ow: {
                  '$ow|P1': [tileKeyP1],
                },
              },
              spyRevealTurnsByPlayer: const {
                'p1': {'$ow|P1': 1},
              },
            ),
          );

          final next = resolveTurnComplete(
            game: game,
            topology: turnTestOwSingleProvinceTopology(),
            orders: const Orders(),
            startFromPhase: TurnPhase.endOfTurn,
          );

          expect(
            next.worldState.playerVisibilityByTile['p1']?[tileKeyP1],
            VisibilityLevel.fullyVisible.name,
          );
        },
      );

      test(
        'one spy leaving foreign province retains visibility while another remains',
        () {
          const ow = turnTestOldWorldRegionId;
          final tileKeyP1 = turnTestOwTileKey('P1');
          final tileKeyP2 = turnTestOwTileKey('P2');

          final topology = twoAdjacentOldWorldProvinceTopology();

          final game = adjacentOwP1P2Game(
            globalGameSeed: turnTestSpyFogGameSeed,
            province1OwnerId: 'p2',
            province2OwnerId: 'p2',
            units: [
              Unit(
                id: 'spy_a',
                type: kUnitTypeSpy,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: tileKeyP1,
              ),
              Unit(
                id: 'spy_b',
                type: kUnitTypeSpy,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: tileKeyP1,
              ),
            ],
            playerVisibilityByTile: {
              'p1': {tileKeyP1: 'fullyVisible', tileKeyP2: 'fogged'},
            },
            tileKeysByRegionAndProvince: {
              ow: {
                '$ow|P1': [tileKeyP1],
                '$ow|P2': [tileKeyP2],
              },
            },
            players: const [
              Player(id: 'p1', displayName: 'P1', isHuman: true),
              Player(id: 'p2', displayName: 'P2', isHuman: false),
            ],
          );

          final moveOrders = Orders(
            moveOrdersByPlayerId: {
              'p1': [
                MoveOrder(
                  unitId: 'spy_a',
                  destinationTileKey: turnTestOwTileKey('P2'),
                ),
              ],
            },
          );

          final next = resolveTurnComplete(
            game: game,
            topology: topology,
            orders: moveOrders,
          );

          expect(
            next.worldState.playerVisibilityByTile['p1']?[tileKeyP1],
            VisibilityLevel.fullyVisible.name,
          );
        },
      );
    });
  });
}
