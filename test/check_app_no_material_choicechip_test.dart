import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_choicechip.dart';

void main() {
  group('runCheckAppNoMaterialChoiceChip', () {
    test('passes when feature files use CtChoiceChip', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_choicechip_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/clean.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';

Widget chip() => CtChoiceChip(
  label: const Text('cat'),
  selected: false,
  onSelected: (_) {},
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialChoiceChip(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('fails when a feature file constructs ChoiceChip(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_choicechip_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_choicechip.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget chip() => ChoiceChip(
  label: const Text('cat'),
  selected: false,
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialChoiceChip(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('bad_choicechip.dart:3: ChoiceChip('),
      );
      expect(logs.join('\n'), contains('CtChoiceChip'));
    });

    test('fails on the ChoiceChip.elevated named constructor', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_choicechip_named_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/named.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget a() => ChoiceChip.elevated(label: const Text('a'), selected: false);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialChoiceChip(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('ChoiceChip.elevated('));
    });

    test('does not flag CtChoiceChip or user identifiers ending in ChoiceChip', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_choicechip_suffix_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/suffix.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';

Widget a() => CtChoiceChip(label: const Text('a'), selected: false, onSelected: (_) {});
Widget b() => MyChoiceChip(label: const Text('b'));
''');

      final code = runCheckAppNoMaterialChoiceChip(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('allowlists Ct-* chrome widgets and dev-tooling screens', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_choicechip_allow_',
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

Widget bypass() => ChoiceChip(label: const Text('x'), selected: false);
''');
      }

      final code = runCheckAppNoMaterialChoiceChip(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_choicechip_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialChoiceChip(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });
  });

  group('bannedChoiceChipConstructionPattern (regex shape)', () {
    test('matches ChoiceChip( and ChoiceChip.elevated(', () {
      const samples = <String>[
        'ChoiceChip(',
        'ChoiceChip (',
        'ChoiceChip.elevated(',
      ];
      for (final s in samples) {
        expect(
          bannedChoiceChipConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does NOT match CtChoiceChip / suffixed identifiers / theme', () {
      const safe = <String>[
        'CtChoiceChip(',
        'MyChoiceChip(',
        'ChoiceChipTheme(',
        'ChoiceChip',
      ];
      for (final s in safe) {
        expect(
          bannedChoiceChipConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
