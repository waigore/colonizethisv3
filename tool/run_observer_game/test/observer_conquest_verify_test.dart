import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_test/test.dart';

import 'package:run_observer_game/observer_conquest_verify.dart';

Map<String, Object?> _snapshotWithOwOwnership(Map<String, String> owByGp) {
  final rows = <Map<String, String?>>[];
  for (final entry in owByGp.entries) {
    rows.add(<String, String?>{
      'id': 'oldWorld|p_${entry.key}',
      'ownerId': entry.value,
    });
  }
  rows.add(<String, String?>{'id': 'newWorld|p_nw1', 'ownerId': 'gp1'});
  rows.sort((a, b) => (a['id'] ?? '').compareTo(b['id'] ?? ''));
  return <String, Object?>{'provinceOwnershipSorted': rows};
}

/// Snapshot where every GP holds [perGpCount] Old World provinces.
Map<String, Object?> _uniformOwSnapshot(int perGpCount) {
  final rows = <Map<String, String?>>[];
  for (final gp in kObserverGreatPowerIds) {
    for (var i = 0; i < perGpCount; i++) {
      rows.add(<String, String?>{
        'id': 'oldWorld|${gp}_$i',
        'ownerId': gp,
      });
    }
  }
  rows.sort((a, b) => (a['id'] ?? '').compareTo(b['id'] ?? ''));
  return <String, Object?>{'provinceOwnershipSorted': rows};
}

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
  group('countOldWorldProvincesOwned', () {
    test('counts only oldWorld| provinces for owner', () {
      final snap = _snapshotWithOwOwnership(<String, String>{
        'gp1a': 'gp1',
        'gp1b': 'gp1',
        'gp2': 'gp2',
      });
      expect(countOldWorldProvincesOwned(snap, 'gp1'), 2);
      expect(countOldWorldProvincesOwned(snap, 'gp2'), 1);
    });
  });

  group('verifyPerGpOldWorldConquestGains', () {
    test('passes when each GP gains at least minGain', () {
      final start = _snapshotWithOwOwnership(<String, String>{
        for (final gp in kObserverGreatPowerIds) gp: gp,
      });
      final endRows = <Map<String, String?>>[];
      for (final gp in kObserverGreatPowerIds) {
        for (var i = 0; i < 10; i++) {
          endRows.add(<String, String?>{
            'id': 'oldWorld|p_${gp}_$i',
            'ownerId': gp,
          });
        }
      }
      endRows.sort((a, b) => (a['id'] ?? '').compareTo(b['id'] ?? ''));
      final end = <String, Object?>{'provinceOwnershipSorted': endRows};

      expect(
        verifyPerGpOldWorldConquestGains(
          turnStartSnapshot: start,
          turnEndSnapshot: end,
          minGainPerGp: 3,
        ),
        isEmpty,
      );
    });

    test('fails when a GP gains fewer than minGain', () {
      final start = _snapshotWithOwOwnership(<String, String>{
        'gp1': 'gp1',
        'gp2': 'gp2',
        'gp3': 'gp3',
        'gp4': 'gp4',
        'gp5': 'gp5',
        'gp6': 'gp6',
      });
      final end = _snapshotWithOwOwnership(<String, String>{
        'gp1': 'gp1',
        'gp1b': 'gp1',
        'gp2': 'gp2',
        'gp3': 'gp3',
        'gp4': 'gp4',
        'gp5': 'gp5',
        'gp6': 'gp6',
      });

      final failures = verifyPerGpOldWorldConquestGains(
        turnStartSnapshot: start,
        turnEndSnapshot: end,
        minGainPerGp: 3,
      );
      expect(failures, isNotEmpty);
      expect(failures.first, contains('gp1'));
    });

    test('lists every GP that falls short (multiple offenders)', () {
      final start = _uniformOwSnapshot(7);
      final endRows = <Map<String, String?>>[
        for (final gp in kObserverGreatPowerIds)
          for (var i = 0; i < (gp == 'gp1' ? 10 : 7); i++)
            <String, String?>{'id': 'oldWorld|${gp}_$i', 'ownerId': gp},
      ]..sort((a, b) => (a['id'] ?? '').compareTo(b['id'] ?? ''));
      final end = <String, Object?>{'provinceOwnershipSorted': endRows};
      final failures = verifyPerGpOldWorldConquestGains(
        turnStartSnapshot: start,
        turnEndSnapshot: end,
      );
      expect(failures.length, 5);
      expect(failures.any((l) => l.contains('gp1')), isFalse);
      for (final gp in ['gp2', 'gp3', 'gp4', 'gp5', 'gp6']) {
        expect(
          failures.any((l) => l.contains(gp)),
          isTrue,
          reason: '$gp should be flagged as short on conquest',
        );
      }
    });
  });

  group('oldWorldProvinceCountsByGp', () {
    test('returns zero for every GP when snapshot is empty', () {
      final counts = oldWorldProvinceCountsByGp(<String, Object?>{
        'provinceOwnershipSorted': const [],
      });
      expect(counts.keys.toSet(), kObserverGreatPowerIds.toSet());
      expect(counts.values.toSet(), {0});
    });

    test('counts Old World holdings per GP and ignores other regions', () {
      final snap = _snapshotWithOwOwnership(<String, String>{
        'a': 'gp1',
        'b': 'gp1',
        'c': 'gp2',
      });
      final counts = oldWorldProvinceCountsByGp(snap);
      expect(counts['gp1'], 2);
      expect(counts['gp2'], 1);
      expect(counts['gp3'], 0);
    });
  });

  group('countOldWorldProvincesOwned defensive cases', () {
    test('returns zero when provinceOwnershipSorted is missing', () {
      expect(
        countOldWorldProvincesOwned(<String, Object?>{}, 'gp1'),
        0,
      );
    });

    test('returns zero when provinceOwnershipSorted is not a list', () {
      expect(
        countOldWorldProvincesOwned(
          <String, Object?>{'provinceOwnershipSorted': 'not-a-list'},
          'gp1',
        ),
        0,
      );
    });

    test('skips non-map rows without throwing', () {
      final snap = <String, Object?>{
        'provinceOwnershipSorted': [
          {'id': 'oldWorld|p1', 'ownerId': 'gp1'},
          'malformed',
          42,
        ],
      };
      expect(countOldWorldProvincesOwned(snap, 'gp1'), 1);
    });
  });

  group('observerTurnSnapshotPath', () {
    test('zero-pads turn number to six digits', () {
      expect(
        observerTurnSnapshotPath(tracesGameDir: '/tmp/g1', turnNumber: 7),
        '/tmp/g1/turn-000007.snapshot.json',
      );
      expect(
        observerTurnSnapshotPath(tracesGameDir: '/tmp/g1', turnNumber: 100),
        '/tmp/g1/turn-000100.snapshot.json',
      );
    });
  });

  group('verifyObserverConquestFromTraceDir', () {
    test('returns empty failures when every GP gains >=3 between turn 1 and 100',
        () {
      final tmp = Directory.systemTemp.createTempSync('conquest_pass_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      _writeSnapshot(tmp.path, 1, _uniformOwSnapshot(7));
      _writeSnapshot(tmp.path, kObserverConquestCanonicalTurns,
          _uniformOwSnapshot(10));
      expect(
        verifyObserverConquestFromTraceDir(tmp.path),
        isEmpty,
      );
    });

    test('lists every short-gain GP from disk-loaded snapshots', () {
      final tmp = Directory.systemTemp.createTempSync('conquest_short_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      _writeSnapshot(tmp.path, 1, _uniformOwSnapshot(7));
      final endRows = <Map<String, String?>>[
        for (final gp in kObserverGreatPowerIds)
          for (var i = 0; i < (gp == 'gp1' ? 10 : 8); i++)
            <String, String?>{'id': 'oldWorld|${gp}_$i', 'ownerId': gp},
      ]..sort((a, b) => (a['id'] ?? '').compareTo(b['id'] ?? ''));
      _writeSnapshot(
        tmp.path,
        kObserverConquestCanonicalTurns,
        <String, Object?>{'provinceOwnershipSorted': endRows},
      );
      final failures = verifyObserverConquestFromTraceDir(tmp.path);
      expect(failures.length, 5);
      expect(failures.any((l) => l.contains('gp1')), isFalse);
      for (final gp in ['gp2', 'gp3', 'gp4', 'gp5', 'gp6']) {
        expect(failures.any((l) => l.contains(gp)), isTrue);
      }
    });

    test('reports missing start snapshot when turn-1 file absent', () {
      final tmp = Directory.systemTemp.createTempSync('conquest_no_start_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      _writeSnapshot(tmp.path, kObserverConquestCanonicalTurns,
          _uniformOwSnapshot(10));
      final failures = verifyObserverConquestFromTraceDir(tmp.path);
      expect(failures, hasLength(1));
      expect(failures.single, contains('missing start snapshot'));
      expect(failures.single, contains('turn-000001'));
    });

    test('reports missing end snapshot when turn-100 file absent', () {
      final tmp = Directory.systemTemp.createTempSync('conquest_no_end_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      _writeSnapshot(tmp.path, 1, _uniformOwSnapshot(7));
      final failures = verifyObserverConquestFromTraceDir(tmp.path);
      expect(failures, hasLength(1));
      expect(failures.single, contains('missing end snapshot'));
      expect(failures.single, contains('turn-000100'));
    });

    test('honors custom startTurn, endTurn, and minGainPerGp overrides', () {
      final tmp = Directory.systemTemp.createTempSync('conquest_custom_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      _writeSnapshot(tmp.path, 5, _uniformOwSnapshot(7));
      _writeSnapshot(tmp.path, 50, _uniformOwSnapshot(8));
      expect(
        verifyObserverConquestFromTraceDir(
          tmp.path,
          startTurn: 5,
          endTurn: 50,
          minGainPerGp: 1,
        ),
        isEmpty,
      );
      final failures = verifyObserverConquestFromTraceDir(
        tmp.path,
        startTurn: 5,
        endTurn: 50,
        minGainPerGp: 2,
      );
      expect(failures, hasLength(kObserverGreatPowerIds.length));
    });
  });
}
