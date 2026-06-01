import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_textbutton.dart';

void main() {
  group('runCheckAppNoMaterialTextButton', () {
    test(
      'passes when every features file uses CtNinePatchButton (no TextButton)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_textbutton_pass_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/clean.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';

class Clean extends StatelessWidget {
  const Clean({super.key});

  @override
  Widget build(BuildContext context) {
    return CtNinePatchButton(
      onPressed: () {},
      child: const Text('cancel'),
    );
  }
}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialTextButton(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test('fails when a feature file constructs TextButton(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_textbutton_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_cancel.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget cancel() => TextButton(
  onPressed: () {},
  child: const Text('cancel'),
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialTextButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('bad_cancel.dart:3: TextButton('),
      );
      expect(
        logs.join('\n'),
        contains('CtNinePatchButton'),
      );
    });

    test('fails for TextButton.icon / .tonalIcon variants', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_textbutton_variants_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/variants.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget iconVariant() => TextButton.icon(
  onPressed: () {},
  icon: const Icon(Icons.close),
  label: const Text('close'),
);

Widget tonalIconVariant() => TextButton.tonalIcon(
  onPressed: () {},
  icon: const Icon(Icons.close),
  label: const Text('close'),
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialTextButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      final joined = logs.join('\n');
      expect(joined, contains('TextButton.icon('));
      expect(joined, contains('TextButton.tonalIcon('));
    });

    test(
      'passes when TextButton appears inside a // comment or /// dartdoc',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_textbutton_comment_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer CtNinePatchButton over TextButton( for catalog click affordances.
// TextButton( must not appear in real code, but a // comment is fine.
class C {}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialTextButton(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test(
      'does not flag identifiers that contain "TextButton" without '
      'an opening paren (false-positive guard)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_textbutton_identifier_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/identifier.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

class FakeTextButtonProbe {
  static const String label = 'TextButtonProbe';
}
''');

        final code = runCheckAppNoMaterialTextButton(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test(
      'does not flag CtDangerTextButton (Ct-* catalog widget with TextButton '
      'as a suffix)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_textbutton_ct_danger_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/labour_row.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_danger_text_button.dart';

Widget disband() => CtDangerTextButton(
  label: 'Disband',
  onPressed: () {},
);
''');

        final code = runCheckAppNoMaterialTextButton(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test(
      'does not flag TextButton.styleFrom (static ButtonStyle factory; '
      'legitimate theme work that does not construct the widget)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_textbutton_style_from_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/theme_helpers.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

ButtonStyle accentStyle() => TextButton.styleFrom(
  foregroundColor: const Color(0xFFAABBCC),
);
''');

        final code = runCheckAppNoMaterialTextButton(
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
          'check_app_no_material_textbutton_chrome_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File(
          '${temp.path}/app/lib/features/game/widgets/chrome/ct_thing.dart',
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget fallback() => TextButton(onPressed: () {}, child: const Text('ok'));
''');

        final code = runCheckAppNoMaterialTextButton(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('allowlists dev-tooling screens (SYS10001, SYS20001)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_textbutton_devtools_',
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

Widget bypass() => TextButton(onPressed: () {}, child: const Text('ok'));
''');
      }

      final code = runCheckAppNoMaterialTextButton(
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
          'check_app_no_material_textbutton_test_skip_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File(
          '${temp.path}/app/lib/features/game/widgets/some_widget_test.dart',
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget probe() => TextButton(onPressed: () {}, child: const Text('ok'));
''');

        final code = runCheckAppNoMaterialTextButton(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_textbutton_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialTextButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });

    test('reports file path and line number on violation', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_textbutton_line_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/x/y.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'import \'package:flutter/material.dart\';\n'
          '// line 2\n'
          '// line 3\n'
          'Widget z() => TextButton(onPressed: () {}, child: const Text(\'ok\'));\n',
        );

      final logs = <String>[];
      final code = runCheckAppNoMaterialTextButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('app/lib/features/x/y.dart:4: TextButton('),
      );
    });
  });

  group('shouldSkipAppNoMaterialTextButtonFile (scope predicate)', () {
    test('skips generated suffixes', () {
      expect(
        shouldSkipAppNoMaterialTextButtonFile(
          'app/lib/features/x/y.g.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialTextButtonFile(
          'app/lib/features/x/y.freezed.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialTextButtonFile(
          'app/lib/features/x/y.mocks.dart',
        ),
        isTrue,
      );
    });

    test('skips test files inside features/', () {
      expect(
        shouldSkipAppNoMaterialTextButtonFile(
          'app/lib/features/x/y_test.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialTextButtonFile(
          'app/lib/features/x/test/y.dart',
        ),
        isTrue,
      );
    });

    test('skips Ct-* chrome catalog widgets', () {
      expect(
        shouldSkipAppNoMaterialTextButtonFile(
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
          shouldSkipAppNoMaterialTextButtonFile(path),
          isTrue,
          reason: 'expected $path to be allowlisted',
        );
      }
    });

    test(
      'does not skip ordinary feature widgets (in scope for the check)',
      () {
        expect(
          shouldSkipAppNoMaterialTextButtonFile(
            'app/lib/features/game/flame/game_map_canvas_stack.dart',
          ),
          isFalse,
        );
        expect(
          shouldSkipAppNoMaterialTextButtonFile(
            'app/lib/features/game/widgets/move_fleet_dialog.dart',
          ),
          isFalse,
        );
        expect(
          shouldSkipAppNoMaterialTextButtonFile(
            'app/lib/features/game/widgets/military_units_panel.dart',
          ),
          isFalse,
        );
      },
    );
  });

  group('bannedTextButtonConstructionPattern (regex shape)', () {
    test('matches TextButton + named constructors with opening paren', () {
      const samples = <String>[
        'TextButton(',
        'TextButton (',
        'TextButton.icon(',
        'TextButton.tonalIcon(',
      ];
      for (final s in samples) {
        expect(
          bannedTextButtonConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does not match identifiers without an opening paren', () {
      const safe = <String>[
        'TextButtonProbe',
        'FakeTextButton',
        'TextButtonTheme',
        'CtNinePatchButton',
      ];
      for (final s in safe) {
        expect(
          bannedTextButtonConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });

    test(
      'does not match catalog widgets that contain "TextButton" as a suffix',
      () {
        // CtDangerTextButton is a sanctioned Ct-* catalog widget (its very
        // name ends in TextButton). Word boundary in the regex must keep
        // this consumer call site out of scope.
        const safe = <String>[
          'CtDangerTextButton(',
          'CtDangerTextButton (',
          ' MyCustomTextButton(',
        ];
        for (final s in safe) {
          expect(
            bannedTextButtonConstructionPattern.hasMatch(s),
            isFalse,
            reason:
                'expected pattern NOT to match $s (TextButton-suffixed names '
                'are sanctioned catalog widgets)',
          );
        }
      },
    );

    test(
      'does not match TextButton.styleFrom (static ButtonStyle factory)',
      () {
        const safe = <String>[
          'TextButton.styleFrom(',
          'TextButton.styleFrom (',
        ];
        for (final s in safe) {
          expect(
            bannedTextButtonConstructionPattern.hasMatch(s),
            isFalse,
            reason:
                'expected pattern NOT to match $s (styleFrom is a theme '
                'helper, not a widget constructor)',
          );
        }
      },
    );
  });
}
