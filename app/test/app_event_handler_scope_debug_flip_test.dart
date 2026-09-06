// applyDebugFlipProvince pins (Refs #4352, #4734 Slice J).
import 'package:colonizethis_app_debug/colonizethis_app_debug.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'app_event_handler_scope_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyDebugFlipProvinceOwnership', () {
    test('flips province through canonical transfer on valid command', () {
      final result = scopeApplyFlip(
        scopeFlipBaseGame(
          phase: TurnPhase.orders,
          ownerId: 'ai_1',
          humanVisibility: 'fogged',
        ),
        scopeFlipNameEvent(),
      );

      expect(result.game, isNotNull);
      expect(
        result.game!.worldState.oldWorld.provinces.single.ownerId,
        'human_1',
      );
      expect(result.game!.worldState.oldWorld.units.single.ownerId, 'human_1');
      expect(result.message, contains('Flipped province oldWorld|P1'));
      expect(result.message, contains('Regiments transferred: 1'));
    });

    test('rejects command outside human orders phase', () {
      final result = scopeApplyFlip(
        scopeFlipBaseGame(
          phase: TurnPhase.movement,
          ownerId: 'ai_1',
          humanVisibility: 'fogged',
        ),
        scopeFlipNameEvent(),
      );

      expect(result.game, isNull);
      expect(
        result.message,
        contains('allowed only during human Orders phase'),
      );
    });

    test('rejects unknown province visibility to human', () {
      final result = scopeApplyFlip(
        scopeFlipBaseGame(
          phase: TurnPhase.orders,
          ownerId: 'ai_1',
          humanVisibility: 'unknown',
        ),
        scopeFlipNameEvent(),
      );

      expect(result.game, isNull);
      expect(result.message, contains('unknown to human player'));
    });

    test('rejects already human-owned province', () {
      final result = scopeApplyFlip(
        scopeFlipBaseGame(
          phase: TurnPhase.orders,
          ownerId: 'human_1',
          humanVisibility: 'fogged',
        ),
        scopeFlipNameEvent(),
      );

      expect(result.game, isNull);
      expect(result.message, contains('already human-owned'));
    });

    test('rejects ambiguous province display name in region', () {
      final game = Game(
        id: 'g-flip-amb',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|P1',
                regionId: 'oldWorld',
                ownerId: 'ai_1',
                displayName: 'New Bordeaux',
              ),
              Province(
                id: 'oldWorld|P2',
                regionId: 'oldWorld',
                ownerId: 'ai_1',
                displayName: 'new bordeaux',
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'P1': ['oldWorld|P1|0|0'],
              'P2': ['oldWorld|P2|0|0'],
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
      expect(result.message, contains('ambiguous'));
    });

    test('rejects province display name not found in region', () {
      final result = scopeApplyFlip(
        scopeFlipBaseGame(
          phase: TurnPhase.orders,
          ownerId: 'ai_1',
          humanVisibility: 'fogged',
        ),
        scopeFlipNameEvent('Nonexistent Province'),
      );

      expect(result.game, isNull);
      expect(result.message, contains('not found'));
    });
  });
}
