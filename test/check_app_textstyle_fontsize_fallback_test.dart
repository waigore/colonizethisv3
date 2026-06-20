import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_textstyle_fontsize_fallback.dart';

void main() {
  group('runCheckAppTextStyleFontSizeFallback', () {
    test(
      'passes when every themed-text fallback matches the canonical slot size',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_textstyle_fontsize_fallback_pass_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/clean.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

TextStyle resolve(TextTheme textTheme) {
  return textTheme.bodySmall ?? const TextStyle(fontSize: 12);
}
''');

        final logs = <String>[];
        final code = runCheckAppTextStyleFontSizeFallback(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test('fails when a fallback fontSize drifts from the canonical slot', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_textstyle_fontsize_fallback_drift_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

TextStyle resolve(TextTheme textTheme) {
  return textTheme.bodySmall ?? const TextStyle(fontSize: 13);
}
''');

      final logs = <String>[];
      final code = runCheckAppTextStyleFontSizeFallback(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('bad.dart:4: textTheme.bodySmall fallback fontSize 13'),
      );
      expect(logs.join('\n'), contains('expected 12'));
    });

    test('detects a drift split across a line break', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_textstyle_fontsize_fallback_multiline_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/wrap.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

TextStyle resolve(TextTheme textTheme) {
  return textTheme.titleMedium ??
      const TextStyle(fontSize: 18);
}
''');

      final logs = <String>[];
      final code = runCheckAppTextStyleFontSizeFallback(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('textTheme.titleMedium fallback fontSize 18'),
      );
      expect(logs.join('\n'), contains('expected 16'));
    });

    test('does not flag slots outside the canonical table', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_textstyle_fontsize_fallback_unknown_slot_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/unknown.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

TextStyle resolve(TextTheme textTheme) {
  return textTheme.displayLarge ?? const TextStyle(fontSize: 99);
}
''');

      final code = runCheckAppTextStyleFontSizeFallback(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('does not flag a drift mentioned only inside a // comment', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_textstyle_fontsize_fallback_comment_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

// Avoid textTheme.bodySmall ?? const TextStyle(fontSize: 13) drift here.
class C {}
''');

      final logs = <String>[];
      final code = runCheckAppTextStyleFontSizeFallback(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('enforces fallbacks under app/lib/widgets/ as well', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_textstyle_fontsize_fallback_widgets_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/.keep.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('// keep\n');
      File('${temp.path}/app/lib/widgets/bad_widget.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

TextStyle resolve(TextTheme textTheme) {
  return textTheme.labelSmall ?? const TextStyle(fontSize: 10);
}
''');

      final logs = <String>[];
      final code = runCheckAppTextStyleFontSizeFallback(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains(
          'app/lib/widgets/bad_widget.dart:4: textTheme.labelSmall fallback '
          'fontSize 10',
        ),
      );
      expect(logs.join('\n'), contains('expected 11'));
    });

    test('does not scan test files inside features/ (production surface)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_textstyle_fontsize_fallback_test_skip_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/some_widget_test.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

const sample = TextStyle(fontSize: 13);
TextStyle resolve(TextTheme t) =>
    t.bodySmall ?? const TextStyle(fontSize: 13);
''');

      final code = runCheckAppTextStyleFontSizeFallback(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_textstyle_fontsize_fallback_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppTextStyleFontSizeFallback(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });
  });

  group('findTextStyleFontSizeFallbackViolations (line attribution)', () {
    test('reports the slot-token line number on violation', () {
      final violations = findTextStyleFontSizeFallbackViolations(
        'app/lib/features/x/y.dart',
        'import \'a\';\n'
            '// line 2\n'
            '// line 3\n'
            'final s = textTheme.titleLarge ?? const TextStyle(fontSize: 21);\n',
      );

      expect(violations, hasLength(1));
      expect(violations.single, startsWith('app/lib/features/x/y.dart:4:'));
      expect(violations.single, contains('expected 22'));
    });

    test('returns empty when the in-table fallback already matches', () {
      final violations = findTextStyleFontSizeFallbackViolations(
        'app/lib/features/x/y.dart',
        'final s = textTheme.titleLarge ?? const TextStyle(fontSize: 22);\n',
      );

      expect(violations, isEmpty);
    });
  });

  group('shouldSkipAppTextStyleFontSizeFallbackFile (scope predicate)', () {
    test('skips generated suffixes', () {
      expect(
        shouldSkipAppTextStyleFontSizeFallbackFile('app/lib/features/x/y.g.dart'),
        isTrue,
      );
      expect(
        shouldSkipAppTextStyleFontSizeFallbackFile(
          'app/lib/features/x/y.freezed.dart',
        ),
        isTrue,
      );
    });

    test('skips test files', () {
      expect(
        shouldSkipAppTextStyleFontSizeFallbackFile(
          'app/lib/features/x/y_test.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppTextStyleFontSizeFallbackFile(
          'app/lib/features/x/test/y.dart',
        ),
        isTrue,
      );
    });

    test('does not skip ordinary feature / widget files', () {
      expect(
        shouldSkipAppTextStyleFontSizeFallbackFile(
          'app/lib/features/game/widgets/move_army_dialog.dart',
        ),
        isFalse,
      );
      expect(
        shouldSkipAppTextStyleFontSizeFallbackFile(
          'app/lib/widgets/ct_section_label.dart',
        ),
        isFalse,
      );
    });
  });

  group('canonicalFontSizeBySlot (table)', () {
    test('matches the #2914 §S7 slot→size mapping', () {
      expect(canonicalFontSizeBySlot['headlineMedium'], 28);
      expect(canonicalFontSizeBySlot['headlineSmall'], 24);
      expect(canonicalFontSizeBySlot['titleLarge'], 22);
      expect(canonicalFontSizeBySlot['titleMedium'], 16);
      expect(canonicalFontSizeBySlot['titleSmall'], 14);
      expect(canonicalFontSizeBySlot['bodyLarge'], 16);
      expect(canonicalFontSizeBySlot['bodyMedium'], 14);
      expect(canonicalFontSizeBySlot['bodySmall'], 12);
      expect(canonicalFontSizeBySlot['labelLarge'], 14);
      expect(canonicalFontSizeBySlot['labelMedium'], 12);
      expect(canonicalFontSizeBySlot['labelSmall'], 11);
    });
  });
}
