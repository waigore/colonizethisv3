import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_function_size.dart';

void main() {
  group('scanFunctionSizesFromSourceForTest', () {
    test('counts non-empty non-// lines in function declaration span', () {
      const source = '''
int f() {
  // ignored
  final a = 1;

  final b = 2;
  return a + b;
}
''';
      final sizes = scanFunctionSizesFromSourceForTest(source);
      final f = sizes.singleWhere((e) => e.symbol == 'f');
      expect(f.measuredLines, 5);
    });
  });

  group('runCheckFunctionSize', () {
    test('fails when non-allowlisted function exceeds threshold', () {
      final temp = Directory.systemTemp.createTempSync('fn-size-');
      try {
        final libDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_logic', 'lib', 'src'),
        )..createSync(recursive: true);
        File(p.join(libDir.path, 'big.dart')).writeAsStringSync('''
int giant() {
  final v1 = 1;
  final v2 = 2;
  final v3 = 3;
  final v4 = 4;
  final v5 = 5;
  final v6 = 6;
  final v7 = 7;
  final v8 = 8;
  final v9 = 9;
  final v10 = 10;
  final v11 = 11;
  final v12 = 12;
  final v13 = 13;
  final v14 = 14;
  final v15 = 15;
  final v16 = 16;
  final v17 = 17;
  final v18 = 18;
  final v19 = 19;
  return v1 + v2 + v3 + v4 + v5 + v6 + v7 + v8 + v9 + v10 + v11 + v12 + v13 + v14 + v15 + v16 + v17 + v18 + v19;
}
''');

        final errors = <String>[];
        final exitCode = runCheckFunctionSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('giant'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes with allowlisted max_measured_lines', () {
      final temp = Directory.systemTemp.createTempSync('fn-size-allow-');
      try {
        final libDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_logic', 'lib', 'src'),
        )..createSync(recursive: true);
        File(p.join(libDir.path, 'big.dart')).writeAsStringSync('''
int giant() {
  final v1 = 1;
  final v2 = 2;
  final v3 = 3;
  final v4 = 4;
  final v5 = 5;
  final v6 = 6;
  final v7 = 7;
  final v8 = 8;
  final v9 = 9;
  final v10 = 10;
  final v11 = 11;
  final v12 = 12;
  final v13 = 13;
  final v14 = 14;
  final v15 = 15;
  final v16 = 16;
  final v17 = 17;
  final v18 = 18;
  final v19 = 19;
  return v1 + v2 + v3 + v4 + v5 + v6 + v7 + v8 + v9 + v10 + v11 + v12 + v13 + v14 + v15 + v16 + v17 + v18 + v19;
}
''');
        final toolDir = Directory(p.join(temp.path, 'tool'))
          ..createSync(recursive: true);
        File(
          p.join(toolDir.path, 'function_size_allowlist.yaml'),
        ).writeAsStringSync('''
allowed_over_20:
  - file: packages/colonizethis_logic/lib/src/big.dart
    symbol: giant
    max_measured_lines: 22
''');

        final exitCode = runCheckFunctionSize(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
