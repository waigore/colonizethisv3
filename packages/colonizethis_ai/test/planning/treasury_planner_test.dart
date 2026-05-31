/// Treasury planner trade-order generation (Refs #2994 F1–F5, F7 wiring).
library;

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _gameWithStockpile({
  required Stockpile stockpile,
  required int treasury,
  List<OvertureState> overtures = const [],
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p1',
        stockpile: stockpile,
        treasury: treasury,
      ),
    ],
    overtureStates: overtures,
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      'timber': 20,
      'iron': 20,
      'fabric': 40,
      'castIron': 60,
    }),
  );
}

void main() {
  group('runTreasuryPlanner (Refs #2994)', () {
    test(
      'surplus timber below regiment treasury threshold emits urgent sell offer',
      () {
        final stockpile = const Stockpile().applyDelta('timber', 80);
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: 0,
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        );
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
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: treasury,
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: treasury,
        );
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
        final game = _gameWithStockpile(
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
              CommodityCatalog.fabric.id: 5.0,
              CommodityCatalog.wool.id: 50.0,
              CommodityCatalog.cotton.id: 50.0,
            },
          ),
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: assignments,
          treasury: game.players.first.treasury,
        );
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

    test('no embassy yields offers only, no bids', () {
      final stockpile = const Stockpile()
          .applyDelta('timber', 80)
          .applyDelta('fabric', 0);
      final game = _gameWithStockpile(
        stockpile: stockpile,
        treasury: 0,
      );
      final orders = runTreasuryPlanner(
        game: game,
        playerId: 'gp1',
        stockpile: stockpile,
        productionAssignments: const [],
        treasury: 0,
      );
      expect(
        orders.where((o) => o.type == TradeOrderType.bid),
        isEmpty,
      );
      expect(
        orders.where((o) => o.type == TradeOrderType.offer),
        isNotEmpty,
      );
    });

    test('deterministic for identical inputs', () {
      final stockpile = const Stockpile().applyDelta('timber', 60);
      final game = _gameWithStockpile(stockpile: stockpile, treasury: 10);
      final a = runTreasuryPlanner(
        game: game,
        playerId: 'gp1',
        stockpile: stockpile,
        productionAssignments: const [],
        treasury: 10,
      );
      final b = runTreasuryPlanner(
        game: game,
        playerId: 'gp1',
        stockpile: stockpile,
        productionAssignments: const [],
        treasury: 10,
      );
      expect(a, b);
    });
  });

  group('runTreasuryPlanner partial-fill-aware forecasting (Refs #2994 F8)', () {
    test(
      'carry-forward offer covers full surplus: no new timber offer emitted',
      () {
        // With stockpile=80 timber, projected reserve for a rawMaterial is
        // consumption(4) + inputs(0) + safety(4) = 8 → nominal surplus = 72.
        // A carry-forward of exactly 72 should drop new emission to zero.
        const carryForwardQuantity = 72;
        final stockpile = const Stockpile().applyDelta('timber', 80);
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: 0,
        ).copyWith(
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 20.0},
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
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        );
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
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: 0,
        ).copyWith(
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 20.0},
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
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        );
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
        final game = _gameWithStockpile(
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
              CommodityCatalog.fabric.id: 5.0,
              CommodityCatalog.wool.id: 50.0,
              CommodityCatalog.cotton.id: 50.0,
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
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: assignments,
          treasury: game.players.first.treasury,
        );
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
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: treasury,
        ).copyWith(
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 20.0},
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
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: treasury,
        );
        final timberOffer = orders.firstWhere(
          (o) =>
              o.commodityId == CommodityCatalog.timber.id &&
              o.type == TradeOrderType.offer,
        );
        expect(timberOffer.priority, kTreasuryOfferPriorityUrgent);
      },
    );

    test(
      'prior-turn full fill rate lifts forecast above threshold and uses moderate offer priority',
      () {
        // treasury (1000) is below the cheapest regiment cost (2000) but the
        // discounted forecast 1000 + 72 * 20 * 1.0 = 2440 clears the
        // threshold, so the offer priority falls back to moderate.
        const treasury = 1000;
        final stockpile = const Stockpile().applyDelta('timber', 80);
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: treasury,
        ).copyWith(
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 20.0},
            lastTurnActivity: {
              CommodityCatalog.timber.id: const MarketActivity(
                totalOfferQuantity: 100,
                filledQuantity: 100,
              ),
            },
          ),
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: treasury,
        );
        final timberOffer = orders.firstWhere(
          (o) =>
              o.commodityId == CommodityCatalog.timber.id &&
              o.type == TradeOrderType.offer,
        );
        expect(timberOffer.priority, kTreasuryOfferPriorityModerate);
      },
    );

    test(
      'deterministic with carry-forward and prior activity state populated',
      () {
        final stockpile = const Stockpile().applyDelta('timber', 80);
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: 0,
        ).copyWith(
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 20.0},
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
        final a = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        );
        final b = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        );
        expect(a, b);
      },
    );
  });
}
