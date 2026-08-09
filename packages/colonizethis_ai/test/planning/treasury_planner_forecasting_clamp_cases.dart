// Case bodies for `treasury_planner_forecasting_test.dart` (Refs #4291 Slice D).

/// Treasury planner partial-fill-aware forecasting and speculative-bid passes
/// (Refs #2994 F8; Refs #2924 F10/F16).
///
/// Split out of `treasury_planner_test.dart` to keep each file at or below the
/// 1000 non-comment-line repo-lint ceiling.
library;

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'treasury_planner_main_support.dart';



void registerTreasuryPlannerForecastingClampCases() {
  group('runTreasuryPlanner partial-fill-aware forecasting (Refs #2994 F8)', () {
    Stockpile stockpileWellStockedExcept(
      Iterable<CommodityId> excluded,
    ) {
      final excludedSet = excluded.toSet();
      var stockpile = const Stockpile();
      for (final commodity in CommodityCatalog.all) {
        if (richesCommodityIds.contains(commodity.id)) continue;
        if (excludedSet.contains(commodity.id)) continue;
        stockpile = stockpile.applyDelta(
          commodity.id,
          kSpeculativeBidStockpileTarget * 4,
        );
      }
      return stockpile;
    }

    test(
      'affluent treasury without embassy with no prior market activity '
      'emits speculative bids for each eligible food commodity up to the '
      'baseline bid-type cap (Refs #2924 F10, #4186 embassy-free cap)',
      () {
        final affluent = treasuryAffluenceThreshold();
        final stockpile = stockpileWellStockedExcept(const ['grain', 'meat'])
            .applyDelta('timber', 80);
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: affluent,
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: affluent,
        ));
        final bids = orders
            .where((o) => o.type == TradeOrderType.bid)
            .toList();
        expect(
          bids,
          hasLength(2),
          reason:
              'Grain and meat are the only food commodities below the '
              'speculative target; baseline cap (3) allows both.',
        );
        expect(
          bids.map((b) => b.commodityId).toList(),
          ['grain', 'meat'],
          reason:
              'Without prior MarketActivity, speculative bids fill '
              'alphabetical food commodities below target.',
        );
        for (final bid in bids) {
          expect(bid.quantity, kSpeculativeBidStockpileTarget);
          expect(richesCommodityIds.contains(bid.commodityId), isFalse);
          expect(
            bid.commodityId,
            isNot('timber'),
            reason: 'Available-side timber is excluded from speculative bids.',
          );
          expect(
            CommodityCatalog.byId[bid.commodityId]?.category,
            CommodityCategory.food,
          );
        }
      },
    );

    test(
      'affluent treasury without embassy and a liquid commodity in '
      'lastTurnActivity bids for that commodity (Refs #2924 F10 — '
      'liquidity-aware selection)',
      () {
        final affluent = treasuryAffluenceThreshold();
        final stockpile = stockpileWellStockedExcept(const ['iron'])
            .applyDelta('timber', 80);
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: affluent,
        ).copyWith(
          worldMarketState: WorldMarketState(
            prices: {
              CommodityCatalog.iron.id: 10,
            },
            lastTurnActivity: const {
              'iron': MarketActivity(
                totalOfferQuantity: 500,
                filledQuantity: 0,
              ),
            },
          ),
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: affluent,
        ));
        final bids = orders
            .where((o) => o.type == TradeOrderType.bid)
            .toList();
        expect(bids, hasLength(1));
        expect(
          bids.single.commodityId,
          'iron',
          reason:
              'iron has prior-turn offer volume so the liquidity-aware '
              'selector picks it for the single baseline-cap bid slot.',
        );
      },
    );

    test(
      'affluent treasury still suppresses speculative bid when projected '
      'stockpile of every non-riches commodity already meets the target '
      '(Refs #2924 F10)',
      () {
        final affluent = treasuryAffluenceThreshold();
        var stockpile = const Stockpile();
        for (final commodity in CommodityCatalog.all) {
          if (richesCommodityIds.contains(commodity.id)) continue;
          stockpile = stockpile.applyDelta(
            commodity.id,
            kSpeculativeBidStockpileTarget + 4,
          );
        }
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: affluent,
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: affluent,
        ));
        expect(
          orders.where((o) => o.type == TradeOrderType.bid),
          isEmpty,
          reason:
              'Every commodity already meets kSpeculativeBidStockpileTarget '
              'so the speculative pass has no positive deficit to emit.',
        );
      },
    );

    test(
      'below the affluence threshold the speculative pass stays off '
      '(Refs #2924 F10 — gate is treasuryAffluenceThreshold())',
      () {
        final justBelow = treasuryAffluenceThreshold() - 1;
        var stockpile = const Stockpile().applyDelta('timber', 80);
        for (final commodity in CommodityCatalog.all) {
          if (richesCommodityIds.contains(commodity.id)) continue;
          if (commodity.id == 'timber') continue;
          stockpile = stockpile.applyDelta(
            commodity.id,
            kSpeculativeBidStockpileTarget * 4,
          );
        }
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: justBelow,
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: justBelow,
        ));
        expect(
          orders.where((o) => o.type == TradeOrderType.bid),
          isEmpty,
          reason:
              'Below treasuryAffluenceThreshold() the speculative-bid '
              'pass must remain inactive; no deficit bids either because '
              'every non-riches commodity is well-stocked.',
        );
      },
    );

    test(
      'speculative pass output is deterministic across identical inputs '
      '(Refs #2924 F10)',
      () {
        final affluent = treasuryAffluenceThreshold();
        final stockpile = const Stockpile().applyDelta('timber', 80);
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: affluent,
        );
        final a = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: affluent,
        ));
        final b = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: affluent,
        ));
        expect(a, b);
      },
    );

    test(
      'deterministic with carry-forward and prior activity state populated',
      () {
        final stockpile = const Stockpile().applyDelta('timber', 80);
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: 0,
        ).copyWith(
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 20},
            lastTurnActivity: {
              CommodityCatalog.timber.id: const MarketActivity(
                totalOfferQuantity: 40,
                filledQuantity: 10,
              ),
            },
            carryForwardOffersByFactionId: {
              'gp1': [
                TradeOrder(
                  commodityId: CommodityCatalog.timber.id,
                  type: TradeOrderType.offer,
                  quantity: 20,
                  priority: kTreasuryOfferPriorityUrgent,
                ),
              ],
            },
          ),
        );
        final a = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        ));
        final b = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        ));
        expect(a, b);
      },
    );
  });
}
