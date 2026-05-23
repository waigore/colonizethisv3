import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_test/test.dart';

import 'package:run_observer_game/observer_conquest_verify.dart'
    show kObserverGreatPowerIds, observerTurnSnapshotPath;
import 'package:run_observer_game/observer_workforce_verify.dart';

/// Builds a v4-shaped snapshot. By default each player rollup includes
/// `luxuryStockpile` and `lastTurnLuxuryProduction` blocks sized to
/// satisfy the §21 bullet 4 luxury sustain check for the GP's worker
/// pool, so existing tests that only exercise peasant + trained
/// thresholds remain green. Override [luxuryStockpileByGp] and/or
/// [lastTurnLuxuryProductionByGp] to test luxury-specific behaviour.
Map<String, Object?> _snapshotWithWorkerPools(
  Map<String, WorkerPoolCounts> byGp, {
  Map<String, Map<String, int>>? luxuryStockpileByGp,
  Map<String, Map<String, int>>? lastTurnLuxuryProductionByGp,
}) {
  Map<String, int> defaultLuxuryStockpileFor(WorkerPoolCounts counts) =>
      <String, int>{
        'refinedSugar': counts.apprentices,
        'cigars': counts.journeymen,
        'furHats': counts.masters,
      };

  final players = <Map<String, Object?>>[];
  for (final entry in byGp.entries) {
    final counts = entry.value;
    final luxuryStockpile =
        luxuryStockpileByGp?[entry.key] ?? defaultLuxuryStockpileFor(counts);
    final lastTurnLuxuryProduction =
        lastTurnLuxuryProductionByGp?[entry.key] ?? const <String, int>{
          'refinedSugar': 0,
          'cigars': 0,
          'furHats': 0,
        };
    players.add(<String, Object?>{
      'playerId': entry.key,
      'displayName': entry.key.toUpperCase(),
      'isHuman': false,
      'workerPool': <String, Object?>{
        'peasants': counts.peasants,
        'apprentices': counts.apprentices,
        'journeymen': counts.journeymen,
        'masters': counts.masters,
      },
      'luxuryStockpile': <String, Object?>{
        'refinedSugar': luxuryStockpile['refinedSugar'] ?? 0,
        'cigars': luxuryStockpile['cigars'] ?? 0,
        'furHats': luxuryStockpile['furHats'] ?? 0,
      },
      'lastTurnLuxuryProduction': <String, Object?>{
        'refinedSugar': lastTurnLuxuryProduction['refinedSugar'] ?? 0,
        'cigars': lastTurnLuxuryProduction['cigars'] ?? 0,
        'furHats': lastTurnLuxuryProduction['furHats'] ?? 0,
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
      // S10b narrows the deferral to food production only.
      expect(kObserverWorkforceFoodProductionDeferred, isTrue);
      expect(kObserverWorkforceApprenticeLuxuryCommodityId, 'refinedSugar');
      expect(kObserverWorkforceJourneymanLuxuryCommodityId, 'cigars');
      expect(kObserverWorkforceMasterLuxuryCommodityId, 'furHats');
      expect(kObserverWorkforceLuxuryTierMapping.map((e) => e.tier).toList(),
          <String>['apprentices', 'journeymen', 'masters']);
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

  group('luxuryAvailableForPlayer', () {
    test('sums luxuryStockpile and lastTurnLuxuryProduction', () {
      final snap = _snapshotWithWorkerPools(
        {
          'gp1': const WorkerPoolCounts(
            peasants: 1,
            apprentices: 1,
            journeymen: 0,
            masters: 0,
          ),
        },
        luxuryStockpileByGp: const {
          'gp1': <String, int>{'refinedSugar': 4},
        },
        lastTurnLuxuryProductionByGp: const {
          'gp1': <String, int>{'refinedSugar': 3},
        },
      );

      expect(luxuryAvailableForPlayer(snap, 'gp1', 'refinedSugar'), 7);
    });

    test('returns 0 when the player rollup is missing', () {
      final snap = <String, Object?>{'players': <Object?>[]};
      expect(luxuryAvailableForPlayer(snap, 'gp1', 'refinedSugar'), 0);
    });

    test('returns 0 when both luxury blocks are absent (v3 snapshot)', () {
      final snap = <String, Object?>{
        'players': <Object?>[
          <String, Object?>{
            'playerId': 'gp1',
            'workerPool': <String, Object?>{
              'peasants': 10,
              'apprentices': 1,
              'journeymen': 0,
              'masters': 0,
            },
          },
        ],
      };
      expect(luxuryAvailableForPlayer(snap, 'gp1', 'refinedSugar'), 0);
    });
  });

  group('verifyPerGpLuxurySustain', () {
    test('passes when every trained tier is matched by stockpile + production',
        () {
      final snap = _snapshotWithWorkerPools({
        for (final gp in kObserverGreatPowerIds) gp: _meetsBoth(),
      });

      expect(verifyPerGpLuxurySustain(turnEndSnapshot: snap), isEmpty);
    });

    test('passes when production covers tier count even with zero stockpile',
        () {
      final snap = _snapshotWithWorkerPools(
        {
          'gp1': const WorkerPoolCounts(
            peasants: 20,
            apprentices: 3,
            journeymen: 0,
            masters: 0,
          ),
        },
        luxuryStockpileByGp: const {
          'gp1': <String, int>{'refinedSugar': 0},
        },
        lastTurnLuxuryProductionByGp: const {
          'gp1': <String, int>{'refinedSugar': 3},
        },
      );

      expect(verifyPerGpLuxurySustain(turnEndSnapshot: snap), isEmpty);
    });

    test('passes when stockpile covers tier count even with zero production',
        () {
      final snap = _snapshotWithWorkerPools(
        {
          'gp1': const WorkerPoolCounts(
            peasants: 20,
            apprentices: 0,
            journeymen: 0,
            masters: 2,
          ),
        },
        luxuryStockpileByGp: const {
          'gp1': <String, int>{'furHats': 2},
        },
        lastTurnLuxuryProductionByGp: const {
          'gp1': <String, int>{'furHats': 0},
        },
      );

      expect(verifyPerGpLuxurySustain(turnEndSnapshot: snap), isEmpty);
    });

    test('skips tiers with zero count regardless of luxury availability', () {
      final snap = _snapshotWithWorkerPools(
        {
          'gp1': const WorkerPoolCounts(
            peasants: 20,
            apprentices: 0,
            journeymen: 0,
            masters: 0,
          ),
        },
        luxuryStockpileByGp: const {
          'gp1': <String, int>{
            'refinedSugar': 0,
            'cigars': 0,
            'furHats': 0,
          },
        },
        lastTurnLuxuryProductionByGp: const {
          'gp1': <String, int>{
            'refinedSugar': 0,
            'cigars': 0,
            'furHats': 0,
          },
        },
      );

      expect(verifyPerGpLuxurySustain(turnEndSnapshot: snap), isEmpty);
    });

    test('emits one failure line per shortfall tier per GP', () {
      final snap = _snapshotWithWorkerPools(
        {
          'gp1': const WorkerPoolCounts(
            peasants: 20,
            apprentices: 4,
            journeymen: 2,
            masters: 1,
          ),
        },
        luxuryStockpileByGp: const {
          'gp1': <String, int>{
            'refinedSugar': 1,
            'cigars': 0,
            'furHats': 0,
          },
        },
        lastTurnLuxuryProductionByGp: const {
          'gp1': <String, int>{
            'refinedSugar': 1,
            'cigars': 1,
            'furHats': 0,
          },
        },
      );

      final failures = verifyPerGpLuxurySustain(turnEndSnapshot: snap);
      expect(failures, hasLength(3));
      expect(
        failures[0],
        startsWith('gp1 apprentices=4 refinedSugar_available=2'),
      );
      expect(failures[0], contains('stockpile=1 lastTurnProduction=1'));
      expect(failures[1], startsWith('gp1 journeymen=2 cigars_available=1'));
      expect(failures[2], startsWith('gp1 masters=1 furHats_available=0'));
    });

    test('failure ordering is apprentice → journeyman → master per GP', () {
      final snap = _snapshotWithWorkerPools(
        {
          for (final gp in kObserverGreatPowerIds)
            gp: const WorkerPoolCounts(
              peasants: 20,
              apprentices: 1,
              journeymen: 1,
              masters: 1,
            ),
        },
        luxuryStockpileByGp: <String, Map<String, int>>{
          for (final gp in kObserverGreatPowerIds)
            gp: const <String, int>{
              'refinedSugar': 0,
              'cigars': 0,
              'furHats': 0,
            },
        },
      );

      final failures = verifyPerGpLuxurySustain(turnEndSnapshot: snap);
      expect(failures, hasLength(kObserverGreatPowerIds.length * 3));
      for (var i = 0; i < kObserverGreatPowerIds.length; i++) {
        final gp = kObserverGreatPowerIds[i];
        expect(failures[i * 3 + 0], startsWith('$gp apprentices='));
        expect(failures[i * 3 + 1], startsWith('$gp journeymen='));
        expect(failures[i * 3 + 2], startsWith('$gp masters='));
      }
    });

    test('treats missing luxury blocks (v3 snapshots) as zero availability',
        () {
      final snap = <String, Object?>{
        'players': <Object?>[
          <String, Object?>{
            'playerId': 'gp1',
            'workerPool': <String, Object?>{
              'peasants': 20,
              'apprentices': 1,
              'journeymen': 0,
              'masters': 0,
            },
          },
        ],
      };

      final failures = verifyPerGpLuxurySustain(turnEndSnapshot: snap);
      expect(failures.any((f) => f.startsWith('gp1 apprentices=1')), isTrue);
      expect(failures.any((f) => f.contains('refinedSugar_available=0')),
          isTrue);
    });
  });

  group('verifyPerGpWorkforceSustain checkLuxurySustain integration', () {
    test('default checkLuxurySustain=true surfaces luxury failures', () {
      final snap = _snapshotWithWorkerPools(
        {
          'gp1': const WorkerPoolCounts(
            peasants: 20,
            apprentices: 0,
            journeymen: 0,
            masters: 1,
          ),
        },
        luxuryStockpileByGp: const {
          'gp1': <String, int>{'furHats': 0},
        },
        lastTurnLuxuryProductionByGp: const {
          'gp1': <String, int>{'furHats': 0},
        },
      );

      // gp1 meets peasants but not trained (1 < 8) — produces a trained
      // failure. Other GPs have no rollup → 6 × (peasants + trained)
      // failures. gp1 also produces a master luxury failure.
      final failures = verifyPerGpWorkforceSustain(turnEndSnapshot: snap);
      expect(
        failures.where((f) => f.contains('furHats_available=0')).length,
        1,
      );
    });

    test('checkLuxurySustain=false skips the luxury pass', () {
      final snap = _snapshotWithWorkerPools(
        {
          for (final gp in kObserverGreatPowerIds)
            gp: const WorkerPoolCounts(
              peasants: 20,
              apprentices: 5,
              journeymen: 3,
              masters: 1,
            ),
        },
        luxuryStockpileByGp: <String, Map<String, int>>{
          for (final gp in kObserverGreatPowerIds)
            gp: const <String, int>{
              'refinedSugar': 0,
              'cigars': 0,
              'furHats': 0,
            },
        },
        lastTurnLuxuryProductionByGp: <String, Map<String, int>>{
          for (final gp in kObserverGreatPowerIds)
            gp: const <String, int>{
              'refinedSugar': 0,
              'cigars': 0,
              'furHats': 0,
            },
        },
      );

      // With opt-out, only the peasants+trained checks run; both pass.
      expect(
        verifyPerGpWorkforceSustain(
          turnEndSnapshot: snap,
          checkLuxurySustain: false,
        ),
        isEmpty,
      );
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
