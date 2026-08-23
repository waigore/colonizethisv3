// Remaining debug flip-province ACs split from the credits/flip host (Refs #4606 Slice D).
import 'package:colonizethis_app_debug/colonizethis_app_debug.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'app_event_handler_scope_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyDebugFlipProvinceOwnership id and persistence', () {
    test('rejects province with no current owner', () {
      final game = Game(
        id: 'g-flip-null-owner',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: 'oldWorld|P1',
                regionId: 'oldWorld',
                ownerId: null,
                displayName: 'New Bordeaux',
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'P1': ['oldWorld|P1|0|0'],
            },
          },
          playerVisibilityByTile: {
            'human_1': {'oldWorld|P1|0|0': 'fogged'},
          },
        ),
        players: const [scopeFlipHuman, scopeFlipAi],
      );

      final result = scopeApplyFlip(game, scopeFlipNameEvent());

      expect(result.game, isNull);
      expect(result.message, contains('no current owner'));
    });

    test('JSON round-trip preserves flip outcome (persistence parity)', () {
      final result = scopeApplyFlip(
        scopeFlipBaseGame(
          phase: TurnPhase.orders,
          ownerId: 'ai_1',
          humanVisibility: 'fogged',
        ),
        scopeFlipNameEvent(),
      );

      expect(result.game, isNotNull);
      final restored = Game.fromJson(result.game!.toJson());
      expect(restored.worldState.oldWorld.provinces.single.ownerId, 'human_1');
      expect(restored.worldState.oldWorld.units.single.ownerId, 'human_1');
    });

    test(
      'flip ambiguity error includes candidate ids and id retry guidance',
      () {
        final game = Game(
          id: 'g-flip-amb-ids',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|P2',
                  regionId: 'oldWorld',
                  ownerId: 'ai_1',
                  displayName: 'New Bordeaux',
                ),
                Province(
                  id: 'oldWorld|P1',
                  regionId: 'oldWorld',
                  ownerId: 'ai_1',
                  displayName: 'New Bordeaux',
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: const {
              'oldWorld': {
                'oldWorld|P1': ['oldWorld|P1|0|0'],
                'oldWorld|P2': ['oldWorld|P2|0|0'],
              },
            },
            playerVisibilityByTile: {
              'human_1': {
                'oldWorld|P1|0|0': 'fogged',
                'oldWorld|P2|0|0': 'fogged',
              },
            },
          ),
          players: const [scopeFlipHuman, scopeFlipAi],
        );
        final result = scopeApplyFlip(game, scopeFlipNameEvent());
        expect(result.game, isNull);
        expect(
          result.message,
          contains('Candidates: oldWorld|P1, oldWorld|P2'),
        );
        expect(result.message, contains('/flip_province <regionId|localId>'));
      },
    );

    test('flip resolves directly by full province id', () {
      final result = scopeApplyFlip(
        scopeFlipBaseGame(
          phase: TurnPhase.orders,
          ownerId: 'ai_1',
          humanVisibility: 'fogged',
        ),
        const FlipDebugProvinceOwnershipEvent(
          humanPlayerId: 'human_1',
          fullProvinceId: 'oldWorld|P1',
        ),
      );
      expect(result.game, isNotNull);
      expect(
        result.game!.worldState.oldWorld.provinces.single.ownerId,
        'human_1',
      );
    });
  });
}
