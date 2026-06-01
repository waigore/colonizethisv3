import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_scaffold.dart';

void main() {
  group('runCheckAppNoMaterialScaffold', () {
    test(
      'passes when every features file uses CtGameFeatureScreenShell '
      '(no direct Scaffold)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_scaffold_pass_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/screens/clean.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_game_feature_screen_shell.dart';

class Clean extends StatelessWidget {
  const Clean({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialScaffold(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test('fails when a feature file constructs Scaffold(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_scaffold_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/screens/bad_screen.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget screen() => Scaffold(
  appBar: AppBar(title: const Text('x')),
  body: const SizedBox.shrink(),
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialScaffold(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('bad_screen.dart:3: Scaffold('),
      );
      expect(
        logs.join('\n'),
        contains('CtGameFeatureScreenShell'),
      );
    });

    test('passes when Scaffold appears inside a // comment or /// dartdoc', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_scaffold_comment_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/screens/ok_comment.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer CtGameFeatureScreenShell over Scaffold( for feature screens.
// Scaffold( must not appear in real code, but a // comment is fine.
class C {}
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialScaffold(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test(
      'does not flag identifiers that contain "Scaffold" without '
      'an opening paren (false-positive guard)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_scaffold_identifier_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/screens/identifier.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

class FakeScaffoldProbe {
  static const String label = 'ScaffoldProbe';
}
''');

        final code = runCheckAppNoMaterialScaffold(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test(
      'does not flag ScaffoldMessenger or ScaffoldState (distinct identifiers)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_scaffold_distinct_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/screens/snackbar.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

void notify(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('hi')),
  );
}

ScaffoldState? readState(BuildContext context) {
  return Scaffold.maybeOf(context);
}
''');

        final code = runCheckAppNoMaterialScaffold(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test(
      'does not flag Scaffold.of(context) static member access',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_scaffold_static_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/screens/static_access.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

void open(BuildContext context) {
  Scaffold.of(context).openDrawer();
}
''');

        final code = runCheckAppNoMaterialScaffold(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test(
      'allowlists Ct-* catalog widgets under features/game/widgets/chrome/',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_scaffold_chrome_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File(
          '${temp.path}/app/lib/features/game/widgets/chrome/ct_thing.dart',
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget fallback() => Scaffold(body: const SizedBox.shrink());
''');

        final code = runCheckAppNoMaterialScaffold(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('allowlists dev-tooling screens (SYS10001, SYS20001)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_scaffold_devtools_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      const debugConsole =
          'app/lib/features/game/flame/debug_console_overlay_panel.dart';
      const debugViewer =
          'app/lib/features/debug_log/debug_log_viewer_screen.dart';

      for (final rel in [debugConsole, debugViewer]) {
        File('${temp.path}/$rel')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget bypass() => Scaffold(body: const SizedBox.shrink());
''');
      }

      final code = runCheckAppNoMaterialScaffold(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test(
      'does not scan test files inside features/ (production surface only)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_scaffold_test_skip_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File(
          '${temp.path}/app/lib/features/game/widgets/some_widget_test.dart',
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget probe() => Scaffold(body: const SizedBox.shrink());
''');

        final code = runCheckAppNoMaterialScaffold(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_scaffold_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialScaffold(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });

    test('reports file path and line number on violation', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_scaffold_line_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/x/y.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'import \'package:flutter/material.dart\';\n'
          '// line 2\n'
          '// line 3\n'
          'Widget z() => Scaffold(body: const SizedBox.shrink());\n',
        );

      final logs = <String>[];
      final code = runCheckAppNoMaterialScaffold(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('app/lib/features/x/y.dart:4: Scaffold('),
      );
    });
  });

  group('shouldSkipAppNoMaterialScaffoldFile (scope predicate)', () {
    test('skips generated suffixes', () {
      expect(
        shouldSkipAppNoMaterialScaffoldFile(
          'app/lib/features/x/y.g.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialScaffoldFile(
          'app/lib/features/x/y.freezed.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialScaffoldFile(
          'app/lib/features/x/y.mocks.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialScaffoldFile(
          'app/lib/features/x/y.gen.dart',
        ),
        isTrue,
      );
    });

    test('skips test files inside features/', () {
      expect(
        shouldSkipAppNoMaterialScaffoldFile(
          'app/lib/features/x/y_test.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialScaffoldFile(
          'app/lib/features/x/test/y.dart',
        ),
        isTrue,
      );
    });

    test('skips Ct-* chrome catalog widgets', () {
      expect(
        shouldSkipAppNoMaterialScaffoldFile(
          'app/lib/features/game/widgets/chrome/ct_thing.dart',
        ),
        isTrue,
      );
    });

    test('skips canonical dev-tooling screens', () {
      const skipped = <String>[
        'app/lib/features/debug_log/debug_log_viewer_screen.dart',
        'app/lib/features/game/flame/debug_console_overlay_panel.dart',
      ];
      for (final path in skipped) {
        expect(
          shouldSkipAppNoMaterialScaffoldFile(path),
          isTrue,
          reason: 'expected $path to be allowlisted',
        );
      }
    });

    test(
      'does not skip ordinary feature screens (in scope for the check)',
      () {
        expect(
          shouldSkipAppNoMaterialScaffoldFile(
            'app/lib/features/game/screens/diplomacy_detail_screen.dart',
          ),
          isFalse,
        );
        expect(
          shouldSkipAppNoMaterialScaffoldFile(
            'app/lib/features/game/widgets/move_fleet_dialog.dart',
          ),
          isFalse,
        );
        expect(
          shouldSkipAppNoMaterialScaffoldFile(
            'app/lib/features/game/flame/game_screen.dart',
          ),
          isFalse,
        );
      },
    );
  });

  group('bannedScaffoldConstructionPattern (regex shape)', () {
    test('matches Scaffold( with optional whitespace', () {
      const samples = <String>[
        'Scaffold(',
        'Scaffold (',
      ];
      for (final s in samples) {
        expect(
          bannedScaffoldConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test(
      'does not match ScaffoldMessenger, ScaffoldState, or static members',
      () {
        const safe = <String>[
          'ScaffoldMessenger.of(',
          'ScaffoldMessenger(',
          'ScaffoldState(',
          'Scaffold.of(',
          'Scaffold.maybeOf(',
          'MyScaffold',
          'FakeScaffold',
          'ScaffoldTheme',
        ];
        for (final s in safe) {
          expect(
            bannedScaffoldConstructionPattern.hasMatch(s),
            isFalse,
            reason: 'expected pattern NOT to match $s',
          );
        }
      },
    );
  });
}
