// Pins SPEC/ui movement dialog contracts (part 1):
// - SPEC/ui/move-army-dialog.md
// Split under repo.app_test_file_size (Refs #4013).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart'
    show editorialMonocleDisplayFontFamily;
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';

import 'move_dialogs_specs_army_support.dart';

void main() {
  suppressLogsForTests();

  group('MoveArmyDialog (SPEC/ui/move-army-dialog.md)', () {
    testWidgets(
      'renders CtDialogShell with section labels and no Material dropdown (Refs #2867 S1)',
      (WidgetTester tester) async {
        await pumpMoveArmySpecsDialog(tester, bus: AppEventBus.create());
        expect(find.byType(MoveArmyDialog), findsOneWidget);
        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.byType(CtSectionLabel), findsAtLeastNWidgets(2));
        expect(find.text('YOUR PROVINCES'), findsOneWidget);
        expect(find.text('INVASION TARGETS'), findsOneWidget);
        expect(find.textContaining('Move army — Army aspecs'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        expect(
          find.descendant(
            of: find.byType(CtDialogShell),
            matching: find.byType(AlertDialog),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'confirm on owned destination emits ArmyMoveRequestedEvent without declareWar',
      (WidgetTester tester) async {
        final (bus, getCaptured, sub) = subscribeArmyMoveRequested();
        addTearDown(sub.cancel);

        await pumpMoveArmySpecsDialog(tester, bus: bus);
        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Confirm'));
        await tester.pumpAndSettle();

        final captured = getCaptured();
        expect(captured, isNotNull);
        expect(captured!.humanPlayerId, kMoveArmySpecsPlayerId);
        expect(captured.moveOrder.armyId, 'aspecs');
        expect(captured.declareWarTargetFactionId, isNull);
        expect(find.byType(MoveArmyDialog), findsNothing);
      },
    );

    testWidgets(
      'invasion row shows declare-war trigger in danger italic, not display font '
      '(Refs #2867 R8)',
      (WidgetTester tester) async {
        final style = await invasionDeclareWarTriggerStyle(tester);
        expect(style?.color, EditorialMonoclePalette.danger);
        expect(style?.fontStyle, FontStyle.italic);
        expect(style?.fontWeight, FontWeight.w600);
        // R8: Cinzel has no italic variant; pinning display font regresses emphasis.
        expect(
          style?.fontFamily,
          isNot(equals(editorialMonocleDisplayFontFamily)),
        );
      },
    );

    testWidgets(
      'confirm on invasion destination then declare-war confirm carries declareWarTargetFactionId',
      (WidgetTester tester) async {
        final (bus, getCaptured, sub) = subscribeArmyMoveRequested();
        addTearDown(sub.cancel);

        await openInvasionWarConfirm(tester, bus);
        await tester.tap(find.text('Declare war and move'));
        await tester.pumpAndSettle();

        final captured = getCaptured();
        expect(captured, isNotNull);
        expect(captured!.declareWarTargetFactionId, kMoveArmySpecsRivalId);
        expect(
          captured.moveOrder.destinationProvinceId,
          kMoveArmySpecsInvasionDest,
        );
      },
    );

    testWidgets(
      'cancel on invasion confirmation aborts emit and keeps dialog mounted',
      (WidgetTester tester) async {
        final (bus, getCaptured, sub) = subscribeArmyMoveRequested();
        addTearDown(sub.cancel);

        await openInvasionWarConfirm(tester, bus);
        await tester.tap(
          find.descendant(
            of: warConfirmSubShell(),
            matching: find.widgetWithText(CtNinePatchButton, 'Cancel'),
          ),
        );
        await tester.pumpAndSettle();

        expect(getCaptured(), isNull);
        expect(find.byType(MoveArmyDialog), findsOneWidget);
      },
    );

    testWidgets(
      'war-confirmation sub-dialog uses danger CtDialogShell + nine-patch actions '
      '(Refs #2867 R9)',
      (WidgetTester tester) async {
        await openInvasionWarConfirm(tester, AppEventBus.create());

        expect(find.byType(CtDialogShell), findsWidgets);
        final CtDialogShell shell = tester.widget<CtDialogShell>(
          find.byType(CtDialogShell).last,
        );
        expect(shell.borderColor, EditorialMonoclePalette.danger);
        expect(shell.borderWidth, CtDialogShell.dangerBorderWidth);
        expect(shell.borderWidth, 1);

        final subShell = warConfirmSubShell();
        expect(
          tester
              .widget<CtNinePatchButton>(
                find.descendant(
                  of: subShell,
                  matching: find.widgetWithText(
                    CtNinePatchButton,
                    'Declare war and move',
                  ),
                ),
              )
              .dangerVariant,
          isTrue,
        );
        expect(
          tester
              .widget<CtNinePatchButton>(
                find.descendant(
                  of: subShell,
                  matching: find.widgetWithText(CtNinePatchButton, 'Cancel'),
                ),
              )
              .dangerVariant,
          isFalse,
        );
        expect(
          find.descendant(of: subShell, matching: find.byType(AlertDialog)),
          findsNothing,
        );
        expect(
          find.descendant(of: subShell, matching: find.byType(TextButton)),
          findsNothing,
        );
      },
    );

    testWidgets(
      'outer Cancel emits no ArmyMoveRequestedEvent and dismisses dialog',
      (WidgetTester tester) async {
        final (bus, getCaptured, sub) = subscribeArmyMoveRequested();
        addTearDown(sub.cancel);

        await pumpMoveArmySpecsDialog(tester, bus: bus);
        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Cancel'));
        await tester.pumpAndSettle();

        expect(getCaptured(), isNull);
        expect(find.byType(MoveArmyDialog), findsNothing);
      },
    );

    testWidgets(
      'with zero offered destinations renders the empty-state copy and disables Confirm',
      (WidgetTester tester) async {
        await pumpMoveArmySpecsDialog(
          tester,
          bus: AppEventBus.create(),
          game: buildMoveArmySpecsIsolatedGame(),
          topology: isolatedMoveArmySpecsTopology,
          humanPlayerId: kMoveArmySpecsIsolatedPlayerId,
        );

        expect(find.text('No valid destinations.'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        final confirmButton = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Confirm'),
        );
        expect(confirmButton.onPressed, isNull);
      },
    );
  });
}
