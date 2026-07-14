import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_map_test_run_generation_harness.dart';

void main() {
  group('mapTestRunGenerationHarnessPathInScope', () {
    test('includes generator and related integration suites', () {
      expect(
        mapTestRunGenerationHarnessPathInScope(
          'packages/colonizethis_map/test/tile_map_generator_core_test.dart',
        ),
        isTrue,
      );
      expect(
        mapTestRunGenerationHarnessPathInScope(
          'packages/colonizethis_map/test/tile_map_generation_determinism_test.dart',
        ),
        isTrue,
      );
      expect(
        mapTestRunGenerationHarnessPathInScope(
          'packages/colonizethis_map/test/tile_map_forest_split_test.dart',
        ),
        isTrue,
      );
    });

    test('excludes support harness', () {
      expect(
        mapTestRunGenerationHarnessPathInScope(
          'packages/colonizethis_map/test/support/tile_map_gen_fixtures.dart',
        ),
        isFalse,
      );
    });
  });

  group('mapTestRunGenerationHarnessViolationReason', () {
    test('flags inline TileMapGenerator(', () {
      const path =
          'packages/colonizethis_map/test/tile_map_generator_core_test.dart';
      final reason = mapTestRunGenerationHarnessViolationReason(
        path,
        'final x = TileMapGenerator(params: p);\n',
      );
      expect(reason, contains('runTileMapGeneration'));
    });

    test('allows preceding exempt marker', () {
      const path =
          'packages/colonizethis_map/test/tile_map_generator_core_test.dart';
      final reason = mapTestRunGenerationHarnessViolationReason(
        path,
        '// map-generation-harness-exempt: constructor/DI probe\n'
        'final gen = TileMapGenerator(params: p);\n',
      );
      expect(reason, isNull);
    });
  });

  group('runCheckMapTestRunGenerationHarness', () {
    test('passes on the live repository tree', () {
      final logs = <String>[];
      final code = runCheckMapTestRunGenerationHarness(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
