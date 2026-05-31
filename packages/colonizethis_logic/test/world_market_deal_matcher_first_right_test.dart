import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'world_market_deal_matcher_test_support.dart';

/// SPEC: SPEC/game/world-market-first-right-of-refusal.md § Rules
/// (#2992 D2 — First Right of Refusal absolute-priority override in
/// `DealMatcher.matchDeals`). The behavior of the helper FRR profit
/// formula and the purchased-tile index is covered by D1/D3 tests; this
/// file exercises the matcher integration only.
void main() {
  PurchasedTileIndex frrIndex({
    String tileKey = 'oldWorld|M1|0|0',
    String owningGpId = 'gpA',
    String sourceFactionId = 'M1',
    String provinceId = 'oldWorld|M1',
  }) =>
      PurchasedTileIndex.forTesting([
        PurchasedTileAttribution(
          tileKey: tileKey,
          owningGpId: owningGpId,
          sourceFactionId: sourceFactionId,
          provinceId: provinceId,
        ),
      ]);

  group('DealMatcher.matchDeals — First Right of Refusal (#2992 D2)', () {
    test(
      'owning GP bid fills purchased-tile offer ahead of higher-priority '
      'bid from another GP (FRR overrides priority tier)',
      () {
        const tileKey = 'oldWorld|M1|0|0';
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'M1': [
                matcherOffer('timber', 10, originTileKey: tileKey),
              ],
            },
            bidsByFactionId: {
              // Owning GP only bids at the lowest precedence (priority 5).
              'gpA': [matcherBid('timber', 10, priority: 5)],
              // Rival GP bids at the highest precedence (priority 1).
              'gpB': [matcherBid('timber', 10, priority: 1)],
            },
            tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
            purchasedTileIndex: frrIndex(),
          ),
        );

        expect(result.filledDeals.length, 1);
        final deal = result.filledDeals.single;
        expect(deal.sellerFactionId, 'M1');
        expect(deal.buyerFactionId, 'gpA');
        expect(deal.commodityId, 'timber');
        expect(deal.quantity, 10);
        expect(deal.isFirstRightOfRefusalMatch, isTrue);
        expect(deal.isFtpMatch, isFalse);

        // Rival GP's bid carries forward intact (no offer remaining).
        expect(result.unfilledBidsByFactionId['gpB'], [
          matcherBid('timber', 10, priority: 1),
        ]);
        expect(result.unfilledOffersByFactionId, isEmpty);
      },
    );

    test(
      'FRR overrides FTP: owning GP bid fills purchased-tile offer before '
      'an FTP-paired bid at the same priority',
      () {
        const tileKey = 'oldWorld|M1|0|0';
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'M1': [
                matcherOffer('timber', 6, originTileKey: tileKey),
              ],
            },
            bidsByFactionId: {
              'gpA': [matcherBid('timber', 6, priority: 1)],
              'gpFtp': [matcherBid('timber', 6, priority: 1)],
            },
            tradeCapacityByFactionId: {'gpA': 100, 'gpFtp': 100},
            ftpPairKeys: {DealMatcher.pairKey('M1', 'gpFtp')},
            purchasedTileIndex: frrIndex(),
          ),
        );

        // Offer is consumed by FRR fill — FTP pair receives nothing.
        expect(result.filledDeals.length, 1);
        expect(result.filledDeals.single.buyerFactionId, 'gpA');
        expect(result.filledDeals.single.isFirstRightOfRefusalMatch, isTrue);
        expect(result.filledDeals.single.isFtpMatch, isFalse);

        expect(result.unfilledBidsByFactionId['gpFtp'], [
          matcherBid('timber', 6, priority: 1),
        ]);
      },
    );

    test(
      'no FRR override when owning GP does not bid: purchased-tile offer '
      'falls back to normal tier matching against other GPs',
      () {
        const tileKey = 'oldWorld|M1|0|0';
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'M1': [
                matcherOffer('timber', 10, originTileKey: tileKey),
              ],
            },
            bidsByFactionId: {
              // Owning GP gpA submits NO bid — fallthrough to gpB.
              'gpB': [matcherBid('timber', 10, priority: 1)],
            },
            tradeCapacityByFactionId: {'gpB': 100},
            purchasedTileIndex: frrIndex(),
          ),
        );

        expect(result.filledDeals.length, 1);
        final deal = result.filledDeals.single;
        expect(deal.buyerFactionId, 'gpB');
        // FRR did not apply — the deal flows through standard tier matching.
        expect(deal.isFirstRightOfRefusalMatch, isFalse);
        expect(deal.isFtpMatch, isFalse);
      },
    );

    test(
      'partial FRR fill: residual offer quantity becomes available for '
      'other GPs at their normal priority tier',
      () {
        const tileKey = 'oldWorld|M1|0|0';
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'M1': [
                matcherOffer('timber', 10, originTileKey: tileKey),
              ],
            },
            bidsByFactionId: {
              // Owning GP wants only 4 of the 10 offered units.
              'gpA': [matcherBid('timber', 4, priority: 5)],
              // Rival GP bids for the rest at priority 1.
              'gpB': [matcherBid('timber', 10, priority: 1)],
            },
            tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
            purchasedTileIndex: frrIndex(),
          ),
        );

        expect(result.filledDeals.length, 2);
        final frrDeal = result.filledDeals.firstWhere(
          (d) => d.isFirstRightOfRefusalMatch,
        );
        expect(frrDeal.buyerFactionId, 'gpA');
        expect(frrDeal.quantity, 4);

        final regularDeal = result.filledDeals.firstWhere(
          (d) => !d.isFirstRightOfRefusalMatch,
        );
        expect(regularDeal.buyerFactionId, 'gpB');
        expect(regularDeal.quantity, 6);

        expect(result.unfilledBidsByFactionId['gpB'], [
          matcherBid('timber', 4, priority: 1),
        ]);
        expect(result.unfilledOffersByFactionId, isEmpty);
      },
    );

    test(
      'cargo limit caps FRR fill (per-buyer cumulative cargo still applies)',
      () {
        const tileKey = 'oldWorld|M1|0|0';
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'M1': [
                matcherOffer('timber', 10, originTileKey: tileKey),
              ],
            },
            bidsByFactionId: {
              'gpA': [matcherBid('timber', 10, priority: 1)],
              'gpB': [matcherBid('timber', 10, priority: 1)],
            },
            // Owning GP only has cargo for 3 units this turn.
            tradeCapacityByFactionId: {'gpA': 3, 'gpB': 100},
            purchasedTileIndex: frrIndex(),
          ),
        );

        expect(result.filledDeals.length, 2);

        final frrDeal = result.filledDeals.firstWhere(
          (d) => d.isFirstRightOfRefusalMatch,
        );
        expect(frrDeal.buyerFactionId, 'gpA');
        expect(frrDeal.quantity, 3);

        final regularDeal = result.filledDeals.firstWhere(
          (d) => !d.isFirstRightOfRefusalMatch,
        );
        expect(regularDeal.buyerFactionId, 'gpB');
        expect(regularDeal.quantity, 7);

        expect(result.unfilledBidsByFactionId['gpA'], [
          matcherBid('timber', 7, priority: 1),
        ]);
      },
    );

    test(
      'offer without originTileKey is unaffected by FRR even when index '
      'has matching attributions',
      () {
        const tileKey = 'oldWorld|M1|0|0';
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              // Plain offer with no tile attribution — must not trigger FRR.
              'sellerX': [matcherOffer('timber', 10)],
            },
            bidsByFactionId: {
              'gpA': [matcherBid('timber', 10, priority: 5)],
              'gpB': [matcherBid('timber', 10, priority: 1)],
            },
            tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
            purchasedTileIndex: frrIndex(tileKey: tileKey),
          ),
        );

        // Highest-priority bid wins normally — gpB at priority 1.
        expect(result.filledDeals.length, 1);
        final deal = result.filledDeals.single;
        expect(deal.buyerFactionId, 'gpB');
        expect(deal.isFirstRightOfRefusalMatch, isFalse);
      },
    );

    test(
      'offer with originTileKey not present in index falls back to normal '
      'matching (no FRR)',
      () {
        const offerTileKey = 'oldWorld|M2|7|3';
        const indexTileKey = 'oldWorld|M1|0|0';
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'M2': [
                matcherOffer('timber', 10, originTileKey: offerTileKey),
              ],
            },
            bidsByFactionId: {
              'gpA': [matcherBid('timber', 10, priority: 5)],
              'gpB': [matcherBid('timber', 10, priority: 1)],
            },
            tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
            purchasedTileIndex: frrIndex(tileKey: indexTileKey),
          ),
        );

        expect(result.filledDeals.length, 1);
        final deal = result.filledDeals.single;
        // Standard tier matching: gpB at priority 1 outbids gpA at 5.
        expect(deal.buyerFactionId, 'gpB');
        expect(deal.isFirstRightOfRefusalMatch, isFalse);
      },
    );

    test(
      'null purchasedTileIndex disables FRR (legacy behavior preserved)',
      () {
        const tileKey = 'oldWorld|M1|0|0';
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'M1': [
                matcherOffer('timber', 10, originTileKey: tileKey),
              ],
            },
            bidsByFactionId: {
              'gpA': [matcherBid('timber', 10, priority: 5)],
              'gpB': [matcherBid('timber', 10, priority: 1)],
            },
            tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
          ),
        );

        // No FRR with a null index — gpB wins on priority 1.
        expect(result.filledDeals.length, 1);
        final deal = result.filledDeals.single;
        expect(deal.buyerFactionId, 'gpB');
        expect(deal.isFirstRightOfRefusalMatch, isFalse);
      },
    );

    test(
      'multiple purchased tiles owned by the same GP each route through FRR',
      () {
        const tileA = 'oldWorld|M1|0|0';
        const tileB = 'oldWorld|M1|1|0';
        final index = PurchasedTileIndex.forTesting(const [
          PurchasedTileAttribution(
            tileKey: tileA,
            owningGpId: 'gpA',
            sourceFactionId: 'M1',
            provinceId: 'oldWorld|M1',
          ),
          PurchasedTileAttribution(
            tileKey: tileB,
            owningGpId: 'gpA',
            sourceFactionId: 'M1',
            provinceId: 'oldWorld|M1',
          ),
        ]);
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'M1': [
                matcherOffer('timber', 5, originTileKey: tileA),
                matcherOffer('timber', 5, originTileKey: tileB),
              ],
            },
            bidsByFactionId: {
              // Single bid for 10 units — must consume both purchased tiles.
              'gpA': [matcherBid('timber', 10, priority: 1)],
            },
            tradeCapacityByFactionId: {'gpA': 100},
            purchasedTileIndex: index,
          ),
        );

        expect(result.filledDeals.length, 2);
        for (final deal in result.filledDeals) {
          expect(deal.buyerFactionId, 'gpA');
          expect(deal.quantity, 5);
          expect(deal.isFirstRightOfRefusalMatch, isTrue);
        }
        expect(result.unfilledOffersByFactionId, isEmpty);
        expect(result.unfilledBidsByFactionId, isEmpty);
      },
    );

    test(
      'FRR pass respects multiple bids from the owning GP in submission order',
      () {
        const tileKey = 'oldWorld|M1|0|0';
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'M1': [
                matcherOffer('timber', 10, originTileKey: tileKey),
              ],
            },
            bidsByFactionId: {
              // Owning GP submits two bids — first 4, then 8 — total 12.
              // FRR should fill 4 from first bid, then 6 from second.
              'gpA': [
                matcherBid('timber', 4, priority: 1),
                matcherBid('timber', 8, priority: 5),
              ],
            },
            tradeCapacityByFactionId: {'gpA': 100},
            purchasedTileIndex: frrIndex(),
          ),
        );

        expect(result.filledDeals.length, 2);
        for (final deal in result.filledDeals) {
          expect(deal.buyerFactionId, 'gpA');
          expect(deal.isFirstRightOfRefusalMatch, isTrue);
        }
        expect(result.filledDeals[0].quantity, 4);
        expect(result.filledDeals[1].quantity, 6);

        // Second bid carries forward residual 2.
        expect(result.unfilledBidsByFactionId['gpA'], [
          matcherBid('timber', 2, priority: 5),
        ]);
      },
    );
  });

  group(
    'DealMatcher.matchDeals — FRR activity bookkeeping (#2992 D2)',
    () {
      test(
        'FRR fills count toward filledQuantity in the per-commodity activity',
        () {
          const tileKey = 'oldWorld|M1|0|0';
          final result = DealMatcher.matchDeals(
            matcherInputs(
              offersByFactionId: {
                'M1': [
                  matcherOffer('timber', 10, originTileKey: tileKey),
                ],
              },
              bidsByFactionId: {
                'gpA': [matcherBid('timber', 6, priority: 5)],
                'gpB': [matcherBid('timber', 6, priority: 1)],
              },
              tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
              purchasedTileIndex: frrIndex(),
            ),
          );

          // 6 fill via FRR, 4 fill via tier matching → 10 total filled.
          expect(
            result.activityByCommodityId['timber'],
            const MarketActivity(
              totalBidQuantity: 12,
              totalOfferQuantity: 10,
              filledQuantity: 10,
            ),
          );
        },
      );
    },
  );

  group('PurchasedTileIndex.forTesting (#2992 D2 test helper)', () {
    test('builds an index from explicit attributions', () {
      const attribution = PurchasedTileAttribution(
        tileKey: 'oldWorld|M1|0|0',
        owningGpId: 'gpA',
        sourceFactionId: 'M1',
        provinceId: 'oldWorld|M1',
      );
      final index = PurchasedTileIndex.forTesting([attribution]);
      expect(index.length, 1);
      expect(index.attributionForTileKey('oldWorld|M1|0|0'), attribution);
      expect(index.attributionForTileKey('missing'), isNull);
    });

    test('first attribution per tileKey wins on duplicates', () {
      const first = PurchasedTileAttribution(
        tileKey: 'oldWorld|M1|0|0',
        owningGpId: 'gpA',
        sourceFactionId: 'M1',
        provinceId: 'oldWorld|M1',
      );
      const second = PurchasedTileAttribution(
        tileKey: 'oldWorld|M1|0|0',
        owningGpId: 'gpB',
        sourceFactionId: 'M1',
        provinceId: 'oldWorld|M1',
      );
      final index = PurchasedTileIndex.forTesting([first, second]);
      expect(index.length, 1);
      expect(index.attributionForTileKey('oldWorld|M1|0|0'), first);
    });

    test('empty input yields empty index', () {
      final index = PurchasedTileIndex.forTesting(const []);
      expect(index.length, 0);
      expect(index.isEmpty, isTrue);
    });
  });
}
