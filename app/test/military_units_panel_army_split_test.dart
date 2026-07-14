// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'support/military_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('Army management (bus events) — split UI', () {
    testWidgets(
      'split home army (all regiments): panel shows new army with regiment rows',
      (WidgetTester tester) async {
        const playerId = 'gp_split_ui_full';
        final initial = buildMilitaryHomeArmyAtCapitalGame(
          id: 'g_split_full',
          playerId: playerId,
          regimentIds: const ['r1', 'r2'],
        );

        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await pumpArmySplitHarness(
          tester,
          initialGame: initial,
          humanPlayerId: playerId,
          bus: bus,
        );

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Army').first;
        await tester.tap(homeTile);
        await tester.pumpAndSettle();

        final splitBtn = find.descendant(
          of: homeTile,
          matching: find.widgetWithText(CtActionTextButton, 'Split'),
        ).first;
        await tester.ensureVisible(splitBtn);
        await tester.tap(splitBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveAll('musketeers')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm Split'));
        // Broadcast bus delivers listeners asynchronously; flush like split_army_dialog_test.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('0 regiments · Capital'), findsOneWidget);
        expect(find.text('2 regiments · Capital'), findsOneWidget);

        await tester.tap(find.text('Army army_1'));
        await tester.pumpAndSettle();
        expect(find.text('Musketeers: 2'), findsOneWidget);
      },
    );

    testWidgets(
      'split home army (partial): panel shows correct counts on both armies',
      (WidgetTester tester) async {
        const playerId = 'gp_split_ui_partial';
        final initial = buildMilitaryHomeArmyAtCapitalGame(
          id: 'g_split_partial',
          playerId: playerId,
          regimentIds: const ['r1', 'r2'],
          nextArmySeq: 7,
        );

        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await pumpArmySplitHarness(
          tester,
          initialGame: initial,
          humanPlayerId: playerId,
          bus: bus,
        );

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Army').first;
        await tester.tap(homeTile);
        await tester.pumpAndSettle();

        final splitBtn = find.descendant(
          of: homeTile,
          matching: find.widgetWithText(CtActionTextButton, 'Split'),
        ).first;
        await tester.ensureVisible(splitBtn);
        await tester.tap(splitBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveOne('musketeers')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm Split'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('1 regiments · Capital'), findsNWidgets(2));

        // After the in-place split rebuild the Home Army row stays expanded
        // (tapping the Split row-action pill no longer toggles the
        // ExpansionTile, since the CtActionTextButton InkWell absorbs the tap),
        // so its single musketeer is already visible.
        expect(find.text('Musketeers: 1'), findsOneWidget);

        await tester.tap(find.text('Army army_7'));
        await tester.pumpAndSettle();
        expect(find.text('Musketeers: 1'), findsNWidgets(2));
      },
    );
  });
}
