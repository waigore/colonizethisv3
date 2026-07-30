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


void main() {
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

    test(
      'prior-turn zero fill rate keeps offer priority urgent below threshold',
      () {
        // treasury (1000) is below the cheapest regiment cost (2000). With a
        // prior offer-side fill rate of 0.0, the F8 forecast must equal the
        // bare treasury and the planner must stay in urgent mode.
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
        // treasury (1000) is below the cheapest regiment cost (2000); the
        // discounted forecast 1000 + 72 * 20 * 1.0 = 2440 clears the
        // threshold, but F16 keys offer priority off actual treasury, so the
        // optimistic forecast must NOT downgrade offers to the moderate tier
        // while the GP is still broke (seed-42 gp5 stalled at 1999 otherwise).
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
