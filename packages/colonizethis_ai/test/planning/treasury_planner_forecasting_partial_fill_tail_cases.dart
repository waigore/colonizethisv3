// Tail case bodies for `treasury_planner_forecasting_partial_fill_cases.dart`.

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_main_support.dart';

void registerTreasuryPlannerForecastingPartialFillTailCases() {
  group('runTreasuryPlanner partial-fill-aware forecasting tail', () {
    test(
      'prior-turn zero fill rate keeps offer priority urgent below threshold',
      () {
        const treasury = 1000;
        final stockpile = const Stockpile().applyDelta('timber', 80);
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: treasury,
        ).copyWith(
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 20},
            lastTurnActivity: {
              CommodityCatalog.timber.id: const MarketActivity(
                totalOfferQuantity: 100,
                filledQuantity: 0,
              ),
            },
          ),
        );
        expect(
          treasury < cheapestRegimentBuildTreasuryCost(),
          isTrue,
          reason:
              'Test premise: treasury must be below the urgency threshold so '
              'fill-rate discounting alone determines the urgency switch.',
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: treasury,
        ));
        final timberOffer = orders.firstWhere(
          (o) =>
              o.commodityId == CommodityCatalog.timber.id &&
              o.type == TradeOrderType.offer,
        );
        expect(timberOffer.priority, kTreasuryOfferPriorityUrgent);
      },
    );

    test(
      'prior-turn full fill rate lifts forecast above threshold but keeps '
      'urgent offer priority while treasury below threshold (Refs #2924 F16)',
      () {
        const treasury = 1000;
        final stockpile = const Stockpile().applyDelta('timber', 80);
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: treasury,
        ).copyWith(
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 20},
            lastTurnActivity: {
              CommodityCatalog.timber.id: const MarketActivity(
                totalOfferQuantity: 100,
                filledQuantity: 100,
              ),
            },
          ),
        );
        expect(
          treasury < cheapestRegimentBuildTreasuryCost(),
          isTrue,
          reason:
              'Test premise: treasury must be below the regiment threshold so '
              'F16 keeps the offer urgent despite the clearing forecast.',
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: treasury,
        ));
        final timberOffer = orders.firstWhere(
          (o) =>
              o.commodityId == CommodityCatalog.timber.id &&
              o.type == TradeOrderType.offer,
        );
        expect(timberOffer.priority, kTreasuryOfferPriorityUrgent);
      },
    );
  });
}
