import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// #3753 R6 boycott colony trade embargo (matcher slice).
///
/// Covers the deal-matcher refusal to fill any offer↔bid pair whose canonical
/// `pairKey(sellerFactionId, buyerFactionId)` is present in
/// `boycottBlockedPairKeys`. The block is bidirectional and independent of FTP
/// / FRR / sell-priority ordering; an empty set is a no-op (legacy matching).
/// SPEC: `SPEC/program/world-market-resolution.md` § Deal matching engine
/// (boycott exclusion); `SPEC/game/diplomacy.md` § GP–Tribe Rules (Boycott).
void main() {
  group('DealMatcher.matchDeals — #3753 R6 boycott exclusion', () {
    test('blocks trade where target GP buys goods a colony Tribe sells', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'tribeT': [matcherOffer('timber', 10, priority: 1)],
          },
          bidsByFactionId: {
            'gpB': [matcherBid('timber', 10, priority: 1)],
          },
          tradeCapacityByFactionId: const {'gpB': 100},
          boycottBlockedPairKeys: {DealMatcher.pairKey('tribeT', 'gpB')},
        ),
      );

      expect(result.filledDeals, isEmpty);
      // Both orders carry forward unfilled.
      expect(result.unfilledOffersByFactionId['tribeT'], [
        matcherOffer('timber', 10, priority: 1),
      ]);
      expect(result.unfilledBidsByFactionId['gpB'], [
        matcherBid('timber', 10, priority: 1),
      ]);
    });

    test('block is bidirectional (colony Tribe buying goods target GP sells)', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'gpB': [matcherOffer('timber', 10, priority: 1)],
          },
          bidsByFactionId: {
            'tribeT': [matcherBid('timber', 10, priority: 1)],
          },
          tradeCapacityByFactionId: const {'tribeT': 100},
          boycottBlockedPairKeys: {DealMatcher.pairKey('tribeT', 'gpB')},
        ),
      );

      expect(result.filledDeals, isEmpty);
    });

    test('only the boycotted GP is blocked; other buyers still trade', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'tribeT': [matcherOffer('timber', 10, priority: 1)],
          },
          bidsByFactionId: {
            // gpB is blocked; gpD is not. gpB sorts first by faction id but must
            // be skipped, leaving the supply for gpD.
            'gpB': [matcherBid('timber', 10, priority: 1)],
            'gpD': [matcherBid('timber', 10, priority: 1)],
          },
          tradeCapacityByFactionId: const {'gpB': 100, 'gpD': 100},
          boycottBlockedPairKeys: {DealMatcher.pairKey('tribeT', 'gpB')},
        ),
      );

      expect(result.filledDeals, hasLength(1));
      expect(result.filledDeals.single.sellerFactionId, 'tribeT');
      expect(result.filledDeals.single.buyerFactionId, 'gpD');
      expect(result.filledDeals.single.quantity, 10);
      // The boycotted buyer's bid carries forward in full.
      expect(result.unfilledBidsByFactionId['gpB'], [
        matcherBid('timber', 10, priority: 1),
      ]);
    });

    test('empty blocked set is a no-op (legacy matching preserved)', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'tribeT': [matcherOffer('timber', 10, priority: 1)],
          },
          bidsByFactionId: {
            'gpB': [matcherBid('timber', 10, priority: 1)],
          },
          tradeCapacityByFactionId: const {'gpB': 100},
        ),
      );

      expect(result.filledDeals, hasLength(1));
      expect(result.filledDeals.single.buyerFactionId, 'gpB');
      expect(result.filledDeals.single.quantity, 10);
    });
  });
}
