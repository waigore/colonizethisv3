import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_long_string_switches.dart';

void main() {
  group('scanLongStringSwitch*', () {
    test('warns at 20 string switch cases', () {
      final cases = List.generate(
        20,
        (i) => "case 'k$i': return $i;",
      ).join('\n');
      final src =
          '''
int f(String v) {
  switch (v) {
$cases
    default:
      return -1;
  }
}
''';
      final warnings = scanLongStringSwitchWarnings(
        'packages/p/lib/a.dart',
        src,
      );
      final errors = scanLongStringSwitchErrors('packages/p/lib/a.dart', src);
      expect(warnings, hasLength(1));
      expect(warnings.single, contains('warn threshold 20'));
      expect(errors, isEmpty);
    });

    test('fails at 50 string switch cases', () {
      final cases = List.generate(
        50,
        (i) => "case 'k$i': return $i;",
      ).join('\n');
      final src =
          '''
int f(String v) {
  switch (v) {
$cases
    default:
      return -1;
  }
}
''';
      final errors = scanLongStringSwitchErrors('packages/p/lib/a.dart', src);
      expect(errors, hasLength(1));
      expect(errors.single, contains('limit 49'));
    });
  });

  group('runCheckLongStringSwitches', () {
    test('skips excluded generated and embed paths', () {
      final temp = Directory.systemTemp.createTempSync('long-switch-');
      addTearDown(() => temp.deleteSync(recursive: true));

      final pkgLib = Directory(p.join(temp.path, 'packages', 'p', 'lib'))
        ..createSync(recursive: true);
      final excludedDir = Directory(p.join(temp.path, 'tool'))
        ..createSync(recursive: true);

      final allowedCases = List.generate(
        50,
        (i) => "case 'allowed$i': return $i;",
      ).join('\n');
      File(p.join(pkgLib.path, 'allowed.dart')).writeAsStringSync('''
int f(String v) {
  switch (v) {
$allowedCases
    default:
      return -1;
  }
}
''');

      final excludedCases = List.generate(
        60,
        (i) => "case 'excluded$i': return $i;",
      ).join('\n');
      File(
        p.join(excludedDir.path, 'tech_effect_summary_embed.dart'),
      ).writeAsStringSync('''
int g(String v) {
  switch (v) {
$excludedCases
    default:
      return -1;
  }
}
''');

      final warnings = <String>[];
      final errors = <String>[];
      final code = runCheckLongStringSwitches(
        temp.path,
        warn: warnings.add,
        err: errors.add,
      );

      expect(code, 1);
      final out = [...warnings, ...errors].join('\n');
      expect(out, contains('allowed.dart'));
      expect(out, isNot(contains('tech_effect_summary_embed.dart')));
    });
  });
}
