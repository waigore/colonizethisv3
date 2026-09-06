// Wood-panel gradient ACs from SPEC/ui/main-menu.md pixelArt chrome.
// Split from screen_spec_acceptance_pixel_art_chrome_test.dart (Refs #4734 Slice H).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';

import 'screen_spec_acceptance_test_support.dart';

void main() {
  suppressLogsForTests();

  group(
    'CtMainMenu — SPEC/ui/main-menu.md wood-panel gradients (pixelArt)',
    () {
      testWidgets(
        'AC 8 (pixelArt) wood-panel button rest gradient: New Game button '
        'paints the three-stop CtGradients.woodPanelButtonGradient '
        '(--surface-lite → --surface → --bg-deep) in the rest state',
        (WidgetTester tester) async {
          await pumpScreenSpecMainMenu(
            tester,
            variant: MainMenuVariant.pixelArt,
          );

          final DecoratedBox surface = findGradientSurfaceFor(
            tester,
            'New Game',
          );
          final BoxDecoration decoration = surface.decoration as BoxDecoration;
          final LinearGradient gradient =
              decoration.gradient! as LinearGradient;
          expect(
            gradient.colors,
            CtGradients.woodPanelButtonGradient.colors,
            reason:
                'pixelArt wood-panel buttons must paint the three-stop '
                'CtGradients.woodPanelButtonGradient at rest.',
          );
          expect(gradient.stops, CtGradients.woodPanelButtonGradient.stops);
        },
      );

      testWidgets(
        'AC 8 (pixelArt) wood-panel button pressed gradient inversion: while '
        'a wood-panel button is held, the surface gradient swaps to '
        'CtGradients.woodPanelButtonGradientPressed; after release the '
        'gradient reverts to the rest CtGradients.woodPanelButtonGradient',
        (WidgetTester tester) async {
          await pumpScreenSpecMainMenu(
            tester,
            variant: MainMenuVariant.pixelArt,
          );
          await expectScreenSpecWoodPanelGradientPressCycle(
            tester,
            'New Game',
          );
        },
      );

      testWidgets(
        'AC 8 negative (plain): pressing a Quit CtNinePatchButton in the plain '
        'variant does not swap its surface gradient (no pressedGradient '
        'configured for the legacy 2-stop CtNinePatchButton)',
        (WidgetTester tester) async {
          await pumpScreenSpecPlainMainMenu(tester);

          final DecoratedBox restSurface = findGradientSurfaceFor(
            tester,
            'Quit',
          );
          final BoxDecoration restDecoration =
              restSurface.decoration as BoxDecoration;
          final LinearGradient restGradient =
              restDecoration.gradient! as LinearGradient;
          expect(
            restGradient.colors,
            CtGradients.buttonGradient.colors,
          );

          final Offset center = tester.getCenter(
            woodPanelButtonFinderFor('Quit'),
          );
          final TestGesture gesture = await tester.startGesture(center);
          await tester.pump();
          await tester.pumpAndSettle();

          final DecoratedBox pressed = findGradientSurfaceFor(tester, 'Quit');
          final BoxDecoration pressedDecoration =
              pressed.decoration as BoxDecoration;
          final LinearGradient pressedGradient =
              pressedDecoration.gradient! as LinearGradient;
          expect(pressedGradient.colors, CtGradients.buttonGradient.colors);

          await gesture.up();
          await tester.pumpAndSettle();
        },
      );
    },
  );
}
