// Case bodies for seed42_s7d_feedstock_helpers_test afford/ownership pins
// (Refs #3997 Phase 8).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/seed42_s7d_feedstock_helpers.dart';
import '../support/seed42_s7d_feedstock_helpers_test_support.dart';

void registerSeed42S7dFeedstockAffordOwnershipCasesTail() {
  final castIron = ProductionRecipesCatalog.castIronFromIron;
  final lumber = ProductionRecipesCatalog.lumberFromTimber;
  final fabricFromWool = ProductionRecipesCatalog.fabricFromWool;
  final timberId = CommodityCatalog.timber.id;
  final ironId = CommodityCatalog.iron.id;
  final woolId = CommodityCatalog.wool.id;
  final grainId = CommodityCatalog.grain.id;

  group('stockpileAffordsAnyProductionRecipe', () {
    test('negative: unknown player id is never feasible', () {
      final game = buildSeed42S7dFeedstockHelperGame(
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
        final game = buildSeed42S7dFeedstockHelperGame(
          workers: const WorkerPool(peasants: 2),
          stockpile: Stockpile(quantities: {grainId: 2, woolId: 2}),
        );
        expect(
          stockpileAndLabourAffordAnyProductionRecipe(game, kSeed42S7dFeedstockHelperPlayerId, [
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
        final game = buildSeed42S7dFeedstockHelperGame(
          workers: const WorkerPool(peasants: 1),
          stockpile: stockpile,
        );
        expect(
          stockpileAffordsAnyProductionRecipe(stockpile, [fabricFromWool]),
          isTrue,
          reason: 'control: the same turn is material-feasible',
        );
        expect(
          stockpileAndLabourAffordAnyProductionRecipe(game, kSeed42S7dFeedstockHelperPlayerId, [
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
      final game = buildSeed42S7dFeedstockHelperGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p0', regionId: 'oldWorld', ownerId: kSeed42S7dFeedstockHelperPlayerId),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p0': ['oldWorld|p0|2|0'],
          },
        },
        resourceByTileKey: const {'oldWorld|p0|2|0': 'timber'},
      );
      expect(
        ownsFeedstockResourceTileAnyLevel(game, kSeed42S7dFeedstockHelperPlayerId, castIronFeedstock),
        isTrue,
      );
    });

    test('negative: the feedstock tile is owned by another faction', () {
      final game = buildSeed42S7dFeedstockHelperGame(
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
        ownsFeedstockResourceTileAnyLevel(game, kSeed42S7dFeedstockHelperPlayerId, castIronFeedstock),
        isFalse,
      );
    });

    test('negative: owned tile hosts a non-feedstock resource', () {
      final game = buildSeed42S7dFeedstockHelperGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p0', regionId: 'oldWorld', ownerId: kSeed42S7dFeedstockHelperPlayerId),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p0': ['oldWorld|p0|0|0'],
          },
        },
        resourceByTileKey: const {'oldWorld|p0|0|0': 'grain'},
      );
      expect(
        ownsFeedstockResourceTileAnyLevel(game, kSeed42S7dFeedstockHelperPlayerId, castIronFeedstock),
        isFalse,
      );
    });

    test('negative: empty feedstock set never matches', () {
      final game = buildSeed42S7dFeedstockHelperGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p0', regionId: 'oldWorld', ownerId: kSeed42S7dFeedstockHelperPlayerId),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p0': ['oldWorld|p0|2|0'],
          },
        },
        resourceByTileKey: const {'oldWorld|p0|2|0': 'timber'},
      );
      expect(
        ownsFeedstockResourceTileAnyLevel(game, kSeed42S7dFeedstockHelperPlayerId, const {}),
        isFalse,
      );
    });
  });

  group('owns(Un)improvedFeedstockResourceTile improvement-level split', () {
    final castIronFeedstock = {timberId, ironId};
    const provinceId = 'oldWorld|p0';
    const tileKey = 'oldWorld|p0|2|0';

    Game gameWithImprovement(int level) => buildSeed42S7dFeedstockHelperGame(
      oldWorldProvinces: const [
        Province(id: provinceId, regionId: 'oldWorld', ownerId: kSeed42S7dFeedstockHelperPlayerId),
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
        ownsUnimprovedFeedstockResourceTile(game, kSeed42S7dFeedstockHelperPlayerId, castIronFeedstock),
        isTrue,
      );
      expect(
        ownsImprovedFeedstockResourceTile(game, kSeed42S7dFeedstockHelperPlayerId, castIronFeedstock),
        isFalse,
      );
      // Any-level probe ignores the improvement split entirely.
      expect(
        ownsFeedstockResourceTileAnyLevel(game, kSeed42S7dFeedstockHelperPlayerId, castIronFeedstock),
        isTrue,
      );
    });

    test('improved (level 1): improved probe true, unimproved probe false', () {
      final game = gameWithImprovement(1);
      expect(
        ownsImprovedFeedstockResourceTile(game, kSeed42S7dFeedstockHelperPlayerId, castIronFeedstock),
        isTrue,
      );
      expect(
        ownsUnimprovedFeedstockResourceTile(game, kSeed42S7dFeedstockHelperPlayerId, castIronFeedstock),
        isFalse,
      );
      expect(
        ownsFeedstockResourceTileAnyLevel(game, kSeed42S7dFeedstockHelperPlayerId, castIronFeedstock),
        isTrue,
      );
    });

    test('empty feedstock set: every probe is false', () {
      final game = gameWithImprovement(0);
      expect(
        ownsUnimprovedFeedstockResourceTile(game, kSeed42S7dFeedstockHelperPlayerId, const {}),
        isFalse,
      );
      expect(
        ownsImprovedFeedstockResourceTile(game, kSeed42S7dFeedstockHelperPlayerId, const {}),
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
          kSeed42S7dFeedstockHelperPlayerId,
          castIronFeedstock,
          (level) => level == 2,
        ),
        isTrue,
      );
      expect(
        scanOwnedFeedstockTiles(
          game,
          kSeed42S7dFeedstockHelperPlayerId,
          castIronFeedstock,
          (_) => false,
        ),
        isFalse,
      );
    });
  });
}
