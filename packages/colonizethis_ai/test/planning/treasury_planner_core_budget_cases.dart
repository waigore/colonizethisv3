// Case bodies for `treasury_planner_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Case bodies for `treasury_planner_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'treasury_planner_main_support.dart';
import 'treasury_planner_core_budget_lock_recovery_tail_cases.dart';


void registerTreasuryPlannerCoreBudgetCases() {
group('runTreasuryPlanner(TreasuryPlannerInput(Refs #2994))', () {
    test(
      'surplus timber below regiment treasury threshold emits urgent sell offer',
      () {
        final stockpile = const Stockpile().applyDelta('timber', 80);
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: 0,
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        ));
        final offers = orders
            .where((o) => o.type == TradeOrderType.offer)
            .toList();
        expect(offers, isNotEmpty);
        final timberOffer = offers
            .where((o) => o.commodityId == CommodityCatalog.timber.id)
            .toList();
        expect(timberOffer, isNotEmpty);
        expect(
          timberOffer.first.priority,
          kTreasuryOfferPriorityUrgent,
          reason: 'Low treasury should use urgent sell priority.',
        );
        expect(timberOffer.first.quantity, greaterThan(0));
      },
    );

    test(
      'abundant treasury above regiment threshold uses moderate offer priority',
      () {
        final stockpile = const Stockpile().applyDelta('timber', 80);
        final treasury = cheapestRegimentBuildTreasuryCost() + 500;
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: treasury,
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: treasury,
        ));
        final timberOffer = orders
            .where(
              (o) =>
                  o.type == TradeOrderType.offer &&
                  o.commodityId == CommodityCatalog.timber.id,
            )
            .toList();
        expect(timberOffer, isNotEmpty);
        expect(timberOffer.first.priority, kTreasuryOfferPriorityModerate);
      },
    );

    test(
      'fabric deficit with embassy emits bid when market price beats production cost',
      () {
        final stockpile = const Stockpile().applyDelta('wool', 4);
        const assignments = [
          AssignedRecipe(
            recipeId: 'fabric_from_wool',
            assignedLabour: 4,
          ),
        ];
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
                  o.type == TradeOrderType.bid &&
                  o.commodityId == CommodityCatalog.fabric.id,
            )
            .toList();
        expect(fabricBids, isNotEmpty);
        expect(
          fabricBids.first.priority,
          kTreasuryBidPriorityEssentialInput,
        );
      },
    );

    test(
      'no embassy and treasury == 0 with no production deficit yields '
      'offers only for non-designated buyer — speculative bidding is gated '
      'by treasury affluence so broke GPs never speculate (Refs #2924 F10; '
      'SPEC/ai/treasury-planner.md § Affluent-GP speculative bidding)',
      () {
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
          treasury: 0,
          turnNumber: 1,
          extraPlayers: const [
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: 'oldWorld|p2',
              stockpile: Stockpile.empty,
              treasury: 0,
            ),
          ],
        );
        expect(lockRecoveryDesignatedBuyerId(game), isEmpty);
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        ));
        expect(
          orders.where((o) => o.type == TradeOrderType.bid),
          isEmpty,
          reason: 'Treasury below affluence threshold (= 0) must not '
              'trigger speculative bids; deficit pass also empty because '
              'every non-riches commodity is well-stocked. gp1 is not the '
              'F11 designated buyer on turn 1.',
        );
        expect(
          orders.where((o) => o.type == TradeOrderType.offer),
          isNotEmpty,
        );
      },
    );

    test(
      'lock-recovery designated buyer rotates among affluent GPs only '
      '(Refs #2924 F11 affluent pool)',
      () {
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: const Stockpile(),
          treasury: 0,
          turnNumber: 3,
          extraPlayers: [
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: 'oldWorld|p2',
              stockpile: Stockpile.empty,
              treasury: treasuryAffluenceThreshold(),
            ),
          ],
        );
        expect(lockRecoveryDesignatedBuyerId(game), 'gp2');
      },
    );
  });

  registerTreasuryPlannerCoreBudgetLockRecoveryTailCases();
}
