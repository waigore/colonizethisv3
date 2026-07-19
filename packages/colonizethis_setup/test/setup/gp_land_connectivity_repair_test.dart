import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';

/// Unit coverage for [gpProvincesAreLandConnected] (Refs #4090 port from logic).
void main() {
  group('gpProvincesAreLandConnected', () {
    test('single province is connected', () {
      final owners = {'p1': 'gp1'};
      final n = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1'},
      };
      expect(gpProvincesAreLandConnected('gp1', owners, n), isTrue);
    });

    test('two adjacent provinces are connected', () {
      final owners = {'p1': 'gp1', 'p2': 'gp1'};
      final n = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1', 'p3'},
        'p3': {},
      };
      expect(gpProvincesAreLandConnected('gp1', owners, n), isTrue);
    });

    test('two non-adjacent provinces are not connected', () {
      final owners = {'p1': 'gp1', 'p3': 'gp1'};
      final n = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1', 'p3'},
        'p3': {'p2'},
      };
      expect(gpProvincesAreLandConnected('gp1', owners, n), isFalse);
    });
  });
}
