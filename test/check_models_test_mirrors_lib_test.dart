import 'package:test/test.dart';

import '../tool/check_models_test_mirrors_lib.dart';

void main() {
  group('modelsTestMirrorsLibPathInScope', () {
    test('positive: paths under the models test tree are in scope', () {
      expect(
        modelsTestMirrorsLibPathInScope(
          'packages/colonizethis_models/test/src/player_test.dart',
        ),
        isTrue,
      );
      expect(
        modelsTestMirrorsLibPathInScope(
          'packages\\colonizethis_models\\test\\player_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: lib sources and other packages are out of scope', () {
      expect(
        modelsTestMirrorsLibPathInScope(
          'packages/colonizethis_models/lib/src/player.dart',
        ),
        isFalse,
      );
      expect(
        modelsTestMirrorsLibPathInScope(
          'packages/colonizethis_combat/test/foo_test.dart',
        ),
        isFalse,
      );
    });
  });

  group('modelsTestMirrorsLibViolationReason', () {
    test('positive: a flat-root test file is flagged', () {
      final reason = modelsTestMirrorsLibViolationReason(
        'packages/colonizethis_models/test/player_test.dart',
      );
      expect(reason, isNotNull);
      expect(reason, contains('test/src/'));
    });

    test('positive: backslash-separated flat-root path is flagged', () {
      final reason = modelsTestMirrorsLibViolationReason(
        'packages\\colonizethis_models\\test\\player_test.dart',
      );
      expect(reason, isNotNull);
    });

    test('negative: a nested test file under test/src/ is allowed', () {
      final reason = modelsTestMirrorsLibViolationReason(
        'packages/colonizethis_models/test/src/player_test.dart',
      );
      expect(reason, isNull);
    });

    test('negative: support helpers under test/support/ are allowed', () {
      final reason = modelsTestMirrorsLibViolationReason(
        'packages/colonizethis_models/test/support/minimal_game.dart',
      );
      expect(reason, isNull);
    });

    test('negative: files outside the models test tree are ignored', () {
      expect(
        modelsTestMirrorsLibViolationReason(
          'packages/colonizethis_orders/test/foo_test.dart',
        ),
        isNull,
      );
    });
  });

  group('runCheckModelsTestMirrorsLib', () {
    test('passes on the current repo tree', () {
      expect(runCheckModelsTestMirrorsLib('.'), 0);
    });
  });
}
