/// Treasury planner trade-order generation (Refs #2994 F1–F5, F7 wiring).
library;

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _gameWithStockpile({
  required Stockpile stockpile,
  required int treasury,
  List<OvertureState> overtures = const [],
  int turnNumber = 1,
  List<Player>? extraPlayers,
}) {
  const ow = 'oldWorld';
  final players = [
    Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: false,
      capitalProvinceId: '$ow|p1',
      stockpile: stockpile,
      treasury: treasury,
    ),
    ...?extraPlayers,
  ];
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: players,
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
              CommodityCatalog.fabric.id: 5,
              CommodityCatalog.wool.id: 50,
              CommodityCatalog.cotton.id: 50,
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
        final game = _gameWithStockpile(
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
        expect(lockRecoveryDesignatedBuyerId(game), 'gp2');
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
        final game = _gameWithStockpile(
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

    test(
      'lock-recovery designated buyer bids liquid food at urgent priority '
      'and does not offer that commodity (Refs #2924 F11/F12)',
      () {
        var stockpile = const Stockpile().applyDelta('grain', 200);
        for (final commodity in CommodityCatalog.all) {
          if (richesCommodityIds.contains(commodity.id)) continue;
          if (commodity.id == 'grain') continue;
          stockpile = stockpile.applyDelta(commodity.id, 4);
        }
        final affluentTreasury = cheapestRegimentBuildTreasuryCost() + 100;
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: 0,
          turnNumber: 0,
          extraPlayers: [
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: 'oldWorld|p2',
              stockpile: Stockpile.empty,
              treasury: affluentTreasury,
            ),
          ],
        ).copyWith(
          worldMarketState: WorldMarketState.withDefaultPrices(const {
            'grain': 10,
            'timber': 20,
          }).copyWith(
            lastTurnActivity: {
              'grain': const MarketActivity(
                totalBidQuantity: 0,
                totalOfferQuantity: 100,
                filledQuantity: 0,
              ),
            },
          ),
        );
        expect(
          lockRecoveryDesignatedBuyerId(game),
          'gp2',
          reason: 'gp2 is the affluent GP and gp1 is broke, so the F12 '
              'affluent-only rotation selects gp2 as designated buyer.',
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp2',
          stockpile: Stockpile.empty,
          productionAssignments: const [],
          treasury: affluentTreasury,
        );
        final grainBids = orders
            .where((o) => o.type == TradeOrderType.bid && o.commodityId == 'grain');
        final grainOffers = orders
            .where((o) => o.type == TradeOrderType.offer && o.commodityId == 'grain');
        expect(grainBids, isNotEmpty);
        expect(grainOffers, isEmpty);
        expect(
          grainBids.first.priority,
          kTreasuryOfferPriorityUrgent,
          reason: 'F12 forces the affluent designated buyer\'s liquidity bid '
              'to the urgent tier even though its own forecast is above the '
              'regiment threshold.',
        );
      },
    );

    test(
      'broke non-designated GP emits offers only when forecast is above '
      'regiment threshold (Refs #2924 F13)',
      () {
        final stockpile = const Stockpile().applyDelta('grain', 500);
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: 50,
          turnNumber: 1,
          extraPlayers: const [
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: 'oldWorld|p2',
              stockpile: Stockpile.empty,
              treasury: 100,
            ),
          ],
        ).copyWith(
          worldMarketState: WorldMarketState.withDefaultPrices(const {
            'grain': 10,
          }).copyWith(
            lastTurnActivity: {
              'grain': const MarketActivity(
                totalBidQuantity: 0,
                totalOfferQuantity: 100,
                filledQuantity: 100,
              ),
            },
          ),
        );
        expect(lockRecoveryDesignatedBuyerId(game), 'gp2');
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 50,
        );
        expect(
          orders.where((o) => o.type == TradeOrderType.bid),
          isEmpty,
          reason: 'Actual treasury 50 < 2000 must keep gp1 on offers-only '
              'even when F8 forecast inflow would exceed the threshold.',
        );
        expect(
          orders.where((o) => o.type == TradeOrderType.offer),
          isNotEmpty,
        );
      },
    );

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
            prices: {CommodityCatalog.timber.id: 20},
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
      'emits exactly one speculative bid for the first eligible food '
      'commodity (deterministic fallback; Refs #2924 F10)',
      () {
        final affluent = treasuryAffluenceThreshold();
        final stockpile = stockpileWellStockedExcept(const ['grain', 'meat'])
            .applyDelta('timber', 80);
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: affluent,
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: affluent,
        );
        final bids = orders
            .where((o) => o.type == TradeOrderType.bid)
            .toList();
        expect(
          bids,
          hasLength(1),
          reason:
              'Speculative pass adds at most one synthetic need entry to '
              'concentrate the single baseline-cap bid slot.',
        );
        final bid = bids.single;
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
          reason:
              'Without prior MarketActivity, the speculative pass falls '
              'back to a food commodity that the F1-F5 deficit pass also '
              'has reason to bid for.',
        );
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
        final game = _gameWithStockpile(
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
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: affluent,
        );
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
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: affluent,
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: affluent,
        );
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
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: justBelow,
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: justBelow,
        );
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
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: affluent,
        );
        final a = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: affluent,
        );
        final b = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: affluent,
        );
        expect(a, b);
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
