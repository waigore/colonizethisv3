import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_card.dart';

void main() {
  group('runCheckAppNoMaterialCard', () {
    test('passes when every features file uses CtPanel (no Material Card)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_card_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/clean.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';

class Clean extends StatelessWidget {
  const Clean({super.key});

  @override
  Widget build(BuildContext context) {
    return const CtPanel(child: Text('section'));
  }
}
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialCard(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('fails when a feature file constructs Card(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_card_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_card.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget panel() => Card(
  child: const Text('section'),
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialCard(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('bad_card.dart:3: Card('));
      expect(logs.join('\n'), contains('CtPanel'));
    });

    test('fails on the Card.filled and Card.outlined named constructors', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_card_named_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/named.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget a() => Card.filled(child: const Text('a'));
Widget b() => Card.outlined(child: const Text('b'));
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialCard(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('Card.filled('));
      expect(logs.join('\n'), contains('Card.outlined('));
    });

    test('passes when Card appears inside a // comment or /// dartdoc', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_card_comment_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer CtPanel over Card( for in-screen sections.
// Card( must not appear in real code, but a // comment is fine.
class C {}
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialCard(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('does not flag user identifiers or theme types containing Card', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_card_suffix_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/suffix.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget a() => ResourceCard(label: const Text('a'));
ThemeData t() => ThemeData(cardTheme: const CardTheme());
''');

      final code = runCheckAppNoMaterialCard(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('allowlists Ct-* catalog widgets under features/game/widgets/chrome/', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_card_chrome_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/chrome/ct_thing.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget fallback() => Card(child: const Text('x'));
''');

      final code = runCheckAppNoMaterialCard(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('allowlists the dev-tooling screens (SYS10001 + SYS20001)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_card_devtools_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      const devScreens = <String>[
        'app/lib/features/debug_log/debug_log_viewer_screen.dart',
        'app/lib/features/game/flame/debug_console_overlay_panel.dart',
      ];
      for (final rel in devScreens) {
        File('${temp.path}/$rel')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget bypass() => Card(child: const Text('x'));
''');
      }

      final code = runCheckAppNoMaterialCard(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_card_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialCard(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });
  });

  group('shouldSkipAppNoMaterialCardFile (scope predicate)', () {
    test('skips generated suffixes and test files', () {
      expect(
        shouldSkipAppNoMaterialCardFile('app/lib/features/x/y.g.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialCardFile('app/lib/features/x/y_test.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialCardFile('app/lib/features/x/test/y.dart'),
        isTrue,
      );
    });

    test('skips Ct-* chrome catalog widgets and dev-tooling screens', () {
      expect(
        shouldSkipAppNoMaterialCardFile(
          'app/lib/features/game/widgets/chrome/ct_thing.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialCardFile(
          'app/lib/features/debug_log/debug_log_viewer_screen.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialCardFile(
          'app/lib/features/game/flame/debug_console_overlay_panel.dart',
        ),
        isTrue,
      );
    });

    test('does not skip ordinary feature widgets', () {
      expect(
        shouldSkipAppNoMaterialCardFile(
          'app/lib/features/game/widgets/production_panel.dart',
        ),
        isFalse,
      );
    });
  });

  group('bannedCardConstructionPattern (regex shape)', () {
    test('matches Card( and its named constructors', () {
      const samples = <String>[
        'Card(',
        'Card (',
        'Card.filled(',
        'Card.outlined(',
      ];
      for (final s in samples) {
        expect(
          bannedCardConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does NOT match suffixed identifiers or theme types', () {
      const safe = <String>[
        'ResourceCard(',
        'MyCard(',
        'CardTheme(',
        'CardThemeData(',
        'Card',
      ];
      for (final s in safe) {
        expect(
          bannedCardConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
