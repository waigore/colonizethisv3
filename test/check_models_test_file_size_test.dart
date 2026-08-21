import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_models_test_file_size.dart';

void main() {
  group('runCheckModelsTestFileSize', () {
    test('fails when a models test file exceeds 250 physical lines', () {
      final temp = Directory.systemTemp.createTempSync('models-test-size-');
      try {
        final testDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_models', 'test'),
        )..createSync(recursive: true);
        final oversized = File(p.join(testDir.path, 'huge_test.dart'));
        oversized.writeAsStringSync(
          '${List.filled(251, '// line').join('\n')}\n',
        );

        final errors = <String>[];
        final exitCode = runCheckModelsTestFileSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('huge_test.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when every models test file is at or below 250 lines', () {
      expect(modelsTestPhysicalFileSizeCeiling, 250);
      final temp = Directory.systemTemp.createTempSync('models-test-size-ok-');
      try {
        final testDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_models', 'test'),
        )..createSync(recursive: true);
        File(
          p.join(testDir.path, 'small_test.dart'),
        ).writeAsStringSync("void main() {}\n");

        final exitCode = runCheckModelsTestFileSize(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('full-tree scan of the live models test suite stays green', () {
      final repoRoot = Directory.current.path;
      final exitCode = runCheckModelsTestFileSize(
        repoRoot,
        info: (_) {},
        err: (_) {},
      );
      expect(exitCode, 0);
    });
  });
}
