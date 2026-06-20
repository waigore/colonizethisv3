import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:run_observer_game/observer_snapshot_v1.dart';

/// Refs #2692 S10a + S10b: `ObserverSnapshot` v3 surfaced per-player
/// `workerPool` counts; v4 adds `luxuryStockpile` and
/// `lastTurnLuxuryProduction` rollups so the workforce sustain
/// verifier can enforce §21 bullet 4 (`stockpile + production >=
/// trained-tier count`).
void main() {
  Game gameWithPools(
    Map<String, WorkerPool> poolByPlayerId, {
    Map<String, Stockpile> stockpileByPlayerId = const {},
  }) {
    return Game(
      id: 'g-workforce',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 100),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [
        for (final entry in poolByPlayerId.entries)
          Player(
            id: entry.key,
            displayName: entry.key.toUpperCase(),
            isHuman: false,
            workerPool: entry.value,
            stockpile: stockpileByPlayerId[entry.key] ?? Stockpile.empty,
          ),
      ],
    );
  }

  group('ObserverSnapshot v4 worker pool exposure', () {
    test('schema version is 4', () {
      expect(observerSnapshotSchemaVersion, 4);
    });

    test('player rollups include a workerPool block with all four tiers', () {
      final game = gameWithPools({
        'gp1': const WorkerPool(
          peasants: 17,
          apprentices: 4,
          journeymen: 3,
          masters: 1,
        ),
      });

      final snapshot = buildObserverSnapshotJson(
        game,
        postResolutionTurnNumber: 100,
      );

      expect(snapshot['observerSnapshotSchemaVersion'], 4);
      final players = snapshot['players'] as List<Object?>;
      final gp1 = players.cast<Map<String, Object?>>().single;
      expect(gp1['playerId'], 'gp1');

      final pool = gp1['workerPool'] as Map<String, Object?>;
      expect(pool['peasants'], 17);
      expect(pool['apprentices'], 4);
      expect(pool['journeymen'], 3);
      expect(pool['masters'], 1);
    });

    test('empty pool serialises to zeros (does not omit fields)', () {
      final game = gameWithPools({'gp1': WorkerPool.empty});

      final snapshot = buildObserverSnapshotJson(
        game,
        postResolutionTurnNumber: 1,
      );

      final pool = (snapshot['players'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .single['workerPool'] as Map<String, Object?>;
      expect(pool['peasants'], 0);
      expect(pool['apprentices'], 0);
      expect(pool['journeymen'], 0);
      expect(pool['masters'], 0);
    });

    test('every player rollup carries its own workerPool block', () {
      final game = gameWithPools({
        'gp1': const WorkerPool(peasants: 5),
        'gp2': const WorkerPool(peasants: 0, masters: 2),
        'gp3': const WorkerPool(apprentices: 1, journeymen: 1),
      });

      final snapshot = buildObserverSnapshotJson(
        game,
        postResolutionTurnNumber: 100,
      );

      final players = (snapshot['players'] as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(players, hasLength(3));
      for (final row in players) {
        expect(row['workerPool'], isA<Map<String, Object?>>());
        final pool = row['workerPool'] as Map<String, Object?>;
        expect(pool.keys.toList()..sort(), <String>[
          'apprentices',
          'journeymen',
          'masters',
          'peasants',
        ]);
      }
    });

    test('player rollup keeps existing v2 fields alongside workerPool', () {
      final game = gameWithPools({
        'gp1': const WorkerPool(peasants: 10),
      });

      final snapshot = buildObserverSnapshotJson(
        game,
        postResolutionTurnNumber: 100,
      );

      final gp1 = (snapshot['players'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .single;

      expect(gp1.containsKey('playerId'), isTrue);
      expect(gp1.containsKey('displayName'), isTrue);
      expect(gp1.containsKey('greatPowerPowerScore'), isTrue);
      expect(gp1.containsKey('treasuryPounds'), isTrue);
      expect(gp1.containsKey('regimentLikeUnitCountHint'), isTrue);
      expect(gp1.containsKey('fleetShipCountHint'), isTrue);
      expect(gp1.containsKey('techUnlockedIds'), isTrue);
      expect(gp1.containsKey('workerPool'), isTrue);
    });
  });

  group('ObserverSnapshot v4 luxury rollups', () {
    test(
      'luxuryStockpile exposes refinedSugar / cigars / furHats from stockpile',
      () {
        final game = gameWithPools(
          {'gp1': const WorkerPool(peasants: 5)},
          stockpileByPlayerId: {
            'gp1': const Stockpile(
              quantities: <String, int>{
                'refinedSugar': 12,
                'cigars': 4,
                'furHats': 7,
                'grain': 99,
              },
            ),
          },
        );

        final snapshot = buildObserverSnapshotJson(
          game,
          postResolutionTurnNumber: 100,
        );

        final gp1 = (snapshot['players'] as List<Object?>)
            .cast<Map<String, Object?>>()
            .single;
        final luxury = gp1['luxuryStockpile'] as Map<String, Object?>;
        expect(luxury['refinedSugar'], 12);
        expect(luxury['cigars'], 4);
        expect(luxury['furHats'], 7);
        expect(luxury.containsKey('grain'), isFalse);
      },
    );

    test('luxuryStockpile defaults to zeros when stockpile lacks commodity', () {
      final game = gameWithPools({'gp1': WorkerPool.empty});

      final snapshot = buildObserverSnapshotJson(
        game,
        postResolutionTurnNumber: 1,
      );

      final luxury = (snapshot['players'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .single['luxuryStockpile'] as Map<String, Object?>;
      expect(luxury['refinedSugar'], 0);
      expect(luxury['cigars'], 0);
      expect(luxury['furHats'], 0);
    });

    test(
      'lastTurnLuxuryProduction aggregates recipe outputs by output commodity',
      () {
        final game = gameWithPools({'gp1': WorkerPool.empty});

        final snapshot = buildObserverSnapshotJson(
          game,
          postResolutionTurnNumber: 100,
          lastTurnProductionByRecipeByPlayerId: const <String, Map<String, int>>{
            'gp1': <String, int>{
              'refinedSugar_from_sugarCane': 3,
              'cigars_from_tobacco': 2,
              'furHats_from_furs': 1,
              // Non-luxury recipes must be ignored.
              'fabric_from_wool': 5,
              'paper_from_timber': 4,
            },
          },
        );

        final production = (snapshot['players'] as List<Object?>)
                .cast<Map<String, Object?>>()
                .single['lastTurnLuxuryProduction']
            as Map<String, Object?>;
        expect(production['refinedSugar'], 3);
        expect(production['cigars'], 2);
        expect(production['furHats'], 1);
        expect(production.containsKey('fabric'), isFalse);
        expect(production.containsKey('paper'), isFalse);
      },
    );

    test('lastTurnLuxuryProduction is zeros when no callback data supplied', () {
      final game = gameWithPools({'gp1': WorkerPool.empty});

      final snapshot = buildObserverSnapshotJson(
        game,
        postResolutionTurnNumber: 100,
      );

      final production = (snapshot['players'] as List<Object?>)
              .cast<Map<String, Object?>>()
              .single['lastTurnLuxuryProduction']
          as Map<String, Object?>;
      expect(production['refinedSugar'], 0);
      expect(production['cigars'], 0);
      expect(production['furHats'], 0);
    });

    test(
      'unknown recipe ids in production map do not crash the snapshot builder',
      () {
        final game = gameWithPools({'gp1': WorkerPool.empty});

        expect(
          () => buildObserverSnapshotJson(
            game,
            postResolutionTurnNumber: 100,
            lastTurnProductionByRecipeByPlayerId:
                const <String, Map<String, int>>{
              'gp1': <String, int>{
                'mystery_recipe_id_that_does_not_exist': 99,
              },
            },
          ),
          returnsNormally,
        );
      },
    );

    test(
      'production map keyed by absent player id leaves that player\'s rollup at zeros',
      () {
        final game = gameWithPools({
          'gp1': WorkerPool.empty,
          'gp2': WorkerPool.empty,
        });

        final snapshot = buildObserverSnapshotJson(
          game,
          postResolutionTurnNumber: 100,
          lastTurnProductionByRecipeByPlayerId:
              const <String, Map<String, int>>{
            'gp1': <String, int>{'cigars_from_tobacco': 2},
          },
        );

        final players = (snapshot['players'] as List<Object?>)
            .cast<Map<String, Object?>>();
        final gp1 = players.firstWhere((r) => r['playerId'] == 'gp1');
        final gp2 = players.firstWhere((r) => r['playerId'] == 'gp2');
        expect(
          (gp1['lastTurnLuxuryProduction'] as Map<String, Object?>)['cigars'],
          2,
        );
        expect(
          (gp2['lastTurnLuxuryProduction'] as Map<String, Object?>)['cigars'],
          0,
        );
      },
    );

    test('kObserverSnapshotLuxuryCommodityIds ordering pins the v4 contract', () {
      expect(kObserverSnapshotLuxuryCommodityIds, <String>[
        'refinedSugar',
        'cigars',
        'furHats',
      ]);
    });
  });
}
