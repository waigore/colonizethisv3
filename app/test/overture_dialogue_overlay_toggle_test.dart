import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'overture_dialogue_overlay_test_support.dart';

void main() {
  suppressLogsForTests();

  group('OvertureDialogueOverlay R22 CtToggleSwitch (#2867 R22)', () {
    Finder acceptToggleAt(int rowIndex) =>
        find.byKey(ValueKey<String>('overtureAcceptToggle_$rowIndex'));

    Finder rejectToggleAt(int rowIndex) =>
        find.byKey(ValueKey<String>('overtureRejectToggle_$rowIndex'));

    testWidgets(
      'phase 2: Accept/Reject CtToggleSwitch glow tokens; only Submit is nine-patch',
      (WidgetTester tester) async {
        await pumpOvertureOverlay(tester, offers: twoStageGp2OvertureOffers);

        for (var i = 0; i < 2; i++) {
          expect(acceptToggleAt(i), findsOneWidget);
          expect(rejectToggleAt(i), findsOneWidget);

          final CtToggleSwitch accept = tester.widget<CtToggleSwitch>(
            acceptToggleAt(i),
          );
          expect(accept.value, isFalse);
          expect(accept.onGlowColor, EditorialMonoclePalette.success);

          final CtToggleSwitch reject = tester.widget<CtToggleSwitch>(
            rejectToggleAt(i),
          );
          expect(reject.value, isFalse);
          expect(reject.onGlowColor, EditorialMonoclePalette.danger);
        }

        // Submit is the only CtNinePatchButton in phase 2 (Accept/Reject are
        // CtToggleSwitch per #2867 R22).
        final Iterable<CtNinePatchButton> buttons = tester
            .widgetList<CtNinePatchButton>(find.byType(CtNinePatchButton));
        expect(buttons, hasLength(1));
        expect(
          buttons.single.key,
          const ValueKey<String>('overtureSubmitButton'),
        );
      },
    );

    testWidgets(
      'Accept/Reject toggles are mutually exclusive (on turns the other off)',
      (WidgetTester tester) async {
        await pumpOvertureOverlay(tester);

        await tester.tap(acceptToggleAt(0));
        await tester.pump();
        expect(tester.widget<CtToggleSwitch>(acceptToggleAt(0)).value, isTrue);
        expect(tester.widget<CtToggleSwitch>(rejectToggleAt(0)).value, isFalse);

        await tester.tap(rejectToggleAt(0));
        await tester.pump();
        expect(tester.widget<CtToggleSwitch>(rejectToggleAt(0)).value, isTrue);
        expect(tester.widget<CtToggleSwitch>(acceptToggleAt(0)).value, isFalse);
      },
    );

    testWidgets(
      'tapping Accept then Reject swaps the committed decision to false',
      (WidgetTester tester) async {
        List<OvertureDecision>? submitted;
        await pumpOvertureOverlay(
          tester,
          offers: singleGp2OvertureOffer,
          onDecisions: (d) => submitted = List.of(d),
        );

        await tester.tap(acceptToggleAt(0));
        await tester.pump();
        await tester.tap(rejectToggleAt(0));
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey<String>('overtureSubmitButton')),
        );
        await tester.pump();

        expect(submitted, isNotNull);
        expect(submitted, hasLength(1));
        expect(submitted!.first.accepted, isFalse);
      },
    );

    testWidgets(
      'tapping a currently-on toggle reverts the row to undecided and '
      're-engages the #2867 R23 Submit gate (positive R22 + R23 interaction)',
      (WidgetTester tester) async {
        await pumpOvertureOverlay(tester);

        final Finder submitFinder = find.byKey(
          const ValueKey<String>('overtureSubmitButton'),
        );

        await tester.tap(acceptToggleAt(0));
        await tester.pump();
        expect(
          tester.widget<CtNinePatchButton>(submitFinder).enabled,
          isTrue,
          reason:
              'Single-row overlay enables Submit immediately once a row is '
              'decided (#2867 R23 positive case).',
        );

        // Tap the Accept toggle again while currently on -> reverts to
        // undecided and Submit must disable again.
        await tester.tap(acceptToggleAt(0));
        await tester.pump();
        final CtToggleSwitch accept = tester.widget<CtToggleSwitch>(
          acceptToggleAt(0),
        );
        final CtToggleSwitch reject = tester.widget<CtToggleSwitch>(
          rejectToggleAt(0),
        );
        expect(accept.value, isFalse);
        expect(reject.value, isFalse);
        expect(
          tester.widget<CtNinePatchButton>(submitFinder).enabled,
          isFalse,
          reason:
              'Reverting a row to undecided must re-engage the R23 Submit '
              'gate so the user cannot submit unintentional decisions.',
        );
      },
    );
  });
}
