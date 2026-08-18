import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_world_lib_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckWorldLibFileSize', () {
    test('passes on current repo tree under wave-7 ceilings', () {
      expect(worldLibFileSizeCeiling, 300);
      expect(worldGameEventsFileSizeCeiling, 400);
      expect(runCheckWorldLibFileSize('.'), 0);
    });

    test('movement_civilian_apply.dart has ≥30 lines of headroom under 300', () {
      final file = File(
        'packages/colonizethis_world/lib/src/world/movement_civilian_apply.dart',
      );
      final lines = file.readAsLinesSync().length;
      expect(lines, lessThanOrEqualTo(270));
    });

    test('fails when a world lib file exceeds the general ceiling', () {
      final root = Directory.systemTemp.createTempSync('world_lib_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_world/lib/src/world/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckWorldLibFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });

    test(
      'allows game_events.dart between 300 and the dedicated 400 ceiling',
      () {
        final root = Directory.systemTemp.createTempSync(
          'world_lib_size_events_ok',
        );
        addTearDown(() => root.deleteSync(recursive: true));
        _writeFile(
          root,
          worldGameEventsRelativePath,
          List.generate(350, (i) => '// event $i').join('\n'),
        );

        final code = runCheckWorldLibFileSize(
          root.path,
          grandfatheredPaths: const [],
          info: (_) {},
          err: (_) {},
        );
        expect(code, 0);
      },
    );

    test('fails when game_events.dart exceeds the dedicated 400 ceiling', () {
      final root = Directory.systemTemp.createTempSync(
        'world_lib_size_events_bad',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        worldGameEventsRelativePath,
        List.generate(401, (i) => '// event $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckWorldLibFileSize(
        root.path,
        grandfatheredPaths: const [],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('game_events.dart'));
      expect(errors.join('\n'), contains('401 physical lines > 400'));
    });

    test('ignores generated files and grandfathered hot files', () {
      final root = Directory.systemTemp.createTempSync('world_lib_size_gen');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_world/lib/src/world/models.g.dart',
        List.generate(12, (i) => '// generated $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_world/lib/src/world/province_lookup.dart',
        List.generate(12, (i) => '// grandfathered $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_world/lib/src/world/ok.dart',
        '// small\n',
      );

      final logs = <String>[];
      final code = runCheckWorldLibFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [
          'packages/colonizethis_world/lib/src/world/province_lookup.dart',
        ],
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
