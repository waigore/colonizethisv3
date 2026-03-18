import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgetbook.dart' as ct_widgetbook;

void main() {
  suppressLogsForTests();

  group('AppThemes', () {
    test('light theme has Material 3 color scheme', () {
      final theme = AppThemes.light;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme, isNotNull);
      expect(theme.textTheme.bodyMedium, isNotNull);
    });

    test('colonial theme wires expected colors and text theme', () {
      final theme = AppThemes.colonial;
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, isNotNull);
      expect(theme.colorScheme.primary, isNotNull);
      expect(theme.textTheme.bodyLarge, isNotNull);
      expect(theme.textTheme.bodySmall, isNotNull);
    });

    // Note: colonialPixelArt uses GoogleFonts and asset bundle access; that
    // requires a full widget binding. We rely on integration tests and manual
    // verification for it rather than unit tests here.
  });

  // Note: Widgetbook itself is covered via integration runs; in unit tests we
  // avoid pumping CtWidgetbookApp because it relies on Widgetbook internals and
  // external font loading, which are outside the scope of fast unit tests.
}

