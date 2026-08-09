import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_turn_test_no_src_imports.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('repo.turn_test_no_src_imports', () {
    test('passes when tests use the testing barrel', () {
      final root = Directory.systemTemp.createTempSync('turn_test_import_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_turn/test/spy_resolver_test.dart',
        "import 'package:colonizethis_turn/colonizethis_turn_testing.dart';\n",
      );

      final logs = <String>[];
      final code = runCheckTurnTestNoSrcImports(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when a test imports src/', () {
      final root = Directory.systemTemp.createTempSync('turn_test_import_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_turn/test/spy_resolver_test.dart',
        "import 'package:colonizethis_turn/src/turn/spy_resolver.dart';\n",
      );

      final logs = <String>[];
      final code = runCheckTurnTestNoSrcImports(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('colonizethis_turn/test/spy_resolver_test.dart'),
      );
    });
  });
}
