import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_map_test_minimal_game_shared.dart';

void main() {
  group('mapTestMinimalGameSharedPathInScope', () {
    test('scopes the five colour/capital/format suites', () {
      expect(
        mapTestMinimalGameSharedPathInScope(
          'packages/colonizethis_map/test/faction_ownership_color_test.dart',
        ),
        isTrue,
      );
      expect(
        mapTestMinimalGameSharedPathInScope(
          'packages/colonizethis_map/test/town_icon_style_test.dart',
        ),
        isFalse,
      );
    });
  });

  group('mapTestMinimalGameSharedViolationReason', () {
    test('flags inline Game(', () {
      expect(
        mapTestMinimalGameSharedViolationReason('final g = Game(id: "x");\n'),
        contains('minimalGame'),
      );
    });

    test('does not flag minimalGame(', () {
      expect(
        mapTestMinimalGameSharedViolationReason(
          'final g = minimalGame(id: "x");\n',
        ),
        isNull,
      );
    });

    test('ignores full-line comment mentioning Game(', () {
      expect(
        mapTestMinimalGameSharedViolationReason(
          '// formerly Game(id: x)\nfinal g = minimalGame();\n',
        ),
        isNull,
      );
    });
  });

  group('runCheckMapTestMinimalGameShared', () {
    test('passes on the live repository tree', () {
      final logs = <String>[];
      final code = runCheckMapTestMinimalGameShared(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
