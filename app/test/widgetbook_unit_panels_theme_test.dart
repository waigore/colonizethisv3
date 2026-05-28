import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

int _argb(Color c) {
  final int a = (c.a * 255.0).round() & 0xFF;
  final int r = (c.r * 255.0).round() & 0xFF;
  final int g = (c.g * 255.0).round() & 0xFF;
  final int b = (c.b * 255.0).round() & 0xFF;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

void main() {
  suppressLogsForTests();

  group('widgetbookEditorialMonocleApp (#2866 S6)', () {
    testWidgets('nested MaterialApp uses editorialMonocle dark theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        widgetbookEditorialMonocleApp(
          child: const Center(child: Text('probe')),
        ),
      );

      final BuildContext ctx = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(ctx);
      expect(theme.brightness, Brightness.dark);
      expect(
        _argb(theme.scaffoldBackgroundColor),
        _argb(EditorialMonoclePalette.bg),
      );
      expect(
        _argb(theme.colorScheme.primary),
        _argb(EditorialMonoclePalette.accent),
      );
    });
  });
}
