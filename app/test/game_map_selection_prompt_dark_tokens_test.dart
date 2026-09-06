// Pins the dark editorial-monocle contract for the work-target selection
// prompt overlay banner rendered by [GameMapCanvasStack] when the map is
// in work target selection mode.
//
// SPEC: `SPEC/ui/map-widget.md` § Dark-theme selection prompt overlay
// tokens + the matching AC under § Acceptance criteria — banner background
// resolves from [EditorialMonoclePalette.bgDeep] at
// `kMapSelectionPromptBackgroundAlpha = 0.85` with a 1 px
// [EditorialMonoclePalette.accentDim] border; the prompt text resolves to
// [EditorialMonoclePalette.fg]; the `cancel` action renders as a
// [CtNinePatchButton] (Ct-* catalog counterpart per the Material
// `TextButton` ban in `SPEC/ui/pixel-art-ui-catalog.md` § Material design
// ban) with the compact `kMapSelectionPromptCancelMinHeight = 34`
// minimum tap-target height; Material `Colors.black` / `Colors.white` /
// Material colour-scheme lookups are forbidden on the banner chrome.
//
// Refs #2861 (in-game shell + empire overview — dark editorial-monocle
// chrome alignment for the map area selection prompt).
// Refs #2914 (S8 Material ban — cancel control replaced with
// `CtNinePatchButton`).

import 'package:colonizethis_app/features/game/flame/map_area/game_map_canvas_stack_selection_prompt_tokens.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'game_map_selection_prompt_dark_tokens_support.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'selection_prompt_dark_tokens');
  });

  testWidgets(
    'selection prompt banner background paints bgDeep + accent-dim border',
    (WidgetTester tester) async {
      await pumpSelectionPromptDarkTokensMode(tester, gamesBox: gamesBox);

      final banner = selectionPromptBannerDecoratedBox(tester);
      final decoration = banner.decoration as BoxDecoration;

      final expectedColor = EditorialMonoclePalette.bgDeep.withValues(
        alpha: kMapSelectionPromptBackgroundAlpha,
      );
      expect(decoration.color, equals(expectedColor));
      expect(
        decoration.color,
        isNot(equals(const Color(0xFF000000).withValues(alpha: 0.72))),
        reason: 'banner background must not paint the legacy black + 0.72',
      );

      final border = decoration.border;
      expect(
        border,
        isA<Border>(),
        reason: 'banner must paint a Border around the bgDeep surface',
      );
      final borderTop = (border as Border).top;
      expect(borderTop.color, equals(EditorialMonoclePalette.accentDim));
      expect(borderTop.width, equals(1.0));
    },
  );

  testWidgets(
    'selection prompt label resolves to EditorialMonoclePalette.fg',
    (WidgetTester tester) async {
      await pumpSelectionPromptDarkTokensMode(tester, gamesBox: gamesBox);

      final promptText = tester.widget<Text>(
        find.text('Select a tile, or click cancel'),
      );
      final style = promptText.style;
      expect(style, isNotNull);
      expect(style!.color, equals(EditorialMonoclePalette.fg));
      expect(
        style.color,
        isNot(equals(const Color(0xFFFFFFFF))),
        reason: 'prompt text must not paint Material Colors.white',
      );
    },
  );

  testWidgets(
    'cancel action renders as CtNinePatchButton with the compact tap '
    'minimum height pinned by SPEC (no Material TextButton)',
    (WidgetTester tester) async {
      await pumpSelectionPromptDarkTokensMode(tester, gamesBox: gamesBox);

      expect(
        find.byType(TextButton),
        findsNothing,
        reason: 'cancel control must not fall back to Material TextButton',
      );

      final Finder cancelFinder = find.ancestor(
        of: find.text('cancel'),
        matching: find.byType(CtNinePatchButton),
      );
      expect(
        cancelFinder,
        findsOneWidget,
        reason:
            'cancel control must render via the CtNinePatchButton catalog '
            'widget so it inherits the canonical brass chrome',
      );

      final CtNinePatchButton cancelButton = tester.widget<CtNinePatchButton>(
        cancelFinder,
      );
      expect(
        cancelButton.minHeight,
        equals(kMapSelectionPromptCancelMinHeight),
        reason:
            'banner cancel must use the compact 34 dp minHeight pinned by '
            'SPEC § Cancel button surface (not the catalog default 48 dp)',
      );
      expect(
        cancelButton.padding,
        equals(const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
      );
    },
  );

  testWidgets(
    'tapping the cancel CtNinePatchButton invokes the cancel callback '
    'and exits selection mode',
    (WidgetTester tester) async {
      await pumpSelectionPromptDarkTokensMode(tester, gamesBox: gamesBox);

      await tester.tap(
        find.ancestor(
          of: find.text('cancel'),
          matching: find.byType(CtNinePatchButton),
        ),
      );
      var promptDismissed = false;
      for (var i = 0; i < 200; i++) {
        await tester.pump(const Duration(milliseconds: 5));
        if (find.text('Select a tile, or click cancel').evaluate().isEmpty) {
          promptDismissed = true;
          break;
        }
      }

      expect(
        promptDismissed,
        isTrue,
        reason:
            'selection prompt overlay must dismiss after the cancel '
            'affordance is activated',
      );
      expect(
        find.text('Select a tile, or click cancel'),
        findsNothing,
        reason:
            'selection prompt overlay must dismiss after the cancel '
            'affordance is activated',
      );
    },
  );

  test(
    'kMapSelectionPromptBackgroundAlpha is pinned at 0.85 per SPEC',
    () {
      expect(kMapSelectionPromptBackgroundAlpha, equals(0.85));
    },
  );

  test(
    'kMapSelectionPromptCancelMinHeight is pinned at 34 per SPEC',
    () {
      expect(kMapSelectionPromptCancelMinHeight, equals(34));
    },
  );
}
