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
  });
}
