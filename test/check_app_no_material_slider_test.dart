import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_slider.dart';

void main() {
  group('runCheckAppNoMaterialSlider', () {
    test('passes when feature files use CtSlider', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_slider_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/clean.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';

Widget s() => CtSlider(value: 0.5, min: 0, max: 1, onChanged: (_) {});
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialSlider(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('fails when a feature file constructs Slider(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_slider_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_slider.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget s() => Slider(
  value: 0.5,
  onChanged: (_) {},
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialSlider(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('bad_slider.dart:3: Slider('));
      expect(logs.join('\n'), contains('CtSlider'));
    });

    test('fails on the Slider.adaptive named constructor', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_slider_named_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/named.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget a() => Slider.adaptive(value: 0.5, onChanged: (_) {});
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialSlider(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('Slider.adaptive('));
    });

    test('does not flag CtSlider / RangeSlider / suffixed identifiers', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_slider_suffix_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/suffix.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';

Widget a() => CtSlider(value: 0.5, min: 0, max: 1, onChanged: (_) {});
Widget b() => RangeSlider(values: const RangeValues(0, 1), onChanged: (_) {});
Widget c() => MyZoomSlider(value: 1);
''');

      final code = runCheckAppNoMaterialSlider(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('allowlists Ct-* chrome widgets and dev-tooling screens', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_slider_allow_',
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

Widget bypass() => Slider(value: 0.5, onChanged: (_) {});
''');
      }

      final code = runCheckAppNoMaterialSlider(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_slider_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialSlider(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });
  });

  group('bannedSliderConstructionPattern (regex shape)', () {
    test('matches Slider( and Slider.adaptive(', () {
      const samples = <String>['Slider(', 'Slider (', 'Slider.adaptive('];
      for (final s in samples) {
        expect(
          bannedSliderConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does NOT match CtSlider / RangeSlider / suffixed / theme', () {
      const safe = <String>[
        'CtSlider(',
        'RangeSlider(',
        'MyZoomSlider(',
        'SliderTheme(',
        'Slider',
      ];
      for (final s in safe) {
        expect(
          bannedSliderConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
