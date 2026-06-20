import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';

/// Exception and seed-resolution coverage for the setup package barrel exports
/// (Refs #3290 — per-package 90% coverage gate for `colonizethis_setup`).
void main() {
  group('SetupValidationException', () {
    test('positive: message constructor preserves message', () {
      final error = SetupValidationException('invalid setup');
      expect(error.message, 'invalid setup');
      expect(error, isA<ArgumentError>());
    });

    test('positive: value constructor preserves invalid value and name', () {
      final error = SetupValidationException.value(-1, 'seed', 'must be >= 0');
      expect(error.invalidValue, -1);
      expect(error.name, 'seed');
      expect(error.message, contains('must be >= 0'));
    });
  });

  group('setup typed exceptions', () {
    test('positive: NoSeaBoundCapitalProvinceException exposes code and details', () {
      final error = NoSeaBoundCapitalProvinceException(details: 'gp1 has no coast');
      expect(error.code, NoSeaBoundCapitalProvinceException.codeValue);
      expect(error.message, 'gp1 has no coast');
    });

    test('positive: NoCoastalCapitalTileForGpException exposes code and details', () {
      final error = NoCoastalCapitalTileForGpException(details: 'gp2 tile missing');
      expect(error.code, NoCoastalCapitalTileForGpException.codeValue);
      expect(error.message, 'gp2 tile missing');
    });

    test('positive: CapitalTileMismatchException exposes code and details', () {
      final error = CapitalTileMismatchException(details: 'tile not in province');
      expect(error.code, CapitalTileMismatchException.codeValue);
      expect(error.message, 'tile not in province');
    });

    test('positive: SetupTopologyDataException carries custom code', () {
      final error = SetupTopologyDataException(
        code: 'missing_topology',
        details: 'oldWorld topology absent',
      );
      expect(error.code, 'missing_topology');
      expect(error.message, 'oldWorld topology absent');
    });

    test('positive: SetupConfigConstraintException carries custom code', () {
      final error = SetupConfigConstraintException(
        code: 'faction_count_mismatch',
        details: 'too few minors',
      );
      expect(error.code, 'faction_count_mismatch');
      expect(error.message, 'too few minors');
    });
  });

  group('generateUniqueProvinceName', () {
    test('positive: returns first candidate when unused', () {
      final used = <String>{};
      final name = generateUniqueProvinceName(1, used);
      expect(name, isNotEmpty);
      expect(used, contains(name));
    });

    test('positive: appends numbered suffix when first candidate is taken', () {
      final used = <String>{};
      final first = generateUniqueProvinceName(42, used);
      final second = generateUniqueProvinceName(42, used);
      expect(second, isNot(equals(first)));
      expect(second, startsWith(first));
    });

    test('positive: seed-based fallback when numbered suffixes are exhausted', () {
      final used = <String>{};
      final base = generateUniqueProvinceName(99, used);
      for (var n = 2; n <= 100; n++) {
        used.add('$base $n');
      }
      final fallback = generateUniqueProvinceName(99, used);
      expect(fallback, endsWith('(99)'));
      expect(used, contains(fallback));
    });
  });

  group('resolveEffectiveSetupSeed', () {
    test('positive: positive config seed is returned unchanged', () {
      expect(resolveEffectiveSetupSeed(42), 42);
    });

    test('positive: zero resolves to a positive epoch-ms value', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final resolved = resolveEffectiveSetupSeed(0);
      final after = DateTime.now().millisecondsSinceEpoch;
      expect(resolved, inInclusiveRange(before, after));
    });

    test('negative: negative config seed throws SetupConfigConstraintException', () {
      expect(
        () => resolveEffectiveSetupSeed(-1),
        throwsA(
          isA<SetupConfigConstraintException>()
              .having((e) => e.code, 'code', 'invalid_setup_seed')
              .having((e) => e.message, 'message', contains('-1')),
        ),
      );
    });
  });
}
