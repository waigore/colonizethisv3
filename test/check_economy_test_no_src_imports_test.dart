import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_test_no_src_imports.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckEconomyTestNoSrcImports', () {
    test('passes when tests use the public barrel', () {
      final root = Directory.systemTemp.createTempSync('economy_test_import_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_economy/test/build_cost_test.dart',
        "import 'package:colonizethis_economy/colonizethis_economy.dart';\n",
      );

      final logs = <String>[];
      final code = runCheckEconomyTestNoSrcImports(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when a test imports src/', () {
      final root = Directory.systemTemp.createTempSync('economy_test_import_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_economy/test/cost_check_test.dart',
        "import 'package:colonizethis_economy/src/economy/cost_check.dart';\n",
      );

      final logs = <String>[];
      final code = runCheckEconomyTestNoSrcImports(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('colonizethis_economy/test/cost_check_test.dart'));
    });
  });
}
