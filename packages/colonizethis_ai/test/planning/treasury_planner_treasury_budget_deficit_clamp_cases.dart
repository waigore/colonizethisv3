// Case bodies for `treasury_planner_treasury_budget_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_treasury_budget_support.dart';

void registerTreasuryPlannerTreasuryBudgetDeficitClampCases() {
  group('runTreasuryPlanner per-bid treasury clamp — deficit path (Refs #3122)', () {
    test(
      'pending BuildUnitOrder treasury cost reduces budget so a fabric '
      'deficit bid is sized within the remaining treasury',
      () {
        // Setup: deficit demand for fabric via wool production assignment.
        // Pending peasant_levies build costs 2000 treasury. Treasury 4000 →
        // budget 2000. Fabric price 40 → maxAffordable 50, but cargo 24 →
        // cargo dominates. Cumulative bid notional ≤ 2000.
        final stockpile = const Stockpile().applyDelta('wool', 4);
        const assignments = [
          AssignedRecipe(
            recipeId: 'fabric_from_wool',
            assignedLabour: 4,
          ),
        ];
        final game = treasuryBudgetTestGameFor(
          stockpile: stockpile,
          treasury: 4000,
          prices: {
            CommodityCatalog.fabric.id: 40,
            CommodityCatalog.wool.id: 50,
            CommodityCatalog.cotton.id: 50,
          },
          overtures: const [kTreasuryBudgetEmbassyOverture],
        );
        const peasantBuild = BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        );
        final currentOrders = const Orders(
          buildUnitOrdersByPlayerId: {
            kTreasuryBudgetGpId: [peasantBuild],
          },
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: kTreasuryBudgetGpId,
          stockpile: stockpile,
          productionAssignments: assignments,
          treasury: 4000,
          currentOrders: currentOrders,
        ));
        // Sum every bid notional against the effective price the planner uses.
        final totalNotional = treasuryBudgetTestBids(orders).fold<int>(
          0,
          (s, b) => s + b.quantity * (game.worldMarketState.prices[b.commodityId] ?? 0),
        );
        expect(
          totalNotional,
          lessThanOrEqualTo(2000),
          reason: 'Pending peasant_levies build (treasuryCost 2000) leaves '
              'budget 2000; cumulative bid notional must not exceed that.',
        );
      },
    );

    test(
      'carry-forward bid notional reduces remaining budget for new bids',
      () {
        // Treasury 4000, carry-forward timber bid notional = 2 * 20 = 40.
        // Without carry-forward, budget would be 4000; with it, ≤ 3960.
        // We verify only the upper bound: new fabric bid notional ≤ 3960.
        final stockpile = const Stockpile().applyDelta('wool', 4);
        const assignments = [
          AssignedRecipe(
            recipeId: 'fabric_from_wool',
            assignedLabour: 4,
          ),
        ];
        final game = treasuryBudgetTestGameFor(
          stockpile: stockpile,
          treasury: 4000,
          prices: {
            CommodityCatalog.fabric.id: 40,
            CommodityCatalog.timber.id: 20,
            CommodityCatalog.wool.id: 50,
            CommodityCatalog.cotton.id: 50,
          },
          carryForwardBidsByFactionId: {
            kTreasuryBudgetGpId: [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.bid,
                quantity: 2,
                priority: 3,
              ),
            ],
          },
          overtures: const [kTreasuryBudgetEmbassyOverture],
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: kTreasuryBudgetGpId,
          stockpile: stockpile,
          productionAssignments: assignments,
          treasury: 4000,
        ));
        final totalNotional = treasuryBudgetTestBids(orders).fold<int>(
          0,
          (s, b) => s + b.quantity * (game.worldMarketState.prices[b.commodityId] ?? 0),
        );
        expect(
          totalNotional,
          lessThanOrEqualTo(4000 - 2 * 20),
          reason: 'Carry-forward timber bid notional of 40 already commits '
              'part of treasury; the new bid notional sum must respect the '
              'remaining 3960.',
        );
      },
    );

    test(
      'treasury below pricePerUnit suppresses the deficit bid entirely '
      'and does not waste the bidTypeCap slot',
      () {
        // Treasury 30 cannot afford a single fabric unit at price 40.
        // The fabric bid is dropped without consuming the bid slot.
        final stockpile = const Stockpile().applyDelta('wool', 4);
        const assignments = [
          AssignedRecipe(
            recipeId: 'fabric_from_wool',
            assignedLabour: 4,
          ),
        ];
        final game = treasuryBudgetTestGameFor(
          stockpile: stockpile,
          treasury: 30,
          prices: {
            CommodityCatalog.fabric.id: 40,
            CommodityCatalog.wool.id: 50,
          },
          overtures: const [kTreasuryBudgetEmbassyOverture],
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: kTreasuryBudgetGpId,
          stockpile: stockpile,
          productionAssignments: assignments,
          treasury: 30,
        ));
        final fabricBids = treasuryBudgetTestBids(orders)
            .where((b) => b.commodityId == CommodityCatalog.fabric.id);
        expect(
          fabricBids,
          isEmpty,
          reason: 'Treasury below pricePerUnit must drop the fabric bid '
              'rather than emitting a 0-quantity placeholder.',
        );
      },
    );
    test(
      'treasury == 0 with deficit path active emits no bid orders '
      '(AC1 strict boundary)',
      () {
        final stockpile = const Stockpile().applyDelta('wool', 4);
        const assignments = [
          AssignedRecipe(
            recipeId: 'fabric_from_wool',
            assignedLabour: 4,
          ),
        ];
        final game = treasuryBudgetTestGameFor(
          stockpile: stockpile,
          treasury: 0,
          prices: {
            CommodityCatalog.fabric.id: 40,
            CommodityCatalog.wool.id: 50,
          },
          overtures: const [kTreasuryBudgetEmbassyOverture],
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: kTreasuryBudgetGpId,
          stockpile: stockpile,
          productionAssignments: assignments,
          treasury: 0,
        ));
        expect(
          treasuryBudgetTestBids(orders),
          isEmpty,
          reason: 'AC1 strict: a GP at treasury == 0 with the deficit '
              'path active must emit zero bid orders — the per-bid '
              'treasury clamp drops the fabric bid before it can '
              'consume a bidTypeCap slot.',
        );
      },
    );

    test('runTreasuryPlanner remains deterministic with new clamp', () {
      final stockpile = const Stockpile()
          .applyDelta('timber', 80)
          .applyDelta('wool', 10);
      const assignments = [
        AssignedRecipe(
          recipeId: 'fabric_from_wool',
          assignedLabour: 4,
        ),
      ];
      final game = treasuryBudgetTestGameFor(
        stockpile: stockpile,
        treasury: cheapestRegimentBuildTreasuryCost() + 500,
        prices: {
          CommodityCatalog.fabric.id: 5,
          CommodityCatalog.timber.id: 20,
          CommodityCatalog.wool.id: 50,
        },
        overtures: const [kTreasuryBudgetEmbassyOverture],
      );
      final a = runTreasuryPlanner(TreasuryPlannerInput(
        game: game,
        playerId: kTreasuryBudgetGpId,
        stockpile: stockpile,
        productionAssignments: assignments,
        treasury: game.players.first.treasury,
      ));
      final b = runTreasuryPlanner(TreasuryPlannerInput(
        game: game,
        playerId: kTreasuryBudgetGpId,
        stockpile: stockpile,
        productionAssignments: assignments,
        treasury: game.players.first.treasury,
      ));
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].commodityId, b[i].commodityId);
        expect(a[i].quantity, b[i].quantity);
        expect(a[i].priority, b[i].priority);
        expect(a[i].type, b[i].type);
      }
    });
  });
}
