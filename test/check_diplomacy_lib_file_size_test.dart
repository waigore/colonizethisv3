import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_diplomacy_lib_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckDiplomacyLibFileSize', () {
    test('passes on current repo tree under wave-6 ceiling', () {
      expect(runCheckDiplomacyLibFileSize('.'), 0);
    });

    test('fails when a diplomacy lib file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync(
        'diplomacy_lib_size_bad',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_diplomacy/lib/src/diplomacy/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckDiplomacyLibFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });

    test('ignores generated files and grandfathered hot files', () {
      final root = Directory.systemTemp.createTempSync(
        'diplomacy_lib_size_gen',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_diplomacy/lib/src/diplomacy/models.g.dart',
        List.generate(12, (i) => '// generated $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_diplomacy/lib/src/dossier/event_dialogue.dart',
        List.generate(12, (i) => '// grandfathered $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_diplomacy/lib/src/diplomacy/ok.dart',
        '// small\n',
      );

      final logs = <String>[];
      final code = runCheckDiplomacyLibFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [
          'packages/colonizethis_diplomacy/lib/src/dossier/event_dialogue.dart',
        ],
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
