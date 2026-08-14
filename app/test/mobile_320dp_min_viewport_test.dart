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

  // Pin the 320 dp minimum-viewport contract for
  // `NewGameLeaderSelectionDialog` (DLG10001). The dialog already
  // pins its 540 dp wide↔narrow boundary in
  // `new_game_leader_selection_dialog_test.dart`; this group closes the
  // remaining 320 dp viewport gap so the shell New Game flow honours the
  // same minimum viewport every other player-facing surface does.
  //
  // SPEC: `SPEC/ui/new-game-leader-selection-dialog.md` § Narrow-viewport
  // slot pickers stacking + § Layout / wireframe;
  // `SPEC/ui/mobile-adaptation.md` § 4 Game Setup + § 7
  // (Minimum-viewport pin). Refs #2870 S7 (narrow stacking) + S8 (dialog
  // scales at narrow widths) + S10 (no horizontal overflow at 320 dp on
  // every covered surface).
  group('SPEC/ui/mobile-adaptation.md § 7 — NewGameLeaderSelectionDialog @ '
      '320 dp (Refs #2870 S7/S8/S10)', () {
    const Key kSlotPickersStackedColumnKey = ValueKey<String>(
      'newGameLeaderDialogSlotPickersColumn',
    );
    const Key kSlotPickersSideBySideRowKey = ValueKey<String>(
      'newGameLeaderDialogSlotPickersRow',
    );

    Map<String, String> defaultInitialLeaderByGpId() {
      final base = GameSetupConfig.defaultConfig;
      final naming = defaultNamingConfig;
      final initial = <String, String>{};
      for (final gpId in base.selectedGreatPowerIds) {
        final gp = naming.gpById(gpId);
        if (gp != null && gp.leaderVariants.isNotEmpty) {
          initial[gpId] = gp.defaultLeaderVariantId;
        }
      }
      return initial;
    }

    // Embeds the dialog directly in the Scaffold body (matches the
    // pattern used by `dialogs_320dp_min_viewport_test.dart`) so the
    // contract under test is the dialog's own [CtDialogShell] layout
    // at the narrow viewport, not the showDialog route plumbing
    // (already covered by `new_game_leader_selection_dialog_test.dart`).
    Future<void> pumpDialog(WidgetTester tester, {required Size size}) async {
      await pumpDialogs320At(
        tester,
        NewGameLeaderSelectionDialog(
          baseConfig: GameSetupConfig.defaultConfig,
          naming: defaultNamingConfig,
          initialLeaderByGpId: defaultInitialLeaderByGpId(),
          blessedProfileNames: const [],
          onCancel: () {},
          onConfirmed: (_, _, _, _, _, _, _) {},
        ),
        size: size,
        locale: const Locale('en'),
      );
    }

    testWidgets('AC3 (positive) NewGameLeaderSelectionDialog @ 320×640: no '
        'RenderFlex overflow exception, six stacked slot bodies render, '
        'side-by-side row body is not mounted', (WidgetTester tester) async {
      await pumpDialog(tester, size: kMobileMinViewport);

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: '
            'NewGameLeaderSelectionDialog must not emit a RenderFlex '
            'overflow exception at kMinViewportWidth (320 dp). '
            'CtDialogShell at 320 dp collapses to ~288 dp content '
            'width — every slot row + the seed field + checkbox + '
            'slider + Cancel/Start action row must wrap within that.',
      );
      // 320 dp < kLeaderSelectionNarrowBreakpoint (540 dp) → narrow stacking
      // contract per SPEC/ui/new-game-leader-selection-dialog.md
      // § Narrow-viewport slot pickers stacking.
      expect(
        find.byKey(kSlotPickersStackedColumnKey),
        findsNWidgets(6),
        reason:
            '320 dp is well below kLeaderSelectionNarrowBreakpoint (540 dp); '
            'every one of the six slot rows MUST mount the stacked '
            'column body keyed `newGameLeaderDialogSlotPickersColumn`.',
      );
      expect(
        find.byKey(kSlotPickersSideBySideRowKey),
        findsNothing,
        reason:
            '320 dp narrow contract MUST NOT mount the wide-viewport '
            'side-by-side row body keyed '
            '`newGameLeaderDialogSlotPickersRow` (negative AC).',
      );
    });

    testWidgets(
      'AC3 (positive) NewGameLeaderSelectionDialog @ 320×640: title + '
      'six slot labels + Cancel + Start labels render within the '
      '~288 dp content column',
      (WidgetTester tester) async {
        await pumpDialog(tester, size: kMobileMinViewport);

        expect(tester.takeException(), isNull);
        expect(find.text('Choose nations and leaders'), findsOneWidget);
        expect(find.text('Slot 1'), findsOneWidget);
        expect(find.text('YOU'), findsOneWidget);
        expect(find.text('Slot 2'), findsOneWidget);
        expect(find.text('Slot 6'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(CtNinePatchButton),
            matching: find.text('Cancel'),
          ),
          findsOneWidget,
          reason:
              'Cancel action label MUST render as a `CtNinePatchButton` '
              'descendant — the footer Cancel/Start row must keep both '
              'labels reachable in the 320 dp content column.',
        );
        expect(
          find.descendant(
            of: find.byType(CtNinePatchButton),
            matching: find.text('Start'),
          ),
          findsOneWidget,
          reason:
              'Start action label MUST render as a `CtNinePatchButton` '
              'descendant — the footer Cancel/Start row must keep both '
              'labels reachable in the 320 dp content column.',
        );
      },
    );

    testWidgets('AC3 (positive) NewGameLeaderSelectionDialog @ 320×640: every '
        'rendered Cancel/Start `CtNinePatchButton` height ≥ '
        'kMinTouchTargetSize (SPEC/ui/mobile-adaptation.md § 1)', (
      WidgetTester tester,
    ) async {
      await pumpDialog(tester, size: kMobileMinViewport);

      expect(tester.takeException(), isNull);
      final List<double> heights = renderedNinePatchButtonHeights(tester);
      // The dialog footer renders exactly two CtNinePatchButtons
      // (Cancel + Start) per the SPEC layout / wireframe. Asserting
      // ≥ 2 keeps the AC robust against future button additions
      // without losing the 44 dp touch-target contract.
      expect(
        heights.length,
        greaterThanOrEqualTo(2),
        reason:
            'NewGameLeaderSelectionDialog footer MUST render at least '
            'Cancel + Start as `CtNinePatchButton` children at the '
            '320 dp viewport.',
      );
      for (final double h in heights) {
        expect(
          h,
          greaterThanOrEqualTo(kMinTouchTargetSize),
          reason:
              'CtNinePatchButton height $h dp violates the 44 dp '
              'touch-target minimum at the 320 dp viewport '
              '(SPEC/ui/mobile-adaptation.md § 1).',
        );
      }
    });

    testWidgets(
      'Negative control: NewGameLeaderSelectionDialog @ 1024×768 pumps '
      'without exception and selects the wide side-by-side row body '
      '(regression sentinel for the narrow-stacking branch — keeps '
      'the 320 dp positive pins meaningful)',
      (WidgetTester tester) async {
        await pumpDialog(tester, size: kMobileWideRegressionViewport);

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(kSlotPickersSideBySideRowKey),
          findsNWidgets(6),
          reason:
              '1024 dp ≥ kLeaderSelectionNarrowBreakpoint (540 dp): the dialog '
              'MUST select the wide side-by-side row body for every '
              'slot. A regression that always picked the narrow column '
              'body would flip this sentinel.',
        );
        expect(
          find.byKey(kSlotPickersStackedColumnKey),
          findsNothing,
          reason:
              'Wide viewport MUST NOT mount the stacked column body — '
              'guards against flipping the breakpoint comparator '
              'direction.',
        );
      },
    );
  });
}
