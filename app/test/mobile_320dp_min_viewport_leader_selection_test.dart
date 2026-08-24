// Pin the 320 dp minimum-viewport contract for NewGameLeaderSelectionDialog.
// SPEC: SPEC/ui/new-game-leader-selection-dialog.md, SPEC/ui/mobile-adaptation.md § 7.
// Refs #2870 S7/S8/S10.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';
import 'mobile_320dp_min_viewport_test_support.dart';

void main() {
  suppressLogsForTests();

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
