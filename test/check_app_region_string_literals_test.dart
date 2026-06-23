import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_region_string_literals.dart';

void main() {
  group('runCheckAppRegionStringLiterals', () {
    test('passes when app files use kRegion* constants', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_region_string_literals_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/clean.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kRegionNewWorld, kRegionOldWorld;

int regionIndex(String regionId) =>
    regionId == kRegionNewWorld ? 1 : (regionId == kRegionOldWorld ? 0 : -1);
''');

      final logs = <String>[];
      final code = runCheckAppRegionStringLiterals(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test("fails when a file hard-codes 'oldWorld' / 'newWorld'", () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_region_string_literals_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/bad_region.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
int regionIndex(String regionId) {
  if (regionId == 'newWorld') return 1;
  if (regionId == "oldWorld") return 0;
  return -1;
}
''');

      final logs = <String>[];
      final code = runCheckAppRegionStringLiterals(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      final out = logs.join('\n');
      expect(out, contains("bad_region.dart:2: 'newWorld'"));
      expect(out, contains('bad_region.dart:3: "oldWorld"'));
      expect(out, contains('kRegionOldWorld'));
    });

    test('does not flag prefixed/composite ids or region_* identifiers', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_region_string_literals_safe_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/safe.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kRegionOldWorld;

bool isOld(String tileKey) => tileKey.startsWith('$kRegionOldWorld|');
String composite() => 'oldWorld|p1';
String label(dynamic l10n) => l10n.region_oldWorld as String;
''');

      final logs = <String>[];
      final code = runCheckAppRegionStringLiterals(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('passes when literal appears inside a // comment or /// dartdoc', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_region_string_literals_comment_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/ok_comment.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
/// Prefer kRegionOldWorld over 'oldWorld' for region ids.
// 'newWorld' must not appear in real code, but a // comment is fine.
class C {}
''');

      final logs = <String>[];
      final code = runCheckAppRegionStringLiterals(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('excludes l10n, test_support, widgetbook, generated, and tests', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_region_string_literals_exclude_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      const excluded = <String>[
        'app/lib/l10n/app_localizations.dart',
        'app/lib/test_support/region_fixtures.dart',
        'app/lib/widgetbook/catalog_panels.dart',
        'app/lib/features/game/model.g.dart',
        'app/lib/features/game/region_test.dart',
      ];
      for (final rel in excluded) {
        File('${temp.path}/$rel')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
const a = 'oldWorld';
const b = 'newWorld';
''');
      }

      final code = runCheckAppRegionStringLiterals(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('returns exit 1 when app/lib does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_region_string_literals_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppRegionStringLiterals(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib not found'));
    });
  });

  group('shouldSkipAppRegionStringLiteralsFile', () {
    test('skips generated, test, l10n, and fixture directories', () {
      const skipped = <String>[
        'app/lib/features/game/model.g.dart',
        'app/lib/features/game/model.freezed.dart',
        'app/lib/features/game/service.mocks.dart',
        'app/lib/features/game/data.gen.dart',
        'app/lib/features/game/region_test.dart',
        'app/lib/l10n/app_localizations_en.dart',
        'app/lib/test_support/region_fixtures.dart',
        'app/lib/widgetbook/catalog_panels.dart',
      ];
      for (final rel in skipped) {
        expect(
          shouldSkipAppRegionStringLiteralsFile(rel),
          isTrue,
          reason: 'expected $rel to be skipped',
        );
      }
    });

    test('does not skip ordinary production files', () {
      expect(
        shouldSkipAppRegionStringLiteralsFile(
          'app/lib/features/game/widgets/utils/military_tree_builder.dart',
        ),
        isFalse,
      );
    });
  });

  group('bannedRegionStringLiteralPattern (regex shape)', () {
    test("matches bare 'oldWorld' / \"newWorld\"", () {
      const samples = <String>[
        "x == 'oldWorld'",
        'x == "oldWorld"',
        "x == 'newWorld'",
        'x == "newWorld"',
      ];
      for (final s in samples) {
        expect(
          bannedRegionStringLiteralPattern.hasMatch(s),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does NOT match composite ids, identifiers, or mismatched quotes', () {
      const safe = <String>[
        "'oldWorld|p1'",
        'region_oldWorld',
        r"'$kRegionOldWorld|'",
        'kRegionNewWorld',
        'oldWorld',
      ];
      for (final s in safe) {
        expect(
          bannedRegionStringLiteralPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
