// Issue-AC-mapped unit tests for World Market First Right of Refusal
// (#2992 D5).
//
// SPEC: `SPEC/game/world-market-first-right-of-refusal.md` (D2 priority
// override, D3 profit formula, D4 treasury transfer). This file
// consolidates the five numbered ACs at the bottom of issue
// [#2992](https://github.com/waigore/colonizethisv3/issues/2992) into a
// single D5 contract file. Each `group(...)` maps 1:1 to one issue AC
// so reviewers / `verify-github-issue` can audit AC↔test coverage
// without cross-referencing slice files. Per-slice tests
// (`world_market_deal_matcher_first_right_test.dart`,
//  `world_market_deal_matcher_first_right_supplement_test.dart`,
//  `economy/world_market/first_right_profit_test.dart`,
//  `economy/world_market/first_right_credits_test.dart`,
//  `economy/world_market/first_right_credits_aggregation_test.dart`,
//  `turn/world_market_phase_first_right_credit_test.dart`)
// continue to exercise the broader SPEC AC table.
//
// Issue AC → group mapping
//  AC #1 — Owning GP's bid wins purchased-tile offer above every
//          priority tier AND above FTP (DealMatcher).
//  AC #2 — Other-GP buy at relation 75 credits owning GP exactly
//          `10 * 20 * 0.75 * 0.40 = 60` treasury (credits helper).
//  AC #3 — Other-GP buy at relation 100 credits exactly 40% of sale
//          value (upper-bound profit rate).
//  AC #4 — Other-GP buy at relation 0 credits 0 treasury (lower bound;
//          also: D2 FRR-match path excluded from D4 aggregation).
//  AC #5 — Multi-GP attribution: each owning GP credited only for own
//          tile(s); same GP across two minors aggregates per source
//          relation independently.
//
// Self-contained: no helpers imported from sibling slice test files.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show DealMatcher, DealMatchInputs;
import 'package:colonizethis_logic/src/economy/world_market/first_right_credits.dart';
import 'package:colonizethis_logic/src/economy/world_market/first_right_profit.dart';
import 'package:colonizethis_logic/src/economy/world_market/purchased_tile_index.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpA = 'gpA';
const String _gpB = 'gpB';
const String _gpC = 'gpC';
const String _gpFtp = 'gpFtp';
const String _minorM1 = 'M1';
const String _minorM2 = 'M2';
const String _tileK1 = 'oldWorld|M1|0|0';
const String _tileK2 = 'oldWorld|M1|1|0';
const String _tileK3 = 'oldWorld|M2|0|0';
const String _provinceM1 = 'oldWorld|M1';
const String _provinceM2 = 'oldWorld|M2';

PurchasedTileAttribution _attr(
  String tileKey,
  String owningGpId,
  String sourceFactionId, [
  String provinceId = _provinceM1,
]) => PurchasedTileAttribution(
  tileKey: tileKey,
  owningGpId: owningGpId,
  sourceFactionId: sourceFactionId,
  provinceId: provinceId,
);

PurchasedTileIndex _index(Iterable<PurchasedTileAttribution> rows) =>
    PurchasedTileIndex.forTesting(rows);

TradeOrder _offer(
  String commodityId,
  int quantity, {
  int priority = 1,
  String? originTileKey,
}) => TradeOrder(
  commodityId: commodityId,
  type: TradeOrderType.offer,
  quantity: quantity,
  priority: priority,
  originTileKey: originTileKey,
);

TradeOrder _bid(String commodityId, int quantity, {int priority = 1}) =>
    TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.bid,
      quantity: quantity,
      priority: priority,
    );

DealMatchInputs _matcherInputs({
  required Map<String, List<TradeOrder>> offersByFactionId,
  required Map<String, List<TradeOrder>> bidsByFactionId,
  required Map<String, int> tradeCapacityByFactionId,
  Map<String, int>? treasuryBudgetByBuyerFactionId,
  Set<String> ftpPairKeys = const {},
  PurchasedTileIndex? purchasedTileIndex,
}) => (
  offersByFactionId: offersByFactionId,
  bidsByFactionId: bidsByFactionId,
  tradeCapacityByFactionId: tradeCapacityByFactionId,
  treasuryBudgetByBuyerFactionId: treasuryBudgetByBuyerFactionId ??
      {for (final id in bidsByFactionId.keys) id: 1 << 30},
  pricesByCommodityId: const {'timber': 20.0},
  ftpPairKeys: ftpPairKeys,
  purchasedTileIndex: purchasedTileIndex,
  lockRecoverySellerPriorityIds: const {},
  treasuryByFactionId: const {},
);

FilledDeal _otherBuyDeal({
  String seller = _minorM1,
  String buyer = _gpB,
  int quantity = 10,
  double pricePerUnit = 20.0,
  String sellerOriginTileKey = _tileK1,
}) => FilledDeal(
  sellerFactionId: seller,
  buyerFactionId: buyer,
  commodityId: 'timber',
  quantity: quantity,
  pricePerUnit: pricePerUnit,
  sellerOriginTileKey: sellerOriginTileKey,
);

void main() {
  group('AC #1 — owning-GP bid wins above priority tiers AND FTP', () {
    test(
      'rival priority-1 bid loses to owning-GP priority-5 bid; rival '
      'priority-1 bid carries forward intact',
      () {
        final result = DealMatcher.matchDeals(
          _matcherInputs(
            offersByFactionId: {
              _minorM1: [_offer('timber', 10, originTileKey: _tileK1)],
            },
            bidsByFactionId: {
              _gpA: [_bid('timber', 10, priority: 5)],
              _gpB: [_bid('timber', 10, priority: 1)],
            },
            tradeCapacityByFactionId: const {_gpA: 100, _gpB: 100},
            purchasedTileIndex: _index([
              _attr(_tileK1, _gpA, _minorM1),
            ]),
          ),
        );
        expect(result.filledDeals, hasLength(1));
        final deal = result.filledDeals.single;
        expect(deal.buyerFactionId, _gpA);
        expect(deal.quantity, 10);
        expect(deal.isFirstRightOfRefusalMatch, isTrue);
        expect(deal.isFtpMatch, isFalse);
        expect(result.unfilledBidsByFactionId[_gpB], [
          _bid('timber', 10, priority: 1),
        ]);
      },
    );

    test(
      'FTP-paired rival bid at same priority loses to owning GP; FTP '
      'partner bid carries forward (FRR overrides FTP)',
      () {
        final result = DealMatcher.matchDeals(
          _matcherInputs(
            offersByFactionId: {
              _minorM1: [_offer('timber', 6, originTileKey: _tileK1)],
            },
            bidsByFactionId: {
              _gpA: [_bid('timber', 6, priority: 1)],
              _gpFtp: [_bid('timber', 6, priority: 1)],
            },
            tradeCapacityByFactionId: const {_gpA: 100, _gpFtp: 100},
            ftpPairKeys: {DealMatcher.pairKey(_minorM1, _gpFtp)},
            purchasedTileIndex: _index([
              _attr(_tileK1, _gpA, _minorM1),
            ]),
          ),
        );
        expect(result.filledDeals, hasLength(1));
        final deal = result.filledDeals.single;
        expect(deal.buyerFactionId, _gpA);
        expect(deal.isFirstRightOfRefusalMatch, isTrue);
        expect(deal.isFtpMatch, isFalse);
        expect(result.unfilledBidsByFactionId[_gpFtp], [
          _bid('timber', 6, priority: 1),
        ]);
      },
    );

    test(
      'negative — owning GP does NOT bid: purchased-tile offer falls '
      'back to standard tier matching (not FRR-flagged)',
      () {
        final result = DealMatcher.matchDeals(
          _matcherInputs(
            offersByFactionId: {
              _minorM1: [_offer('timber', 10, originTileKey: _tileK1)],
            },
            bidsByFactionId: {
              _gpB: [_bid('timber', 10, priority: 1)],
            },
            tradeCapacityByFactionId: const {_gpB: 100},
            purchasedTileIndex: _index([
              _attr(_tileK1, _gpA, _minorM1),
            ]),
          ),
        );
        expect(result.filledDeals, hasLength(1));
        final deal = result.filledDeals.single;
        expect(deal.buyerFactionId, _gpB);
        expect(deal.isFirstRightOfRefusalMatch, isFalse);
      },
    );
  });

  group('AC #2 — relation 75 credits 10*20*0.30 = 60 treasury', () {
    test('credits helper produces rate 0.30 + treasury 60.0 for gpA', () {
      final result = computeFirstRightCredits(
        filledDeals: [_otherBuyDeal()],
        purchasedTileIndex: _index([_attr(_tileK1, _gpA, _minorM1)]),
        relationScoreFor: (gp, src) =>
            gp == _gpA && src == _minorM1 ? 75 : 0,
      );
      expect(result.creditedDeals, hasLength(1));
      final credit = result.creditedDeals.single;
      expect(credit.owningGpId, _gpA);
      expect(credit.sourceFactionId, _minorM1);
      expect(credit.relationScore, 75);
      expect(credit.profit.profitRate, closeTo(0.30, 1e-12));
      expect(credit.profit.profitTreasury, closeTo(60.0, 1e-12));
      expect(result.treasuryCreditByGpId[_gpA], closeTo(60.0, 1e-12));
      expect(result.totalProfitTreasury, closeTo(60.0, 1e-12));
    });
  });

  group('AC #3 — relation 100 credits exactly 40% of sale value', () {
    test(
      'credits helper produces rate kFirstRightMaxProfitRate (0.40) and '
      'treasury == 0.40 * quantity * pricePerUnit',
      () {
        final result = computeFirstRightCredits(
          filledDeals: [
            _otherBuyDeal(quantity: 5, pricePerUnit: 8.0),
          ],
          purchasedTileIndex: _index([_attr(_tileK1, _gpA, _minorM1)]),
          relationScoreFor: (_, _) => 100,
        );
        expect(result.creditedDeals, hasLength(1));
        expect(
          result.creditedDeals.single.profit.profitRate,
          kFirstRightMaxProfitRate,
        );
        // 5 * 8 * 0.40 = 16.0 (exactly 40% of the 40.0 sale value).
        expect(result.totalProfitTreasury, closeTo(16.0, 1e-12));
        expect(result.treasuryCreditByGpId[_gpA], closeTo(16.0, 1e-12));
      },
    );
  });

  group('AC #4 — relation 0 credits 0 treasury (no overseas profit)', () {
    test(
      'credits helper records audit row but transfers 0 treasury (Deal '
      'Book can still surface the no-credit case)',
      () {
        final result = computeFirstRightCredits(
          filledDeals: [_otherBuyDeal()],
          purchasedTileIndex: _index([_attr(_tileK1, _gpA, _minorM1)]),
          relationScoreFor: (_, _) => 0,
        );
        expect(result.creditedDeals, hasLength(1));
        expect(
          result.creditedDeals.single.profit,
          FirstRightProfit.zero,
        );
        expect(result.treasuryCreditByGpId[_gpA], 0.0);
        expect(result.totalProfitTreasury, 0.0);
      },
    );

    test(
      'negative — buyer == owning GP (D2 FRR-match path) excluded from '
      'D4 aggregation: no double-credit when gpA wins the offer itself',
      () {
        final result = computeFirstRightCredits(
          filledDeals: [
            FilledDeal(
              sellerFactionId: _minorM1,
              buyerFactionId: _gpA,
              commodityId: 'timber',
              quantity: 10,
              pricePerUnit: 20.0,
              isFirstRightOfRefusalMatch: true,
              sellerOriginTileKey: _tileK1,
            ),
          ],
          purchasedTileIndex: _index([_attr(_tileK1, _gpA, _minorM1)]),
          relationScoreFor: (_, _) => 100,
        );
        expect(result.creditedDeals, isEmpty);
        expect(result.treasuryCreditByGpId, isEmpty);
        expect(result.totalProfitTreasury, 0.0);
      },
    );
  });

  group('AC #5 — multi-GP attribution, no cross-credit', () {
    test(
      'k1 (gpA, relation 100) + k2 (gpB, relation 50) → gpA 24.0, gpB '
      '8.0; neither GP is credited for the other GP\'s purchased tile',
      () {
        final result = computeFirstRightCredits(
          filledDeals: [
            _otherBuyDeal(
              buyer: _gpC,
              quantity: 6,
              pricePerUnit: 10.0,
              sellerOriginTileKey: _tileK1,
            ),
            _otherBuyDeal(
              buyer: _gpC,
              quantity: 4,
              pricePerUnit: 10.0,
              sellerOriginTileKey: _tileK2,
            ),
          ],
          purchasedTileIndex: _index([
            _attr(_tileK1, _gpA, _minorM1),
            _attr(_tileK2, _gpB, _minorM1),
          ]),
          relationScoreFor: (gp, src) {
            if (gp == _gpA && src == _minorM1) return 100; // 40%
            if (gp == _gpB && src == _minorM1) return 50; // 20%
            return 0;
          },
        );
        expect(
          result.treasuryCreditByGpId.keys,
          containsAll(<String>[_gpA, _gpB]),
        );
        // gpA: 6*10*0.40 = 24.0 (k1 only, never credited for k2)
        expect(result.treasuryCreditByGpId[_gpA], closeTo(24.0, 1e-12));
        // gpB: 4*10*0.20 = 8.0 (k2 only, never credited for k1)
        expect(result.treasuryCreditByGpId[_gpB], closeTo(8.0, 1e-12));
        expect(result.totalProfitTreasury, closeTo(32.0, 1e-12));
      },
    );

    test(
      'same owning GP across two minors aggregates per source relation '
      'independently (k1@M1 relation 100 + k3@M2 relation 25 → gpA 18.0)',
      () {
        final result = computeFirstRightCredits(
          filledDeals: [
            _otherBuyDeal(
              buyer: _gpC,
              quantity: 5,
              pricePerUnit: 8.0,
              sellerOriginTileKey: _tileK1,
            ),
            FilledDeal(
              sellerFactionId: _minorM2,
              buyerFactionId: _gpC,
              commodityId: 'timber',
              quantity: 2,
              pricePerUnit: 10.0,
              sellerOriginTileKey: _tileK3,
            ),
          ],
          purchasedTileIndex: _index([
            _attr(_tileK1, _gpA, _minorM1),
            _attr(_tileK3, _gpA, _minorM2, _provinceM2),
          ]),
          relationScoreFor: (gp, src) {
            if (gp == _gpA && src == _minorM1) return 100; // 40%
            if (gp == _gpA && src == _minorM2) return 25; // 10%
            return 0;
          },
        );
        // k1: 5*8*0.40 = 16.0 + k3: 2*10*0.10 = 2.0 = 18.0
        expect(result.creditedDeals, hasLength(2));
        expect(result.treasuryCreditByGpId.keys, [_gpA]);
        expect(result.treasuryCreditByGpId[_gpA], closeTo(18.0, 1e-12));
        expect(result.totalProfitTreasury, closeTo(18.0, 1e-12));
      },
    );
  });
}
