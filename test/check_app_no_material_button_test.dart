import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_button.dart';

void main() {
  group('runCheckAppNoMaterialButton', () {
    test('passes when feature files use CtNinePatchButton', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_button_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/clean.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget action() => CtNinePatchButton(
  label: 'Go',
  onPressed: () {},
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('fails when a feature file constructs ElevatedButton(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_button_elevated_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget b() => ElevatedButton(
  onPressed: () {},
  child: const Text('Go'),
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('bad.dart:3: ElevatedButton('));
      expect(logs.join('\n'), contains('CtNinePatchButton'));
    });

    test('fails on FilledButton, OutlinedButton, and named constructors', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_button_family_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/family.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget a() => FilledButton(onPressed: () {}, child: const Text('a'));
Widget b() => FilledButton.tonal(onPressed: () {}, child: const Text('b'));
Widget c() => OutlinedButton(onPressed: () {}, child: const Text('c'));
Widget d() => OutlinedButton.icon(
  onPressed: () {},
  icon: const Icon(Icons.check),
  label: const Text('d'),
);
Widget e() => ElevatedButton.icon(
  onPressed: () {},
  icon: const Icon(Icons.check),
  label: const Text('e'),
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      final joined = logs.join('\n');
      expect(joined, contains('found 5 violation(s)'));
      expect(joined, contains('FilledButton('));
      expect(joined, contains('FilledButton.tonal('));
      expect(joined, contains('OutlinedButton('));
      expect(joined, contains('OutlinedButton.icon('));
      expect(joined, contains('ElevatedButton.icon('));
    });

    test('does not flag the static styleFrom ButtonStyle factory or theme '
        'types', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_button_stylefrom_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/style.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

final s = ElevatedButton.styleFrom(backgroundColor: Colors.transparent);
final f = FilledButton.styleFrom();
final o = OutlinedButton.styleFrom();
Widget t() => ElevatedButtonTheme(
  data: const ElevatedButtonThemeData(),
  child: const SizedBox.shrink(),
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('does not flag TextButton (covered by the sibling rule) or '
        'identifiers that merely end in a banned button name', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_button_siblings_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/siblings.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget t() => TextButton(onPressed: () {}, child: const Text('t'));
Widget m() => MyOutlinedButton(onPressed: () {});
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('passes when a banned button appears inside a // or /// comment', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_button_comment_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer CtNinePatchButton over ElevatedButton( for click affordances.
// FilledButton( must not appear in real code, but a // comment is fine.
class C {}
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('allowlists Ct-* catalog widgets under features/game/widgets/chrome/',
        () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_button_chrome_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/chrome/ct_thing.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget fallback() => ElevatedButton(onPressed: () {}, child: const Text('x'));
''');

      final code = runCheckAppNoMaterialButton(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('allowlists the dev-tooling screens (SYS10001 + SYS20001)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_button_devtools_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      const devTools = <String>[
        'app/lib/features/debug_log/debug_log_viewer_screen.dart',
        'app/lib/features/game/flame/debug_console_overlay_panel.dart',
      ];

      for (final rel in devTools) {
        File('${temp.path}/$rel')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget bypass() => OutlinedButton(onPressed: () {}, child: const Text('x'));
''');
      }

      final code = runCheckAppNoMaterialButton(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('does not scan test files inside features/ (production surface only)',
        () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_button_test_skip_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/some_widget_test.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget probe() => ElevatedButton(onPressed: () {}, child: const Text('x'));
''');

      final code = runCheckAppNoMaterialButton(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_button_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });

    test('reports file path and line number on violation', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_button_line_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/x/y.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'import \'package:flutter/material.dart\';\n'
          '// line 2\n'
          '// line 3\n'
          'Widget z() => FilledButton(onPressed: () {}, child: const Text(\'x\'));\n',
        );

      final logs = <String>[];
      final code = runCheckAppNoMaterialButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('app/lib/features/x/y.dart:4: FilledButton('),
      );
    });
  });

  group('shouldSkipAppNoMaterialButtonFile (scope predicate)', () {
    test('skips generated suffixes', () {
      expect(
        shouldSkipAppNoMaterialButtonFile('app/lib/features/x/y.g.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialButtonFile('app/lib/features/x/y.freezed.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialButtonFile('app/lib/features/x/y.mocks.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialButtonFile('app/lib/features/x/y.gen.dart'),
        isTrue,
      );
    });

    test('skips test files inside features/', () {
      expect(
        shouldSkipAppNoMaterialButtonFile('app/lib/features/x/y_test.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialButtonFile('app/lib/features/x/test/y.dart'),
        isTrue,
      );
    });

    test('skips Ct-* chrome catalog widgets', () {
      expect(
        shouldSkipAppNoMaterialButtonFile(
          'app/lib/features/game/widgets/chrome/ct_thing.dart',
        ),
        isTrue,
      );
    });

    test('skips the dev-tooling screens (SYS10001 + SYS20001)', () {
      const skipped = <String>[
        'app/lib/features/debug_log/debug_log_viewer_screen.dart',
        'app/lib/features/game/flame/debug_console_overlay_panel.dart',
      ];
      for (final path in skipped) {
        expect(
          shouldSkipAppNoMaterialButtonFile(path),
          isTrue,
          reason: 'expected $path to be allowlisted',
        );
      }
    });

    test('does not skip ordinary feature widgets (in scope for the check)', () {
      expect(
        shouldSkipAppNoMaterialButtonFile(
          'app/lib/features/game/widgets/military_units_panel.dart',
        ),
        isFalse,
      );
    });
  });

  group('bannedMaterialButtonConstructionPattern (regex shape)', () {
    test('matches bare and named-constructor button construction', () {
      const samples = <String>[
        'ElevatedButton(',
        'ElevatedButton (',
        'ElevatedButton.icon(',
        'FilledButton(',
        'FilledButton.tonal(',
        'FilledButton.tonalIcon(',
        'OutlinedButton(',
        'OutlinedButton.icon(',
      ];
      for (final s in samples) {
        expect(
          bannedMaterialButtonConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does not match styleFrom, theme types, TextButton, or suffix '
        'identifiers', () {
      const safe = <String>[
        'ElevatedButton.styleFrom(',
        'FilledButton.styleFrom(',
        'OutlinedButton.styleFrom(',
        'ElevatedButtonTheme(',
        'OutlinedButtonThemeData(',
        'TextButton(',
        'MyElevatedButton(',
        'CtOutlinedButton(',
        'ElevatedButton',
      ];
      for (final s in safe) {
        expect(
          bannedMaterialButtonConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
