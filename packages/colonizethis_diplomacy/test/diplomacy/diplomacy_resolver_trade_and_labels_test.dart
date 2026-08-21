import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_data/colonizethis_data.dart' show kTechIdTradeFairs;
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

import 'diplomacy_game_fixtures_scenarios_gp_tribe.dart';

void main() {
  group('tradeSlotsForGp', () {
    test('returns 0 without embassy', () {
      final game = tradeSlotsBidCapTestGame();
      expect(tradeSlotsForGp(game, 'gp1', 'minor1'), 0);
    });
    test('returns 3 commodity slots with embassy (baseline)', () {
      final game = tradeSlotsBidCapTestGame(
        overtureStates: const [
          OvertureState(gpId: 'gp1', targetId: 'minor1', stage: OvertureStage.embassy, sinceTurn: 0),
        ],
      );
      expect(tradeSlotsForGp(game, 'gp1', 'minor1'), 3);
    });

    test('returns 6 with embassy and trade_fairs', () {
      final game = tradeSlotsBidCapTestGame(
        techUnlocked: {kTechIdTradeFairs: true},
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      expect(tradeSlotsForGp(game, 'gp1', 'minor1'), 6);
    });
  });

  // Refs #2989 A5; SPEC/program/world-market-resolution.md § Bid type cap helper.
  group('worldMarketBidTypeCap', () {
    test('returns 0 when player is unknown (ghost-player guard)', () {
      final game = tradeSlotsBidCapTestGame();
      expect(worldMarketBidTypeCap(game, 'ghost'), 0);
    });

    test(
      'returns kWorldMarketBaselineBidTypeCap (3) when player has no '
      'overtures at all (Refs #4186 embassy-free ladder)',
      () {
        final game = tradeSlotsBidCapTestGame();
        expect(
          worldMarketBidTypeCap(game, 'gp1'),
          kWorldMarketBaselineBidTypeCap,
        );
        expect(kWorldMarketBaselineBidTypeCap, 3);
      },
    );

    test(
      'returns kWorldMarketBaselineBidTypeCap (3) when player has only '
      'trade-consulate overtures (embassy does not affect cap; Refs #4186)',
      () {
        final game = tradeSlotsBidCapTestGame(
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.tradeConsulate,
              sinceTurn: 0,
            ),
          ],
        );
        expect(
          worldMarketBidTypeCap(game, 'gp1'),
          kWorldMarketBaselineBidTypeCap,
        );
      },
    );

    test(
      'returns 3 with embassy and no trade_fairs (embassy does not raise cap)',
      () {
        final game = tradeSlotsBidCapTestGame(
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        expect(worldMarketBidTypeCap(game, 'gp1'), 3);
      },
    );

    test('returns 3 with NAP overture and no trade_fairs', () {
      final game = tradeSlotsBidCapTestGame(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.nap,
            sinceTurn: 0,
          ),
        ],
      );
      expect(worldMarketBidTypeCap(game, 'gp1'), 3);
    });

    test('returns 6 with trade_fairs regardless of embassy', () {
      final game = tradeSlotsBidCapTestGame(
        techUnlocked: {kTechIdTradeFairs: true},
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      expect(worldMarketBidTypeCap(game, 'gp1'), 6);
    });

    test('returns 6 with trade_fairs and no embassy', () {
      final game = tradeSlotsBidCapTestGame(
        techUnlocked: {kTechIdTradeFairs: true},
      );
      expect(worldMarketBidTypeCap(game, 'gp1'), 6);
    });

    test(
      'embassy on another gp does not change cap for gp without trade_fairs',
      () {
        final game = diplomacyGame(
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'gp2',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        expect(worldMarketBidTypeCap(game, 'gp1'), 3);
        expect(worldMarketBidTypeCap(game, 'gp2'), 3);
      },
    );
  });

  group('scoreToLevel', () {
    test('maps score ranges to levels', () {
      expect(scoreToLevel(0), RelationLevel.hostile);
      expect(scoreToLevel(25), RelationLevel.hostile);
      expect(scoreToLevel(26), RelationLevel.neutral);
      expect(scoreToLevel(50), RelationLevel.neutral);
      expect(scoreToLevel(51), RelationLevel.friendly);
      expect(scoreToLevel(75), RelationLevel.friendly);
      expect(scoreToLevel(76), RelationLevel.allied);
      expect(scoreToLevel(100), RelationLevel.allied);
    });
    test('compares decimal scores on the raw value (no rounding)', () {
      expect(scoreToLevel(25.0), RelationLevel.hostile);
      expect(scoreToLevel(25.5), RelationLevel.neutral);
      expect(scoreToLevel(50.0), RelationLevel.neutral);
      expect(scoreToLevel(50.5), RelationLevel.friendly);
      expect(scoreToLevel(75.0), RelationLevel.friendly);
      expect(scoreToLevel(75.5), RelationLevel.allied);
    });
  });
}
