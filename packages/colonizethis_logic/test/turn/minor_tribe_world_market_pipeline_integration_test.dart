/// Full-pipeline integration tests for the Minor/Tribe → World Market path
/// (Refs #2991 C7).
///
/// Handler-level coverage lives in:
///   - `world_market_phase_minor_auto_offer_test.dart` (C4 auto-offer wiring)
///   - `riches_to_treasury_phase_purchased_tile_riches_test.dart` (C5 riches)
///   - `non_gp_auto_offers_purchased_tile_test.dart` (C6 parity invariant)
///
/// C7 closes the loop through [resolveTurnForGame] so phase ordering,
/// persistence, and cross-phase side effects (riches handoff vs market fill)
/// are exercised together.
///
/// SPEC anchors:
///   - SPEC/game/world-market.md § Minor and tribe auto-sell
///   - SPEC/game/world-market.md § First right of refusal § Riches handoff
///   - SPEC/program/world-market-resolution.md § Step A Gather (Step A.2)
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'minor_tribe_world_market_pipeline_integration_test_support.dart';
import 'riches_to_treasury_phase_purchased_tile_riches_test_support.dart';

void main() {
  group(
    'resolveTurnForGame — Minor/Tribe → World Market e2e (Refs #2991 C7)',
    () {
      test(
        'minor timber auto-offer fills a GP bid through the full turn pipeline '
        '(extraction connectivity → auto-offer → deal match → treasury sink)',
        () {
          const timberPrice = 30.0;
          final result = resolveTurnForGame(
            game: minorTimberAutoOfferPipelineGame(buyerTreasury: 1000),
            topology: kEmptyTopology,
            orders: timberBidOrdersForGp(gpId: 'gpBuyer'),
            tileMapByRegion: minorTimberTileMapByRegion(),
          );

          final next = requireTurnResolutionComplete(result);
          final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');

          expect(buyer.treasury, equals(1000 - timberPrice));
          expect(buyer.stockpile.quantityOf('timber'), equals(1));
          expect(next.worldState.turnState.turnNumber, equals(1));

          final activity = next.worldMarketState.lastTurnActivity['timber'];
          expect(activity, isNotNull);
          expect(activity!.filledQuantity, equals(1));
          expect(activity.deals, hasLength(1));
          expect(activity.deals.first.sellerFactionId, equals('m1'));
          expect(activity.deals.first.buyerFactionId, equals('gpBuyer'));
          expect(
            activity.deals.first.sellerOriginTileKey,
            equals('oldWorld|m1|0|0'),
          );
        },
      );

      test(
        'purchased-tile gold riches handoff credits the owning GP in phase 3 '
        'and the commodity never appears on the world market in phase 13',
        () {
          final base = gameWithPurchasedGoldTile(
            gpATreasury: 100,
            gpAStockpileGold: 0,
          );
          final result = resolveTurnForGame(
            game: base.copyWith(
              worldState: base.worldState.copyWith(
                turnState: const TurnState(
                  phase: TurnPhase.orders,
                  turnNumber: 0,
                ),
              ),
            ),
            topology: kEmptyTopology,
            orders: const Orders(),
            tileMapByRegion: tileMapByRegionForResource(Resource.gold),
          );

          final next = requireTurnResolutionComplete(result);
          final gpA = next.players.firstWhere((p) => p.id == 'gpA');

          expect(gpA.stockpile.quantityOf('gold'), equals(0));
          expect(
            gpA.treasury,
            equals(100 + richesBasePrice('gold')),
            reason:
                'phase 3 purchased-tile riches handoff credits the owning GP',
          );
          expect(
            next.worldMarketState.lastTurnActivity['gold'],
            isNull,
            reason: 'riches are excluded from world-market auto-offers',
          );
          expect(
            next.worldMarketState.lastTurnActivity,
            isEmpty,
            reason: 'no GP trade orders and no non-riches auto-offers',
          );
        },
      );

      test(
        'purchased-tile non-riches timber auto-offers through the market and '
        'fills when another GP bids (C5/C6 do not suppress market path)',
        () {
          const timberPrice = 25.0;
          final game = purchasedTimberBidPipelineGame(gpATreasury: 500);
          final result = resolveTurnForGame(
            game: game,
            topology: kEmptyTopology,
            orders: timberBidOrdersForGp(gpId: 'gpA'),
            tileMapByRegion: tileMapByRegionForResource(Resource.timber),
          );

          final next = requireTurnResolutionComplete(result);
          final gpA = next.players.firstWhere((p) => p.id == 'gpA');

          expect(gpA.treasury, equals(500 - timberPrice));
          expect(gpA.stockpile.quantityOf('timber'), equals(1));

          final activity = next.worldMarketState.lastTurnActivity['timber'];
          expect(activity, isNotNull);
          expect(activity!.filledQuantity, equals(1));
          expect(activity.deals.first.sellerFactionId, equals('M1'));
          expect(
            activity.deals.first.sellerOriginTileKey,
            equals('oldWorld|M1|0|0'),
          );
        },
      );

      test(
        'world market phase is dormant for minor auto-offers when '
        '`tileMapByRegion` is absent on the full pipeline config',
        () {
          final result = resolveTurnForGame(
            game: minorTimberAutoOfferPipelineGame(buyerTreasury: 1000),
            topology: kEmptyTopology,
            orders: timberBidOrdersForGp(gpId: 'gpBuyer'),
          );

          final next = requireTurnResolutionComplete(result);
          final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');

          expect(buyer.treasury, equals(1000));
          expect(buyer.stockpile.quantityOf('timber'), equals(0));
          final activity = next.worldMarketState.lastTurnActivity['timber'];
          expect(
            activity?.filledQuantity ?? 0,
            equals(0),
            reason: 'GP bid alone cannot fill without minor auto-offer',
          );
          expect(activity?.deals ?? const [], isEmpty);
        },
      );
    },
  );
}
