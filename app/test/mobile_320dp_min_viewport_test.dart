// Pin the 320 dp minimum-viewport contract for SPEC/ui/mobile-adaptation.md
// § 7 (Minimum-viewport pin) and `Refs #2870` § Acceptance criteria
//    `SPEC/ui/new-game-leader-selection-dialog.md` § Narrow-viewport slot
//    pickers stacking and `SPEC/ui/mobile-adaptation.md` § 4.
// scope here per the existing `SPEC/ui/mobile-adaptation.md` § 1 carve-out
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// Refs #2870 S10. Shared pumps densify residual mid-500 cases (Refs #4021).
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';
import 'mobile_320dp_min_viewport_test_support.dart';

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — 320 dp minimum viewport (Refs #2870 S10)',
    () {
      for (final c
          in <
            ({
              String name,
              MainMenuVariant variant,
              MainMenuState state,
              bool requireButtons,
            })
          >[
            (
              name:
                  'AC1 (positive) CtMainMenu plain @ 320×640: no exception, '
                  'CtNinePatchButton heights ≥ kMinTouchTargetSize',
              variant: MainMenuVariant.plain,
              state: MainMenuState.default_,
              requireButtons: true,
            ),
            (
              name:
                  'AC1 (positive) CtMainMenu pixelArt @ 320×640: no exception, '
                  'CtNinePatchButton heights ≥ kMinTouchTargetSize',
              variant: MainMenuVariant.pixelArt,
              state: MainMenuState.default_,
              requireButtons: true,
            ),
            (
              name: 'AC1 (positive) CtMainMenu noSaves @ 320×640: no exception',
              variant: MainMenuVariant.plain,
              state: MainMenuState.noSaves,
              requireButtons: false,
            ),
          ]) {
        testWidgets(c.name, (WidgetTester tester) async {
          await pumpMobileNarrow(
            tester,
            wrapMainMenuForMinViewport(variant: c.variant, state: c.state),
            size: kMobileMinViewport,
          );
          expectMobileTouchTargets(tester, requireButtons: c.requireButtons);
        });
      }

      // The 320 dp minimum viewport sits below the 430 dp main-menu
      // narrow breakpoint (`kMainMenuNarrowBreakpoint`), so the menu
      // container must paint the compact `kMainMenuBodyPaddingNarrow`
      // padding rather than the default desktop padding. Existing
      // `screen_spec_acceptance_pixel_art_chrome_test.dart` AC pins this at the 430 dp
      // boundary and at 360 dp; this pin closes the same visual contract
      // at the absolute minimum supported viewport per
      // `SPEC/ui/mobile-adaptation.md` § 4 Main Menu (`≤ 430 dp`) and § 7
      // (`kMinViewportWidth = 320 dp`). Refs #2870 S10 + S6.
      testWidgets(
        'AC1 (positive) CtMainMenu plain @ 320×640: menu body padding is the '
        'compact kMainMenuBodyPaddingNarrow (≤ 430 dp narrow contract)',
        (WidgetTester tester) async {
          await pumpMobileNarrow(
            tester,
            wrapMainMenuForMinViewport(),
            size: kMobileMinViewport,
          );

          expect(tester.takeException(), isNull);
          final Padding bodyPadding = tester.widget<Padding>(
            find.byKey(const Key(kMainMenuBodyPaddingKey)),
          );
          expect(
            bodyPadding.padding,
            kMainMenuBodyPaddingNarrow,
            reason:
                'CtMainMenu at 320 dp (well below the 430 dp narrow '
                'breakpoint) must use the compact narrow padding from '
                'SPEC/ui/mobile-adaptation.md § 4 Main Menu.',
          );
        },
      );

      // The pixelArt variant has an additional narrow rule: the wood-panel
      // menu button labels reduce letter-spacing from
      // `kMainMenuButtonLetterSpacingDefault` to
      // `kMainMenuButtonLetterSpacingNarrow` per
      // `SPEC/ui/mockups/SHEL10002-main-menu.html` `.menu-btn @media
      // (max-width: 430px)`. Pin both the padding and the letter-spacing
      // at the 320 dp minimum viewport.
      testWidgets(
        'AC1 (positive) CtMainMenu pixelArt @ 320×640: compact padding plus '
        'narrow button letter-spacing (≤ 430 dp narrow contract)',
        (WidgetTester tester) async {
          await pumpMobileNarrow(
            tester,
            wrapMainMenuForMinViewport(variant: MainMenuVariant.pixelArt),
            size: kMobileMinViewport,
          );

          expect(tester.takeException(), isNull);
          final Padding bodyPadding = tester.widget<Padding>(
            find.byKey(const Key(kMainMenuBodyPaddingKey)),
          );
          expect(bodyPadding.padding, kMainMenuBodyPaddingNarrow);

          expect(
            find.byWidgetPredicate(
              (Widget w) =>
                  w is Text &&
                  w.style?.letterSpacing == kMainMenuButtonLetterSpacingNarrow,
            ),
            findsWidgets,
            reason:
                'pixelArt menu-button labels at 320 dp must use the narrow '
                'letter-spacing per the ≤ 430 dp rule.',
          );
          expect(
            find.byWidgetPredicate(
              (Widget w) =>
                  w is Text &&
                  w.style?.letterSpacing == kMainMenuButtonLetterSpacingDefault,
            ),
            findsNothing,
            reason:
                'No pixelArt menu-button labels at 320 dp may carry the '
                'wider default letter-spacing.',
          );
        },
      );

      testWidgets(
        'Negative control: CtMainMenu plain @ 1024×768 also pumps without '
        'exception (regression sentinel for the overflow contract)',
        (WidgetTester tester) async {
          await pumpMobileNarrow(
            tester,
            wrapMainMenuForMinViewport(),
            size: kMobileWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
        },
      );
    },
  );
}
