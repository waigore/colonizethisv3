import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_test/test.dart';

import 'package:run_observer_game/observer_conquest_verify.dart'
    show kObserverGreatPowerIds, observerTurnSnapshotPath;
import 'package:run_observer_game/observer_workforce_verify.dart';

Map<String, Object?> _snapshotWithWorkerPools(
  Map<String, WorkerPoolCounts> byGp,
) {
  final players = <Map<String, Object?>>[];
  for (final entry in byGp.entries) {
    players.add(<String, Object?>{
      'playerId': entry.key,
      'displayName': entry.key.toUpperCase(),
      'isHuman': false,
      'workerPool': <String, Object?>{
        'peasants': entry.value.peasants,
        'apprentices': entry.value.apprentices,
        'journeymen': entry.value.journeymen,
        'masters': entry.value.masters,
      },
    });
  }
  return <String, Object?>{'players': players};
}

WorkerPoolCounts _meetsBoth() => const WorkerPoolCounts(
      peasants: 20,
      apprentices: 5,
      journeymen: 3,
      masters: 1,
    );

void _writeSnapshot(
  String dir,
  int turnNumber,
  Map<String, Object?> snapshot,
) {
  final path = observerTurnSnapshotPath(
    tracesGameDir: dir,
    turnNumber: turnNumber,
  );
  File(path).writeAsStringSync(jsonEncode(snapshot));
}

void main() {
  group('workerPoolCountsForPlayer', () {
    test('returns counts when player rollup contains workerPool', () {
      final snap = _snapshotWithWorkerPools({
        'gp1': const WorkerPoolCounts(
          peasants: 12,
          apprentices: 3,
          journeymen: 2,
          masters: 1,
        ),
      });
      final got = workerPoolCountsForPlayer(snap, 'gp1');
      expect(got.peasants, 12);
      expect(got.apprentices, 3);
      expect(got.journeymen, 2);
      expect(got.masters, 1);
      expect(got.trained, 6);
    });

    test('returns zero when players list is missing or wrong type', () {
      expect(workerPoolCountsForPlayer(<String, Object?>{}, 'gp1').peasants, 0);
      expect(
        workerPoolCountsForPlayer(
          <String, Object?>{'players': 'not-a-list'},
          'gp1',
        ).peasants,
        0,
      );
    });

    test('returns zero when player rollup has no workerPool block (v2)', () {
      final snap = <String, Object?>{
        'players': <Object?>[
          <String, Object?>{'playerId': 'gp1', 'displayName': 'GP1'},
        ],
      };
      final got = workerPoolCountsForPlayer(snap, 'gp1');
      expect(got.peasants, 0);
      expect(got.trained, 0);
    });

    test('returns zero when player id is absent', () {
      final snap = _snapshotWithWorkerPools({
        'gp1': const WorkerPoolCounts(
          peasants: 5,
          apprentices: 0,
          journeymen: 0,
          masters: 0,
        ),
      });
      expect(workerPoolCountsForPlayer(snap, 'gp9').peasants, 0);
    });

    test('coerces numeric strings and num values', () {
      final snap = <String, Object?>{
        'players': <Object?>[
          <String, Object?>{
            'playerId': 'gp1',
            'workerPool': <String, Object?>{
              'peasants': '14',
              'apprentices': 4.0,
              'journeymen': '2',
              'masters': 1,
            },
          },
        ],
      };
      final got = workerPoolCountsForPlayer(snap, 'gp1');
      expect(got.peasants, 14);
      expect(got.apprentices, 4);
      expect(got.journeymen, 2);
      expect(got.masters, 1);
    });
  });

  group('verifyPerGpWorkforceSustain', () {
    test('passes when every GP meets both thresholds', () {
      final snap = _snapshotWithWorkerPools({
        for (final gp in kObserverGreatPowerIds) gp: _meetsBoth(),
      });
      expect(verifyPerGpWorkforceSustain(turnEndSnapshot: snap), isEmpty);
    });

    test('emits one failure line per failing threshold per GP', () {
      final snap = _snapshotWithWorkerPools({
        for (final gp in kObserverGreatPowerIds) gp: _meetsBoth(),
      });
      (snap['players'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .firstWhere((r) => r['playerId'] == 'gp3')['workerPool'] =
          <String, Object?>{
        'peasants': 5,
        'apprentices': 0,
        'journeymen': 0,
        'masters': 0,
      };

      final failures = verifyPerGpWorkforceSustain(turnEndSnapshot: snap);
      expect(failures, hasLength(2));
      expect(failures.any((f) => f.startsWith('gp3 peasants=5')), isTrue);
      expect(failures.any((f) => f.startsWith('gp3 trained=0')), isTrue);
    });

    test('reports missing rollups as zero counts (worst-case fail)', () {
      final snap = <String, Object?>{'players': <Object?>[]};
      final failures = verifyPerGpWorkforceSustain(turnEndSnapshot: snap);
      expect(failures.length, kObserverGreatPowerIds.length * 2);
      for (final gp in kObserverGreatPowerIds) {
        expect(failures.any((f) => f.startsWith('$gp peasants=0')), isTrue);
        expect(failures.any((f) => f.startsWith('$gp trained=0')), isTrue);
      }
    });

    test('thresholds are overridable for tuning', () {
      final snap = _snapshotWithWorkerPools({
        for (final gp in kObserverGreatPowerIds)
          gp: const WorkerPoolCounts(
            peasants: 5,
            apprentices: 1,
            journeymen: 0,
            masters: 0,
          ),
      });
      expect(
        verifyPerGpWorkforceSustain(
          turnEndSnapshot: snap,
          minPeasants: 5,
          minTrained: 1,
        ),
        isEmpty,
      );
    });

    test('default thresholds match documented v1 metric (15 / 8)', () {
      expect(kObserverWorkforceMinPeasants, 15);
      expect(kObserverWorkforceMinTrained, 8);
      expect(kObserverWorkforceCanonicalTurn, 100);
      expect(kObserverWorkforceFoodLuxuryDeferred, isTrue);
    });

    test('peasant-only failure surfaces only the peasant line for that GP', () {
      final snap = _snapshotWithWorkerPools({
        for (final gp in kObserverGreatPowerIds) gp: _meetsBoth(),
      });
      (snap['players'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .firstWhere((r) => r['playerId'] == 'gp2')['workerPool'] =
          <String, Object?>{
        'peasants': 14,
        'apprentices': 5,
        'journeymen': 3,
        'masters': 1,
      };

      final failures = verifyPerGpWorkforceSustain(turnEndSnapshot: snap);
      expect(failures, hasLength(1));
      expect(failures.single, startsWith('gp2 peasants=14'));
    });

    test('trained-only failure surfaces only the trained line for that GP', () {
      final snap = _snapshotWithWorkerPools({
        for (final gp in kObserverGreatPowerIds) gp: _meetsBoth(),
      });
      (snap['players'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .firstWhere((r) => r['playerId'] == 'gp4')['workerPool'] =
          <String, Object?>{
        'peasants': 20,
        'apprentices': 4,
        'journeymen': 2,
        'masters': 1,
      };

      final failures = verifyPerGpWorkforceSustain(turnEndSnapshot: snap);
      expect(failures, hasLength(1));
      expect(failures.single, startsWith('gp4 trained=7'));
    });
  });

  group('verifyObserverWorkforceFromTraceDir', () {
    test('returns failures when end snapshot is missing', () {
      final tmp = Directory.systemTemp.createTempSync('obs_workforce_missing_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final failures = verifyObserverWorkforceFromTraceDir(tmp.path);
      expect(failures, hasLength(1));
      expect(failures.single, contains('missing end snapshot'));
    });

    test('passes when turn-100 snapshot meets thresholds for every GP', () {
      final tmp = Directory.systemTemp.createTempSync('obs_workforce_pass_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _writeSnapshot(
        tmp.path,
        kObserverWorkforceCanonicalTurn,
        _snapshotWithWorkerPools({
          for (final gp in kObserverGreatPowerIds) gp: _meetsBoth(),
        }),
      );

      expect(verifyObserverWorkforceFromTraceDir(tmp.path), isEmpty);
    });

    test('honours endTurn override and surfaces threshold failures', () {
      final tmp = Directory.systemTemp.createTempSync('obs_workforce_alt_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      _writeSnapshot(
        tmp.path,
        50,
        _snapshotWithWorkerPools({
          for (final gp in kObserverGreatPowerIds)
            gp: const WorkerPoolCounts(
              peasants: 8,
              apprentices: 1,
              journeymen: 0,
              masters: 0,
            ),
        }),
      );

      final failures = verifyObserverWorkforceFromTraceDir(
        tmp.path,
        endTurn: 50,
      );
      expect(failures, isNotEmpty);
      expect(failures.any((f) => f.contains('peasants=8')), isTrue);
      expect(failures.any((f) => f.contains('trained=1')), isTrue);
    });
  });
}
