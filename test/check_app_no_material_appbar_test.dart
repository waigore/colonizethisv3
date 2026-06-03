import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_appbar.dart';

void main() {
  group('runCheckAppNoMaterialAppBar', () {
    test('passes when feature files use CtTopBar / CtScreenShell', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_appbar_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/clean.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_screen_shell.dart';

Widget s() => const CtScreenShell(title: 'X', child: SizedBox());
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialAppBar(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('fails when a feature file constructs AppBar(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_appbar_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_appbar.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

PreferredSizeWidget bar() => AppBar(
  title: const Text('X'),
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialAppBar(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('bad_appbar.dart:3: AppBar('));
      expect(logs.join('\n'), contains('CtTopBar'));
    });

    test('does not flag SliverAppBar / suffixed identifiers / theme', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_appbar_suffix_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/suffix.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget a() => SliverAppBar(title: const Text('a'));
Widget b() => MyAppBar(title: const Text('b'));
ThemeData t() => ThemeData(appBarTheme: const AppBarTheme());
''');

      final code = runCheckAppNoMaterialAppBar(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('passes when AppBar appears inside a // comment or /// dartdoc', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_appbar_comment_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer CtTopBar over AppBar( for screen top chrome.
// AppBar( must not appear in real code, but a // comment is fine.
class C {}
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialAppBar(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('allowlists Ct-* chrome widgets and dev-tooling screens', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_appbar_allow_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      const allowed = <String>[
        'app/lib/features/game/widgets/chrome/ct_thing.dart',
        'app/lib/features/debug_log/debug_log_viewer_screen.dart',
        'app/lib/features/game/flame/debug_console_overlay_panel.dart',
      ];
      for (final rel in allowed) {
        File('${temp.path}/$rel')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget bypass() => AppBar(title: const Text('x'));
''');
      }

      final code = runCheckAppNoMaterialAppBar(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_appbar_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialAppBar(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });
  });

  group('bannedAppBarConstructionPattern (regex shape)', () {
    test('matches AppBar(', () {
      const samples = <String>['AppBar(', 'AppBar ('];
      for (final s in samples) {
        expect(
          bannedAppBarConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does NOT match SliverAppBar / suffixed identifiers / theme', () {
      const safe = <String>[
        'SliverAppBar(',
        'MyAppBar(',
        'AppBarTheme(',
        'AppBar',
      ];
      for (final s in safe) {
        expect(
          bannedAppBarConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
