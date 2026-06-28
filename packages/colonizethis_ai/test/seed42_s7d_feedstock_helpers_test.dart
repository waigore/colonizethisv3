// Unit coverage for the S7-D feedstock probe helpers (Refs #2847).
//
// `stockpileAffordsAnyProductionRecipe` backs the diagnostic's
// `gpCastIronRecipeFeasibleTurns` counter (material-only). The two
// production-allocation localization helpers added for the PR #3289 castIron
// follow-up back the `gpCastIronRecipeLabourFeasibleTurns` and
// `gpCastIronFeasibleOwnsFeedstockTileTurns` counters, which split a flat
// `gpCastIronProductionAssignedTurns == 0` on the material-feasible turns into
// "labour-starved" vs "labour-feasible" and "owns no feedstock tile" vs "owns a
// feedstock tile". These tests pin their pure semantics so the counters cannot
// silently drift.
//
// The `playerEffectiveLabour` / `playerRawLabourSupply` / `playerFoodOnHand`
// helpers back the `gpCastIronLabourFoodStarvedTurns` /
// `gpCastIronLabourPopulationBoundTurns` fork that splits a labour-infeasible
// castIron turn into "workers exist but are unfed" (food lever) vs "too few
// workers even if fed" (recruitment lever); their tests pin the
// food-gated-vs-raw labour distinction the fork depends on.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/seed42_s7d_feedstock_helpers.dart';

const _playerId = 'gp1';

Game _game({
  WorkerPool workers = const WorkerPool(),
  Stockpile stockpile = const Stockpile(),
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
      const {},
  Map<String, String> resourceByTileKey = const {},
  List<Province> oldWorldProvinces = const [],
  Map<String, int> improvementByTile = const {},
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
      resourceByTileKey: resourceByTileKey,
      tileState: TileMapState(improvementByTile: improvementByTile),
    ),
    players: [
      Player(
        id: _playerId,
        displayName: 'GP',
        isHuman: false,
        stockpile: stockpile,
        workerPool: workers,
      ),
    ],
  );
}

void main() {
  final castIron = ProductionRecipesCatalog.castIronFromTimberIronCoal;
  final lumber = ProductionRecipesCatalog.lumberFromTimber;
  final fabricFromWool = ProductionRecipesCatalog.fabricFromWool;
  final timberId = CommodityCatalog.timber.id;
  final ironId = CommodityCatalog.iron.id;
  final woolId = CommodityCatalog.wool.id;
  final grainId = CommodityCatalog.grain.id;
  final meatId = CommodityCatalog.meat.id;

  group('stockpileAffordsAnyProductionRecipe', () {
    test(
      'positive: holds every input of the sole recipe (castIron = 2 timber + '
      '2 iron)',
      () {
        final stockpile = Stockpile(quantities: {timberId: 2, ironId: 2});
        expect(
          stockpileAffordsAnyProductionRecipe(stockpile, [castIron]),
          isTrue,
        );
      },
    );

    test('positive: affords at least one of several candidate recipes', () {
      // Holds timber but no iron: cannot run castIron, but can run lumber
      // (2 timber). Any single affordable recipe satisfies the helper.
      final stockpile = Stockpile(quantities: {timberId: 2});
      expect(
        stockpileAffordsAnyProductionRecipe(stockpile, [castIron, lumber]),
        isTrue,
      );
    });

    test('positive: surplus above the input requirement still affords', () {
      final stockpile = Stockpile(quantities: {timberId: 71, ironId: 64});
      expect(
        stockpileAffordsAnyProductionRecipe(stockpile, [castIron]),
        isTrue,
      );
    });

    test('negative: missing one required input (iron) is not affordable', () {
      final stockpile = Stockpile(quantities: {timberId: 5, ironId: 1});
      expect(
        stockpileAffordsAnyProductionRecipe(stockpile, [castIron]),
        isFalse,
      );
    });

    test('negative: empty stockpile affords nothing', () {
      expect(
        stockpileAffordsAnyProductionRecipe(Stockpile.empty, [castIron]),
        isFalse,
      );
    });

    test('negative: empty recipe list is never affordable', () {
      final stockpile = Stockpile(quantities: {timberId: 99, ironId: 99});
      expect(
        stockpileAffordsAnyProductionRecipe(stockpile, const []),
        isFalse,
      );
    });

    test('boundary: exactly one short of an input is not affordable', () {
      final stockpile = Stockpile(quantities: {timberId: 2, ironId: 1});
      expect(
        stockpileAffordsAnyProductionRecipe(stockpile, [castIron]),
        isFalse,
      );
    });
  });

  group('stockpileAndLabourAffordAnyProductionRecipe', () {
    test(
      'positive: material on hand and effective labour covers one castIron run '
      '(labourPerOutput 5)',
      () {
        // 10 peasants fed by 10 grain -> 10 effective labour; castIron needs 5
        // labour and 2 timber + 2 iron, so feasibleRuns >= 1.
        final game = _game(
          workers: const WorkerPool(peasants: 10),
          stockpile: Stockpile(
            quantities: {grainId: 10, timberId: 2, ironId: 2},
          ),
        );
        expect(
          stockpileAndLabourAffordAnyProductionRecipe(game, _playerId, [
            castIron,
          ]),
          isTrue,
        );
      },
    );

    test(
      'negative (labour-starved): material present but effective labour below '
      'one run is not feasible',
      () {
        // 1 peasant fed by 1 grain -> 1 effective labour < castIron's 5, so the
        // recipe is materially affordable yet labour-starved. This is the
        // decisive split the diagnostic relies on.
        final stockpile = Stockpile(
          quantities: {grainId: 1, timberId: 2, ironId: 2},
        );
        final game = _game(
          workers: const WorkerPool(peasants: 1),
          stockpile: stockpile,
        );
        expect(
          stockpileAffordsAnyProductionRecipe(stockpile, [castIron]),
          isTrue,
          reason: 'control: the same turn is material-feasible',
        );
        expect(
          stockpileAndLabourAffordAnyProductionRecipe(game, _playerId, [
            castIron,
          ]),
          isFalse,
        );
      },
    );

    test('negative: missing a material input is not feasible even with labour', () {
      final game = _game(
        workers: const WorkerPool(peasants: 10),
        stockpile: Stockpile(quantities: {grainId: 10, timberId: 2}),
      );
      expect(
        stockpileAndLabourAffordAnyProductionRecipe(game, _playerId, [castIron]),
        isFalse,
      );
    });

    test('negative: empty recipe list is never feasible', () {
      final game = _game(
        workers: const WorkerPool(peasants: 10),
        stockpile: Stockpile(quantities: {grainId: 10}),
      );
      expect(
        stockpileAndLabourAffordAnyProductionRecipe(game, _playerId, const []),
        isFalse,
      );
    });

    test('negative: unknown player id is never feasible', () {
      final game = _game(
        workers: const WorkerPool(peasants: 10),
        stockpile: Stockpile(
          quantities: {grainId: 10, timberId: 2, ironId: 2},
        ),
      );
      expect(
        stockpileAndLabourAffordAnyProductionRecipe(game, 'no_such_player', [
          castIron,
        ]),
        isFalse,
      );
    });

    test(
      'positive (fabric): material on hand and effective labour covers one '
      'fabric run (labourPerOutput 2)',
      () {
        // 2 peasants fed by 2 grain -> 2 effective labour; fabric_from_wool
        // needs 2 labour and 2 wool, so feasibleRuns >= 1.
        final game = _game(
          workers: const WorkerPool(peasants: 2),
          stockpile: Stockpile(quantities: {grainId: 2, woolId: 2}),
        );
        expect(
          stockpileAndLabourAffordAnyProductionRecipe(game, _playerId, [
            fabricFromWool,
          ]),
          isTrue,
        );
      },
    );

    test(
      'negative (fabric labour-starved): wool on hand but a single effective '
      'labour is below the fabric run (the gp5 circular-fabric case)',
      () {
        // 1 peasant fed by 1 grain -> 1 effective labour < fabric_from_wool's
        // labourPerOutput 2. The recruit boost that would grow castIron labour
        // needs 2 fabric, but fabric itself cannot be produced at 1 labour:
        // the Refs #2847 S7-D circular deadlock the new counter localizes.
        final stockpile = Stockpile(quantities: {grainId: 1, woolId: 2});
        final game = _game(
          workers: const WorkerPool(peasants: 1),
          stockpile: stockpile,
        );
        expect(
          stockpileAffordsAnyProductionRecipe(stockpile, [fabricFromWool]),
          isTrue,
          reason: 'control: the same turn is material-feasible',
        );
        expect(
          stockpileAndLabourAffordAnyProductionRecipe(game, _playerId, [
            fabricFromWool,
          ]),
          isFalse,
        );
      },
    );
  });

  group('ownsFeedstockResourceTileAnyLevel', () {
    final castIronFeedstock = {timberId, ironId};

    test('positive: owns a province tile hosting a castIron feedstock', () {
      final game = _game(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p0', regionId: 'oldWorld', ownerId: _playerId),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p0': ['oldWorld|p0|2|0'],
          },
        },
        resourceByTileKey: const {'oldWorld|p0|2|0': 'timber'},
      );
      expect(
        ownsFeedstockResourceTileAnyLevel(game, _playerId, castIronFeedstock),
        isTrue,
      );
    });

    test('negative: the feedstock tile is owned by another faction', () {
      final game = _game(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p0', regionId: 'oldWorld', ownerId: 'gp2'),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p0': ['oldWorld|p0|2|0'],
          },
        },
        resourceByTileKey: const {'oldWorld|p0|2|0': 'timber'},
      );
      expect(
        ownsFeedstockResourceTileAnyLevel(game, _playerId, castIronFeedstock),
        isFalse,
      );
    });

    test('negative: owned tile hosts a non-feedstock resource', () {
      final game = _game(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p0', regionId: 'oldWorld', ownerId: _playerId),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p0': ['oldWorld|p0|0|0'],
          },
        },
        resourceByTileKey: const {'oldWorld|p0|0|0': 'grain'},
      );
      expect(
        ownsFeedstockResourceTileAnyLevel(game, _playerId, castIronFeedstock),
        isFalse,
      );
    });

    test('negative: empty feedstock set never matches', () {
      final game = _game(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p0', regionId: 'oldWorld', ownerId: _playerId),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p0': ['oldWorld|p0|2|0'],
          },
        },
        resourceByTileKey: const {'oldWorld|p0|2|0': 'timber'},
      );
      expect(
        ownsFeedstockResourceTileAnyLevel(game, _playerId, const {}),
        isFalse,
      );
    });
  });

  group('owns(Un)improvedFeedstockResourceTile improvement-level split', () {
    final castIronFeedstock = {timberId, ironId};
    const provinceId = 'oldWorld|p0';
    const tileKey = 'oldWorld|p0|2|0';

    Game gameWithImprovement(int level) => _game(
      oldWorldProvinces: const [
        Province(id: provinceId, regionId: 'oldWorld', ownerId: _playerId),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          provinceId: [tileKey],
        },
      },
      resourceByTileKey: const {tileKey: 'timber'},
      improvementByTile: {tileKey: level},
    );

    test('unimproved (level 0): unimproved probe true, improved probe false', () {
      final game = gameWithImprovement(0);
      expect(
        ownsUnimprovedFeedstockResourceTile(game, _playerId, castIronFeedstock),
        isTrue,
      );
      expect(
        ownsImprovedFeedstockResourceTile(game, _playerId, castIronFeedstock),
        isFalse,
      );
      // Any-level probe ignores the improvement split entirely.
      expect(
        ownsFeedstockResourceTileAnyLevel(game, _playerId, castIronFeedstock),
        isTrue,
      );
    });

    test('improved (level 1): improved probe true, unimproved probe false', () {
      final game = gameWithImprovement(1);
      expect(
        ownsImprovedFeedstockResourceTile(game, _playerId, castIronFeedstock),
        isTrue,
      );
      expect(
        ownsUnimprovedFeedstockResourceTile(game, _playerId, castIronFeedstock),
        isFalse,
      );
      expect(
        ownsFeedstockResourceTileAnyLevel(game, _playerId, castIronFeedstock),
        isTrue,
      );
    });

    test('empty feedstock set: every probe is false', () {
      final game = gameWithImprovement(0);
      expect(
        ownsUnimprovedFeedstockResourceTile(game, _playerId, const {}),
        isFalse,
      );
      expect(
        ownsImprovedFeedstockResourceTile(game, _playerId, const {}),
        isFalse,
      );
    });

    test('scanOwnedFeedstockTiles: custom predicate drives the match', () {
      final game = gameWithImprovement(2);
      // Predicate matching exactly level 2 succeeds; a never-true predicate
      // short-circuits to false even though the owned feedstock tile exists.
      expect(
        scanOwnedFeedstockTiles(
          game,
          _playerId,
          castIronFeedstock,
          (level) => level == 2,
        ),
        isTrue,
      );
      expect(
        scanOwnedFeedstockTiles(
          game,
          _playerId,
          castIronFeedstock,
          (_) => false,
        ),
        isFalse,
      );
    });
  });

  group('playerRawLabourSupply', () {
    test('positive: tier-weighted population ceiling ignores food', () {
      // 2 peasants (1 each) + 1 journeyman (6) = 8 raw labour, regardless of an
      // empty stockpile — this is the fully-fed ceiling.
      final game = _game(
        workers: const WorkerPool(peasants: 2, journeymen: 1),
      );
      expect(playerRawLabourSupply(game, _playerId), 8);
    });

    test('positive: counts every tier (peasant/apprentice/journeyman/master)', () {
      // 1*1 + 1*4 + 1*6 + 1*8 = 19.
      final game = _game(
        workers: const WorkerPool(
          peasants: 1,
          apprentices: 1,
          journeymen: 1,
          masters: 1,
        ),
      );
      expect(playerRawLabourSupply(game, _playerId), 19);
    });

    test('negative: unknown player has no labour supply', () {
      final game = _game(workers: const WorkerPool(peasants: 10));
      expect(playerRawLabourSupply(game, 'no_such_player'), 0);
    });
  });

  group('playerEffectiveLabour', () {
    test('positive: fully-fed workers supply their full labour', () {
      // 10 peasants fed by 10 grain -> 10 effective labour (no military upkeep).
      final game = _game(
        workers: const WorkerPool(peasants: 10),
        stockpile: Stockpile(quantities: {grainId: 10}),
      );
      expect(playerEffectiveLabour(game, _playerId), 10);
    });

    test(
      'food-starved: raw ceiling exceeds effective labour when food is short',
      () {
        // 10 peasants but only 3 grain -> 3 fed -> 3 effective labour, far below
        // the raw ceiling of 10. This is the food-starved fork condition.
        final game = _game(
          workers: const WorkerPool(peasants: 10),
          stockpile: Stockpile(quantities: {grainId: 3}),
        );
        expect(playerRawLabourSupply(game, _playerId), 10);
        expect(playerEffectiveLabour(game, _playerId), lessThan(10));
        expect(playerEffectiveLabour(game, _playerId), 3);
      },
    );

    test('negative: no food means every worker strikes (zero labour)', () {
      final game = _game(
        workers: const WorkerPool(peasants: 10),
        stockpile: const Stockpile(),
      );
      expect(playerEffectiveLabour(game, _playerId), 0);
    });

    test('negative: unknown player has no effective labour', () {
      final game = _game(
        workers: const WorkerPool(peasants: 10),
        stockpile: Stockpile(quantities: {grainId: 10}),
      );
      expect(playerEffectiveLabour(game, 'no_such_player'), 0);
    });
  });

  group('playerFoodOnHand', () {
    final foodIds = {grainId, meatId};

    test('positive: sums grain and meat on hand', () {
      final game = _game(
        stockpile: Stockpile(quantities: {grainId: 7, meatId: 5, timberId: 9}),
      );
      expect(playerFoodOnHand(game, _playerId, foodIds), 12);
    });

    test('negative: empty stockpile holds no food', () {
      final game = _game(stockpile: const Stockpile());
      expect(playerFoodOnHand(game, _playerId, foodIds), 0);
    });

    test('negative: empty food id set returns zero', () {
      final game = _game(
        stockpile: Stockpile(quantities: {grainId: 7, meatId: 5}),
      );
      expect(playerFoodOnHand(game, _playerId, const {}), 0);
    });

    test('negative: unknown player holds no food', () {
      final game = _game(
        stockpile: Stockpile(quantities: {grainId: 7, meatId: 5}),
      );
      expect(playerFoodOnHand(game, 'no_such_player', foodIds), 0);
    });
  });

  group('seed42S7dCastIronLabourTurnMeasure.fabricRecipeLabourFeasible', () {
    ({
      bool peasantRecruitGate,
      bool peasantRecruitAffordable,
      bool holdsFabricFeedstock,
      bool fabricRecipeFeasible,
      bool fabricRecipeLabourFeasible,
      bool castIronMaterialFeasible,
      bool castIronLabourFeasible,
      bool castIronLabourFoodStarved,
      bool castIronLabourPopulationBound,
      bool castIronOwnsFeedstockTile,
    })
    measure(Game game) => seed42S7dCastIronLabourTurnMeasure(
      game: game,
      playerId: _playerId,
      fabricFeedstockIds: {woolId},
      fabricRecipes: [fabricFromWool],
      castIronRecipes: [castIron],
      castIronFeedstockIds: {timberId, ironId},
      castIronMinLabourPerOutput: 5,
    );

    test('positive: fabric material- and labour-feasible at 2 labour', () {
      final ci = measure(
        _game(
          workers: const WorkerPool(peasants: 2),
          stockpile: Stockpile(quantities: {grainId: 2, woolId: 2}),
        ),
      );
      expect(ci.fabricRecipeFeasible, isTrue);
      expect(ci.fabricRecipeLabourFeasible, isTrue);
    });

    test(
      'negative (circular deadlock): fabric material-feasible yet labour-'
      'starved at a single effective labour',
      () {
        final ci = measure(
          _game(
            workers: const WorkerPool(peasants: 1),
            stockpile: Stockpile(quantities: {grainId: 1, woolId: 2}),
          ),
        );
        expect(ci.fabricRecipeFeasible, isTrue);
        expect(ci.fabricRecipeLabourFeasible, isFalse);
      },
    );

    test(
      'subset invariant: labour-feasible is false whenever material-feasible '
      'is false (no wool on hand)',
      () {
        final ci = measure(
          _game(
            workers: const WorkerPool(peasants: 10),
            stockpile: Stockpile(quantities: {grainId: 10}),
          ),
        );
        expect(ci.fabricRecipeFeasible, isFalse);
        expect(ci.fabricRecipeLabourFeasible, isFalse);
      },
    );
  });

  group('castIronFeedstockExtractionLabourFutile', () {
    // castIron's labourPerOutput is 5; a lock-recovery seller's raw labour
    // ceiling sits at 1-2 on seed 42, so the helper localizes the
    // castIron-feedstock order-matching gap off the critical path.
    const castIronMinLabour = 5;

    test(
      'positive: raw labour ceiling below the castIron labourPerOutput is '
      'futile (a filled feedstock bid still cannot run the recipe)',
      () {
        // 2 peasants -> raw ceiling 2 < 5, regardless of food on hand: even a
        // fully-fed seller cannot fund one castIron run.
        final game = _game(workers: const WorkerPool(peasants: 2));
        expect(playerRawLabourSupply(game, _playerId), 2);
        expect(
          castIronFeedstockExtractionLabourFutile(
            game,
            _playerId,
            castIronMinLabour,
          ),
          isTrue,
        );
      },
    );

    test(
      'negative: raw labour ceiling at or above the castIron labourPerOutput is '
      'not futile (the feedstock bid would matter)',
      () {
        // 1 journeyman -> raw ceiling 6 >= 5: a filled timber/iron bid could
        // yield a labour-feasible castIron run, so feedstock supply is on-path.
        final game = _game(workers: const WorkerPool(journeymen: 1));
        expect(playerRawLabourSupply(game, _playerId), 6);
        expect(
          castIronFeedstockExtractionLabourFutile(
            game,
            _playerId,
            castIronMinLabour,
          ),
          isFalse,
        );
      },
    );

    test('boundary: raw ceiling exactly equal to labourPerOutput is not futile', () {
      // 5 peasants -> raw ceiling 5 == 5: one run is exactly fundable.
      final game = _game(workers: const WorkerPool(peasants: 5));
      expect(playerRawLabourSupply(game, _playerId), 5);
      expect(
        castIronFeedstockExtractionLabourFutile(
          game,
          _playerId,
          castIronMinLabour,
        ),
        isFalse,
      );
    });

    test('negative: a non-positive min labourPerOutput is never futile', () {
      // No castIron recipe (min == 0) means the labour ceiling is trivially
      // sufficient; the helper must not report futility.
      final game = _game(workers: const WorkerPool());
      expect(
        castIronFeedstockExtractionLabourFutile(game, _playerId, 0),
        isFalse,
      );
    });

    test(
      'unknown player: zero raw labour is below the positive threshold => '
      'futile',
      () {
        final game = _game(workers: const WorkerPool(peasants: 10));
        expect(
          castIronFeedstockExtractionLabourFutile(
            game,
            'no_such_player',
            castIronMinLabour,
          ),
          isTrue,
        );
      },
    );
  });

  group('recordSeed42S7dCastIronMarketOfferCounters', () {
    final castIronId = CommodityCatalog.castIron.id;

    TradeOrder offer(String id) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.offer,
      quantity: 1,
      priority: 1,
    );
    TradeOrder bid(String id) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.bid,
      quantity: 1,
      priority: 1,
    );

    test(
      'positive: another faction offers castIron => present bumped, absent not',
      () {
        final present = <String, int>{'gp3': 0};
        final absent = <String, int>{'gp3': 0};
        recordSeed42S7dCastIronMarketOfferCounters(
          feedstockGateActiveThisTurn: {'gp3'},
          tradeOrdersByPlayerId: {
            'gp1': [offer(castIronId)],
            'gp3': [bid(castIronId)],
          },
          castIronCommodityId: castIronId,
          presentTurns: present,
          absentTurns: absent,
        );
        expect(present['gp3'], 1);
        expect(absent['gp3'], 0);
      },
    );

    test(
      'negative: no other faction offers castIron (only own offer + others\' '
      'bids / unrelated offers) => absent bumped, present not',
      () {
        final present = <String, int>{'gp3': 0};
        final absent = <String, int>{'gp3': 0};
        recordSeed42S7dCastIronMarketOfferCounters(
          feedstockGateActiveThisTurn: {'gp3'},
          tradeOrdersByPlayerId: {
            // The seller's own castIron offer must not count as supply.
            'gp3': [offer(castIronId)],
            // Other GPs bid castIron (demand, not supply) or offer a
            // different commodity — neither is releasable castIron supply.
            'gp1': [bid(castIronId), offer(timberId)],
            'gp2': [offer(ironId)],
          },
          castIronCommodityId: castIronId,
          presentTurns: present,
          absentTurns: absent,
        );
        expect(present['gp3'], 0);
        expect(absent['gp3'], 1);
      },
    );

    test('gates strictly on the active set — inactive GPs are untouched', () {
      final present = <String, int>{'gp3': 0, 'gp4': 0};
      final absent = <String, int>{'gp3': 0, 'gp4': 0};
      recordSeed42S7dCastIronMarketOfferCounters(
        feedstockGateActiveThisTurn: {'gp3'},
        tradeOrdersByPlayerId: {
          'gp1': [offer(castIronId)],
        },
        castIronCommodityId: castIronId,
        presentTurns: present,
        absentTurns: absent,
      );
      expect(present['gp3'], 1);
      expect(present['gp4'], 0);
      expect(absent['gp4'], 0);
    });
  });

  group('recordSeed42S7dFabricMarketOfferCounters (Refs #2847)', () {
    final fabricId = CommodityCatalog.fabric.id;

    TradeOrder offer(String id) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.offer,
      quantity: 1,
      priority: 1,
    );
    TradeOrder bid(String id) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.bid,
      quantity: 1,
      priority: 1,
    );

    test(
      'positive: another faction offers fabric => present bumped, absent not',
      () {
        final present = <String, int>{'gp3': 0};
        final absent = <String, int>{'gp3': 0};
        recordSeed42S7dFabricMarketOfferCounters(
          fabricMarketPathActiveThisTurn: {'gp3'},
          tradeOrdersByPlayerId: {
            'gp1': [offer(fabricId)],
            'gp3': [bid(fabricId)],
          },
          presentTurns: present,
          absentTurns: absent,
        );
        expect(present['gp3'], 1);
        expect(absent['gp3'], 0);
      },
    );

    test(
      'negative: no other faction offers fabric => absent bumped, present not',
      () {
        final present = <String, int>{'gp3': 0};
        final absent = <String, int>{'gp3': 0};
        recordSeed42S7dFabricMarketOfferCounters(
          fabricMarketPathActiveThisTurn: {'gp3'},
          tradeOrdersByPlayerId: {
            'gp3': [offer(fabricId)],
            'gp1': [bid(fabricId)],
            'gp2': [offer(CommodityCatalog.timber.id)],
          },
          presentTurns: present,
          absentTurns: absent,
        );
        expect(present['gp3'], 0);
        expect(absent['gp3'], 1);
      },
    );

    test('gates strictly on the active set — inactive GPs are untouched', () {
      final present = <String, int>{'gp3': 0, 'gp5': 0};
      final absent = <String, int>{'gp3': 0, 'gp5': 0};
      recordSeed42S7dFabricMarketOfferCounters(
        fabricMarketPathActiveThisTurn: {'gp3'},
        tradeOrdersByPlayerId: {
          'gp2': [offer(fabricId)],
        },
        presentTurns: present,
        absentTurns: absent,
      );
      expect(present['gp3'], 1);
      expect(present['gp5'], 0);
      expect(absent['gp5'], 0);
    });
  });

  group('recordSeed42S7dOtherFactionOfferCounters (shared, Refs #3749)', () {
    final timberCommodityId = CommodityCatalog.timber.id;

    TradeOrder offer(String id) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.offer,
      quantity: 1,
      priority: 1,
    );
    TradeOrder bid(String id) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.bid,
      quantity: 1,
      priority: 1,
    );

    test(
      'positive: another faction offers the commodity => present bumped',
      () {
        final present = <String, int>{'gp3': 0};
        final absent = <String, int>{'gp3': 0};
        recordSeed42S7dOtherFactionOfferCounters(
          activeThisTurn: {'gp3'},
          tradeOrdersByPlayerId: {
            'gp1': [offer(timberCommodityId)],
            'gp3': [bid(timberCommodityId)],
          },
          commodityId: timberCommodityId,
          presentTurns: present,
          absentTurns: absent,
        );
        expect(present['gp3'], 1);
        expect(absent['gp3'], 0);
      },
    );

    test(
      'negative: own offer + others\' bids/unrelated offers => absent bumped',
      () {
        final present = <String, int>{'gp3': 0};
        final absent = <String, int>{'gp3': 0};
        recordSeed42S7dOtherFactionOfferCounters(
          activeThisTurn: {'gp3'},
          tradeOrdersByPlayerId: {
            'gp3': [offer(timberCommodityId)],
            'gp1': [bid(timberCommodityId)],
            'gp2': [offer(ironId)],
          },
          commodityId: timberCommodityId,
          presentTurns: present,
          absentTurns: absent,
        );
        expect(present['gp3'], 0);
        expect(absent['gp3'], 1);
      },
    );
  });
}
