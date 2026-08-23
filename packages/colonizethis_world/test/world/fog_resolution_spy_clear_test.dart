import 'package:colonizethis_world/src/world/fog_resolution.dart';
import 'package:colonizethis_test/test.dart';

import 'fog_resolution_spy_clear_apply_cases.dart';

void main() {
  _fog_resolution_spy_clear_testTests();
}

void _fog_resolution_spy_clear_testTests() {
  group('clearSpyRevealTimersForProvince', () {
    test('removes timers only for the given player and province', () {
      const ow = 'oldWorld';
      final existing = <String, Map<String, int>>{
        'p1': {'$ow|P1': 3, '$ow|P2': 2},
        'p2': {'$ow|P2': 4},
      };

      final next = clearSpyRevealTimersForProvince(existing, 'p1', '$ow|P2');

      expect(next['p1'], isNotNull);
      expect(next['p1']!.containsKey('$ow|P1'), isTrue);
      expect(next['p1']!.containsKey('$ow|P2'), isFalse);
      // Other players' timers untouched.
      expect(next['p2']!.containsKey('$ow|P2'), isTrue);
    });

    test('drops empty inner map when last timer is removed', () {
      const ow = 'oldWorld';
      final existing = <String, Map<String, int>>{
        'p1': {'$ow|P2': 1},
        'p2': {'$ow|P2': 2},
      };

      final next = clearSpyRevealTimersForProvince(existing, 'p1', '$ow|P2');

      expect(next.containsKey('p1'), isFalse);
      expect(next['p2']!.containsKey('$ow|P2'), isTrue);
    });
  });

  group('clearSpyRevealTimersForProvinceOwnershipTransfer', () {
    test('removes timers for old and new owner only', () {
      const ow = 'oldWorld';
      final existing = <String, Map<String, int>>{
        'a': {'$ow|P1': 3},
        'b': {'$ow|P1': 2},
        'c': {'$ow|P2': 1},
      };

      final next = clearSpyRevealTimersForProvinceOwnershipTransfer(
        existing,
        '$ow|P1',
        'a',
        'b',
      );

      expect(next['a']?['$ow|P1'], isNull);
      expect(next['b']?['$ow|P1'], isNull);
      expect(next['c']!['$ow|P2'], 1);
    });
  });

  registerFogResolutionSpyClearApplyCases();
}
