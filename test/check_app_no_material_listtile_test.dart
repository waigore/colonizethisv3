import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_listtile.dart';

void main() {
  group('runCheckAppNoMaterialListTile', () {
    test('passes when feature files compose non-Material list rows', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_listtile_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/clean.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

class Clean extends StatelessWidget {
  const Clean({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Row'),
      ),
    );
  }
}
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialListTile(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('fails when a feature file constructs ListTile(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_listtile_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_tile.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget tile() => ListTile(
  title: const Text('Row'),
  onTap: () {},
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialListTile(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('bad_tile.dart:3: ListTile('));
      expect(logs.join('\n'), contains('UnitsEntityActionRow'));
    });

    test('does not flag the sibling list-tile families SwitchListTile / '
        'CheckboxListTile / RadioListTile', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_listtile_siblings_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/siblings.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget a() => SwitchListTile(value: false, onChanged: (_) {});
Widget b() => CheckboxListTile(value: false, onChanged: (_) {});
Widget c() => RadioListTile<int>(value: 0, groupValue: 0, onChanged: (_) {});
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialListTile(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('passes when ListTile appears inside a // comment or /// dartdoc', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_listtile_comment_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer UnitsEntityActionRow over ListTile( for unit rows.
// ListTile( must not appear in real code, but a // comment is fine.
class C {}
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialListTile(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('does not flag identifiers that contain "ListTile" without '
        'an opening paren (false-positive guard)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_listtile_identifier_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/identifier.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

class FakeListTileProbe {
  static const String label = 'ListTileProbe';
}
''');

      final code = runCheckAppNoMaterialListTile(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('allowlists Ct-* catalog widgets under features/game/widgets/chrome/', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_listtile_chrome_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/chrome/ct_thing.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget fallback() => ListTile(title: const Text('x'));
''');

      final code = runCheckAppNoMaterialListTile(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('allowlists the dev-tooling screens (SYS10001 + SYS20001)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_listtile_devtools_',
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

Widget bypass() => ListTile(title: const Text('x'));
''');
      }

      final code = runCheckAppNoMaterialListTile(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('does not scan test files inside features/ (production surface only)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_listtile_test_skip_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/some_widget_test.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget probe() => ListTile(title: const Text('x'));
''');

      final code = runCheckAppNoMaterialListTile(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_listtile_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialListTile(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });

    test('reports file path and line number on violation', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_listtile_line_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/x/y.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'import \'package:flutter/material.dart\';\n'
          '// line 2\n'
          '// line 3\n'
          'Widget z() => ListTile(title: const Text(\'x\'));\n',
        );

      final logs = <String>[];
      final code = runCheckAppNoMaterialListTile(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('app/lib/features/x/y.dart:4: ListTile('),
      );
    });
  });

  group('shouldSkipAppNoMaterialListTileFile (scope predicate)', () {
    test('skips generated suffixes', () {
      expect(
        shouldSkipAppNoMaterialListTileFile('app/lib/features/x/y.g.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialListTileFile('app/lib/features/x/y.freezed.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialListTileFile('app/lib/features/x/y.mocks.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialListTileFile('app/lib/features/x/y.gen.dart'),
        isTrue,
      );
    });

    test('skips test files inside features/', () {
      expect(
        shouldSkipAppNoMaterialListTileFile('app/lib/features/x/y_test.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialListTileFile('app/lib/features/x/test/y.dart'),
        isTrue,
      );
    });

    test('skips Ct-* chrome catalog widgets', () {
      expect(
        shouldSkipAppNoMaterialListTileFile(
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
          shouldSkipAppNoMaterialListTileFile(path),
          isTrue,
          reason: 'expected $path to be allowlisted',
        );
      }
    });

    test('does not skip ordinary feature widgets (in scope for the check)', () {
      expect(
        shouldSkipAppNoMaterialListTileFile(
          'app/lib/features/game/widgets/military_units_panel.dart',
        ),
        isFalse,
      );
      expect(
        shouldSkipAppNoMaterialListTileFile(
          'app/lib/features/game/widgets/civilian_units_panel_support.dart',
        ),
        isFalse,
      );
    });
  });

  group('bannedListTileConstructionPattern (regex shape)', () {
    test('matches bare ListTile construction with an opening paren', () {
      const samples = <String>['ListTile(', 'ListTile ('];
      for (final s in samples) {
        expect(
          bannedListTileConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does not match sibling list-tile families or bare identifiers', () {
      const safe = <String>[
        'SwitchListTile(',
        'CheckboxListTile(',
        'RadioListTile(',
        'MyListTile(',
        'ListTileTheme(',
        'ListTile',
        'ListTileProbe',
      ];
      for (final s in safe) {
        expect(
          bannedListTileConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
