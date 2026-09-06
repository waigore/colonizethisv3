// MilitaryUnitsPanel header chrome tests. SPEC/ui/military-units-panel.md (Refs #4734 Slice E).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';

import 'military_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;
  const String humanPlayerIdWithNoUnits = 'no-such-player';

  setUpAll(() {
    game = buildMilitaryPanelTestGame();
    humanPlayerIdWithUnits = game.players.first.id;
  });

  group('MilitaryUnitsPanel header chrome', () {
    testWidgets('header Train renders as a primary CtActionTextButton pill '
        '(no CtNinePatchButton header chrome) — #3514 owner decisions #5/#15', (
      WidgetTester tester,
    ) async {
      await pumpMilitaryPanel(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithNoUnits,
      );

      final headerButtons = find.descendant(
        of: find.byType(UnitsPanelShell),
        matching: find.byType(CtActionTextButton),
      );
      expect(headerButtons, findsNWidgets(2));
      final train = find.descendant(
        of: find.byType(UnitsPanelShell),
        matching: find.widgetWithText(CtActionTextButton, 'Train'),
      );
      expect(train, findsOneWidget);
      expect(tester.widget<CtActionTextButton>(train).primary, isTrue);
      expect(find.byType(CtNinePatchButton), findsNothing);
    });

    testWidgets(
      'header Combine renders as a primary CtActionTextButton pill when a '
      'combinable roster is present — #3514 owner decisions #5/#15',
      (WidgetTester tester) async {
        await pumpMilitaryPanel(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithUnits,
        );

        final combine = find.ancestor(
          of: find.text('Combine'),
          matching: find.byType(CtActionTextButton),
        );
        if (combine.evaluate().isNotEmpty) {
          expect(
            tester.widget<CtActionTextButton>(combine.first).primary,
            isTrue,
          );
          expect(
            find.ancestor(
              of: find.text('Combine'),
              matching: find.byType(CtNinePatchButton),
            ),
            findsNothing,
          );
        }
        final train = find.ancestor(
          of: find.text('Train'),
          matching: find.byType(CtActionTextButton),
        );
        expect(train, findsOneWidget);
        expect(tester.widget<CtActionTextButton>(train.first).primary, isTrue);
      },
    );

    testWidgets('panel is wrapped in CtPanel', (WidgetTester tester) async {
      await pumpMilitaryPanel(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      );

      expect(find.byType(CtPanel), findsOneWidget);
    });
  });
}
