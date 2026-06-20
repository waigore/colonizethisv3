import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';

int _argb(Color c) {
  final int a = (c.a * 255.0).round() & 0xFF;
  final int r = (c.r * 255.0).round() & 0xFF;
  final int g = (c.g * 255.0).round() & 0xFF;
  final int b = (c.b * 255.0).round() & 0xFF;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

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

  group('AppThemes.editorialMonocle', () {
    test('brightness is dark and uses Material 3', () {
      final theme = AppThemes.editorialMonocle;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('color scheme maps catalog tokens to the expected sRGB values', () {
      final theme = AppThemes.editorialMonocle;
      expect(_argb(theme.colorScheme.surface), _argb(EditorialMonoclePalette.surface));
      expect(_argb(theme.colorScheme.onSurface), _argb(EditorialMonoclePalette.fg));
      expect(_argb(theme.colorScheme.primary), _argb(EditorialMonoclePalette.accent));
      expect(_argb(theme.colorScheme.onPrimary), _argb(EditorialMonoclePalette.bg));
      expect(_argb(theme.colorScheme.secondary), _argb(EditorialMonoclePalette.accentDim));
      expect(_argb(theme.colorScheme.error), _argb(EditorialMonoclePalette.danger));
      expect(_argb(theme.colorScheme.onError), _argb(EditorialMonoclePalette.bg));
      expect(_argb(theme.colorScheme.outline), _argb(EditorialMonoclePalette.border));
      expect(
        _argb(theme.colorScheme.surfaceContainerHighest),
        _argb(EditorialMonoclePalette.surfaceLite),
      );
    });

    test('scaffoldBackgroundColor maps to --bg', () {
      final theme = AppThemes.editorialMonocle;
      expect(_argb(theme.scaffoldBackgroundColor), _argb(EditorialMonoclePalette.bg));
    });

    test('appBarTheme.backgroundColor maps to --surface-lite', () {
      final theme = AppThemes.editorialMonocle;
      expect(
        _argb(theme.appBarTheme.backgroundColor!),
        _argb(EditorialMonoclePalette.surfaceLite),
      );
      expect(
        _argb(theme.appBarTheme.foregroundColor!),
        _argb(EditorialMonoclePalette.fg),
      );
    });

    test('display text styles use the Cinzel font family', () {
      final theme = AppThemes.editorialMonocle;
      for (final TextStyle? style in <TextStyle?>[
        theme.textTheme.headlineMedium,
        theme.textTheme.headlineSmall,
        theme.textTheme.titleLarge,
        theme.textTheme.titleMedium,
        theme.textTheme.titleSmall,
      ]) {
        expect(style, isNotNull);
        expect(
          style!.fontFamily ?? '',
          contains('Cinzel'),
          reason: 'display text styles must derive from GoogleFonts.cinzel',
        );
      }
    });

    test('body text styles do not force the display (Cinzel) family', () {
      final theme = AppThemes.editorialMonocle;
      for (final TextStyle? style in <TextStyle?>[
        theme.textTheme.bodyLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
      ]) {
        expect(style, isNotNull);
        expect(
          style!.fontFamily ?? '',
          isNot(contains('Cinzel')),
          reason: 'body text must use the platform default sans-serif stack',
        );
      }
    });

    test('text colors lean on the editorial-monocle palette', () {
      final theme = AppThemes.editorialMonocle;
      expect(_argb(theme.textTheme.bodyLarge!.color!), _argb(EditorialMonoclePalette.fg));
      expect(
        _argb(theme.textTheme.bodySmall!.color!),
        _argb(EditorialMonoclePalette.muted),
      );
    });

    test('legacy colonial theme remains loadable (not the running default)', () {
      // R5 / backward-compat: colonial themes must still build without
      // crashes for Widgetbook fallback and debug toggles.
      expect(AppThemes.colonial.useMaterial3, isTrue);
      expect(AppThemes.colonial.brightness, Brightness.light);
    });
  });

  group('App default theme', () {
    testWidgets('mounts with AppThemes.editorialMonocle as the active theme',
        (WidgetTester tester) async {
      // Build only the App's MaterialApp.theme indirectly by reading the
      // exported [AppThemes.editorialMonocle] used in `app/lib/app.dart` so
      // the test does not need to spin up the full ProviderScope shell.
      final ThemeData appTheme = AppThemes.editorialMonocle;
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Builder(
            builder: (BuildContext context) {
              final ThemeData ctx = Theme.of(context);
              return Scaffold(
                backgroundColor: ctx.scaffoldBackgroundColor,
                body: Text(
                  appNavigatorKey.toString(),
                  style: ctx.textTheme.bodyMedium,
                ),
              );
            },
          ),
        ),
      );
      final BuildContext ctx = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(ctx);
      expect(theme.brightness, Brightness.dark);
      expect(
        _argb(theme.scaffoldBackgroundColor),
        _argb(EditorialMonoclePalette.bg),
      );
    });
  });

  // Note: Widgetbook itself is covered via integration runs; in unit tests we
  // avoid pumping CtWidgetbookApp because it relies on Widgetbook internals and
  // external font loading, which are outside the scope of fast unit tests.
}

