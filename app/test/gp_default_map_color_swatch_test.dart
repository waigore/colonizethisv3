import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

void main() {
  suppressLogsForTests();

  group('GpDefaultMapColorSwatch', () {
    testWidgets('uses greatPowerDefaultColorRgb for known id', (
      WidgetTester tester,
    ) async {
      final rgb = greatPowerDefaultColorRgb['portugal']!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GpDefaultMapColorSwatch(greatPowerId: 'portugal'),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GpDefaultMapColorSwatch),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration;
      expect(decoration, isA<BoxDecoration>());
      expect(
        (decoration as BoxDecoration).color,
        Color.fromRGBO(rgb.$1, rgb.$2, rgb.$3, 1),
      );
    });

    testWidgets(
      'falls back to EditorialMonoclePalette.muted for unknown id (Refs #2914 S4)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GpDefaultMapColorSwatch(greatPowerId: 'not_a_gp'),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GpDefaultMapColorSwatch),
            matching: find.byType(Container),
          ),
        );
        final decoration = container.decoration;
        expect(decoration, isA<BoxDecoration>());
        expect(
          (decoration as BoxDecoration).color,
          EditorialMonoclePalette.muted,
        );
      },
    );
  });
}
