import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

/// Unit coverage for world-market Step A gather helpers extracted in Refs #4039.
void main() {
  group('splitTradeOrdersByType', () {
    test('positive: partitions offers and bids by faction', () {
      final split = splitTradeOrdersByType({
        'gpA': [
          TradeOrder(
            commodityId: 'timber',
            type: TradeOrderType.offer,
            quantity: 5,
            priority: 1,
          ),
          TradeOrder(
            commodityId: 'grain',
            type: TradeOrderType.bid,
            quantity: 3,
            priority: 2,
          ),
        ],
        'gpB': [
          TradeOrder(
            commodityId: 'timber',
            type: TradeOrderType.bid,
            quantity: 4,
            priority: 1,
          ),
        ],
      });

      expect(split.offersByFactionId.keys, ['gpA']);
      expect(split.offersByFactionId['gpA']!.single.commodityId, 'timber');
      expect(split.bidsByFactionId.keys, unorderedEquals(['gpA', 'gpB']));
      expect(split.bidsByFactionId['gpA']!.single.commodityId, 'grain');
      expect(split.bidsByFactionId['gpB']!.single.quantity, 4);
    });

    test('negative: drops non-positive quantities and empty factions', () {
      final split = splitTradeOrdersByType({
        'gpA': [
          TradeOrder(
            commodityId: 'timber',
            type: TradeOrderType.offer,
            quantity: 0,
            priority: 1,
          ),
        ],
        'gpB': const <TradeOrder>[],
      });

      expect(split.offersByFactionId, isEmpty);
      expect(split.bidsByFactionId, isEmpty);
    });
  });

  group('applyLockRecoveryTreasuryViewForMarket', () {
    test('positive: floors negative treasury for broke sellers below regiment '
        'build band', () {
      final threshold = cheapestRegimentBuildTreasuryCost();
      final game = TestFixtures.minimalGame(
        players: [
          Player(
            id: 'broke',
            displayName: 'Broke',
            isHuman: false,
            treasury: -50,
          ),
          Player(
            id: 'rich',
            displayName: 'Rich',
            isHuman: false,
            treasury: threshold + 100,
          ),
        ],
      );

      final view = applyLockRecoveryTreasuryViewForMarket(game);
      expect(view.lockRecoverySellerPriorityIds, contains('broke'));
      expect(
        view.gameForMarket.players.firstWhere((p) => p.id == 'broke').treasury,
        0,
      );
      expect(
        view.gameForMarket.players.firstWhere((p) => p.id == 'rich').treasury,
        threshold + 100,
      );
      expect(
        game.players.firstWhere((p) => p.id == 'broke').treasury,
        -50,
        reason: 'original game treasury must stay unchanged',
      );
    });

    test('negative: leaves game unchanged when no seller is below band', () {
      final threshold = cheapestRegimentBuildTreasuryCost();
      final game = TestFixtures.minimalGame(
        players: [
          Player(
            id: 'gpA',
            displayName: 'A',
            isHuman: false,
            treasury: threshold,
          ),
        ],
      );

      final view = applyLockRecoveryTreasuryViewForMarket(game);
      expect(view.lockRecoverySellerPriorityIds, isEmpty);
      expect(identical(view.gameForMarket, game), isTrue);
      expect(view.gameForMarket.players.single.treasury, threshold);
    });
  });
}
