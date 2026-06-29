// Embassy overseas-profit kickback (#3753 R8.3) aggregation tests for
// `computeFirstRightCredits`.
//
// SPEC: `SPEC/game/world-market-first-right-of-refusal.md` § Profit formula
// (D3, AC-7) and § Treasury transfer (D4, AC-D4-7/AC-D4-8). The kickback path
// credits every embassy-holding GP that does NOT own the sourcing tile a 10%
// share of its relation portion, including on sales with no purchased-tile
// attribution (R8.6); the tile owner is excluded from the kickback (R8.5) but
// still receives its full tile-owner share.

import 'package:colonizethis_economy/src/economy/world_market/first_right_credits.dart';
import 'package:colonizethis_test/test.dart';

import 'first_right_credits_test_support.dart';

void main() {
  group('computeFirstRightCredits embassy kickbacks (#3753 R8.3)', () {
    test(
      'non-owner embassy GP receives 10% kickback while tile owner gets full '
      'share and no kickback',
      () {
        final result = computeFirstRightCredits(
          filledDeals: [
            deal(
              buyer: 'gpB',
              quantity: 10,
              pricePerUnit: 20.0,
              sellerOriginTileKey: 'k1',
            ),
          ],
          purchasedTileIndex: idx([
            attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
          ]),
          relationScoreFor: (gp, src) => gp == 'gpA' && src == 'M1' ? 100 : 0,
          embassyGpRelationsFor: (src) =>
              src == 'M1' ? const {'gpA': 100, 'gpC': 50} : const {},
        );
        // Tile owner gpA: full share 10*20*1.0 = 200.0, no kickback (R8.5).
        expect(result.treasuryCreditByGpId['gpA'], closeTo(200.0, 1e-12));
        expect(result.embassyKickbackByGpId.containsKey('gpA'), isFalse);
        // Non-owner embassy gpC: kickback 10*20*0.5*0.10 = 10.0.
        expect(result.embassyKickbackByGpId['gpC'], closeTo(10.0, 1e-12));
        expect(result.totalEmbassyKickback, closeTo(10.0, 1e-12));
      },
    );

    test('R8.6 — kickback applies on Minor/Tribe sale with no purchased tile', () {
      final result = computeFirstRightCredits(
        filledDeals: [deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
        purchasedTileIndex: idx(const []),
        relationScoreFor: (_, _) => 0,
        embassyGpRelationsFor: (src) =>
            src == 'M1' ? const {'gpC': 50} : const {},
      );
      // No tile-owner share; gpC still gets the 10% relation-portion kickback.
      expect(result.treasuryCreditByGpId, isEmpty);
      expect(result.embassyKickbackByGpId['gpC'], closeTo(10.0, 1e-12));
    });

    test(
      'R8.7 — buyer == tile owner: no tile-owner share, other embassy GPs '
      'still get kickbacks',
      () {
        final result = computeFirstRightCredits(
          filledDeals: [
            deal(
              buyer: 'gpA',
              quantity: 10,
              pricePerUnit: 20.0,
              sellerOriginTileKey: 'k1',
            ),
          ],
          purchasedTileIndex: idx([
            attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
          ]),
          relationScoreFor: (_, _) => 100,
          embassyGpRelationsFor: (src) =>
              src == 'M1' ? const {'gpA': 100, 'gpC': 50} : const {},
        );
        // gpA is the buyer+owner: no tile-owner overseas profit, no kickback.
        expect(result.treasuryCreditByGpId, isEmpty);
        expect(result.embassyKickbackByGpId.containsKey('gpA'), isFalse);
        // gpC still receives its kickback.
        expect(result.embassyKickbackByGpId['gpC'], closeTo(10.0, 1e-12));
      },
    );

    test('no embassy holders → no kickbacks (empty callback result)', () {
      final result = computeFirstRightCredits(
        filledDeals: [
          deal(
            buyer: 'gpB',
            quantity: 10,
            pricePerUnit: 20.0,
            sellerOriginTileKey: 'k1',
          ),
        ],
        purchasedTileIndex: idx([
          attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
        ]),
        relationScoreFor: (_, _) => 100,
        embassyGpRelationsFor: (_) => const {},
      );
      expect(result.embassyKickbackByGpId, isEmpty);
      expect(result.totalEmbassyKickback, 0.0);
      // Tile-owner full share still applies.
      expect(result.treasuryCreditByGpId['gpA'], closeTo(200.0, 1e-12));
    });

    test('relation-0 embassy holder records no kickback', () {
      final result = computeFirstRightCredits(
        filledDeals: [deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
        purchasedTileIndex: idx(const []),
        relationScoreFor: (_, _) => 0,
        embassyGpRelationsFor: (src) =>
            src == 'M1' ? const {'gpC': 0} : const {},
      );
      expect(result, same(FirstRightCreditsResult.empty));
    });
  });
}
