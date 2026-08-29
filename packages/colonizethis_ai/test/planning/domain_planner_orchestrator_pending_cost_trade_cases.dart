// Case bodies for `domain_planner_orchestrator_pending_cost_trade_test.dart`
// (Refs #3122).

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_spy_trade_scenarios.dart';
import '../support/domain_planner_orchestrator_test_support.dart';
import '../support/domain_planner_test_fake_api.dart';
import 'domain_planner_orchestrator_pending_cost_trade_support.dart';

void registerDomainPlannerOrchestratorPendingCostTradeCases() {
  group(
    'Refs #3122 — orchestrator trade-order recompute with pending costs',
    () {
      test(
        'when the flag is set, the orchestrator picks a peasant_levies '
        'regiment build and the recomputed trade-order bid budget '
        'subtracts that pending treasury cost',
        () {
          final stockpile = const Stockpile()
              .applyDelta('wool', 4)
              .applyDelta('fabric', 1);
          final game = buildOrchestratorPendingCostTradeScenarioGame(
            treasury: 4000,
            stockpile: stockpile,
          );
          const peasantBuild = BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: kOrchestratorOwHomeProvince,
          );
          const api = FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [],
            build: [peasantBuild],
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
          );
          final outcome = runPendingCostTradeOrchestrator(
            economyPlan: const EconomyPlan(
              productionAssignments: [
                AssignedRecipe(
                  recipeId: 'fabric_from_wool',
                  assignedLabour: 4,
                ),
              ],
              cargoPreference: CargoPreference.none,
              tradeOrders: <TradeOrder>[],
            ),
            game: game,
            api: api,
            recompute: true,
          );
          final builds =
              outcome.orders.buildUnitOrdersByPlayerId[kPendingCostTradeNationId];
          expect(builds, isNotNull);
          expect(builds!, hasLength(1));
          expect(builds.first.unitType, 'peasant_levies');

          const cheapestRegimentBuildTreasuryCost = 2000;
          final trades =
              outcome.orders.tradeOrdersByPlayerId[kPendingCostTradeNationId] ??
                  const [];
          final bidNotional = trades
              .where((o) => o.type == TradeOrderType.bid)
              .fold<int>(
                0,
                (sum, b) =>
                    sum +
                    b.quantity *
                        (game.worldMarketState.prices[b.commodityId] ?? 0)
                            .toInt(),
              );
          expect(
            bidNotional,
            lessThanOrEqualTo(4000 - cheapestRegimentBuildTreasuryCost),
            reason: 'Pending peasant_levies build (treasuryCost 2000) must '
                'reduce the recomputed trade-order bid budget below the '
                'remaining treasury of 2000.',
          );
          expect(
            outcome.domainGateData?.tradePlannerRan,
            trades.isNotEmpty,
          );
        },
      );

      test(
        'when the flag is set, mock economyPlan.tradeOrders are ignored '
        'and the orchestrator emits its own recomputed list',
        () {
          final mockTrade = <TradeOrder>[
            TradeOrder(
              commodityId: 'grain',
              type: TradeOrderType.bid,
              quantity: 99,
              priority: 1,
            ),
          ];
          final game = buildOrchestratorPendingCostTradeScenarioGame(
            treasury: 0,
            stockpile: const Stockpile().applyDelta('timber', 80),
          );
          const api = FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [],
            build: [],
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
          );
          final outcome = runPendingCostTradeOrchestrator(
            economyPlan: EconomyPlan(
              productionAssignments: const [],
              cargoPreference: CargoPreference.none,
              tradeOrders: mockTrade,
            ),
            game: game,
            api: api,
            recompute: true,
          );
          final trades =
              outcome.orders.tradeOrdersByPlayerId[kPendingCostTradeNationId] ??
                  const [];
          final survivedMock = trades.any(
            (o) =>
                o.commodityId == 'grain' &&
                o.type == TradeOrderType.bid &&
                o.quantity == 99,
          );
          expect(
            survivedMock,
            isFalse,
            reason:
                'recomputeTradeOrdersWithPendingCosts: true must ignore '
                'economyPlan.tradeOrders and call runTreasuryPlanner '
                'directly.',
          );
        },
      );

      test(
        'when the flag is unset (default), mock economyPlan.tradeOrders '
        'still flow through unchanged (existing F7 wiring contract)',
        () {
          final mockTrade = <TradeOrder>[
            TradeOrder(
              commodityId: 'fabric',
              type: TradeOrderType.offer,
              quantity: 3,
              priority: 5,
            ),
          ];
          final game = buildOrchestratorPendingCostTradeScenarioGame(
            treasury: 0,
            stockpile: const Stockpile(),
          );
          const api = FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [],
            build: [],
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
          );
          final outcome = runPendingCostTradeOrchestrator(
            economyPlan: EconomyPlan(
              productionAssignments: const [],
              cargoPreference: CargoPreference.none,
              tradeOrders: mockTrade,
            ),
            game: game,
            api: api,
            recompute: false,
          );
          final trades =
              outcome.orders.tradeOrdersByPlayerId[kPendingCostTradeNationId];
          expect(trades, isNotNull);
          expect(trades, hasLength(1));
          expect(trades!.first.commodityId, 'fabric');
          expect(trades.first.type, TradeOrderType.offer);
          expect(trades.first.quantity, 3);
        },
      );
    },
  );
}
