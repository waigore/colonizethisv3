import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_no_logic_deps.dart';

void main() {
  group('runCheckSetupNoLogicDeps', () {
    test('passes on current repo tree', () {
      expect(runCheckSetupNoLogicDeps('.'), 0);
    });

    test('fails when a planted test-tree logic import is present', () {
      final root = Directory.systemTemp.createTempSync('setup_no_logic');
      addTearDown(() => root.deleteSync(recursive: true));
      final lib = Directory(
        p.join(root.path, 'packages/colonizethis_setup/lib'),
      )..createSync(recursive: true);
      File(p.join(lib.path, 'ok.dart')).writeAsStringSync('// ok\n');
      final testDir = Directory(
        p.join(root.path, 'packages/colonizethis_setup/test/setup'),
      )..createSync(recursive: true);
      File(p.join(testDir.path, 'planted.dart')).writeAsStringSync(
        "import 'package:colonizethis_logic/colonizethis_logic.dart';\n",
      );

      final errors = <String>[];
      final code = runCheckSetupNoLogicDeps(root.path, err: errors.add);
      expect(code, 1);
      expect(errors.join('\n'), contains('planted.dart'));
    });
  });
}
