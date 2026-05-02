import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_repeated_magic_numbers.dart';

void main() {
  group('collectMagicLiteralsFromSource', () {
    test('skips paths under test trees', () {
      expect(
        collectMagicLiteralsFromSource(
          'packages/foo/test/x.dart',
          'int f() => 0xDEADBEEF;',
        ),
        isEmpty,
      );
    });

    test('collects hex literals in lib paths', () {
      final occ = collectMagicLiteralsFromSource(
        'packages/foo/lib/x.dart',
        'int f() => 0xABBACADA;',
      );
      expect(occ, isNotEmpty);
      expect(occ.single.value, 0xABBACADA);
    });

    test('skips integer inside const variable initializer', () {
      const src = '''
const int kSecret = 0x12345678;
int a() => 0x12345678;
int b() => 0x12345678;
''';
      final occ = collectMagicLiteralsFromSource(
        'packages/foo/lib/x.dart',
        src,
      );
      expect(occ.length, 2);
    });

    test('does not track repeated small decimal literals', () {
      const src = '''
int a() => 50;
int b() => 50;
int c() => 50;
int d() => 50;
int e() => 50;
''';
      expect(
        collectMagicLiteralsFromSource('packages/foo/lib/x.dart', src),
        isEmpty,
      );
    });

    test('tracks repeated known LCG decimal literals', () {
      const src = '''
int a() => 12345;
int b() => 12345;
int c() => 12345;
int d() => 12345;
int e() => 12345;
''';
      final occ = collectMagicLiteralsFromSource(
        'packages/foo/lib/x.dart',
        src,
      );
      expect(occ.where((o) => o.value == 12345).length, 5);
    });
  });

  group('runCheckRepeatedMagicNumbers', () {
    test(
      'fails on repeated magic; legacy keyed waiver YAML under tool/ is not read',
      () {
        final temp = Directory.systemTemp.createTempSync('magic-legacy-');
        addTearDown(() => temp.deleteSync(recursive: true));

        final libDir = Directory(p.join(temp.path, 'packages', 'p', 'lib'))
          ..createSync(recursive: true);
        File(p.join(libDir.path, 'm.dart')).writeAsStringSync(r'''
int a() => 0xDECAFBAD;
int b() => 0xDECAFBAD;
int c() => 0xDECAFBAD;
int d() => 0xDECAFBAD;
int e() => 0xDECAFBAD;
''');

        final toolDir = Directory(p.join(temp.path, 'tool'))
          ..createSync(recursive: true);
        File(
          p.join(toolDir.path, 'legacy_repeated_magic_waiver_table.yaml'),
        ).writeAsStringSync('''
# Decoy: historical repo-lint keyed waiver shape; checker must not load this.
exempt_files:
  - packages/p/lib/m.dart
''');

        final errors = <String>[];
        final code = runCheckRepeatedMagicNumbers(
          temp.path,
          info: (_) {},
          err: errors.add,
          warn: (_) {},
        );

        expect(code, 1);
        final out = errors.join('\n');
        expect(out, contains('m.dart'));
        expect(out, contains('3737844653'));
      },
    );
  });
}
