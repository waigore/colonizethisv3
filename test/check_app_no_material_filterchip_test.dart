import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_filterchip.dart';

void main() {
  group('runCheckAppNoMaterialFilterChip', () {
    test(
      'passes when every features file uses CtChoiceChip (no FilterChip)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_filterchip_pass_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/clean.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';

class Clean extends StatelessWidget {
  const Clean({super.key});

  @override
  Widget build(BuildContext context) {
    return CtChoiceChip(
      label: const Text('all'),
      selected: false,
      onSelected: (_) {},
    );
  }
}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialFilterChip(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test('fails when a feature file constructs FilterChip(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_filterchip_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_chip.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget chip() => FilterChip(
  label: const Text('all'),
  selected: false,
  onSelected: (_) {},
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialFilterChip(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('bad_chip.dart:3: FilterChip('));
      expect(logs.join('\n'), contains('CtChoiceChip'));
    });

    test('fails for FilterChip.elevated variant', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_filterchip_elevated_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/elevated.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget elevated() => FilterChip.elevated(
  label: const Text('all'),
  selected: false,
  onSelected: (_) {},
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialFilterChip(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('FilterChip.elevated('));
    });

    test(
      'passes when FilterChip appears inside a // comment or /// dartdoc',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_filterchip_comment_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer CtChoiceChip over FilterChip( for chip chrome.
// FilterChip( must not appear in real code, but a // comment is fine.
class C {}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialFilterChip(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test('does not flag identifiers that contain "FilterChip" without '
        'an opening paren (false-positive guard)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_filterchip_identifier_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/identifier.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

class FakeFilterChipProbe {
  static const String label = 'FilterChipProbe';
}
''');

      final code = runCheckAppNoMaterialFilterChip(
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
          'check_app_no_material_filterchip_chrome_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/chrome/ct_thing.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget fallback() => FilterChip(
  label: const Text('x'),
  selected: false,
  onSelected: (_) {},
);
''');

        final code = runCheckAppNoMaterialFilterChip(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('allowlists dev-tooling screens (SYS10001, SYS20001)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_filterchip_devtools_',
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

Widget bypass() => FilterChip(
  label: const Text('x'),
  selected: false,
  onSelected: (_) {},
);
''');
      }

      final code = runCheckAppNoMaterialFilterChip(
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
          'check_app_no_material_filterchip_test_skip_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/some_widget_test.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget probe() => FilterChip(
  label: const Text('x'),
  selected: false,
  onSelected: (_) {},
);
''');

        final code = runCheckAppNoMaterialFilterChip(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_filterchip_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialFilterChip(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });

    test('reports file path and line number on violation', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_filterchip_line_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/x/y.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'import \'package:flutter/material.dart\';\n'
          '// line 2\n'
          '// line 3\n'
          'Widget z() => FilterChip(label: const Text(\'x\'), selected: false, onSelected: (_) {});\n',
        );

      final logs = <String>[];
      final code = runCheckAppNoMaterialFilterChip(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('app/lib/features/x/y.dart:4: FilterChip('),
      );
    });
  });

  group('shouldSkipAppNoMaterialFilterChipFile (scope predicate)', () {
    test('skips generated suffixes', () {
      expect(
        shouldSkipAppNoMaterialFilterChipFile('app/lib/features/x/y.g.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialFilterChipFile(
          'app/lib/features/x/y.freezed.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialFilterChipFile(
          'app/lib/features/x/y.mocks.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialFilterChipFile('app/lib/features/x/y.gen.dart'),
        isTrue,
      );
    });

    test('skips test files inside features/', () {
      expect(
        shouldSkipAppNoMaterialFilterChipFile('app/lib/features/x/y_test.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialFilterChipFile('app/lib/features/x/test/y.dart'),
        isTrue,
      );
    });

    test('skips Ct-* chrome catalog widgets', () {
      expect(
        shouldSkipAppNoMaterialFilterChipFile(
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
          shouldSkipAppNoMaterialFilterChipFile(path),
          isTrue,
          reason: 'expected $path to be allowlisted',
        );
      }
    });

    test('does not skip ordinary feature widgets (in scope for the check)', () {
      expect(
        shouldSkipAppNoMaterialFilterChipFile(
          'app/lib/features/game/widgets/move_fleet_dialog.dart',
        ),
        isFalse,
      );
      expect(
        shouldSkipAppNoMaterialFilterChipFile(
          'app/lib/features/game/widgets/turn_news_dialog.dart',
        ),
        isFalse,
      );
      expect(
        shouldSkipAppNoMaterialFilterChipFile(
          'app/lib/features/game/flame/game_screen.dart',
        ),
        isFalse,
      );
    });
  });

  group('bannedFilterChipConstructionPattern (regex shape)', () {
    test('matches FilterChip + elevated constructor with opening paren', () {
      const samples = <String>[
        'FilterChip(',
        'FilterChip (',
        'FilterChip.elevated(',
      ];
      for (final s in samples) {
        expect(
          bannedFilterChipConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does not match identifiers without an opening paren', () {
      const safe = <String>[
        'FilterChipProbe',
        'FakeFilterChip',
        'FilterChipTheme',
        'CtChoiceChip',
        'MyFilterChip',
        'FilterChip.styleFrom',
      ];
      for (final s in safe) {
        expect(
          bannedFilterChipConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
