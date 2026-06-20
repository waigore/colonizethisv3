/// Treasury planner trade-order generation (Refs #2994 F1–F5, F7 wiring).
///
/// Partial-fill-aware forecasting and speculative-bid passes live in
/// `treasury_planner_forecasting_test.dart` (split for the 1000 non-comment
/// line repo-lint ceiling).
library;

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
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

/// Builds a single-GP game where `gp1` is a below-quota zero-NW lock-recovery
/// seller (`oldWorldProvincesOwned == owProvinces` in `[2, 10)`, no NW
/// provinces) for the F17 food-surplus-release tests (Refs #2924).
Game _lockRecoverySellerGame({
  required Stockpile stockpile,
  required int treasury,
  int owProvinces = 3,
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-lock-recovery-seller-f17',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < owProvinces; i++)
            Province(id: '$ow|p1_$i', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p1_0',
        stockpile: stockpile,
        treasury: treasury,
      ),
    ],
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      'grain': 10,
      'timber': 20,
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
        expect(lockRecoveryDesignatedBuyerId(game), isEmpty);
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
      'below-quota zero-NW affluent GP is excluded from designated buyer '
      'pool (Refs #2924 Path F)',
      () {
        const ow = 'oldWorld';
        final game = Game(
          id: 'g-lock-recovery-seller',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 7; i++)
                  Province(
                    id: '$ow|p2_$i',
                    regionId: ow,
                    ownerId: 'gp2',
                  ),
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(
              id: 'gp1',
              displayName: 'GP1',
              isHuman: false,
              capitalProvinceId: '$ow|p1',
              treasury: 0,
            ),
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: '$ow|p2_0',
              treasury: 2500,
            ),
          ],
        );
        expect(
          lockRecoveryDesignatedBuyerId(game),
          isEmpty,
          reason: 'gp2 is affluent but below quota with zero NW — must stay '
              'sell-only until Path F credits accumulate.',
        );
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
      'all-broke campaign: no GP liquidity buyer — phase-13 minor bids (F15)',
      () {
        final stockpile = const Stockpile().applyDelta('grain', 8);
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'GP1',
              isHuman: false,
              stockpile: stockpile,
              treasury: 50,
            ),
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              stockpile: Stockpile.empty,
              treasury: 80,
            ),
          ],
          worldMarketState: WorldMarketState.withDefaultPrices(const {
            'grain': 10,
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
          isLockRecoveryLiquidityBuyer(
            game: game,
            playerId: 'gp2',
            treasuryBudgetForBids: 80,
            treasuryForecast: 80,
          ),
          isFalse,
          reason: 'F15 buy-side is logic-phase minor auto-bids when no GP is '
              'affluent.',
        );
        final gp2Orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp2',
          stockpile: Stockpile.empty,
          productionAssignments: const [],
          treasury: 80,
        );
        expect(
          gp2Orders.where(
            (o) => o.type == TradeOrderType.bid && o.commodityId == 'grain',
          ),
          isEmpty,
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
        expect(lockRecoveryDesignatedBuyerId(game), isEmpty);
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
        for (final offer in orders.where((o) => o.type == TradeOrderType.offer)) {
          expect(
            offer.priority,
            kTreasuryOfferPriorityUrgent,
            reason: 'Refs #2924 F16: actual treasury below regiment threshold '
                'must keep offers on the urgent tier even when F8 forecast '
                'exceeds the threshold.',
          );
        }
      },
    );

    test(
      'broke GP keeps urgent offer tier at treasury 1999 when forecast clears '
      'threshold (Refs #2924 F16)',
      () {
        final stockpile = const Stockpile().applyDelta('grain', 500);
        final game = _gameWithStockpile(
          stockpile: stockpile,
          treasury: 1999,
          turnNumber: 1,
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
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 1999,
        );
        final offers = orders.where((o) => o.type == TradeOrderType.offer);
        expect(offers, isNotEmpty);
        for (final offer in offers) {
          expect(offer.priority, kTreasuryOfferPriorityUrgent);
        }
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

  group('lock-recovery seller food-surplus release (Refs #2924 F17)', () {
    test(
      'below-quota zero-NW seller releases food above one consumption cycle',
      () {
        // grain reserve for the seller is consumption (8) with the 2x safety
        // buffer dropped, so grain 16 yields surplus 8 -> an urgent offer.
        final stockpile = const Stockpile().applyDelta('grain', 16);
        final game = _lockRecoverySellerGame(stockpile: stockpile, treasury: 0);
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        );
        final grainOffers = orders
            .where(
              (o) => o.type == TradeOrderType.offer && o.commodityId == 'grain',
            )
            .toList();
        expect(
          grainOffers,
          isNotEmpty,
          reason: 'F17: a broke lock-recovery seller drops the 2x food safety '
              'buffer so grain above one consumption cycle is offered.',
        );
        expect(grainOffers.first.priority, kTreasuryOfferPriorityUrgent);
        expect(grainOffers.first.quantity, greaterThan(0));
      },
    );

    test(
      'seller food reserve floor equals one consumption cycle (no offer at 8)',
      () {
        // grain 8 == consumption: surplus 0, so no offer. This pins the food
        // reserve at exactly `consumption` (safety buffer == 0) for sellers,
        // distinguishing F17 from the 1x (reserve 16) and 2x (reserve 24)
        // buffers.
        final stockpile = const Stockpile().applyDelta('grain', 8);
        final game = _lockRecoverySellerGame(stockpile: stockpile, treasury: 0);
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        );
        expect(
          orders.where(
            (o) => o.type == TradeOrderType.offer && o.commodityId == 'grain',
          ),
          isEmpty,
        );
      },
    );

    test(
      'non-seller GP keeps the 2x food safety buffer (negative control)',
      () {
        // gp1 owns a single OW province -> not a lock-recovery seller. grain 16
        // is below the 2x reserve (24), so no offer is emitted.
        final stockpile = const Stockpile().applyDelta('grain', 16);
        final game = _gameWithStockpile(stockpile: stockpile, treasury: 0);
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        );
        expect(
          orders.where(
            (o) => o.type == TradeOrderType.offer && o.commodityId == 'grain',
          ),
          isEmpty,
          reason: 'A non-seller GP retains the 2x food safety buffer, so grain '
              '16 < reserve 24 yields no surplus offer.',
        );
      },
    );

    test('seller food-release path is deterministic', () {
      final stockpile = const Stockpile().applyDelta('grain', 20);
      final game = _lockRecoverySellerGame(stockpile: stockpile, treasury: 0);
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
    });

    test(
      'snapshot province counts match world-state scans (Refs #3288)',
      () {
        final stockpile = const Stockpile().applyDelta('grain', 20);
        final game = _lockRecoverySellerGame(stockpile: stockpile, treasury: 0);
        const snapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(oldWorldProvincesOwned: 3),
          colonial: ColonialSummary(newWorldProvincesOwned: 0),
          economy: EconomySummary(treasury: 0),
          relations: {},
        );
        final withoutSnapshot = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        );
        final withSnapshot = runTreasuryPlanner(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
          snapshot: snapshot,
        );
        expect(withSnapshot, withoutSnapshot);
      },
    );
  });
}
