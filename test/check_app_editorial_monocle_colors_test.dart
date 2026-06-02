import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_editorial_monocle_colors.dart';

void main() {
  group('runCheckAppEditorialMonocleColors', () {
    test(
      'passes when every features file uses EditorialMonoclePalette tokens',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_editorial_monocle_colors_pass_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/clean.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';

class Clean extends StatelessWidget {
  const Clean({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: EditorialMonoclePalette.fg);
  }
}
''');

        final logs = <String>[];
        final code = runCheckAppEditorialMonocleColors(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test(
      'fails when a feature file uses Colors.black54 (named Material color)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_editorial_monocle_colors_black54_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/bad_scrim.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget scrim() => Container(color: Colors.black54);
''');

        final logs = <String>[];
        final code = runCheckAppEditorialMonocleColors(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 1);
        expect(
          logs.join('\n'),
          contains('bad_scrim.dart:3: Colors.black54'),
        );
        expect(
          logs.join('\n'),
          contains('EditorialMonoclePalette token'),
        );
      },
    );

    test('fails for Colors.white70 and other opacity-suffixed variants', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_editorial_monocle_colors_white70_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_text.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

const placeholder = TextStyle(color: Colors.white70);
''');

      final code = runCheckAppEditorialMonocleColors(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 1);
    });

    test('fails for raw const Color(0x...) hex literal in feature code', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_editorial_monocle_colors_hex_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_hex.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

const accent = Color(0xFFCC0000);
const accentConst = const Color(0xFFCC0000);
''');

      final logs = <String>[];
      final code = runCheckAppEditorialMonocleColors(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      // Only `const Color(0x...)` form should fire, not the bare `Color(0x...)`
      // (which compiles in non-const positions and is already covered by other
      // gates / palette adoption).
      expect(logs.join('\n'), contains('bad_hex.dart:4: const Color(0x'));
    });

    test('passes for redAccent variants used inside a comment', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_editorial_monocle_colors_comment_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer EditorialMonoclePalette.danger over Colors.redAccent.
// Colors.black54 must not appear in real code, but a // comment is fine.
class C {}
''');

      final logs = <String>[];
      final code = runCheckAppEditorialMonocleColors(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('does not flag Colors.transparent (not on the ban list)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_editorial_monocle_colors_transparent_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/transparent_ok.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget hitTarget() => Container(color: Colors.transparent);
''');

      final code = runCheckAppEditorialMonocleColors(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test(
      'allowlists Ct-* catalog widgets under features/game/widgets/chrome/',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_editorial_monocle_colors_chrome_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File(
          '${temp.path}/app/lib/features/game/widgets/chrome/ct_thing.dart',
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

const fallback = TextStyle(color: Colors.white);
''');

        final code = runCheckAppEditorialMonocleColors(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('allowlists Flame canvas renderers and palette data files', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_editorial_monocle_colors_flame_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      const flameRenderer =
          'app/lib/features/game/flame/region_map_component_render_core.dart';
      const palette =
          'app/lib/features/game/flame/resource_icon_disc_palette.dart';
      const debugViewer =
          'app/lib/features/debug_log/debug_log_viewer_screen.dart';

      for (final rel in [flameRenderer, palette, debugViewer]) {
        File('${temp.path}/$rel')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

const bypass = Color(0xFF888888);
const debug = TextStyle(color: Colors.white);
''');
      }

      final code = runCheckAppEditorialMonocleColors(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test(
      'no longer allowlists debug_console_overlay_panel.dart (Refs #2914 S3 + S8 '
      'token adoption + CtIconAction migration)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_editorial_monocle_colors_debug_console_promoted_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        const debugConsole =
            'app/lib/features/game/flame/debug_console_overlay_panel.dart';
        File('${temp.path}/$debugConsole')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

const sample = TextStyle(color: Colors.white);
''');

        final logs = <String>[];
        final code = runCheckAppEditorialMonocleColors(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 1);
        expect(
          logs.join('\n'),
          contains(
            'app/lib/features/game/flame/debug_console_overlay_panel.dart:3: '
            'Colors.white',
          ),
        );
      },
    );

    test(
      'does not scan test files inside features/ (production surface only)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_editorial_monocle_colors_test_skip_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File(
          '${temp.path}/app/lib/features/game/widgets/some_widget_test.dart',
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

const sample = TextStyle(color: Colors.black54);
''');

        final code = runCheckAppEditorialMonocleColors(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_editorial_monocle_colors_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppEditorialMonocleColors(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });

    test(
      'fails when a file under app/lib/widgets/ uses a banned Material color '
      '(extended scope for #2914 §S4)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_editorial_monocle_colors_widgets_named_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        // features/ root must exist for the check to run; populate with a
        // clean placeholder so the widgets/ scan is what surfaces.
        File('${temp.path}/app/lib/features/.keep.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('// keep\n');
        File('${temp.path}/app/lib/widgets/bad_widget.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

const placeholder = TextStyle(color: Colors.black54);
''');

        final logs = <String>[];
        final code = runCheckAppEditorialMonocleColors(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 1);
        expect(
          logs.join('\n'),
          contains('app/lib/widgets/bad_widget.dart:3: Colors.black54'),
        );
      },
    );

    test(
      'fails when a file under app/lib/widgets/ uses a raw const Color(0x...) '
      'hex literal (extended scope for #2914 §S4)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_editorial_monocle_colors_widgets_hex_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/.keep.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('// keep\n');
        File('${temp.path}/app/lib/widgets/bad_hex_widget.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

const accentConst = const Color(0xFFCC0000);
''');

        final logs = <String>[];
        final code = runCheckAppEditorialMonocleColors(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 1);
        expect(
          logs.join('\n'),
          contains(
            'app/lib/widgets/bad_hex_widget.dart:3: const Color(0x',
          ),
        );
      },
    );

    test(
      'allowlists app/lib/widgets/ canvas-compositing files '
      '(ct_main_menu_collage.dart, main_menu.dart)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_editorial_monocle_colors_widgets_compositing_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/.keep.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('// keep\n');

        // ct_main_menu_collage.dart — saveLayer alpha multiplier; the
        // const Color(0xFFFFFFFF) literal is a compositing argument.
        File('${temp.path}/app/lib/widgets/ct_main_menu_collage.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

final layerPaint = Paint()
  ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8);
''');

        // main_menu.dart — hover ColorFilter.mode darken composite; the
        // Colors.black literal is a blend operand, not a theme reference.
        File('${temp.path}/app/lib/widgets/main_menu.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

final hoverFilter = ColorFilter.mode(
  Colors.black.withValues(alpha: 0.15),
  BlendMode.darken,
);
''');

        final code = runCheckAppEditorialMonocleColors(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test(
      'does not scan test files inside app/lib/widgets/ '
      '(production surface only)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_editorial_monocle_colors_widgets_test_skip_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/.keep.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('// keep\n');
        File('${temp.path}/app/lib/widgets/some_widget_test.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

const sample = TextStyle(color: Colors.black54);
''');

        final code = runCheckAppEditorialMonocleColors(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test(
      'passes when app/lib/widgets/ is absent from the scanned tree '
      '(scan is opportunistic, not required)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_editorial_monocle_colors_widgets_absent_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/clean.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';

class Clean extends StatelessWidget {
  const Clean({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: EditorialMonoclePalette.fg);
  }
}
''');

        final code = runCheckAppEditorialMonocleColors(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('reports file path and line number on violation', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_editorial_monocle_colors_line_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/x/y.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'import \'package:flutter/material.dart\';\n'
          '// line 2\n'
          '// line 3\n'
          'const bad = TextStyle(color: Colors.grey);\n',
        );

      final logs = <String>[];
      final code = runCheckAppEditorialMonocleColors(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('app/lib/features/x/y.dart:4: Colors.grey'),
      );
    });
  });

  group('shouldSkipAppEditorialMonocleColorsFile (scope predicate)', () {
    test('skips generated suffixes', () {
      expect(
        shouldSkipAppEditorialMonocleColorsFile(
          'app/lib/features/x/y.g.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppEditorialMonocleColorsFile(
          'app/lib/features/x/y.freezed.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppEditorialMonocleColorsFile(
          'app/lib/features/x/y.mocks.dart',
        ),
        isTrue,
      );
    });

    test('skips test files inside features/', () {
      expect(
        shouldSkipAppEditorialMonocleColorsFile(
          'app/lib/features/x/y_test.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppEditorialMonocleColorsFile(
          'app/lib/features/x/test/y.dart',
        ),
        isTrue,
      );
    });

    test('skips Ct-* chrome catalog widgets', () {
      expect(
        shouldSkipAppEditorialMonocleColorsFile(
          'app/lib/features/game/widgets/chrome/ct_thing.dart',
        ),
        isTrue,
      );
    });

    test('skips canonical Flame renderer + debug + palette files', () {
      const skipped = <String>[
        'app/lib/features/game/flame/region_map_component_render_core.dart',
        'app/lib/features/game/flame/region_map_component_render_political.dart',
        'app/lib/features/game/flame/region_map_component_render_markers.dart',
        'app/lib/features/game/flame/game_region_minimap.dart',
        'app/lib/features/game/flame/resource_icon_disc_palette.dart',
        'app/lib/features/debug_log/debug_log_viewer_screen.dart',
      ];
      for (final path in skipped) {
        expect(
          shouldSkipAppEditorialMonocleColorsFile(path),
          isTrue,
          reason: 'expected $path to be allowlisted',
        );
      }
    });

    test(
      'does not skip debug_console_overlay_panel.dart (in scope for the '
      'check after Refs #2914 S3 + S8 token adoption)',
      () {
        expect(
          shouldSkipAppEditorialMonocleColorsFile(
            'app/lib/features/game/flame/debug_console_overlay_panel.dart',
          ),
          isFalse,
        );
      },
    );

    test(
      'skips app/lib/widgets/ canvas-compositing files (Refs #2914 §S4 '
      'extended scope)',
      () {
        const compositing = <String>[
          'app/lib/widgets/ct_main_menu_collage.dart',
          'app/lib/widgets/main_menu.dart',
        ];
        for (final path in compositing) {
          expect(
            shouldSkipAppEditorialMonocleColorsFile(path),
            isTrue,
            reason: 'expected $path to be allowlisted as a canvas-'
                'compositing file (alpha multiplier / blend operand)',
          );
        }
      },
    );

    test(
      'does not skip ordinary feature widgets (in scope for the check)',
      () {
        expect(
          shouldSkipAppEditorialMonocleColorsFile(
            'app/lib/features/game/widgets/move_army_dialog.dart',
          ),
          isFalse,
        );
        expect(
          shouldSkipAppEditorialMonocleColorsFile(
            'app/lib/features/game/screens/trade_screen.dart',
          ),
          isFalse,
        );
        expect(
          shouldSkipAppEditorialMonocleColorsFile(
            'app/lib/features/game/flame/game_side_menu.dart',
          ),
          isFalse,
        );
      },
    );

    test(
      'does not skip ordinary app/lib/widgets/ files (in scope for the check '
      'under #2914 §S4 extended scope)',
      () {
        expect(
          shouldSkipAppEditorialMonocleColorsFile(
            'app/lib/widgets/ct_dialog_shell.dart',
          ),
          isFalse,
        );
        expect(
          shouldSkipAppEditorialMonocleColorsFile(
            'app/lib/widgets/ct_nine_patch_button.dart',
          ),
          isFalse,
        );
        expect(
          shouldSkipAppEditorialMonocleColorsFile(
            'app/lib/widgets/ct_section_label.dart',
          ),
          isFalse,
        );
      },
    );
  });

  group('bannedColorLiteralPattern (regex shape)', () {
    test('matches named Material color tokens listed in #2914 §1', () {
      const samples = <String>[
        'Colors.black',
        'Colors.black54',
        'Colors.black87',
        'Colors.white',
        'Colors.white60',
        'Colors.white70',
        'Colors.red',
        'Colors.redAccent',
        'Colors.green',
        'Colors.greenAccent',
        'Colors.grey',
        'Colors.gray',
      ];
      for (final s in samples) {
        expect(
          bannedColorLiteralPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('matches raw const Color(0x...) hex literals', () {
      expect(
        bannedColorLiteralPattern.hasMatch('const Color(0xFFCC0000)'),
        isTrue,
      );
      expect(
        bannedColorLiteralPattern.hasMatch(' const  Color (0xff112233)'),
        isTrue,
      );
    });

    test('does not match Colors.transparent or unrelated identifiers', () {
      const safe = <String>[
        'Colors.transparent',
        'EditorialMonoclePalette.fg',
        'Colors.amber',
        'Colors.blue',
        'const TextStyle(color: ...)',
        'Color.fromRGBO(10, 20, 30, 1)',
      ];
      for (final s in safe) {
        expect(
          bannedColorLiteralPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
