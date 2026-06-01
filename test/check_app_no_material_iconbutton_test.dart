import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_iconbutton.dart';

void main() {
  group('runCheckAppNoMaterialIconButton', () {
    test(
      'passes when every features file uses CtIconAction (no IconButton)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_iconbutton_pass_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/clean.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';

class Clean extends StatelessWidget {
  const Clean({super.key});

  @override
  Widget build(BuildContext context) {
    return CtIconAction(
      icon: Icons.my_location,
      onPressed: () {},
      tooltip: 'Locate',
    );
  }
}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialIconButton(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test('fails when a feature file constructs IconButton(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_iconbutton_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_locate.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget locate() => IconButton(
  icon: const Icon(Icons.my_location),
  onPressed: () {},
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialIconButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('bad_locate.dart:3: IconButton('),
      );
      expect(
        logs.join('\n'),
        contains('CtIconAction'),
      );
    });

    test('fails for IconButton.outlined / .filled / .filledTonal variants', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_iconbutton_variants_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/variants.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget outlined() => IconButton.outlined(
  icon: const Icon(Icons.menu),
  onPressed: () {},
);

Widget filled() => IconButton.filled(
  icon: const Icon(Icons.menu),
  onPressed: () {},
);

Widget filledTonal() => IconButton.filledTonal(
  icon: const Icon(Icons.menu),
  onPressed: () {},
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialIconButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      final joined = logs.join('\n');
      expect(joined, contains('IconButton.outlined('));
      expect(joined, contains('IconButton.filled('));
      expect(joined, contains('IconButton.filledTonal('));
    });

    test(
      'passes when IconButton appears inside a // comment or /// dartdoc',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_iconbutton_comment_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer CtIconAction over IconButton( for glyph-only tap targets.
// IconButton( must not appear in real code, but a // comment is fine.
class C {}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialIconButton(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test(
      'does not flag identifiers that contain "IconButton" without '
      'an opening paren (false-positive guard)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_iconbutton_identifier_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/identifier.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

class FakeIconButtonProbe {
  static const String label = 'IconButtonProbe';
}
''');

        final code = runCheckAppNoMaterialIconButton(
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
          'check_app_no_material_iconbutton_chrome_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File(
          '${temp.path}/app/lib/features/game/widgets/chrome/ct_thing.dart',
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget fallback() => IconButton(icon: const Icon(Icons.menu), onPressed: () {});
''');

        final code = runCheckAppNoMaterialIconButton(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('allowlists dev-tooling screens (SYS10001, SYS20001)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_iconbutton_devtools_',
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

Widget bypass() => IconButton(icon: const Icon(Icons.close), onPressed: () {});
''');
      }

      final code = runCheckAppNoMaterialIconButton(
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
          'check_app_no_material_iconbutton_test_skip_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File(
          '${temp.path}/app/lib/features/game/widgets/some_widget_test.dart',
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget probe() => IconButton(icon: const Icon(Icons.bug_report), onPressed: () {});
''');

        final code = runCheckAppNoMaterialIconButton(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_iconbutton_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialIconButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });

    test('reports file path and line number on violation', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_iconbutton_line_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/x/y.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'import \'package:flutter/material.dart\';\n'
          '// line 2\n'
          '// line 3\n'
          'Widget z() => IconButton(icon: const Icon(Icons.menu), onPressed: () {});\n',
        );

      final logs = <String>[];
      final code = runCheckAppNoMaterialIconButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('app/lib/features/x/y.dart:4: IconButton('),
      );
    });
  });

  group('shouldSkipAppNoMaterialIconButtonFile (scope predicate)', () {
    test('skips generated suffixes', () {
      expect(
        shouldSkipAppNoMaterialIconButtonFile(
          'app/lib/features/x/y.g.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialIconButtonFile(
          'app/lib/features/x/y.freezed.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialIconButtonFile(
          'app/lib/features/x/y.mocks.dart',
        ),
        isTrue,
      );
    });

    test('skips test files inside features/', () {
      expect(
        shouldSkipAppNoMaterialIconButtonFile(
          'app/lib/features/x/y_test.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialIconButtonFile(
          'app/lib/features/x/test/y.dart',
        ),
        isTrue,
      );
    });

    test('skips Ct-* chrome catalog widgets', () {
      expect(
        shouldSkipAppNoMaterialIconButtonFile(
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
          shouldSkipAppNoMaterialIconButtonFile(path),
          isTrue,
          reason: 'expected $path to be allowlisted',
        );
      }
    });

    test(
      'does not skip ordinary feature widgets (in scope for the check)',
      () {
        expect(
          shouldSkipAppNoMaterialIconButtonFile(
            'app/lib/features/game/widgets/move_fleet_dialog.dart',
          ),
          isFalse,
        );
        expect(
          shouldSkipAppNoMaterialIconButtonFile(
            'app/lib/features/game/widgets/military_units_panel.dart',
          ),
          isFalse,
        );
        expect(
          shouldSkipAppNoMaterialIconButtonFile(
            'app/lib/features/game/flame/game_screen.dart',
          ),
          isFalse,
        );
      },
    );
  });

  group('bannedIconButtonConstructionPattern (regex shape)', () {
    test('matches IconButton + named constructors with opening paren', () {
      const samples = <String>[
        'IconButton(',
        'IconButton (',
        'IconButton.outlined(',
        'IconButton.filled(',
        'IconButton.filledTonal(',
      ];
      for (final s in samples) {
        expect(
          bannedIconButtonConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does not match identifiers without an opening paren', () {
      const safe = <String>[
        'IconButtonProbe',
        'FakeIconButton',
        'IconButton.styleFrom',
        'CtIconAction',
        'IconButtonTheme',
      ];
      for (final s in safe) {
        expect(
          bannedIconButtonConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
