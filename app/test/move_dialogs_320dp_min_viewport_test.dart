// Pin the 320 dp minimum-viewport contract for the two in-game move
// dialogs that share the [CtDialogShell] chrome but live outside the
// existing `dialogs_320dp_min_viewport_test.dart` family because they
// require a non-trivial `Game` + `MapTopology` fixture for the
// destination probe:
//
//  * [MoveArmyDialog]  — opened from the non-Home army row Move action
//    in `MilitaryUnitsPanel` (SPEC/ui/move-army-dialog.md). The shell
//    hosts up to two `CtSectionLabel`-headed destination groups (YOUR
//    PROVINCES, INVASION TARGETS) plus a trailing Cancel + Confirm
//    `CtNinePatchButton` action row.
//  * [MoveFleetDialog] — opened from the non-Home fleet row Move action
//    in `NavalUnitsPanel` (SPEC/ui/move-fleet-dialog.md). The shell
//    hosts up to two `CtSectionLabel`-headed destination groups (SEA
//    ZONES, PORTS) plus the same Cancel + Confirm action row.
//
// Both dialogs render their chrome via [CtDialogShell] (`maxWidth: 480`
// default; `Dialog.insetPadding: 16`). At [kMinViewportWidth] (320 dp)
// the inset padding dominates so the content column collapses to
// ~288 dp — the same narrow budget the `dialogs_320dp_min_viewport`
// pins already exercise for [GameParametersDialog], [TurnNewsDialog],
// etc. The pins assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception escapes the framework — the contract the other
//    `*_320dp_min_viewport_test.dart` files rely on.
//  * The localized title, both Cancel and Confirm action labels, and
//    at least one destination row label render end-to-end so the
//    layout actually exercises the dialog body at 320 dp rather than
//    no-op'ing.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the host overflow
//    contract upstream of the dialog itself would be caught.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/move-army-dialog.md` § Layout / wireframe.
// SPEC: `SPEC/ui/move-fleet-dialog.md` § Layout / wireframe.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';
import 'move_dialogs_320dp_min_viewport_test_support.dart';

const Size _kMinViewport = kDialogs320MinViewport;
const Size _kWideRegressionViewport = kDialogs320WideRegressionViewport;

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — MoveArmyDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    testWidgets(
      'AC (positive) MoveArmyDialog @ 320×640: no RenderFlex overflow '
      'exception, title + YOUR PROVINCES + Cancel + Confirm all render',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          buildMoveArmyDialog320(),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: MoveArmyDialog must not '
              'emit a RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp). CtDialogShell at 320 dp collapses to ~288 dp '
              'content width — the title row, both CtSectionLabel '
              'headers, the destination radio rows, and the trailing '
              'Cancel + Confirm action row must all wrap within that.',
        );
        expect(find.byType(MoveArmyDialog), findsOneWidget);
        expect(find.textContaining('Move army'), findsOneWidget);
        // CtSectionLabel renders text upper-cased.
        expect(find.text('YOUR PROVINCES'), findsOneWidget);
        expect(find.text('INVASION TARGETS'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Confirm'), findsOneWidget);
      },
    );

    testWidgets(
      'Negative control: MoveArmyDialog @ 1024×768 also pumps without '
      'exception (regression sentinel for the overflow contract — '
      'keeps the 320 dp positive pin meaningful)',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          buildMoveArmyDialog320(),
          size: _kWideRegressionViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(MoveArmyDialog), findsOneWidget);
        expect(find.textContaining('Move army'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Confirm'), findsOneWidget);
      },
    );
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — MoveFleetDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    testWidgets(
      'AC (positive) MoveFleetDialog @ 320×640: no RenderFlex overflow '
      'exception, title + SEA ZONES + Cancel + Confirm all render',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          buildMoveFleetDialog320(),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: MoveFleetDialog must not '
              'emit a RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp). CtDialogShell at 320 dp collapses to ~288 dp '
              'content width — the title row, the SEA ZONES '
              'CtSectionLabel, the sea-zone radio rows, and the trailing '
              'Cancel + Confirm action row must all wrap within that.',
        );
        expect(find.byType(MoveFleetDialog), findsOneWidget);
        expect(find.textContaining('Move fleet'), findsOneWidget);
        // CtSectionLabel renders text upper-cased; SEA ZONES is the
        // guaranteed section for the single-sea-zone destination
        // fixture.
        expect(find.text('SEA ZONES'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Confirm'), findsOneWidget);
      },
    );

    testWidgets(
      'Negative control: MoveFleetDialog @ 1024×768 also pumps without '
      'exception (regression sentinel for the overflow contract — '
      'keeps the 320 dp positive pin meaningful)',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          buildMoveFleetDialog320(),
          size: _kWideRegressionViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(MoveFleetDialog), findsOneWidget);
        expect(find.textContaining('Move fleet'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Confirm'), findsOneWidget);
      },
    );
  });
}
