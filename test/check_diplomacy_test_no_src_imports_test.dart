import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_diplomacy_test_no_src_imports.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckDiplomacyTestNoSrcImports', () {
    test('passes when tests use the public barrel', () {
      final root = Directory.systemTemp.createTempSync('diplomacy_test_import_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_diplomacy/test/diplomacy/foo_test.dart',
        "import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';\n",
      );

      final logs = <String>[];
      final code = runCheckDiplomacyTestNoSrcImports(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when a test imports src/', () {
      final root =
          Directory.systemTemp.createTempSync('diplomacy_test_import_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_diplomacy/test/diplomacy/foo_test.dart',
        "import 'package:colonizethis_diplomacy/src/diplomacy/war_resolver.dart';\n",
      );

      final logs = <String>[];
      final code = runCheckDiplomacyTestNoSrcImports(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('diplomacy/foo_test.dart'));
    });

    test('allows phase_types_split deep-import gate test', () {
      final root =
          Directory.systemTemp.createTempSync('diplomacy_test_import_allow');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_phase_types_split_test.dart',
        "import 'package:colonizethis_diplomacy/src/diplomacy/phase_types/ftp_offer.dart';\n",
      );

      final logs = <String>[];
      final code = runCheckDiplomacyTestNoSrcImports(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
