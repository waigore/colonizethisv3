import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_test_no_matrix_part_shards.dart';

const String _body =
    "import 'package:test/test.dart';\n\n"
    'void main() {\n'
    "  test('placeholder', () {\n"
    '    expect(1, 1);\n'
    '  });\n'
    '}\n';

void main() {
  group('runCheckAiTestNoMatrixPartShards', () {
    test(
      'fails when a part2 shard coexists with a sibling *_support.dart',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-matrix-part-');
        try {
          final planning = Directory(
            p.join(
              temp.path,
              'packages',
              'colonizethis_ai',
              'test',
              'planning',
            ),
          )..createSync(recursive: true);
          File(
            p.join(planning.path, 'example_matrix_support.dart'),
          ).writeAsStringSync('// support\n');
          File(
            p.join(planning.path, 'example_matrix_part2_test.dart'),
          ).writeAsStringSync(_body);

          final errors = <String>[];
          final exitCode = runCheckAiTestNoMatrixPartShards(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('example_matrix_part2_test.dart'));
          expect(errors.join('\n'), contains('example_matrix_support.dart'));
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test(
      'passes when part shards exist without a sibling *_support.dart',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-matrix-ok-part-');
        try {
          final planning = Directory(
            p.join(
              temp.path,
              'packages',
              'colonizethis_ai',
              'test',
              'planning',
            ),
          )..createSync(recursive: true);
          File(
            p.join(planning.path, 'mid_migration_part2_test.dart'),
          ).writeAsStringSync(_body);

          final exitCode = runCheckAiTestNoMatrixPartShards(
            temp.path,
            info: (_) {},
            err: (_) {},
          );
          expect(exitCode, 0);
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test('passes when only a consolidated contract + support exist', () {
      final temp = Directory.systemTemp.createTempSync('ai-matrix-ok-');
      try {
        final planning = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_ai',
            'test',
            'planning',
          ),
        )..createSync(recursive: true);
        File(
          p.join(planning.path, 'example_matrix_support.dart'),
        ).writeAsStringSync('// support\n');
        File(
          p.join(planning.path, 'example_matrix_test.dart'),
        ).writeAsStringSync(_body);

        final exitCode = runCheckAiTestNoMatrixPartShards(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
      'fails when a lettered part_a_cases shard exists under planning tests',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-matrix-letter-');
        try {
          final planning = Directory(
            p.join(
              temp.path,
              'packages',
              'colonizethis_ai',
              'test',
              'planning',
            ),
          )..createSync(recursive: true);
          File(
            p.join(planning.path, 'foo_part_a_cases.dart'),
          ).writeAsStringSync('// cases\n');
          File(
            p.join(planning.path, 'foo_part_b_test.dart'),
          ).writeAsStringSync(_body);

          final errors = <String>[];
          final exitCode = runCheckAiTestNoMatrixPartShards(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('foo_part_a_cases.dart'));
          expect(errors.join('\n'), contains('foo_part_b_test.dart'));
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );
  });
}
