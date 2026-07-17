import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_source_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckEconomySourceFileSize', () {
    test('passes on current repo tree under phase-7 ceiling', () {
      expect(runCheckEconomySourceFileSize('.'), 0);
    });

    test('fails when an economy lib file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('economy_src_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_economy/lib/src/economy/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckEconomySourceFileSize(
        root.path,
        ceiling: 10,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });

    test('ignores generated files and passes under the ceiling', () {
      final root = Directory.systemTemp.createTempSync('economy_src_size_gen');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_economy/lib/src/economy/models.g.dart',
        List.generate(12, (i) => '// generated $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_economy/lib/src/economy/ok.dart',
        '// small\n',
      );

      final logs = <String>[];
      final code = runCheckEconomySourceFileSize(
        root.path,
        ceiling: 10,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
