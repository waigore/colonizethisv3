// Pin the 320 dp minimum-viewport contract for [GrantOrSubsidyDialog]
// (DIPL20001) — grant + subsidy happy paths.
// Below-minimum + wide sentinel live in
// `grant_or_subsidy_dialog_320dp_min_viewport_below_minimum_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7; `SPEC/ui/grant-or-subsidy-dialog.md`.
// Refs #2870 S8/S10.

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_dialogs.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show grantAidAmountStep;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';
import 'grant_or_subsidy_dialog_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — GrantOrSubsidyDialog (DIPL20001) '
      '@ 320 dp (Refs #2870 S8/S10)', () {
    testWidgets(
      'AC (positive) GrantOrSubsidyDialog (grant mode, treasury 5000) '
      '@ 320×640: no RenderFlex overflow exception, "Grant aid" title + '
      'treasury body + amount label + both stepper buttons + Cancel + '
      'Submit labels render — the CtDialogShell at 320 dp collapses to '
      '~288 dp content width and the title row, treasury / step body, '
      '1 dp thin divider, centered "−" / "+" stepper, and trailing '
      'right-aligned Cancel + Submit Row must wrap within that budget '
      'per SPEC/ui/grant-or-subsidy-dialog.md § Layout / wireframe.',
      (WidgetTester tester) async {
        // 5x the step (= 5000 with grantAidAmountStep = 1000) so the
        // initial amount snaps to grantAidDefaultAmount (1000) and
        // both stepper buttons are enabled — the canonical happy path
        // through the dialog body.
        final game = buildGrantOrSubsidy320Game(
          humanTreasury: 5 * grantAidAmountStep,
        );
        final bus = AppEventBus.create();

        await pumpDialogs320At(
          tester,
          GrantOrSubsidyDialog(
            game: game,
            humanPlayerId: 'gp1',
            targetFactionId: 'gp2',
            isSubsidy: false,
            bus: bus,
          ),
          size: kGrantOrSubsidy320MinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: GrantOrSubsidyDialog '
              'must not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The CtDialogShell title + '
              'treasury / step body + 1 dp thin divider + "−" / "+" '
              'stepper + Cancel/Submit Row must wrap within the '
              '~288 dp content width.',
        );
        // Title + treasury + action labels render end-to-end.
        expect(find.text('Grant aid'), findsOneWidget);
        expect(find.textContaining('Treasury:'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Submit'), findsOneWidget);
        // Keyed chrome anchors mount so the bespoke stepper fits in
        // the narrow column.
        expect(
          find.byKey(const Key('grantOrSubsidyDialogTitle')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('grantOrSubsidyDialogTreasury')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('grantOrSubsidyDialogThinDivider')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('grantOrSubsidyDialogAmount')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('diplo_amount_minus')), findsOneWidget);
        expect(find.byKey(const Key('diplo_amount_plus')), findsOneWidget);
        // Below-minimum hint MUST be absent on the happy path.
        expect(
          find.byKey(const Key('grantOrSubsidyDialogWarning')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('grantOrSubsidyDialogPreview')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC (positive) GrantOrSubsidyDialog (subsidy mode, treasury 5000) '
      '@ 320×640: no RenderFlex overflow exception, "Set subsidy" '
      'title + percent step line + Cancel + Submit labels render — the '
      'title flips to the subsidy slot and the treasury-independent '
      'percent stepper (5–20%, step 5) stays enabled at the same narrow '
      'viewport (Refs #3753 R3).',
      (WidgetTester tester) async {
        final game = buildGrantOrSubsidy320Game(
          humanTreasury: 5 * grantAidAmountStep,
        );
        final bus = AppEventBus.create();

        await pumpDialogs320At(
          tester,
          GrantOrSubsidyDialog(
            game: game,
            humanPlayerId: 'gp1',
            targetFactionId: 'gp2',
            isSubsidy: true,
            bus: bus,
          ),
          size: kGrantOrSubsidy320MinViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Set subsidy'), findsOneWidget);
        // Subsidy mode shows the percent step line, not the £ treasury copy.
        expect(find.textContaining('Subsidy step:'), findsOneWidget);
        expect(find.textContaining('Treasury:'), findsNothing);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Submit'), findsOneWidget);
        // Below-minimum hint MUST stay absent — subsidy is treasury-independent.
        expect(
          find.byKey(const Key('grantOrSubsidyDialogWarning')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('grantOrSubsidyDialogPreview')),
          findsOneWidget,
        );
      },
    );
  });
}
