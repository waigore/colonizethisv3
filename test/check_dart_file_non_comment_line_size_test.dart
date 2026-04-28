import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_dart_file_non_comment_line_size.dart';

void main() {
  group('countNonCommentLinesFromSource', () {
    test('excludes line comments and block comments', () {
      const source = '''
// leading comment
final a = 1; // trailing comment
/* block
comment */
final b = 2;
''';
      expect(countNonCommentLinesFromSource(source), 2);
    });

    test('does not treat comment tokens inside strings as comments', () {
      const source = '''
final a = "// not a comment";
final b = "/* not a block */";
''';
      expect(countNonCommentLinesFromSource(source), 2);
    });

    test('counts non-empty triple-quoted string content lines', () {
      const source = '''
final value = """
alpha

beta
""";
''';
      expect(countNonCommentLinesFromSource(source), 4);
    });

    test(
      'treats ignore and coverage markers as comments unless code exists',
      () {
        const source = '''
// ignore: dead_code
// coverage:ignore-file
final a = 1; // ignore: avoid_print
''';
        expect(countNonCommentLinesFromSource(source), 1);
      },
    );
  });

  group('runCheckDartFileNonCommentLineSize', () {
    test('fails when any file has more than 1000 non-comment lines', () {
      final temp = Directory.systemTemp.createTempSync('dart-ncl-size-fail-');
      addTearDown(() => temp.deleteSync(recursive: true));

      final violating = File(
        p.join(temp.path, 'packages', 'x', 'lib', 'big.dart'),
      )..createSync(recursive: true);
      violating.writeAsStringSync(List.filled(1001, 'final x = 1;').join('\n'));

      final logs = <String>[];
      final code = runCheckDartFileNonCommentLineSize(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      final output = logs.join('\n');
      expect(output, contains('packages/x/lib/big.dart'));
      expect(output, contains('1001 non-comment lines > 1000'));
    });

    test('excludes generated suffixes including .gen.dart', () {
      final temp = Directory.systemTemp.createTempSync(
        'dart-ncl-size-generated-',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final generatedFile = File(
        p.join(temp.path, 'app', 'lib', 'generated', 'skip.gen.dart'),
      )..createSync(recursive: true);
      generatedFile.writeAsStringSync(
        List.filled(2000, 'final generated = 1;').join('\n'),
      );

      final code = runCheckDartFileNonCommentLineSize(temp.path);
      expect(code, 0);
    });
  });
}
