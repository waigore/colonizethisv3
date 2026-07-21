import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_test_core_fixtures_shared.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckEconomyTestCoreFixturesShared', () {
    test('passes when guarded files use shared builders only', () {
      final root = Directory.systemTemp.createTempSync('economy_core_fixture_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_economy/test/build_cost_test.dart',
        "import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';\n"
        'void main() { final p = corePlayer(); }\n',
      );

      final logs = <String>[];
      final code = runCheckEconomyTestCoreFixturesShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when a guarded file inlines Game(', () {
      final root = Directory.systemTemp.createTempSync('economy_core_fixture_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_economy/test/worker_economy_test.dart',
        "final game = Game(id: 'g1');\n",
      );

      final logs = <String>[];
      final code = runCheckEconomyTestCoreFixturesShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('worker_economy_test.dart'));
    });

    test('passes when support lib defers Game( to fixture_builders', () {
      final root = Directory.systemTemp.createTempSync('economy_support_fixture_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_economy_test_support/lib/src/core_economy_test_support.dart',
        "import 'fixture_builders/core_game_builders.dart';\n"
        'void main() { final p = corePlayer(); }\n',
      );
      _writeFile(
        root,
        'packages/colonizethis_economy_test_support/lib/src/fixture_builders/core_game_builders.dart',
        "final game = Game(id: 'g1');\n",
      );

      final logs = <String>[];
      final code = runCheckEconomyTestCoreFixturesShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when support lib outside fixture_builders inlines Game(', () {
      final root =
          Directory.systemTemp.createTempSync('economy_support_fixture_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_economy_test_support/lib/src/extraction_fixture_support.dart',
        "final game = Game(id: 'g1');\n",
      );

      final logs = <String>[];
      final code = runCheckEconomyTestCoreFixturesShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('extraction_fixture_support.dart'));
    });
  });
}
