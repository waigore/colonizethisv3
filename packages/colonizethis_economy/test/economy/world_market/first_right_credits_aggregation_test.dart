import 'package:colonizethis_economy/src/economy/world_market/first_right_credits.dart';
import 'package:colonizethis_test/test.dart';

import 'first_right_credits_test_support.dart';

void main() {
  group('computeFirstRightCredits aggregation (#3753 R8.2 full share)', () {
    test('multi-tile — two owning GPs aggregate credits independently', () {
      final result = computeFirstRightCredits(
        filledDeals: [
          // gpA owns k1 from M1 — gpC buys 10 @ 10, relation 100 → 100.0
          deal(
            buyer: 'gpC',
            quantity: 10,
            pricePerUnit: 10.0,
            sellerOriginTileKey: 'k1',
          ),
          // gpB owns k2 from M1 — gpC buys 4 @ 5, relation 50 → 10.0
          deal(
            buyer: 'gpC',
            quantity: 4,
            pricePerUnit: 5.0,
            sellerOriginTileKey: 'k2',
          ),
          // gpA owns k3 from M2 — gpC buys 2 @ 3, relation 25 → 1.5
          deal(
            buyer: 'gpC',
            quantity: 2,
            pricePerUnit: 3.0,
            sellerOriginTileKey: 'k3',
          ),
        ],
        purchasedTileIndex: idx([
          attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
          attr(tileKey: 'k2', owningGpId: 'gpB', sourceFactionId: 'M1'),
          attr(tileKey: 'k3', owningGpId: 'gpA', sourceFactionId: 'M2'),
        ]),
        relationScoreFor: (gp, src) {
          if (gp == 'gpA' && src == 'M1') return 100; // 100%
          if (gp == 'gpB' && src == 'M1') return 50; // 50%
          if (gp == 'gpA' && src == 'M2') return 25; // 25%
          return 0;
        },
      );
      // 10*10*1.0 = 100.0, 2*3*0.25 = 1.5 → gpA gets 101.5
      // 4*5*0.50 = 10.0 → gpB gets 10.0
      expect(result.treasuryCreditByGpId.keys, containsAll(['gpA', 'gpB']));
      expect(result.treasuryCreditByGpId['gpA']!, closeTo(101.5, 1e-12));
      expect(result.treasuryCreditByGpId['gpB']!, closeTo(10.0, 1e-12));
      expect(result.totalProfitTreasury, closeTo(111.5, 1e-12));
      expect(result.creditedDeals, hasLength(3));
    });

    test(
      'multi-GP precedence — buyer == owning GP for one tile, other-GP buyer for another',
      () {
        // The two purchased tiles share the same source minor M1 and
        // owning GP gpA. The first deal is gpA's own purchase (D2 FRR-match
        // path), the second is gpB buying the residual — only the second
        // should generate a D4 credit.
        final result = computeFirstRightCredits(
          filledDeals: [
            deal(
              buyer: 'gpA',
              isFirstRightOfRefusalMatch: true,
              quantity: 4,
              pricePerUnit: 10.0,
              sellerOriginTileKey: 'k1',
            ),
            deal(
              buyer: 'gpB',
              quantity: 6,
              pricePerUnit: 10.0,
              sellerOriginTileKey: 'k1',
            ),
          ],
          purchasedTileIndex: idx([
            attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
          ]),
          relationScoreFor: (_, _) => 100,
        );
        // Only gpB's purchase is in D4 scope; 6 * 10 * 1.0 = 60.0 (full share)
        expect(result.creditedDeals, hasLength(1));
        expect(result.creditedDeals.single.deal.buyerFactionId, 'gpB');
        expect(result.treasuryCreditByGpId, {'gpA': closeTo(60.0, 1e-12)});
        expect(result.totalProfitTreasury, closeTo(60.0, 1e-12));
      },
    );

    test(
      'deterministic — identical inputs return identical credit/aggregation order',
      () {
        FirstRightCreditsResult run() => computeFirstRightCredits(
          filledDeals: [
            deal(
              buyer: 'gpC',
              quantity: 1,
              pricePerUnit: 5.0,
              sellerOriginTileKey: 'k2',
            ),
            deal(
              buyer: 'gpC',
              quantity: 2,
              pricePerUnit: 5.0,
              sellerOriginTileKey: 'k1',
            ),
            deal(
              buyer: 'gpC',
              quantity: 3,
              pricePerUnit: 5.0,
              sellerOriginTileKey: 'k2',
            ),
          ],
          purchasedTileIndex: idx([
            attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
            attr(tileKey: 'k2', owningGpId: 'gpB', sourceFactionId: 'M1'),
          ]),
          relationScoreFor: (_, _) => 100,
        );
        final first = run();
        final second = run();
        expect(
          first.treasuryCreditByGpId.keys.toList(),
          equals(second.treasuryCreditByGpId.keys.toList()),
        );
        for (final key in first.treasuryCreditByGpId.keys) {
          expect(
            first.treasuryCreditByGpId[key],
            equals(second.treasuryCreditByGpId[key]),
          );
        }
        expect(first.creditedDeals.length, second.creditedDeals.length);
        // First emission order — gpB (k2) then gpA (k1).
        expect(
          first.treasuryCreditByGpId.keys.first,
          'gpB',
          reason: 'insertion order tracks first deal mentioning each owning GP',
        );
      },
    );
  });
}
