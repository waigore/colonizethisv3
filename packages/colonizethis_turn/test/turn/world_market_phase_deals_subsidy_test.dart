import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/src/turn/phases/world_market_phase_deals.dart';
import 'package:colonizethis_test/test.dart';

/// `applyDealsToPlayers` subsidy price adjustment (Refs #3753 R3.4).
///
/// SPEC anchors:
///
/// - `SPEC/game/world-market.md` § Subsidy price adjustment (Minor/Tribe deals).
/// - `SPEC/program/world-market-resolution.md` § Step D — Subsidy price
///   adjustment.
void main() {
  // gpA subsidises Minor M1; gpB is an unrelated GP buyer; M2 is a second
  // Minor that gpA does not subsidise. Only gpA participates as a GP in deals
  // with M1/M2 (minors are treasury sinks, never credited).
  List<Player> players() => const [
    Player(id: 'gpA', displayName: 'GP A', isHuman: true, treasury: 1000),
    Player(id: 'gpB', displayName: 'GP B', isHuman: false, treasury: 1000),
  ];

  FilledDeal deal({
    required String seller,
    required String buyer,
    int quantity = 10,
    double pricePerUnit = 20.0,
  }) => FilledDeal(
    sellerFactionId: seller,
    buyerFactionId: buyer,
    commodityId: 'timber',
    quantity: quantity,
    pricePerUnit: pricePerUnit,
  );

  int treasuryOf(List<Player> ps, String id) =>
      ps.firstWhere((p) => p.id == id).treasury;

  group('applyDealsToPlayers subsidy price adjustment (Refs #3753 R3.4)', () {
    test('R3.4b surcharge: GP buyer pays percent% extra to its subsidised '
        'Minor seller', () {
      final next = applyDealsToPlayers(
        players: players(),
        filledDeals: [deal(seller: 'm1', buyer: 'gpA')],
        subsidyPercentByPayerTargetKey: const {'gpA>m1': 10},
      );

      // base 10*20 = 200, +10% surcharge = 220 debited from the GP buyer.
      expect(treasuryOf(next, 'gpA'), 1000 - 220);
    });

    test('R3.4a discount: GP seller is credited percent% less when selling to '
        'its subsidised Minor buyer', () {
      final next = applyDealsToPlayers(
        players: players(),
        filledDeals: [deal(seller: 'gpA', buyer: 'm1')],
        subsidyPercentByPayerTargetKey: const {'gpA>m1': 20},
      );

      // base 10*20 = 200, -20% discount = 160 credited to the GP seller.
      // (Minor buyer is a sink: no buyer debit applied for a non-GP buyer.)
      expect(treasuryOf(next, 'gpA'), 1000 + 160);
    });

    test('R3.4 scoping: no adjustment for a deal with a non-subsidised '
        'counterparty', () {
      final next = applyDealsToPlayers(
        players: players(),
        filledDeals: [deal(seller: 'm2', buyer: 'gpA')],
        subsidyPercentByPayerTargetKey: const {'gpA>m1': 10},
      );

      // m2 is not subsidised by gpA → unadjusted notional 200 debited.
      expect(treasuryOf(next, 'gpA'), 1000 - 200);
    });

    test('empty subsidy map preserves legacy GP→GP transfer (no adjustment)',
        () {
      final next = applyDealsToPlayers(
        players: players(),
        filledDeals: [deal(seller: 'gpB', buyer: 'gpA')],
      );

      // GP↔GP transfer: buyer debited 200, seller credited 200 (conserved).
      expect(treasuryOf(next, 'gpA'), 1000 - 200);
      expect(treasuryOf(next, 'gpB'), 1000 + 200);
    });

    test('subsidy map does not alter GP↔GP deals even when a key is present',
        () {
      final next = applyDealsToPlayers(
        players: players(),
        filledDeals: [deal(seller: 'gpB', buyer: 'gpA')],
        subsidyPercentByPayerTargetKey: const {'gpA>m1': 20},
      );

      // The directed key targets m1, not gpB; the GP↔GP deal is unadjusted.
      expect(treasuryOf(next, 'gpA'), 1000 - 200);
      expect(treasuryOf(next, 'gpB'), 1000 + 200);
    });
  });
}
