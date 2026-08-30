import 'package:colonizethis_economy/colonizethis_economy.dart'
    show defaultCargoHoldsStub;
import 'package:colonizethis_test/test.dart';

import '../support/world_market_test_support.dart';
import 'world_market_phase_extraction_cargo_cases.dart';

/// Cargo-released-by-extraction integration for the world market phase
/// (Refs #2990 B2 / SPEC/game/world-market.md § Cargo — AC *Cargo released
/// by under-used extraction*).
void main() {
  group('worldMarketTurnPhaseHandler — extraction tonnage subtraction '
      '(Refs #2990 B2)', () {
    test('tradeCapacity = homeFleetCargo − overseasShippedTonnage; '
        'bid partial-fills against the reduced cap', () {
      expect(defaultCargoHoldsStub, 24);
      final next = runWorldMarketPhaseFrom(
        pipeline: extractionCargoTimberPipeline(
          shippedTonnage: 12,
          sellerTimber: 30,
          buyerTreasury: 100000,
        ),
        orders: gpGpTimberTradeOrders(offerQuantity: 24, bidQuantity: 24),
      );

      final buyer = next.players.firstWhere(
        (p) => p.id == extractionCargoBuyerId,
      );
      expect(
        buyer.stockpile.quantityOf('timber'),
        12,
        reason:
            'bid capped by trade cargo capacity (24 stub − 12 extraction '
            'tonnage = 12 holds available for trade shipping)',
      );
      final carryBids = next
          .worldMarketState
          .carryForwardBidsByFactionId[extractionCargoBuyerId];
      expect(carryBids, isNotNull);
      expect(carryBids!.single.commodityId, 'timber');
      expect(
        carryBids.single.quantity,
        12,
        reason:
            'residual 12 units of the 24-unit bid carry forward at the '
            'original priority',
      );
    });

    test('overseas shipped tonnage ≥ home-fleet capacity clamps trade cargo '
        'to 0 — no fills, full bid carry-forward', () {
      final next = runWorldMarketPhaseFrom(
        pipeline: extractionCargoTimberPipeline(
          shippedTonnage: 24,
          sellerTimber: 10,
          buyerTreasury: 100000,
        ),
        orders: gpGpTimberTradeOrders(offerQuantity: 5, bidQuantity: 5),
      );

      final buyer = next.players.firstWhere(
        (p) => p.id == extractionCargoBuyerId,
      );
      expect(
        buyer.stockpile.quantityOf('timber'),
        0,
        reason: 'tradeCapacity clamped to 0 leaves zero room for fills',
      );
      expect(buyer.treasury, 100000, reason: 'no debit when no deal fills');
      final carryBids = next
          .worldMarketState
          .carryForwardBidsByFactionId[extractionCargoBuyerId];
      expect(carryBids, isNotNull);
      expect(carryBids!.single.quantity, 5);
    });

    test('overseas shipped tonnage exceeding home-fleet capacity does not '
        'underflow tradeCapacity (released-cargo clamp at 0)', () {
      final next = runWorldMarketPhaseFrom(
        pipeline: extractionCargoTimberPipeline(
          shippedTonnage: 999,
          sellerTimber: 5,
          buyerTreasury: 1000,
        ),
        orders: gpGpTimberTradeOrders(offerQuantity: 5, bidQuantity: 5),
      );

      final buyer = next.players.firstWhere(
        (p) => p.id == extractionCargoBuyerId,
      );
      expect(buyer.stockpile.quantityOf('timber'), 0);
      final carryBids = next
          .worldMarketState
          .carryForwardBidsByFactionId[extractionCargoBuyerId];
      expect(carryBids, isNotNull);
      expect(carryBids!.single.quantity, 5);
    });

    test('missing tonnage entry defaults to 0 — buyer keeps full home-fleet '
        'capacity (legacy contract preserved)', () {
      final next = runWorldMarketPhaseFrom(
        pipeline: extractionCargoTimberPipelineNoTonnageMap(
          sellerTimber: 5,
          buyerTreasury: 1000,
        ),
        orders: gpGpTimberTradeOrders(offerQuantity: 5, bidQuantity: 5),
      );

      final buyer = next.players.firstWhere(
        (p) => p.id == extractionCargoBuyerId,
      );
      expect(
        buyer.stockpile.quantityOf('timber'),
        5,
        reason:
            'no extraction tonnage on the pipeline state → full home-fleet '
            'cargo available for trade (matches the pre-B2 contract)',
      );
      expect(next.worldMarketState.carryForwardBidsByFactionId, isEmpty);
    });
  });
}
