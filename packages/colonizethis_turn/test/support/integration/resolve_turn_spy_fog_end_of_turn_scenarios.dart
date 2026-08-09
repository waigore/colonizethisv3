import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../turn_resolver_test_harness.dart';

void registerSpyFogEndOfTurnTests() {
  group('spy fog end-of-turn', () {
    group('spy fog end of turn', () {
      test(
        'endOfTurn fog decay does not apply when Explorer is in other-faction province',
        () {
          const ow = turnTestOldWorldRegionId;
          final tileKeyP2 = turnTestOwTileKey('P2');
          final game = adjacentOwP1P2Game(
            phase: TurnPhase.endOfTurn,
            turnNumber: 1,
            globalGameSeed: turnTestSpyFogGameSeed,
            units: [
              Unit(
                id: 'explorer1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$ow|P2',
              ),
            ],
            playerVisibilityByTile: {
              'p1': {tileKeyP2: VisibilityLevel.fullyVisible.name},
              'p2': {},
            },
            tileKeysByRegionAndProvince: {
              ow: {
                'P1': [turnTestOwTileKey('P1')],
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
            topology: twoAdjacentOldWorldProvinceTopology(),
            orders: const Orders(),
            startFromPhase: TurnPhase.endOfTurn,
          );
          expect(
            next.worldState.playerVisibilityByTile['p1']?[tileKeyP2],
            VisibilityLevel.fullyVisible.name,
          );
        },
      );

      test(
        'endOfTurn fog decay uses full province id: same local id in two regions',
        () {
          final tileKeyOwP1 = turnTestOwTileKey('P1');
          final tileKeyNwP1 = turnTestNwTileKey('P1');
          const ow = kRegionOldWorld;
          final game = turnTestSpyFogOwNwSameLocalIdGame(
            owUnits: [
              Unit(
                id: 'explorer1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
            ],
          );
          final next = resolveTurnComplete(
            game: game,
            topology: turnTestSpyFogOwNwSameLocalIdTopology(),
            orders: const Orders(),
            startFromPhase: TurnPhase.endOfTurn,
          );
          expect(
            next.worldState.playerVisibilityByTile['p1']?[tileKeyOwP1],
            VisibilityLevel.fullyVisible.name,
            reason: 'Explorer in oldWorld|P1 keeps that province visible',
          );
          expect(
            next.worldState.playerVisibilityByTile['p1']?[tileKeyNwP1],
            VisibilityLevel.fogged.name,
            reason:
                'No Explorer in newWorld|P1; must fog (full province id, not local)',
          );
        },
      );

      test(
        'endOfTurn fogs province immediately when no Explorer/Spy remains',
        () {
          const ow = turnTestOldWorldRegionId;
          final tileKeyP2 = turnTestOwTileKey('P2');
          final game = adjacentOwP1P2Game(
            phase: TurnPhase.endOfTurn,
            turnNumber: 1,
            globalGameSeed: turnTestSpyFogGameSeed,
            playerVisibilityByTile: {
              'p1': {tileKeyP2: 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: {
              ow: {
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
            topology: twoAdjacentOldWorldProvinceTopology(),
            orders: const Orders(),
            startFromPhase: TurnPhase.endOfTurn,
          );

          expect(
            next.worldState.playerVisibilityByTile['p1']?[tileKeyP2],
            VisibilityLevel.fogged.name,
          );
        },
      );

      test(
        'endOfTurn retains visibility while a Spy remains in the province',
        () {
          const ow = turnTestOldWorldRegionId;
          final tileKeyP2 = turnTestOwTileKey('P2');
          final game = adjacentOwP1P2Game(
            phase: TurnPhase.endOfTurn,
            turnNumber: 1,
            globalGameSeed: turnTestSpyFogGameSeed,
            units: [
              Unit(
                id: 'spy1',
                type: kUnitTypeSpy,
                ownerId: 'p1',
                locationProvinceId: '$ow|P2',
                tileKey: tileKeyP2,
              ),
            ],
            playerVisibilityByTile: {
              'p1': {tileKeyP2: 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: {
              ow: {
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
            topology: twoAdjacentOldWorldProvinceTopology(),
            orders: const Orders(),
            startFromPhase: TurnPhase.endOfTurn,
          );

          expect(
            next.worldState.playerVisibilityByTile['p1']?[tileKeyP2],
            VisibilityLevel.fullyVisible.name,
          );
        },
      );
    });
  });
}
