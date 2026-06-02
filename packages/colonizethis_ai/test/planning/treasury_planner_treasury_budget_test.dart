// Per-bid treasury clamp in `runTreasuryPlanner` (Refs #3122).
//
// SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing.
library;

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp = 'gp1';

Game _gameFor({
  required int treasury,
  Stockpile stockpile = const Stockpile(),
  Map<CommodityId, int>? prices,
  Map<String, List<TradeOrder>>? carryForwardBidsByFactionId,
  Map<String, MarketActivity>? lastTurnActivity,
  int turnNumber = 1,
  List<OvertureState> overtures = const [],
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g_treasury_cap',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: _gp),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: _gp,
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p1',
        stockpile: stockpile,
        treasury: treasury,
      ),
    ],
    overtureStates: overtures,
    worldMarketState: WorldMarketState.withDefaultPrices(
      prices ??
          const {
            'timber': 20,
            'iron': 20,
            'fabric': 40,
            'castIron': 60,
          },
    ).copyWith(
      carryForwardBidsByFactionId: carryForwardBidsByFactionId,
      lastTurnActivity: lastTurnActivity,
    ),
  );
}

List<TradeOrder> _bids(List<TradeOrder> orders) =>
    orders.where((o) => o.type == TradeOrderType.bid).toList();

const _embassyOverture = OvertureState(
  gpId: _gp,
  targetId: 'minor1',
  stage: OvertureStage.embassy,
  sinceTurn: 0,
);

void main() {
  group('runTreasuryPlanner per-bid treasury clamp (Refs #3122)', () {
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
        final game = _gameFor(
          stockpile: stockpile,
          treasury: 4000,
          prices: {
            CommodityCatalog.fabric.id: 40,
            CommodityCatalog.wool.id: 50,
            CommodityCatalog.cotton.id: 50,
          },
          overtures: const [_embassyOverture],
        );
        const peasantBuild = BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        );
        final currentOrders = const Orders(
          buildUnitOrdersByPlayerId: {
            _gp: [peasantBuild],
          },
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: _gp,
          stockpile: stockpile,
          productionAssignments: assignments,
          treasury: 4000,
          currentOrders: currentOrders,
        );
        // Sum every bid notional against the effective price the planner uses.
        final totalNotional = _bids(orders).fold<int>(
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
        final game = _gameFor(
          stockpile: stockpile,
          treasury: 4000,
          prices: {
            CommodityCatalog.fabric.id: 40,
            CommodityCatalog.timber.id: 20,
            CommodityCatalog.wool.id: 50,
            CommodityCatalog.cotton.id: 50,
          },
          carryForwardBidsByFactionId: {
            _gp: [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.bid,
                quantity: 2,
                priority: 3,
              ),
            ],
          },
          overtures: const [_embassyOverture],
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: _gp,
          stockpile: stockpile,
          productionAssignments: assignments,
          treasury: 4000,
        );
        final totalNotional = _bids(orders).fold<int>(
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
        final game = _gameFor(
          stockpile: stockpile,
          treasury: 30,
          prices: {
            CommodityCatalog.fabric.id: 40,
            CommodityCatalog.wool.id: 50,
          },
          overtures: const [_embassyOverture],
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: _gp,
          stockpile: stockpile,
          productionAssignments: assignments,
          treasury: 30,
        );
        final fabricBids = _bids(orders)
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
      'lock-recovery designated buyer respects treasury budget: liquidity '
      'bid notional + pending costs <= original treasury',
      () {
        const grain = 'grain';
        // gp1 broke (forces lock recovery), gp2 affluent designated buyer.
        var stockpile = const Stockpile().applyDelta(grain, 200);
        for (final commodity in CommodityCatalog.all) {
          if (richesCommodityIds.contains(commodity.id)) continue;
          if (commodity.id == grain) continue;
          stockpile = stockpile.applyDelta(commodity.id, 4);
        }
        const grainPrice = 10;
        final affluentTreasury =
            cheapestRegimentBuildTreasuryCost() + 100;
        final game = _gameFor(
          stockpile: stockpile,
          treasury: 0,
          prices: {grain: grainPrice, 'timber': 20},
          lastTurnActivity: {
            grain: const MarketActivity(
              totalBidQuantity: 0,
              totalOfferQuantity: 100,
              filledQuantity: 0,
            ),
          },
        );
        final game2 = game.copyWith(
          players: [
            ...game.players,
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: 'oldWorld|p2',
              stockpile: const Stockpile()
                  .applyDelta(CommodityCatalog.fabric.id, 4),
              workerPool: const WorkerPool(peasants: 5),
              treasury: affluentTreasury,
            ),
          ],
        );
        expect(lockRecoveryDesignatedBuyerId(game2), 'gp2');
        const pendingBuild = BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p2',
        );
        final currentOrders = const Orders(
          buildUnitOrdersByPlayerId: {
            'gp2': [pendingBuild],
          },
        );
        final orders = runTreasuryPlanner(
          game: game2,
          playerId: 'gp2',
          stockpile: game2.players[1].stockpile,
          productionAssignments: const [],
          treasury: affluentTreasury,
          currentOrders: currentOrders,
        );
        final grainBids = _bids(orders).where((b) => b.commodityId == grain);
        final grainOffers = orders.where(
          (o) =>
              o.type == TradeOrderType.offer && o.commodityId == grain,
        );
        // Mutual exclusion must always hold for the designated buyer's
        // liquidity commodity (Refs #2924 F11 / F12).
        expect(grainOffers, isEmpty,
            reason: 'Mutual exclusion: designated buyer must not offer the '
                'liquidity food commodity.');
        // Budget invariant: cumulative bid notional must fit within the
        // remaining treasury after one pending peasant_levies build (2000).
        const peasantCost = 2000;
        final totalNotional = grainBids.fold<int>(
          0,
          (s, b) => s + b.quantity * grainPrice,
        );
        expect(
          totalNotional + peasantCost,
          lessThanOrEqualTo(affluentTreasury),
          reason: 'Liquidity bid notional + pending build cost must not '
              'exceed gp2 starting treasury (the matcher would clamp).',
        );
      },
    );

    // SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing —
    // AC5: when the affluent-speculative pass picks commodity C but the
    // running treasury budget cannot fund the full
    // `kSpeculativeBidStockpileTarget` (= 8) units, the emitted bid
    // quantity equals the affordable floor `budget ~/ price`, not the
    // stockpile target. The bid is only dropped when that floor is `0`
    // (Refs #3122).
    test(
      'speculative pass: budget/price < kSpeculativeBidStockpileTarget '
      'emits bid at quantity == floor(budget/price), not target 8',
      () {
        // Treasury == affluence threshold (= cheapestRegimentBuildTreasuryCost
        // = 2000) so the affluent speculative pass is active. Stockpile
        // covers grain/meat so the food deficit path stays out of `need`;
        // every other non-riches commodity has `projected == 0 < 8` and
        // is therefore speculative-eligible. lastTurnActivity routes the
        // speculative selection to castIron (the liquid pick branch
        // outranks both food and alphabetical fallback per
        // _addSpeculativeBidNeeds, so the selected commodity is
        // deterministic for this fixture).
        const castIron = 'castIron';
        const castIronPrice = 400;
        final affluentTreasury = treasuryAffluenceThreshold();
        // floor(2000 / 400) == 5, strictly less than kSpeculativeBidStockpileTarget (8).
        final expectedAffordableFloor = affluentTreasury ~/ castIronPrice;
        expect(
          expectedAffordableFloor < kSpeculativeBidStockpileTarget,
          isTrue,
          reason: 'Fixture invariant: affordable floor must be below the '
              'speculative stockpile target so the per-bid clamp dominates.',
        );
        final stockpile = const Stockpile()
            .applyDelta('grain', 100)
            .applyDelta('meat', 100);
        final game = _gameFor(
          stockpile: stockpile,
          treasury: affluentTreasury,
          prices: const {
            castIron: castIronPrice,
            'grain': 5,
            'meat': 5,
          },
          lastTurnActivity: const {
            castIron: MarketActivity(
              totalBidQuantity: 0,
              totalOfferQuantity: 100,
              filledQuantity: 0,
            ),
          },
          overtures: const [_embassyOverture],
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: _gp,
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: affluentTreasury,
        );
        final castIronBids = _bids(orders)
            .where((b) => b.commodityId == castIron)
            .toList();
        expect(
          castIronBids,
          hasLength(1),
          reason: 'A non-zero affordable floor must not drop the '
              'speculative bid; the planner emits exactly one castIron bid '
              'after the per-bid treasury clamp.',
        );
        expect(
          castIronBids.single.quantity,
          expectedAffordableFloor,
          reason: 'Speculative bid quantity must equal '
              'floor(budget / price) = floor(2000 / 400) = 5, not the '
              'kSpeculativeBidStockpileTarget (= 8) gap.',
        );
        // Budget invariant for the speculative path: cumulative notional
        // never exceeds the affluent treasury at planner entry.
        final totalNotional = _bids(orders).fold<int>(
          0,
          (s, b) =>
              s + b.quantity * (game.worldMarketState.prices[b.commodityId] ?? 0),
        );
        expect(totalNotional, lessThanOrEqualTo(affluentTreasury));
      },
    );

    // SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing —
    // AC6: when the lock-recovery designated buyer's per-bid budget is
    // below the liquidity commodity's per-unit price the synthetic grain
    // bid drops (affordableQty == 0). Mutual exclusion against the
    // liquidity commodity's offer side is preserved by the unconditional
    // `available.remove(commodityId)` at the head of
    // `_applyLockRecoveryLiquidityBid` (Refs #2924 F11 / F12 + #3122).
    test(
      'lock-recovery designated buyer with budget < pricePerUnit emits no '
      'liquidity bid and still preserves mutual exclusion on offers',
      () {
        const grain = 'grain';
        const grainPrice = 10;
        // gp1 is broke (treasury 0 < cheapestRegimentBuildTreasuryCost)
        // so `_anyBrokeGreatPower(game)` is true and lock-recovery rotation
        // selects from the affluent pool that includes gp2.
        var stockpile = const Stockpile().applyDelta(grain, 200);
        for (final commodity in CommodityCatalog.all) {
          if (richesCommodityIds.contains(commodity.id)) continue;
          if (commodity.id == grain) continue;
          stockpile = stockpile.applyDelta(commodity.id, 4);
        }
        final affluentTreasury = treasuryAffluenceThreshold();
        // One pending peasant_levies build consumes the entire affluent
        // treasury (buildTreasuryCost == 2000 == affluentTreasury), so
        // `treasuryBudgetForBids` collapses to 0 and the synthetic grain
        // bid's affordable quantity drops to floor(0 / 10) = 0.
        final base = _gameFor(
          stockpile: stockpile,
          treasury: 0,
          prices: const {grain: grainPrice, 'fabric': 40},
          lastTurnActivity: const {
            grain: MarketActivity(
              totalBidQuantity: 0,
              totalOfferQuantity: 100,
              filledQuantity: 0,
            ),
          },
        );
        final gp2Stockpile = const Stockpile()
            .applyDelta(grain, 100)
            .applyDelta(CommodityCatalog.fabric.id, 4);
        final game = base.copyWith(
          players: [
            ...base.players,
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: 'oldWorld|p2',
              stockpile: gp2Stockpile,
              workerPool: const WorkerPool(peasants: 5),
              treasury: affluentTreasury,
            ),
          ],
        );
        expect(
          lockRecoveryDesignatedBuyerId(game),
          'gp2',
          reason: 'Fixture invariant: gp1 is broke and gp2 is the only '
              'affluent GP, so the rotation must pick gp2.',
        );
        const pendingBuild = BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p2',
        );
        final currentOrders = const Orders(
          buildUnitOrdersByPlayerId: {
            'gp2': [pendingBuild],
          },
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: 'gp2',
          stockpile: gp2Stockpile,
          productionAssignments: const [],
          treasury: affluentTreasury,
          currentOrders: currentOrders,
        );
        final grainBids = _bids(orders).where((b) => b.commodityId == grain);
        final grainOffers = orders.where(
          (o) => o.type == TradeOrderType.offer && o.commodityId == grain,
        );
        expect(
          grainBids,
          isEmpty,
          reason: 'Lock-recovery designated buyer with '
              'treasuryBudgetForBids == 0 < grainPrice must not emit a '
              'grain bid (affordableQty == 0).',
        );
        expect(
          grainOffers,
          isEmpty,
          reason: 'Mutual exclusion: even when the synthetic liquidity '
              'bid drops, the designated buyer must not offer the '
              'liquidity commodity — `_applyLockRecoveryLiquidityBid` '
              'removes it from `available` before the affordability '
              'check.',
        );
      },
    );

    // SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing —
    // AC1 (strict): given an AI GP with `treasury == 0` and the deficit
    // path active (the only bid path that can fire at zero treasury per
    // the planner's preconditions — the speculative pass requires
    // `treasury >= treasuryAffluenceThreshold()` and the lock-recovery
    // designated buyer rotation only selects from the affluent pool),
    // the planner must emit no `TradeOrderType.bid` orders. The
    // pre-existing "treasury below pricePerUnit suppresses the deficit
    // bid entirely" case proves the suppression at `treasury == 30`
    // where `budget < price`; this pin closes the literal `treasury == 0`
    // boundary against future regressions where the clamp could
    // accidentally fall back to a non-zero default budget (Refs #3122).
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
        final game = _gameFor(
          stockpile: stockpile,
          treasury: 0,
          prices: {
            CommodityCatalog.fabric.id: 40,
            CommodityCatalog.wool.id: 50,
          },
          overtures: const [_embassyOverture],
        );
        final orders = runTreasuryPlanner(
          game: game,
          playerId: _gp,
          stockpile: stockpile,
          productionAssignments: assignments,
          treasury: 0,
        );
        expect(
          _bids(orders),
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
      final game = _gameFor(
        stockpile: stockpile,
        treasury: cheapestRegimentBuildTreasuryCost() + 500,
        prices: {
          CommodityCatalog.fabric.id: 5,
          CommodityCatalog.timber.id: 20,
          CommodityCatalog.wool.id: 50,
        },
        overtures: const [_embassyOverture],
      );
      final a = runTreasuryPlanner(
        game: game,
        playerId: _gp,
        stockpile: stockpile,
        productionAssignments: assignments,
        treasury: game.players.first.treasury,
      );
      final b = runTreasuryPlanner(
        game: game,
        playerId: _gp,
        stockpile: stockpile,
        productionAssignments: assignments,
        treasury: game.players.first.treasury,
      );
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
