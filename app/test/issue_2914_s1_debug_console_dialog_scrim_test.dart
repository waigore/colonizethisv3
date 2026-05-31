/// Pins #2914 S1 — `app/lib/features/` must not paint the legacy
/// `Colors.black54` scrim. The canonical dark-theme scrim is
/// `EditorialMonoclePalette.dialogScrim`, per `SPEC/ui/pixel-art-ui-catalog.md`
/// § Dialog scrim ("Widgets MUST resolve the scrim through that token ...
/// rather than hard-coding `Colors.black54` / hex literals.").
///
/// Two complementary pins:
///
/// 1. Positive: `debug_console_overlay_panel.dart` references
///    `EditorialMonoclePalette.dialogScrim` and never references the legacy
///    `Colors.black54` literal.
/// 2. Negative / regression sweep: no Dart source under `app/lib/features/`
///    contains `Colors.black54` outside of line comments (which may still
///    document the ban itself).
///
/// Refs #2914 S1.
library;

import 'dart:convert' show LineSplitter;
import 'dart:io' show Directory, File, FileSystemEntity;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Refs #2914 S1: debug console scrim uses EditorialMonoclePalette', () {
    test(
        'debug_console_overlay_panel.dart references '
        'EditorialMonoclePalette.dialogScrim and not Colors.black54', () {
      const String relativePath =
          'lib/features/game/flame/debug_console_overlay_panel.dart';
      final File file = File(relativePath);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'fixture file must exist at $relativePath',
      );
      final String source = file.readAsStringSync();

      expect(
        source.contains('EditorialMonoclePalette.dialogScrim'),
        isTrue,
        reason:
            'Refs #2914 S1: the debug-console overlay panel scrim and input '
            'fill must resolve through EditorialMonoclePalette.dialogScrim, '
            'the canonical dark-theme scrim token defined in '
            'SPEC/ui/pixel-art-ui-catalog.md § Dialog scrim.',
      );

      // Strip line comments and string-literal occurrences so the pin only
      // fires on actual code references to the banned Material literal.
      final Iterable<String> nonCommentLines = source
          .split('\n')
          .map((String line) => line.trimLeft())
          .where((String line) => !line.startsWith('//'));
      expect(
        nonCommentLines.any((String line) => line.contains('Colors.black54')),
        isFalse,
        reason:
            'Refs #2914 S1 / SPEC/ui/pixel-art-ui-catalog.md § Dialog scrim: '
            'the legacy Material Colors.black54 literal must not be reintroduced '
            'in debug_console_overlay_panel.dart; use '
            'EditorialMonoclePalette.dialogScrim instead.',
      );
    });
  });

  group('Refs #2914 S1: no Colors.black54 in app/lib/features/ (regression)',
      () {
    test(
        'no Dart source under app/lib/features/ references Colors.black54 '
        'outside of line comments', () {
      final Directory featuresDir = Directory('lib/features');
      expect(
        featuresDir.existsSync(),
        isTrue,
        reason: 'fixture root must exist at lib/features',
      );

      final List<String> violations = <String>[];
      for (final FileSystemEntity entity
          in featuresDir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart')) continue;

        final List<String> lines = const LineSplitter().convert(
          entity.readAsStringSync(),
        );
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].trimLeft().startsWith('//')) continue;
          if (!lines[i].contains('Colors.black54')) continue;
          violations.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Refs #2914 S1 / SPEC/ui/pixel-art-ui-catalog.md § Dialog scrim: '
            'app/lib/features/ must not paint Material Colors.black54 as the '
            'dialog scrim; resolve from EditorialMonoclePalette.dialogScrim. '
            'Violations:\n  ${violations.join('\n  ')}',
      );
    });
  });
}
