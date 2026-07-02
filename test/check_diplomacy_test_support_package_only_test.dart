import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_diplomacy_test_support_package_only.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckDiplomacyTestSupportPackageOnly', () {
    test('passes when test/support is absent', () {
      final root = Directory.systemTemp.createTempSync('diplomacy_support_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_diplomacy/test/diplomacy/foo_test.dart',
        'void main() {}\n',
      );

      final logs = <String>[];
      final code = runCheckDiplomacyTestSupportPackageOnly(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when test/support fixture file is reintroduced', () {
      final root =
          Directory.systemTemp.createTempSync('diplomacy_support_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_diplomacy/test/support/new_fixtures.dart',
        'void main() {}\n',
      );

      final logs = <String>[];
      final code = runCheckDiplomacyTestSupportPackageOnly(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('test/support/new_fixtures.dart'));
    });
  });
}
