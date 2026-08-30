import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_turn_lib_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckTurnLibFileSize', () {
    test(
      'passes on current repo tree under wave-8 250 physical-line ceiling',
      () {
        expect(runCheckTurnLibFileSize('.'), 0);
      },
    );

    test('ceiling is 250 after #4583 Slice B ratchet', () {
      expect(turnLibFileSizeCeiling, 250);
    });

    test('grandfather allowlist is empty after #4342', () {
      expect(turnLibFileSizeGrandfathered, isEmpty);
    });

    test('fails when a turn lib file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('turn_lib_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_turn/lib/src/turn/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckTurnLibFileSize(
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
      final root = Directory.systemTemp.createTempSync('turn_lib_size_gen');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_turn/lib/src/turn/models.g.dart',
        List.generate(12, (i) => '// generated $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_turn/lib/src/turn/research_resolver.dart',
        List.generate(12, (i) => '// grandfathered $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_turn/lib/src/turn/ok.dart',
        '// small\n',
      );

      final logs = <String>[];
      final code = runCheckTurnLibFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [
          'packages/colonizethis_turn/lib/src/turn/research_resolver.dart',
        ],
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
