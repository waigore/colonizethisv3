import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_models_lib_physical_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckModelsLibPhysicalFileSize', () {
    test('passes on current repo tree under wave-4 250 ceiling', () {
      expect(modelsLibPhysicalFileSizeCeiling, 250);
      expect(runCheckModelsLibPhysicalFileSize('.'), 0);
    });

    test('fails when a models lib file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('models_lib_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_models/lib/src/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckModelsLibPhysicalFileSize(
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
      final root = Directory.systemTemp.createTempSync('models_lib_size_gen');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_models/lib/src/models.g.dart',
        List.generate(12, (i) => '// generated $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_models/lib/src/hot.dart',
        List.generate(12, (i) => '// grandfathered $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_models/lib/src/ok.dart',
        '// small\n',
      );

      final logs = <String>[];
      final code = runCheckModelsLibPhysicalFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [
          'packages/colonizethis_models/lib/src/hot.dart',
        ],
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when a grandfather entry is now under cap', () {
      final root = Directory.systemTemp.createTempSync('models_lib_size_shrink');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_models/lib/src/small.dart',
        '// small\n',
      );

      final errors = <String>[];
      final code = runCheckModelsLibPhysicalFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [
          'packages/colonizethis_models/lib/src/small.dart',
        ],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('remove from allowlist'));
    });

    test('fails when a grandfather entry no longer exists', () {
      final root = Directory.systemTemp.createTempSync('models_lib_size_stale');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(
        p.join(root.path, 'packages', 'colonizethis_models', 'lib'),
      ).createSync(recursive: true);

      final errors = <String>[];
      final code = runCheckModelsLibPhysicalFileSize(
        root.path,
        grandfatheredPaths: const [
          'packages/colonizethis_models/lib/src/gone.dart',
        ],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('stale grandfather'));
    });
  });
}
