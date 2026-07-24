import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_diplomacy_test_support_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckDiplomacyTestSupportFileSize', () {
    test('passes on current repo tree under #4130 ceiling', () {
      expect(runCheckDiplomacyTestSupportFileSize('.'), 0);
    });

    test('fails when a support lib file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync(
        'diplomacy_support_size_bad',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_diplomacy_test_support/lib/src/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckDiplomacyTestSupportFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });

    test('ignores generated files', () {
      final root = Directory.systemTemp.createTempSync(
        'diplomacy_support_size_gen',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_diplomacy_test_support/lib/src/models.g.dart',
        List.generate(12, (i) => '// generated $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_diplomacy_test_support/lib/src/ok.dart',
        '// small\n',
      );

      final logs = <String>[];
      final code = runCheckDiplomacyTestSupportFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [],
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
