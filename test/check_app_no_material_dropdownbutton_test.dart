import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_dropdownbutton.dart';

void main() {
  group('runCheckAppNoMaterialDropdownButton', () {
    test('passes when feature files use CtDropdown', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_dropdownbutton_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/clean.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';

Widget d() => CtDropdown<String>(value: 'a', items: const [], onChanged: (_) {});
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialDropdownButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('fails when a feature file constructs DropdownButton<T>(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_dropdownbutton_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_dropdown.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget d() => DropdownButton<String>(
  value: 'a',
  items: const [],
  onChanged: (_) {},
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialDropdownButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('bad_dropdown.dart:3: DropdownButton<String>('),
      );
      expect(logs.join('\n'), contains('CtDropdown'));
    });

    test('fails on the non-generic DropdownButton( form', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_dropdownbutton_plain_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/plain.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget d() => DropdownButton(items: const [], onChanged: (_) {});
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialDropdownButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('DropdownButton('));
    });

    test(
      'does not flag DropdownButtonFormField / DropdownButtonHideUnderline',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_dropdownbutton_siblings_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/siblings.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget a() => DropdownButtonFormField<String>(items: const [], onChanged: (_) {});
Widget b() => DropdownButtonHideUnderline(child: const Text('x'));
Widget c() => MyDropdownButton(value: 1);
''');

        final code = runCheckAppNoMaterialDropdownButton(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('allowlists Ct-* chrome widgets and dev-tooling screens', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_dropdownbutton_allow_',
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

Widget bypass() => DropdownButton<String>(items: const [], onChanged: (_) {});
''');
      }

      final code = runCheckAppNoMaterialDropdownButton(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_dropdownbutton_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialDropdownButton(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });
  });

  group('bannedDropdownButtonConstructionPattern (regex shape)', () {
    test('matches DropdownButton( and DropdownButton<T>(', () {
      const samples = <String>[
        'DropdownButton(',
        'DropdownButton (',
        'DropdownButton<String>(',
        'DropdownButton<int>(',
      ];
      for (final s in samples) {
        expect(
          bannedDropdownButtonConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does NOT match sibling Material types or suffixed identifiers', () {
      const safe = <String>[
        'DropdownButtonFormField(',
        'DropdownButtonFormField<String>(',
        'DropdownButtonHideUnderline(',
        'MyDropdownButton(',
        'DropdownButton',
      ];
      for (final s in safe) {
        expect(
          bannedDropdownButtonConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
