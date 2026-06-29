import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// #3753 R7.3 sell-priority relation tiebreaker (matcher slice).
///
/// Covers the deal-matcher buyer reorder for Minor/Tribe seller offers:
/// consulate-holding buyers (those keyed in
/// `sellPriorityRelationByMinorTribeSeller`) are served first by descending
/// relation score, ties by ascending faction id; consulate-less buyers fall
/// back to default order; GP sellers (absent from the map) keep legacy order.
/// SPEC: `SPEC/program/world-market-resolution.md` § Step B item 4,
/// `SPEC/game/world-market.md` § Sell-priority relation tiebreaker.
void main() {
  group('DealMatcher.matchDeals — #3753 R7.3 sell-priority relation', () {
    test('higher-relation consulate-holding buyer wins limited supply', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'minorM': [matcherOffer('timber', 5, priority: 1)],
          },
          bidsByFactionId: {
            // Submitted in ascending faction id so default order would put
            // gpHigh first only by id; relation ordering must dominate.
            'gpHigh': [matcherBid('timber', 5, priority: 1)],
            'gpLow': [matcherBid('timber', 5, priority: 1)],
          },
          tradeCapacityByFactionId: const {'gpHigh': 100, 'gpLow': 100},
          sellPriorityRelationByMinorTribeSeller: const {
            'minorM': {'gpHigh': 80, 'gpLow': 40},
          },
        ),
      );

      expect(result.filledDeals, hasLength(1));
      expect(result.filledDeals.single.buyerFactionId, 'gpHigh');
      expect(result.filledDeals.single.quantity, 5);
      // gpLow's bid carries forward in full (lost the tiebreaker).
      expect(result.unfilledBidsByFactionId['gpLow'], [
        matcherBid('timber', 5, priority: 1),
      ]);
    });

    test('relation order overrides default ascending-faction-id order', () {
      // 'aBuyer' sorts first by faction id but has the lower relation, so the
      // relation tiebreaker must promote 'zBuyer' ahead of it.
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'minorM': [matcherOffer('timber', 4, priority: 1)],
          },
          bidsByFactionId: {
            'aBuyer': [matcherBid('timber', 4, priority: 1)],
            'zBuyer': [matcherBid('timber', 4, priority: 1)],
          },
          tradeCapacityByFactionId: const {'aBuyer': 100, 'zBuyer': 100},
          sellPriorityRelationByMinorTribeSeller: const {
            'minorM': {'aBuyer': 30, 'zBuyer': 90},
          },
        ),
      );

      expect(result.filledDeals.single.buyerFactionId, 'zBuyer');
    });

    test('consulate-less buyer falls back behind consulate-holding buyer', () {
      // gpHigh has the higher relation but holds no consulate (absent from the
      // relation map), so the only consulate-holding buyer (gpLow) is served
      // first regardless of relation.
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'minorM': [matcherOffer('timber', 5, priority: 1)],
          },
          bidsByFactionId: {
            'gpHigh': [matcherBid('timber', 5, priority: 1)],
            'gpLow': [matcherBid('timber', 5, priority: 1)],
          },
          tradeCapacityByFactionId: const {'gpHigh': 100, 'gpLow': 100},
          sellPriorityRelationByMinorTribeSeller: const {
            'minorM': {'gpLow': 40},
          },
        ),
      );

      expect(result.filledDeals.single.buyerFactionId, 'gpLow');
      expect(result.unfilledBidsByFactionId['gpHigh'], [
        matcherBid('timber', 5, priority: 1),
      ]);
    });

    test('relation tie breaks deterministically by ascending faction id', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'minorM': [matcherOffer('timber', 5, priority: 1)],
          },
          bidsByFactionId: {
            'gpB': [matcherBid('timber', 5, priority: 1)],
            'gpA': [matcherBid('timber', 5, priority: 1)],
          },
          tradeCapacityByFactionId: const {'gpA': 100, 'gpB': 100},
          sellPriorityRelationByMinorTribeSeller: const {
            'minorM': {'gpA': 55, 'gpB': 55},
          },
        ),
      );

      expect(result.filledDeals.single.buyerFactionId, 'gpA');
    });

    test('seller absent from map keeps legacy ordering (no reorder)', () {
      // 'minorM' has an entry but the active seller 'minorN' does not, so its
      // offer keeps the default ascending-faction-id order (the matcher only
      // reorders bids for offers whose seller appears in the map). The
      // Minor/Tribe-only restriction itself is enforced by the phase-handler
      // builder and covered in the turn integration test.
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'minorN': [matcherOffer('timber', 5, priority: 1)],
          },
          bidsByFactionId: {
            'gpA': [matcherBid('timber', 5, priority: 1)],
            'gpZ': [matcherBid('timber', 5, priority: 1)],
          },
          tradeCapacityByFactionId: const {'gpA': 100, 'gpZ': 100},
          sellPriorityRelationByMinorTribeSeller: const {
            'minorM': {'gpA': 1, 'gpZ': 99},
          },
        ),
      );

      // Relation map favours gpZ but applies to 'minorM' only; 'minorN' keeps
      // the default order → ascending faction id picks gpA.
      expect(result.filledDeals.single.buyerFactionId, 'gpA');
    });

    test('empty relation map preserves legacy ordering for minor seller', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'minorM': [matcherOffer('timber', 5, priority: 1)],
          },
          bidsByFactionId: {
            'gpA': [matcherBid('timber', 5, priority: 1)],
            'gpZ': [matcherBid('timber', 5, priority: 1)],
          },
          tradeCapacityByFactionId: const {'gpA': 100, 'gpZ': 100},
        ),
      );

      // No tiebreaker data → ascending faction id default order: gpA first.
      expect(result.filledDeals.single.buyerFactionId, 'gpA');
    });

    test('priority tier remains absolute over relation tiebreaker', () {
      // gpLow bids at higher-precedence tier 1; gpHigh (higher relation) bids
      // at tier 2. Tier precedence wins over the relation tiebreaker.
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'minorM': [
              matcherOffer('timber', 5, priority: 1),
              matcherOffer('timber', 5, priority: 2),
            ],
          },
          bidsByFactionId: {
            'gpHigh': [matcherBid('timber', 5, priority: 2)],
            'gpLow': [matcherBid('timber', 5, priority: 1)],
          },
          tradeCapacityByFactionId: const {'gpHigh': 100, 'gpLow': 100},
          sellPriorityRelationByMinorTribeSeller: const {
            'minorM': {'gpHigh': 90, 'gpLow': 10},
          },
        ),
      );

      // gpLow's tier-1 bid fills the tier-1 offer first; gpHigh's tier-2 bid
      // fills the tier-2 offer next.
      expect(result.filledDeals, hasLength(2));
      expect(result.filledDeals.first.buyerFactionId, 'gpLow');
      expect(result.filledDeals[1].buyerFactionId, 'gpHigh');
    });
  });
}
