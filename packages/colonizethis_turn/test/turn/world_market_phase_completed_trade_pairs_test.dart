import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/src/turn/phases/world_market_phase_deals.dart';
import 'package:colonizethis_test/test.dart';

/// `completedTradePairKeysFromDeals` (Refs #3753 R10): canonical GP-involved
/// pair keys recorded by the World Market phase for the next turn's trade-deal
/// relation boost. SPEC/program/world-market-resolution.md § Step F.
FilledDeal _deal(String seller, String buyer) => FilledDeal(
  sellerFactionId: seller,
  buyerFactionId: buyer,
  commodityId: 'timber',
  quantity: 5,
  pricePerUnit: 30.0,
);

void main() {
  group('completedTradePairKeysFromDeals', () {
    const gpIds = {'gp1', 'gp2'};

    test('positive: GP↔Minor deal yields canonical min|max pair key', () {
      final keys = completedTradePairKeysFromDeals(
        filledDeals: [_deal('gp1', 'm1')],
        gpFactionIds: gpIds,
      );
      expect(keys, const {'gp1|m1'});
    });

    test('positive: GP↔GP deal yields one canonical key', () {
      final keys = completedTradePairKeysFromDeals(
        filledDeals: [_deal('gp2', 'gp1')],
        gpFactionIds: gpIds,
      );
      expect(keys, const {'gp1|gp2'});
    });

    test('positive: multiple deals for one pair deduplicate to one key', () {
      final keys = completedTradePairKeysFromDeals(
        filledDeals: [_deal('gp1', 'm1'), _deal('gp1', 'm1')],
        gpFactionIds: gpIds,
      );
      expect(keys, const {'gp1|m1'});
    });

    test('negative: deal between two non-GP factions is excluded', () {
      final keys = completedTradePairKeysFromDeals(
        filledDeals: [_deal('m1', 'm2')],
        gpFactionIds: gpIds,
      );
      expect(keys, isEmpty);
    });

    test('negative: self-trade (seller == buyer) is excluded', () {
      final keys = completedTradePairKeysFromDeals(
        filledDeals: [_deal('gp1', 'gp1')],
        gpFactionIds: gpIds,
      );
      expect(keys, isEmpty);
    });

    test('negative: no deals yields empty set', () {
      final keys = completedTradePairKeysFromDeals(
        filledDeals: const [],
        gpFactionIds: gpIds,
      );
      expect(keys, isEmpty);
    });
  });
}
