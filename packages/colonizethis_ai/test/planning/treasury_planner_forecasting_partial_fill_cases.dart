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



void registerTreasuryPlannerForecastingPartialFillCases() {
  group('runTreasuryPlanner partial-fill-aware forecasting (Refs #2994 F8)', () {
    test(
      'carry-forward offer covers full surplus: no new timber offer emitted',
      () {
        // With stockpile=80 timber, projected reserve for a rawMaterial is
        // consumption(4) + inputs(0) + safety(4) = 8 → nominal surplus = 72.
        // A carry-forward of exactly 72 should drop new emission to zero.
        const carryForwardQuantity = 72;
        final stockpile = const Stockpile().applyDelta('timber', 80);
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: 0,
        ).copyWith(
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 20},
            carryForwardOffersByFactionId: {
              'gp1': [
                TradeOrder(
                  commodityId: CommodityCatalog.timber.id,
                  type: TradeOrderType.offer,
                  quantity: carryForwardQuantity,
                  priority: kTreasuryOfferPriorityUrgent,
                ),
              ],
            },
          ),
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        ));
        final timberOffers = orders
            .where(
              (o) =>
                  o.commodityId == CommodityCatalog.timber.id &&
                  o.type == TradeOrderType.offer,
            )
            .toList();
        expect(
          timberOffers,
          isEmpty,
          reason:
              'Carry-forward residual already saturates the surplus; planner '
              'must not re-emit.',
        );
      },
    );

    test(
      'carry-forward offer partially covers surplus: planner emits residual only',
      () {
        // Nominal surplus = 72 (see test above). Carry-forward of 30 leaves
        // 42 units of fresh capacity for this turn.
        const carryForwardQuantity = 30;
        const expectedResidual = 42;
        final stockpile = const Stockpile().applyDelta('timber', 80);
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: 0,
        ).copyWith(
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 20},
            carryForwardOffersByFactionId: {
              'gp1': [
                TradeOrder(
                  commodityId: CommodityCatalog.timber.id,
                  type: TradeOrderType.offer,
                  quantity: carryForwardQuantity,
                  priority: kTreasuryOfferPriorityUrgent,
                ),
              ],
            },
          ),
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        ));
        final timberOffers = orders
            .where(
              (o) =>
                  o.commodityId == CommodityCatalog.timber.id &&
                  o.type == TradeOrderType.offer,
            )
            .toList();
        expect(timberOffers, hasLength(1));
        expect(timberOffers.single.quantity, expectedResidual);
      },
    );

    test(
      'carry-forward bid covers full deficit: no new fabric bid emitted',
      () {
        // The fabric-deficit test above shows the unmitigated planner emits a
        // fabric bid. A carry-forward bid for the entire deficit must
        // suppress the new emission.
        final stockpile = const Stockpile().applyDelta('wool', 4);
        const assignments = [
          AssignedRecipe(
            recipeId: 'fabric_from_wool',
            assignedLabour: 4,
          ),
        ];
        const carryForwardBidQuantity = 2;
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: cheapestRegimentBuildTreasuryCost() + 100,
          overtures: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        ).copyWith(
          worldMarketState: WorldMarketState(
            prices: {
              CommodityCatalog.fabric.id: 5,
              CommodityCatalog.wool.id: 50,
              CommodityCatalog.cotton.id: 50,
            },
            carryForwardBidsByFactionId: {
              'gp1': [
                TradeOrder(
                  commodityId: CommodityCatalog.fabric.id,
                  type: TradeOrderType.bid,
                  quantity: carryForwardBidQuantity,
                  priority: kTreasuryBidPriorityEssentialInput,
                ),
              ],
            },
          ),
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: assignments,
          treasury: game.players.first.treasury,
        ));
        final fabricBids = orders
            .where(
              (o) =>
                  o.commodityId == CommodityCatalog.fabric.id &&
                  o.type == TradeOrderType.bid,
            )
            .toList();
        expect(
          fabricBids,
          isEmpty,
          reason: 'Carry-forward bid already covers the projected deficit.',
        );
      },
    );
  });
}
