import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_chip.dart';

void main() {
  group('runCheckAppNoMaterialChip', () {
    test(
      'passes when every features file uses palette-token primitives '
      '(no raw Material Chip)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_chip_pass_',
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
      label: const Text('cat'),
      selected: false,
      onSelected: (_) {},
    );
  }
}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialChip(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test('fails when a feature file constructs Chip(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_chip_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_chip.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget chip() => Chip(
  label: const Text('cat'),
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialChip(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('bad_chip.dart:3: Chip('));
      expect(logs.join('\n'), contains('CtChoiceChip'));
    });

    test(
      'passes when Chip appears inside a // comment or /// dartdoc',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_chip_comment_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer CtChoiceChip over Chip( for chip chrome.
// Chip( must not appear in real code, but a // comment is fine.
class C {}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialChip(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test(
      'does not flag sibling chip-family Material constructors (handled '
      'by sibling rules: FilterChip / ChoiceChip / ActionChip / InputChip)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_chip_siblings_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/siblings.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget a() => FilterChip(label: const Text('a'), selected: false, onSelected: (_) {});
Widget b() => ChoiceChip(label: const Text('b'), selected: false);
Widget c() => ActionChip(label: const Text('c'), onPressed: () {});
Widget d() => InputChip(label: const Text('d'));
Widget e() => RawChip(label: const Text('e'));
''');

        final code = runCheckAppNoMaterialChip(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test(
      'does not flag Ct-* catalog widgets that contain "Chip" as a suffix',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_chip_ct_choice_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/ct_choice_user.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';

Widget chip() => CtChoiceChip(
  label: const Text('x'),
  selected: false,
  onSelected: (_) {},
);
''');

        final code = runCheckAppNoMaterialChip(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('does not flag user-defined identifiers ending in "Chip"', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_chip_user_identifier_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/legend.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

class _LegendChip extends StatelessWidget {
  const _LegendChip({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegendChip();
  }
}
''');

      final code = runCheckAppNoMaterialChip(
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
          'check_app_no_material_chip_chrome_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/chrome/ct_thing.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget fallback() => Chip(label: const Text('x'));
''');

        final code = runCheckAppNoMaterialChip(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('allowlists the Debug Console Overlay dev-tooling screen (SYS20001)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_chip_devtools_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      const debugConsole =
          'app/lib/features/game/flame/debug_console_overlay_panel.dart';

      for (final rel in [debugConsole]) {
        File('${temp.path}/$rel')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget bypass() => Chip(label: const Text('x'));
''');
      }

      final code = runCheckAppNoMaterialChip(
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
          'check_app_no_material_chip_test_skip_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/some_widget_test.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget probe() => Chip(label: const Text('x'));
''');

        final code = runCheckAppNoMaterialChip(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_chip_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialChip(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });

    test('reports file path and line number on violation', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_chip_line_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/x/y.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'import \'package:flutter/material.dart\';\n'
          '// line 2\n'
          '// line 3\n'
          'Widget z() => Chip(label: const Text(\'x\'));\n',
        );

      final logs = <String>[];
      final code = runCheckAppNoMaterialChip(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('app/lib/features/x/y.dart:4: Chip('),
      );
    });
  });

  group('shouldSkipAppNoMaterialChipFile (scope predicate)', () {
    test('skips generated suffixes', () {
      expect(
        shouldSkipAppNoMaterialChipFile('app/lib/features/x/y.g.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialChipFile('app/lib/features/x/y.freezed.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialChipFile('app/lib/features/x/y.mocks.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialChipFile('app/lib/features/x/y.gen.dart'),
        isTrue,
      );
    });

    test('skips test files inside features/', () {
      expect(
        shouldSkipAppNoMaterialChipFile('app/lib/features/x/y_test.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialChipFile('app/lib/features/x/test/y.dart'),
        isTrue,
      );
    });

    test('skips Ct-* chrome catalog widgets', () {
      expect(
        shouldSkipAppNoMaterialChipFile(
          'app/lib/features/game/widgets/chrome/ct_thing.dart',
        ),
        isTrue,
      );
    });

    test('skips the Debug Console Overlay dev-tooling screen (SYS20001)', () {
      const skipped = <String>[
        'app/lib/features/game/flame/debug_console_overlay_panel.dart',
      ];
      for (final path in skipped) {
        expect(
          shouldSkipAppNoMaterialChipFile(path),
          isTrue,
          reason: 'expected $path to be allowlisted',
        );
      }
    });

    test('does not skip ordinary feature widgets (in scope for the check)', () {
      expect(
        shouldSkipAppNoMaterialChipFile(
          'app/lib/features/game/widgets/tech_tree_widget_legend.dart',
        ),
        isFalse,
      );
      expect(
        shouldSkipAppNoMaterialChipFile(
          'app/lib/features/game/widgets/move_fleet_dialog.dart',
        ),
        isFalse,
      );
      expect(
        shouldSkipAppNoMaterialChipFile(
          'app/lib/features/game/flame/game_screen.dart',
        ),
        isFalse,
      );
    });
  });

  group('bannedChipConstructionPattern (regex shape)', () {
    test('matches the unprefixed Material Chip constructor', () {
      const samples = <String>[
        'Chip(',
        'Chip (',
        'Chip\t(',
      ];
      for (final s in samples) {
        expect(
          bannedChipConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test(
      'does NOT match sibling chip-family Material constructors '
      '(those have dedicated rules)',
      () {
        const safe = <String>[
          'FilterChip(',
          'FilterChip.elevated(',
          'ChoiceChip(',
          'ActionChip(',
          'InputChip(',
          'RawChip(',
          'MaterialChip(',
        ];
        for (final s in safe) {
          expect(
            bannedChipConstructionPattern.hasMatch(s),
            isFalse,
            reason: 'expected pattern NOT to match $s',
          );
        }
      },
    );

    test(
      'does NOT match Ct-* catalog widgets containing "Chip" as suffix',
      () {
        const safe = <String>[
          'CtChoiceChip(',
          'CtChip(',
          '_LegendChip(',
          'MyChip(',
          'AwesomeChipProbe(',
        ];
        for (final s in safe) {
          expect(
            bannedChipConstructionPattern.hasMatch(s),
            isFalse,
            reason: 'expected pattern NOT to match $s',
          );
        }
      },
    );

    test('does not match identifiers without an opening paren', () {
      const safe = <String>[
        'Chip',
        'Chip.styleFrom',
        'ChipTheme',
        'ChipThemeData',
      ];
      for (final s in safe) {
        expect(
          bannedChipConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
