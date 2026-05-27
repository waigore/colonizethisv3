import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('CtGradients tokens resolve from EditorialMonoclePalette', () {
    test('buttonGradient flows surfaceLite → surface top-to-bottom', () {
      final LinearGradient g = CtGradients.buttonGradient;
      expect(g.begin, Alignment.topCenter);
      expect(g.end, Alignment.bottomCenter);
      expect(g.colors, hasLength(2));
      expect(g.colors.first, EditorialMonoclePalette.surfaceLite);
      expect(g.colors.last, EditorialMonoclePalette.surface);
    });

    test('panelGradient flows surface → bg top-to-bottom', () {
      final LinearGradient g = CtGradients.panelGradient;
      expect(g.begin, Alignment.topCenter);
      expect(g.end, Alignment.bottomCenter);
      expect(g.colors.first, EditorialMonoclePalette.surface);
      expect(g.colors.last, EditorialMonoclePalette.bg);
    });

    test('rowGradient flows bg → surface left-to-right', () {
      final LinearGradient g = CtGradients.rowGradient;
      expect(g.begin, Alignment.centerLeft);
      expect(g.end, Alignment.centerRight);
      expect(g.colors.first, EditorialMonoclePalette.bg);
      expect(g.colors.last, EditorialMonoclePalette.surface);
    });

    test('topBarGradient flows surfaceLite → surface top-to-bottom', () {
      final LinearGradient g = CtGradients.topBarGradient;
      expect(g.begin, Alignment.topCenter);
      expect(g.end, Alignment.bottomCenter);
      expect(g.colors.first, EditorialMonoclePalette.surfaceLite);
      expect(g.colors.last, EditorialMonoclePalette.surface);
    });

    test('victoryPanelGradient flows surfaceLite → bgDeep top-to-bottom', () {
      final LinearGradient g = CtGradients.victoryPanelGradient;
      expect(g.begin, Alignment.topCenter);
      expect(g.end, Alignment.bottomCenter);
      expect(g.colors, hasLength(2));
      expect(g.colors.first, EditorialMonoclePalette.surfaceLite);
      expect(g.colors.last, EditorialMonoclePalette.bgDeep);
    });

    test('no gradient color is a hard-coded literal off the palette', () {
      final Set<Color> palette = <Color>{
        EditorialMonoclePalette.bg,
        EditorialMonoclePalette.bgDeep,
        EditorialMonoclePalette.surface,
        EditorialMonoclePalette.surfaceLite,
      };
      final List<LinearGradient> all = <LinearGradient>[
        CtGradients.buttonGradient,
        CtGradients.panelGradient,
        CtGradients.rowGradient,
        CtGradients.topBarGradient,
        CtGradients.victoryPanelGradient,
      ];
      for (final LinearGradient g in all) {
        for (final Color c in g.colors) {
          expect(
            palette.contains(c),
            isTrue,
            reason:
                'gradient must source colors from EditorialMonoclePalette '
                'background-family tokens',
          );
        }
      }
    });
  });
}
