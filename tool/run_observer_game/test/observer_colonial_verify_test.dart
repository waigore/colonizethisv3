import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_test/test.dart';

import 'package:run_observer_game/observer_colonial_verify.dart';
import 'package:run_observer_game/observer_conquest_verify.dart';

Map<String, Object?> _snapshot({
  required List<Map<String, String?>> provinces,
  int extractable = 100,
  int improved = 70,
}) {
  return <String, Object?>{
    'provinceOwnershipSorted': provinces,
    'extractableResourceTileCount': extractable,
    'improvedExtractableResourceTileCount': improved,
  };
}

/// Writes [snapshot] to `<dir>/turn-<padded turnNumber>.snapshot.json`.
void _writeTurnSnapshot(
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
  group('verifyGlobalNewWorldGpOwnership', () {
    test('passes when every newWorld province is GP-owned', () {
      final snap = _snapshot(
        provinces: [
          {'id': 'newWorld|p1', 'ownerId': 'gp1'},
          {'id': 'newWorld|p2', 'ownerId': 'gp2'},
          {'id': 'oldWorld|p3', 'ownerId': 'tribe1'},
        ],
      );
      expect(verifyGlobalNewWorldGpOwnership(snap), isEmpty);
    });

    test('fails when tribe owns a newWorld province', () {
      final snap = _snapshot(
        provinces: [
          {'id': 'newWorld|p1', 'ownerId': 'tribe1'},
        ],
      );
      final failures = verifyGlobalNewWorldGpOwnership(snap);
      expect(failures, isNotEmpty);
      expect(failures.first, contains('newWorld|p1'));
    });
  });

  group('verifyExtractableImprovementRatio', () {
    test('passes at exactly 0.70', () {
      final snap = _snapshot(
        provinces: const [],
        extractable: 100,
        improved: 70,
      );
      expect(verifyExtractableImprovementRatio(snap), isEmpty);
    });

    test('fails at 0.69 with ratio in message', () {
      final snap = _snapshot(
        provinces: const [],
        extractable: 100,
        improved: 69,
      );
      final failures = verifyExtractableImprovementRatio(snap);
      expect(failures, isNotEmpty);
      expect(failures.first, contains('0.690'));
      expect(failures.first, contains('0.70'));
    });

    test('passes when denominator is zero', () {
      final snap = _snapshot(
        provinces: const [],
        extractable: 0,
        improved: 0,
      );
      expect(verifyExtractableImprovementRatio(snap), isEmpty);
    });
  });

  group('verifyGlobalNewWorldGpOwnership stderr surface', () {
    test('lists every offending newWorld province id (multiple failures)', () {
      final snap = _snapshot(
        provinces: [
          {'id': 'newWorld|p1', 'ownerId': 'tribe1'},
          {'id': 'newWorld|p2', 'ownerId': 'minor3'},
          {'id': 'newWorld|p3', 'ownerId': null},
          {'id': 'newWorld|p4', 'ownerId': 'gp2'},
        ],
      );
      final failures = verifyGlobalNewWorldGpOwnership(snap);
      expect(failures.length, 3);
      expect(failures.any((line) => line.contains('newWorld|p1')), isTrue);
      expect(failures.any((line) => line.contains('newWorld|p2')), isTrue);
      expect(failures.any((line) => line.contains('newWorld|p3')), isTrue);
      expect(failures.any((line) => line.contains('newWorld|p4')), isFalse);
    });

    test('treats empty ownerId as non-GP', () {
      final snap = _snapshot(
        provinces: [
          {'id': 'newWorld|p1', 'ownerId': ''},
        ],
      );
      final failures = verifyGlobalNewWorldGpOwnership(snap);
      expect(failures, hasLength(1));
      expect(failures.single, contains('newWorld|p1'));
    });

    test('reports unparseable provinceOwnershipSorted', () {
      final snap = <String, Object?>{
        'provinceOwnershipSorted': 'not-a-list',
      };
      expect(
        verifyGlobalNewWorldGpOwnership(snap),
        ['provinceOwnershipSorted missing or not a list'],
      );
    });
  });

  group('verifyExtractableImprovementRatio rollup edge cases', () {
    test('reports missing rollup keys', () {
      final snap = <String, Object?>{
        'provinceOwnershipSorted': const [],
      };
      final failures = verifyExtractableImprovementRatio(snap);
      expect(failures, hasLength(1));
      expect(failures.single, contains('extractableResourceTileCount'));
    });

    test('respects custom minRatio override', () {
      final snap = _snapshot(
        provinces: const [],
        extractable: 100,
        improved: 60,
      );
      expect(
        verifyExtractableImprovementRatio(snap, minRatio: 0.50),
        isEmpty,
      );
      expect(
        verifyExtractableImprovementRatio(snap, minRatio: 0.70),
        isNotEmpty,
      );
    });
  });

  group('verifyObserverColonialExpansionFromTraceDir', () {
    test('returns empty failures when turn-150 snapshot passes both checks', () {
      final tmp = Directory.systemTemp.createTempSync(
        'colonial_verify_pass_',
      );
      addTearDown(() => tmp.deleteSync(recursive: true));
      _writeTurnSnapshot(
        tmp.path,
        kObserverColonialCanonicalTurn,
        _snapshot(
          provinces: [
            for (var i = 1; i <= 4; i++)
              {'id': 'newWorld|nw_$i', 'ownerId': 'gp${(i % 6) + 1}'},
          ],
          extractable: 200,
          improved: 150,
        ),
      );
      expect(
        verifyObserverColonialExpansionFromTraceDir(tmp.path),
        isEmpty,
      );
    });

    test('lists every tribe-owned newWorld province in failures', () {
      final tmp = Directory.systemTemp.createTempSync(
        'colonial_verify_tribe_',
      );
      addTearDown(() => tmp.deleteSync(recursive: true));
      _writeTurnSnapshot(
        tmp.path,
        kObserverColonialCanonicalTurn,
        _snapshot(
          provinces: [
            {'id': 'newWorld|nw_a', 'ownerId': 'tribe1'},
            {'id': 'newWorld|nw_b', 'ownerId': 'tribe2'},
            {'id': 'newWorld|nw_c', 'ownerId': 'gp1'},
          ],
          extractable: 100,
          improved: 80,
        ),
      );
      final failures = verifyObserverColonialExpansionFromTraceDir(tmp.path);
      expect(failures.length, 2);
      expect(failures.any((l) => l.contains('newWorld|nw_a')), isTrue);
      expect(failures.any((l) => l.contains('newWorld|nw_b')), isTrue);
      expect(failures.any((l) => l.contains('newWorld|nw_c')), isFalse);
    });

    test('returns ratio failure when extractable improvement < 0.70', () {
      final tmp = Directory.systemTemp.createTempSync(
        'colonial_verify_ratio_',
      );
      addTearDown(() => tmp.deleteSync(recursive: true));
      _writeTurnSnapshot(
        tmp.path,
        kObserverColonialCanonicalTurn,
        _snapshot(
          provinces: [
            {'id': 'newWorld|nw_a', 'ownerId': 'gp1'},
          ],
          extractable: 100,
          improved: 69,
        ),
      );
      final failures = verifyObserverColonialExpansionFromTraceDir(tmp.path);
      expect(failures, hasLength(1));
      expect(failures.single, contains('0.690'));
      expect(failures.single, contains('0.70'));
    });

    test('aggregates ownership and ratio failures from same snapshot', () {
      final tmp = Directory.systemTemp.createTempSync(
        'colonial_verify_combined_',
      );
      addTearDown(() => tmp.deleteSync(recursive: true));
      _writeTurnSnapshot(
        tmp.path,
        kObserverColonialCanonicalTurn,
        _snapshot(
          provinces: [
            {'id': 'newWorld|nw_a', 'ownerId': 'tribe1'},
          ],
          extractable: 100,
          improved: 50,
        ),
      );
      final failures = verifyObserverColonialExpansionFromTraceDir(tmp.path);
      expect(failures.length, 2);
      expect(failures.any((l) => l.contains('newWorld|nw_a')), isTrue);
      expect(failures.any((l) => l.contains('0.500')), isTrue);
    });

    test('reports missing end snapshot path when file absent', () {
      final tmp = Directory.systemTemp.createTempSync(
        'colonial_verify_missing_',
      );
      addTearDown(() => tmp.deleteSync(recursive: true));
      final failures = verifyObserverColonialExpansionFromTraceDir(tmp.path);
      expect(failures, hasLength(1));
      expect(failures.single, contains('missing end snapshot'));
      expect(
        failures.single,
        contains(
          'turn-${kObserverColonialCanonicalTurn.toString().padLeft(6, '0')}',
        ),
      );
    });

    test('honors custom endTurn parameter when locating snapshot', () {
      final tmp = Directory.systemTemp.createTempSync(
        'colonial_verify_custom_turn_',
      );
      addTearDown(() => tmp.deleteSync(recursive: true));
      _writeTurnSnapshot(
        tmp.path,
        42,
        _snapshot(
          provinces: [
            {'id': 'newWorld|nw_a', 'ownerId': 'gp1'},
          ],
          extractable: 100,
          improved: 95,
        ),
      );
      expect(
        verifyObserverColonialExpansionFromTraceDir(tmp.path, endTurn: 42),
        isEmpty,
      );
      expect(
        verifyObserverColonialExpansionFromTraceDir(tmp.path, endTurn: 99),
        contains(predicate<String>((line) => line.contains('turn-000099'))),
      );
    });

    test('honors custom minImprovementRatio override', () {
      final tmp = Directory.systemTemp.createTempSync(
        'colonial_verify_min_ratio_',
      );
      addTearDown(() => tmp.deleteSync(recursive: true));
      _writeTurnSnapshot(
        tmp.path,
        kObserverColonialCanonicalTurn,
        _snapshot(
          provinces: [
            {'id': 'newWorld|nw_a', 'ownerId': 'gp1'},
          ],
          extractable: 100,
          improved: 55,
        ),
      );
      expect(
        verifyObserverColonialExpansionFromTraceDir(
          tmp.path,
          minImprovementRatio: 0.50,
        ),
        isEmpty,
      );
      expect(
        verifyObserverColonialExpansionFromTraceDir(
          tmp.path,
          minImprovementRatio: 0.70,
        ),
        isNotEmpty,
      );
    });
  });
}
