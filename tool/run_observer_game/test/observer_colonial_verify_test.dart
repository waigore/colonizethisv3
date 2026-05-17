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
}
