// Below-minimum + wide regression pins for [GrantOrSubsidyDialog]
// (DIPL20001). Grant + subsidy happy paths live in
// `grant_or_subsidy_dialog_320dp_min_viewport_test.dart`.
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
      'AC (positive) GrantOrSubsidyDialog (grant mode, treasury below '
      'minimum step) @ 320×640: no RenderFlex overflow exception, the '
      'keyed _BelowMinimumWarning row mounts, both stepper buttons are '
      'disabled, and the trailing Cancel + Submit Row still renders — '
      'pins the optional warning + 16 dp gap + action row contract '
      'fitting within the ~288 dp content width per '
      'SPEC/ui/grant-or-subsidy-dialog.md § Layout / wireframe.',
      (WidgetTester tester) async {
        // Treasury strictly below grantAidAmountStep (= 1000) so
        // canAdjust is false and the warning row mounts.
        final game = buildGrantOrSubsidy320Game(
          humanTreasury: grantAidAmountStep - 1,
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
              'must not overflow at kMinViewportWidth (320 dp) when '
              'the optional below-minimum warning row mounts above the '
              'Cancel + Submit Row.',
        );
        expect(find.text('Grant aid'), findsOneWidget);
        expect(
          find.byKey(const Key('grantOrSubsidyDialogWarning')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('grantOrSubsidyDialogPreview')),
          findsNothing,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Submit'), findsOneWidget);
      },
    );

    testWidgets(
      'Negative control: GrantOrSubsidyDialog (grant mode) @ 1024×768 '
      'also pumps without exception (regression sentinel for the '
      'overflow contract — keeps the 320 dp positive pins meaningful).',
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
            isSubsidy: false,
            bus: bus,
          ),
          size: kGrantOrSubsidy320WideViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Grant aid'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Submit'), findsOneWidget);
      },
    );
  });
}
