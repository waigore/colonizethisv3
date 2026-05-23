import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:run_observer_game/observer_snapshot_v1.dart';

/// Refs #2692 S10a: `ObserverSnapshot` v3 must surface per-player
/// `workerPool` counts so the workforce sustain verifier can read
/// peasants and trained-tier counts directly from the snapshot.
void main() {
  Game _gameWithPools(Map<String, WorkerPool> poolByPlayerId) {
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
          ),
      ],
    );
  }

  group('ObserverSnapshot v3 worker pool exposure', () {
    test('schema version is 3', () {
      expect(observerSnapshotSchemaVersion, 3);
    });

    test('player rollups include a workerPool block with all four tiers', () {
      final game = _gameWithPools({
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

      expect(snapshot['observerSnapshotSchemaVersion'], 3);
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
      final game = _gameWithPools({'gp1': WorkerPool.empty});

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
      final game = _gameWithPools({
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
      final game = _gameWithPools({
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
}
