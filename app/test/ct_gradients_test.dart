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

    test(
      'woodPanelButtonGradient flows surfaceLite → surface → bgDeep top-to-bottom '
      'with mockup-matching 0%/40%/100% stops',
      () {
        // SPEC/ui/main-menu.md § Buttons region; mockup
        // `SPEC/ui/mockups/SHEL10002-main-menu.html` `.menu-btn` default
        // background.
        final LinearGradient g = CtGradients.woodPanelButtonGradient;
        expect(g.begin, Alignment.topCenter);
        expect(g.end, Alignment.bottomCenter);
        expect(g.colors, <Color>[
          EditorialMonoclePalette.surfaceLite,
          EditorialMonoclePalette.surface,
          EditorialMonoclePalette.bgDeep,
        ]);
        expect(g.stops, const <double>[0.0, 0.4, 1.0]);
      },
    );

    test(
      'woodPanelButtonGradientPressed inverts the wood-panel rest gradient '
      'top-to-bottom (bgDeep → surface → surfaceLite) per .menu-btn:active',
      () {
        // SPEC/ui/main-menu.md AC `Wood-panel button pressed gradient
        // inversion`; mockup `.menu-btn:active`.
        final LinearGradient rest = CtGradients.woodPanelButtonGradient;
        final LinearGradient pressed =
            CtGradients.woodPanelButtonGradientPressed;
        expect(pressed.begin, Alignment.topCenter);
        expect(pressed.end, Alignment.bottomCenter);
        expect(pressed.colors, rest.colors.reversed.toList());
        expect(pressed.stops, rest.stops);
        expect(pressed.colors, <Color>[
          EditorialMonoclePalette.bgDeep,
          EditorialMonoclePalette.surface,
          EditorialMonoclePalette.surfaceLite,
        ]);
      },
    );

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
        CtGradients.woodPanelButtonGradient,
        CtGradients.woodPanelButtonGradientPressed,
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
