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
    String giantFunctionSource({required int statements}) {
      final body = List.generate(
        statements,
        (i) => '  final v${i + 1} = ${i + 1};',
      ).join('\n');
      final sum = List.generate(statements, (i) => 'v${i + 1}').join(' + ');
      return 'int giant() {\n$body\n  return $sum;\n}\n';
    }

    test('fails when function exceeds threshold', () {
      final temp = Directory.systemTemp.createTempSync('fn-size-');
      try {
        final libDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_logic', 'lib', 'src'),
        )..createSync(recursive: true);
        File(
          p.join(libDir.path, 'big.dart'),
        ).writeAsStringSync(giantFunctionSource(statements: 210));

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

    test('fails for oversized functions in non-logic packages', () {
      final temp = Directory.systemTemp.createTempSync('fn-size-data-');
      try {
        final libDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_data', 'lib', 'src'),
        )..createSync(recursive: true);
        File(
          p.join(libDir.path, 'big.dart'),
        ).writeAsStringSync(giantFunctionSource(statements: 210));

        final errors = <String>[];
        final exitCode = runCheckFunctionSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(
          errors.join('\n'),
          contains('packages/colonizethis_data/lib/src/big.dart'),
        );
        expect(errors.join('\n'), contains('giant'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails even when legacy waiver yaml is present', () {
      final temp = Directory.systemTemp.createTempSync('fn-size-legacy-');
      try {
        final libDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_logic', 'lib', 'src'),
        )..createSync(recursive: true);
        File(
          p.join(libDir.path, 'big.dart'),
        ).writeAsStringSync(giantFunctionSource(statements: 210));
        final toolDir = Directory(p.join(temp.path, 'tool'))
          ..createSync(recursive: true);
        File(
          p.join(toolDir.path, 'function_size_allowlist.yaml'),
        ).writeAsStringSync('''
allowed_over_20:
  - file: packages/colonizethis_logic/lib/src/big.dart
    symbol: giant
    max_measured_lines: 220
''');

        final errors = <String>[];
        final exitCode = runCheckFunctionSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('big.dart'));
        expect(errors.join('\n'), contains('giant'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
