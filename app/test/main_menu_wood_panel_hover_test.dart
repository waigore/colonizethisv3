// Widget tests pinning the wood-panel button hover state in the
// `CtMainMenu` `pixelArt` variant (Refs #2860 AC 7). Verifies the
// SPEC/ui/main-menu.md § Variant rendering hover ACs:
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'main_menu_wood_panel_hover_test_support.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'CtMainMenu pixelArt wood-panel button hover state '
    '(SPEC/ui/main-menu.md § Variant rendering hover ACs; Refs #2860 AC 7)',
    () {
      testWidgets(
        'hovering the New Game wood-panel button shifts the surface border to '
        '--accent and brightens the brass corner brackets to --accent-bright '
        'at hover alpha (border accent strengthens + corners brighten)',
        (WidgetTester tester) async {
          await pumpPixelArtMainMenu(tester);

          final DecoratedBox restSurface = findWoodPanelSurfaceBox(
            tester,
            'New Game',
          );
          final Border restBorder =
              (restSurface.decoration as BoxDecoration).border! as Border;
          expect(restBorder.top.color, EditorialMonoclePalette.border);

          final Color? restBrass = brassColorFromPainter(
            findWoodPanelBrassPainter(tester, 'New Game'),
          );
          expect(restBrass, isNotNull);
          expect(
            restBrass!.r,
            closeTo(EditorialMonoclePalette.accent.r, 0.001),
            reason: 'Rest brass-bracket red channel must match --accent',
          );
          expect(
            restBrass.a,
            closeTo(CtNinePatchButton.defaultCornerAlpha, 0.001),
            reason:
                'Rest brass-bracket alpha must equal '
                'CtNinePatchButton.defaultCornerAlpha (0.75)',
          );

          final TestGesture gesture = await addMainMenuMousePointer(tester);
          final Offset center = tester.getCenter(
            woodPanelButtonFor('New Game'),
          );
          await gesture.moveTo(center);
          await settleHoverColorAnimation(tester);

          final DecoratedBox hoverSurface = findWoodPanelSurfaceBox(
            tester,
            'New Game',
          );
          final Border hoverBorder =
              (hoverSurface.decoration as BoxDecoration).border! as Border;
          expect(
            hoverBorder.top.color,
            EditorialMonoclePalette.accent,
            reason:
                'Hover state must shift the surface border from --border to '
                '--accent (mockup .menu-btn:hover { border-color: var(--accent) })',
          );

          final Color? hoverBrass = brassColorFromPainter(
            findWoodPanelBrassPainter(tester, 'New Game'),
          );
          expect(hoverBrass, isNotNull);
          expect(
            hoverBrass!.r,
            closeTo(EditorialMonoclePalette.accentBright.r, 0.001),
            reason:
                'Hover brass-bracket red channel must match --accent-bright',
          );
          expect(
            hoverBrass.a,
            closeTo(CtNinePatchButton.hoverCornerAlpha, 0.001),
            reason:
                'Hover brass-bracket alpha must equal '
                'CtNinePatchButton.hoverCornerAlpha (1.0)',
          );
        },
      );

      testWidgets(
        'hovering the New Game wood-panel button brightens the engraved '
        'label color to --accent-bright while preserving the 1 px downward '
        '--surface engrave shadow',
        (WidgetTester tester) async {
          await pumpPixelArtMainMenu(tester);

          final RichText restLabel = findWoodPanelLabelRichText(
            tester,
            'New Game',
          );
          final TextSpan restSpan = restLabel.text as TextSpan;
          expect(restSpan.style?.color, EditorialMonoclePalette.accent);
          final List<Shadow>? restShadows = restSpan.style?.shadows;
          expect(restShadows, isNotNull);
          expect(restShadows!.length, 1);
          expect(
            restShadows.first.offset,
            CtNinePatchButton.engravedShadowOffset,
          );
          expect(restShadows.first.blurRadius, 0);
          expect(restShadows.first.color, EditorialMonoclePalette.surface);

          final TestGesture gesture = await addMainMenuMousePointer(tester);
          final Offset center = tester.getCenter(
            woodPanelButtonFor('New Game'),
          );
          await gesture.moveTo(center);
          await settleHoverColorAnimation(tester);

          final RichText hoverLabel = findWoodPanelLabelRichText(
            tester,
            'New Game',
          );
          final TextSpan hoverSpan = hoverLabel.text as TextSpan;
          expect(
            hoverSpan.style?.color,
            EditorialMonoclePalette.accentBright,
            reason:
                'Hover state must shift the engraved label color from '
                '--accent to --accent-bright (mockup .menu-btn:hover { '
                'color: var(--accent-bright) })',
          );

          final List<Shadow>? hoverShadows = hoverSpan.style?.shadows;
          expect(
            hoverShadows,
            isNotNull,
            reason:
                'Engraved label shadow must persist across hover (mockup '
                'retains the recessed 1 px downward shadow)',
          );
          expect(hoverShadows!.length, 1);
          expect(
            hoverShadows.first.offset,
            CtNinePatchButton.engravedShadowOffset,
          );
          expect(hoverShadows.first.blurRadius, 0);
          expect(
            hoverShadows.first.color,
            EditorialMonoclePalette.surface,
            reason:
                'Engrave shadow must remain --surface even when the label '
                'foreground brightens',
          );
        },
      );

      testWidgets(
        'hover state is strictly transient: moving the pointer off the '
        'wood-panel button reverts border to --border, brass corners to '
        '--accent × 0.75 alpha, and label color back to --accent',
        (WidgetTester tester) async {
          await pumpPixelArtMainMenu(tester);

          final TestGesture gesture = await addMainMenuMousePointer(tester);
          final Offset center = tester.getCenter(
            woodPanelButtonFor('New Game'),
          );
          await gesture.moveTo(center);
          await settleHoverColorAnimation(tester);

          final Border hoverBorder =
              (findWoodPanelSurfaceBox(tester, 'New Game').decoration
                          as BoxDecoration)
                      .border!
                  as Border;
          expect(hoverBorder.top.color, EditorialMonoclePalette.accent);

          await gesture.moveTo(const Offset(-1000, -1000));
          await settleHoverExitAnimation(tester);

          final DecoratedBox restSurface = findWoodPanelSurfaceBox(
            tester,
            'New Game',
          );
          final Border restBorder =
              (restSurface.decoration as BoxDecoration).border! as Border;
          expect(
            restBorder.top.color,
            EditorialMonoclePalette.border,
            reason:
                'After the pointer leaves, the border must revert to '
                '--border (hover is strictly transient).',
          );

          final Color? restBrass = brassColorFromPainter(
            findWoodPanelBrassPainter(tester, 'New Game'),
          );
          expect(restBrass, isNotNull);
          expect(
            restBrass!.r,
            closeTo(EditorialMonoclePalette.accent.r, 0.001),
            reason:
                'After hover ends, brass-bracket red channel must revert '
                'to --accent',
          );
          expect(
            restBrass.a,
            closeTo(CtNinePatchButton.defaultCornerAlpha, 0.001),
            reason:
                'After hover ends, brass-bracket alpha must revert to '
                'CtNinePatchButton.defaultCornerAlpha (0.75)',
          );

          final RichText restLabel = findWoodPanelLabelRichText(
            tester,
            'New Game',
          );
          final TextSpan restSpan = restLabel.text as TextSpan;
          expect(
            restSpan.style?.color,
            EditorialMonoclePalette.accent,
            reason:
                'After hover ends, the engraved label color must revert '
                'to --accent',
          );
        },
      );
    },
  );
}
