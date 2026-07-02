// Unit tests for the shared world-market admission helpers (Refs #3615
import 'package:colonizethis_economy/colonizethis_economy.dart';
// Cluster 1).
//
// SPEC anchors:
//   - SPEC/program/world-market-resolution.md § Trade order validation
//     (rules 2 / 3 / 4).
//   - SPEC/game/world-market.md § Tradeable commodities.
import 'package:colonizethis_data/colonizethis_data.dart' as data;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('isWorldMarketTradeableCommodity (rule 2)', () {
    test('non-riches commodity is tradeable', () {
      expect(isWorldMarketTradeableCommodity('timber'), isTrue);
      expect(isWorldMarketTradeableCommodity('iron'), isTrue);
    });

    test('every riches commodity is not tradeable', () {
      for (final richesId in data.richesCommodityIds) {
        expect(
          isWorldMarketTradeableCommodity(richesId),
          isFalse,
          reason: '$richesId should be excluded from the world market',
        );
      }
    });
  });

  group('commoditiesWithBidAndOffer (rule 3)', () {
    test('returns commodities appearing as both bid and offer', () {
      final excluded = commoditiesWithBidAndOffer([
        testBid('timber', 5),
        testOffer('timber', 5),
        testBid('iron', 5),
        testOffer('wool', 5),
      ]);
      expect(excluded, {'timber'});
    });

    test('returns const empty set when no offer side exists', () {
      final excluded = commoditiesWithBidAndOffer([
        testBid('timber', 5),
        testBid('iron', 5),
      ]);
      expect(excluded, isEmpty);
    });

    test('returns const empty set when no bid side exists', () {
      final excluded = commoditiesWithBidAndOffer([
        testOffer('timber', 5),
        testOffer('iron', 5),
      ]);
      expect(excluded, isEmpty);
    });

    test('handles multiple overlapping commodities', () {
      final excluded = commoditiesWithBidAndOffer([
        testBid('timber', 5),
        testOffer('timber', 5),
        testBid('iron', 5),
        testOffer('iron', 5),
        testOffer('wool', 5),
      ]);
      expect(excluded, {'timber', 'iron'});
    });
  });

  group('admittedBidCommodityIdsInSubmissionOrder (rule 4)', () {
    test('admits distinct bid commodities in submission order up to the cap', () {
      final admitted = admittedBidCommodityIdsInSubmissionOrder(
        proposedOrders: [
          testBid('wool', 1),
          testBid('iron', 1),
          testBid('coal', 1),
          testBid('timber', 1),
        ],
        bidTypeCap: 3,
        mutuallyExcludedCommodityIds: const <CommodityId>{},
      );
      // First three distinct commodities by submission order; timber dropped.
      expect(admitted, {'wool', 'iron', 'coal'});
      expect(admitted.contains('timber'), isFalse);
    });

    test('a repeat bid on an admitted commodity does not consume a slot', () {
      final admitted = admittedBidCommodityIdsInSubmissionOrder(
        proposedOrders: [
          testBid('wool', 1),
          testBid('wool', 2),
          testBid('iron', 1),
          testBid('coal', 1),
        ],
        bidTypeCap: 3,
        mutuallyExcludedCommodityIds: const <CommodityId>{},
      );
      expect(admitted, {'wool', 'iron', 'coal'});
    });

    test('skips non-positive quantities, riches, and mutually-excluded ids', () {
      final admitted = admittedBidCommodityIdsInSubmissionOrder(
        proposedOrders: [
          testBid('timber', 0), // rule 1: non-positive
          testBid('gold', 5), // rule 2: riches
          testBid('iron', 5), // rule 3: mutually excluded below
          testBid('wool', 5),
          testBid('coal', 5),
        ],
        bidTypeCap: 6,
        mutuallyExcludedCommodityIds: const <CommodityId>{'iron'},
      );
      expect(admitted, {'wool', 'coal'});
    });

    test('returns const empty set when bidTypeCap <= 0', () {
      final admitted = admittedBidCommodityIdsInSubmissionOrder(
        proposedOrders: [testBid('timber', 5)],
        bidTypeCap: 0,
        mutuallyExcludedCommodityIds: const <CommodityId>{},
      );
      expect(admitted, isEmpty);
    });

    test('ignores offers entirely', () {
      final admitted = admittedBidCommodityIdsInSubmissionOrder(
        proposedOrders: [
          testOffer('timber', 5),
          testBid('iron', 5),
        ],
        bidTypeCap: 6,
        mutuallyExcludedCommodityIds: const <CommodityId>{},
      );
      expect(admitted, {'iron'});
    });
  });
}
