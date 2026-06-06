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
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
      resourceByTileKey: resourceByTileKey,
      tileState: TileMapState(),
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
  final timberId = CommodityCatalog.timber.id;
  final ironId = CommodityCatalog.iron.id;
  final grainId = CommodityCatalog.grain.id;

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
}
