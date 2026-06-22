import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Matcher-level coverage for the per-buyer treasury clamp added to Step C
/// (Refs #3115). The matcher receives `treasuryBudgetByBuyerFactionId`
/// in `DealMatchInputs`; this suite asserts the clamp behavior, FRR
/// integration, `bidPartialFillTreasuryInsufficient` note emission, the
/// missing-price defect path, and the missing-buyer-entry edge case.
///
/// SPEC anchors:
/// - `SPEC/program/world-market-resolution.md` § Step C — Match
///   (treasury clamp, running tally, note emission).
/// - `SPEC/program/world-market-resolution.md` § Deal matching engine
///   (`treasuryBudgetByBuyerFactionId` field; missing-entry → 0 budget).
void main() {
  group('DealMatcher.matchDeals — treasury clamp (Refs #3115)', () {
    test('truncates a single oversized bid to floor(treasury / price)', () {
      // AC #1: treasury 100, bid 10 @ 30 → fills 3 (floor(100/30) = 3),
      // residual 7 carries forward.
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('timber', 10)],
          },
          bidsByFactionId: {
            'gp1': [matcherBid('timber', 10)],
          },
          tradeCapacityByFactionId: const {'gp1': 100},
          treasuryBudgetByBuyerFactionId: const {'gp1': 100},
        ),
      );

      expect(result.filledDeals, hasLength(1));
      final deal = result.filledDeals.single;
      expect(deal.buyerFactionId, 'gp1');
      expect(deal.quantity, 3);
      expect(deal.pricePerUnit, 30.0);
      expect(result.unfilledBidsByFactionId['gp1'], hasLength(1));
      expect(
        result.unfilledBidsByFactionId['gp1']!.single,
        matcherBid('timber', 7),
      );
    });

    test('per-buyer running tally exhausts treasury across bids in order', () {
      // AC #2: treasury 100, A 5 @ 20 (notional 100) → fully fills; B 5 @ 20
      // (notional 100) → no fill, full carry-forward.
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'sellerA': [matcherOffer('alpha', 5)],
            'sellerB': [matcherOffer('beta', 5)],
          },
          bidsByFactionId: {
            'gp1': [matcherBid('alpha', 5), matcherBid('beta', 5)],
          },
          tradeCapacityByFactionId: const {'gp1': 100},
          treasuryBudgetByBuyerFactionId: const {'gp1': 100},
          pricesByCommodityId: const {'alpha': 20.0, 'beta': 20.0},
        ),
      );

      expect(result.filledDeals, hasLength(1));
      final alphaDeal = result.filledDeals.single;
      expect(alphaDeal.commodityId, 'alpha');
      expect(alphaDeal.quantity, 5);
      expect(result.unfilledBidsByFactionId['gp1'], hasLength(1));
      expect(
        result.unfilledBidsByFactionId['gp1']!.single,
        matcherBid('beta', 5),
      );
    });

    test(
      'negative-treasury buyer treated as zero budget (full suppression)',
      () {
        // AC #3: budget clamped to 0 → no fills; all bids carry forward at
        // original quantity.
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'sellerA': [matcherOffer('timber', 10)],
            },
            bidsByFactionId: {
              'gp1': [matcherBid('timber', 10)],
            },
            tradeCapacityByFactionId: const {'gp1': 100},
            treasuryBudgetByBuyerFactionId: const {'gp1': -50},
          ),
        );

        expect(result.filledDeals, isEmpty);
        expect(result.unfilledBidsByFactionId['gp1'], hasLength(1));
        expect(
          result.unfilledBidsByFactionId['gp1']!.single,
          matcherBid('timber', 10),
        );
      },
    );

    test('FRR pre-pass respects treasury clamp', () {
      // AC #4: gp1 owns purchased tile, treasury 60, FRR offer 10 @ 20 →
      // fills 3, residual 7 carries forward.
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'M1': [
              matcherOffer('timber', 10, originTileKey: 'oldWorld|M1|0|0'),
            ],
          },
          bidsByFactionId: {
            'gpA': [matcherBid('timber', 10)],
          },
          tradeCapacityByFactionId: const {'gpA': 100},
          treasuryBudgetByBuyerFactionId: const {'gpA': 60},
          pricesByCommodityId: const {'timber': 20.0},
          purchasedTileIndex: frrMatcherTestIndex(),
        ),
      );

      expect(result.filledDeals, hasLength(1));
      final frrDeal = result.filledDeals.single;
      expect(frrDeal.isFirstRightOfRefusalMatch, isTrue);
      expect(frrDeal.buyerFactionId, 'gpA');
      expect(frrDeal.quantity, 3);
      expect(result.unfilledBidsByFactionId['gpA'], hasLength(1));
      expect(
        result.unfilledBidsByFactionId['gpA']!.single,
        matcherBid('timber', 10).copyWith(quantity: 7),
      );
    });

    test('emits exactly one bidPartialFillTreasuryInsufficient note per '
        'truncated bid (full bid quantity carried in note)', () {
      // AC #5: matcher activity contains exactly one note with the
      // truncated bid's original submitted quantity.
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('timber', 10)],
          },
          bidsByFactionId: {
            'gp1': [matcherBid('timber', 10)],
          },
          tradeCapacityByFactionId: const {'gp1': 100},
          treasuryBudgetByBuyerFactionId: const {'gp1': 100},
        ),
      );

      final activity = result.activityByCommodityId['timber'];
      expect(activity, isNotNull);
      expect(activity!.notes, hasLength(1));
      expect(
        activity.notes.single,
        const MarketActivityNote(
          kind: MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
          factionId: 'gp1',
          commodityId: 'timber',
          quantity: 10,
        ),
      );
    });

    test('two identical runs produce byte-identical FilledDeal sequences', () {
      // AC #6: determinism with treasury clamp.
      DealMatchResult runOnce() => DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('timber', 10)],
          },
          bidsByFactionId: {
            'gp1': [matcherBid('timber', 10)],
            'gp2': [matcherBid('timber', 10)],
          },
          tradeCapacityByFactionId: const {'gp1': 100, 'gp2': 100},
          treasuryBudgetByBuyerFactionId: const {'gp1': 100, 'gp2': 200},
        ),
      );

      final a = runOnce();
      final b = runOnce();
      expect(a.filledDeals, equals(b.filledDeals));
      expect(
        a.unfilledBidsByFactionId.keys.toList()..sort(),
        equals(b.unfilledBidsByFactionId.keys.toList()..sort()),
      );
    });

    test(
      'zero-price commodity preserves legacy free-fill (no treasury debit)',
      () {
        // AC #8: pricesByCommodityId returns 0.0 (missing-price defect path).
        // matchQty should be governed by offer/bid/cargo, not by treasury.
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'a': [matcherOffer('iron', 5)],
            },
            bidsByFactionId: {
              'gp1': [matcherBid('iron', 5)],
            },
            tradeCapacityByFactionId: const {'gp1': 100},
            // Even a zero-treasury buyer should fill in this branch.
            treasuryBudgetByBuyerFactionId: const {'gp1': 0},
            pricesByCommodityId: const <CommodityId, double>{},
          ),
        );

        expect(result.filledDeals, hasLength(1));
        final deal = result.filledDeals.single;
        expect(deal.pricePerUnit, 0.0);
        expect(deal.quantity, 5);
        final activity = result.activityByCommodityId['iron'];
        expect(activity, isNotNull);
        expect(
          activity!.notes,
          isEmpty,
          reason: 'no treasury truncation should be recorded on free-fill',
        );
      },
    );

    test('missing buyer entry in treasury budget treated as zero', () {
      // AC #9: buyer omitted from treasuryBudgetByBuyerFactionId → 0
      // budget; no fills, all bids carry forward.
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('timber', 5)],
          },
          bidsByFactionId: {
            'gp1': [matcherBid('timber', 5)],
          },
          tradeCapacityByFactionId: const {'gp1': 100},
          treasuryBudgetByBuyerFactionId: const <String, int>{},
        ),
      );

      expect(result.filledDeals, isEmpty);
      expect(result.unfilledBidsByFactionId['gp1'], hasLength(1));
      expect(
        result.unfilledBidsByFactionId['gp1']!.single,
        matcherBid('timber', 5),
      );
    });

    test('unaffordable bid at non-zero price emits a note even with zero '
        'fill quantity', () {
      // Negative path defense: a buyer with treasury < price cannot
      // afford even a single unit; the bid is fully suppressed but the
      // truncation note is still emitted so the Deal Book can attribute
      // the no-op fill.
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('timber', 1)],
          },
          bidsByFactionId: {
            'gp1': [matcherBid('timber', 1)],
          },
          tradeCapacityByFactionId: const {'gp1': 100},
          treasuryBudgetByBuyerFactionId: const {'gp1': 10},
          pricesByCommodityId: const {'timber': 30.0},
        ),
      );

      expect(result.filledDeals, isEmpty);
      final activity = result.activityByCommodityId['timber'];
      expect(activity, isNotNull);
      expect(activity!.notes, hasLength(1));
      expect(
        activity.notes.single.kind,
        MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
      );
    });

    test('cargo clamps tighter than treasury → matchQty falls back to cargo, '
        'no truncation note emitted', () {
      // Defense for the AC #5 / AC #8 note-emission contract: only when
      // treasury actually limits the fill do we record the note.
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('timber', 10)],
          },
          bidsByFactionId: {
            'gp1': [matcherBid('timber', 10)],
          },
          // Cargo only allows 4 units; treasury permits 10.
          tradeCapacityByFactionId: const {'gp1': 4},
          treasuryBudgetByBuyerFactionId: const {'gp1': 10_000},
          pricesByCommodityId: const {'timber': 30.0},
        ),
      );

      expect(result.filledDeals.single.quantity, 4);
      final activity = result.activityByCommodityId['timber'];
      expect(activity, isNotNull);
      expect(
        activity!.notes,
        isEmpty,
        reason:
            'cargo-truncated bids do not emit the treasury-insufficient '
            'note (only treasury-clamped fills emit it)',
      );
    });
  });
}
