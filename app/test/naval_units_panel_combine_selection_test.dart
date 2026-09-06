// Combine selection pins for NavalUnitsPanel (Refs #4013, #4352).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';

import 'naval_panel_combine_cases.dart';
import 'naval_units_panel_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  group('NavalUnitsPanel combine selection', () {
    testWidgets(
      'AC: Header checkbox selects all fleets then second interaction clears',
      (WidgetTester tester) async {
        const humanId = 'gp_select_all';
        final selectAllGame = buildNavalPanelMergePortFleetsFromSpecs(
          humanId: humanId,
          gameId: 'g_select_all',
          displayName: 'Select-all tester',
          fleets: const [
            (id: 'a', shipId: 'ship_1', typeId: 'carrack'),
            (id: 'b', shipId: 'ship_2', typeId: 'fluyte'),
          ],
        );

        await pumpNavalPanel(
          tester,
          game: selectAllGame,
          humanPlayerId: humanId,
        );

        final headerCheckboxFinder = find.descendant(
          of: find.byType(NavalUnitsPanel),
          matching: find.byWidgetPredicate(
            (w) => w is Checkbox && w.tristate == true,
          ),
        );
        expect(headerCheckboxFinder, findsOneWidget);

        await tester.tap(headerCheckboxFinder);
        await tester.pumpAndSettle();

        final checkboxes = find.byType(Checkbox);
        final cbCount = checkboxes.evaluate().length;
        expect(cbCount, greaterThanOrEqualTo(2));
        for (var i = 0; i < cbCount; i++) {
          expect(tester.widget<Checkbox>(checkboxes.at(i)).value, isTrue);
        }

        await tester.tap(headerCheckboxFinder);
        await tester.pumpAndSettle();

        for (var i = 0; i < cbCount; i++) {
          expect(tester.widget<Checkbox>(checkboxes.at(i)).value, isFalse);
        }
      },
    );

    testWidgets(
      'AC: Partial row selection shows indeterminate header; header tap selects all',
      (WidgetTester tester) async {
        const humanId = 'gp_partial_header';

        final partialGame = buildNavalPanelCapitalMergePortFleetsGame(
          humanId: humanId,
          gameId: 'g_partial_header',
          displayName: 'Partial header tester',
          playerHasCapital: false,
          nextShipInstanceSeq: 4,
          fleets: [
            navalPanelPortFleetAtMergePort('p1', humanId, 'ps1', 'carrack'),
            navalPanelPortFleetAtMergePort('p2', humanId, 'ps2', 'fluyte'),
            navalPanelPortFleetAtMergePort('p3', humanId, 'ps3', 'carrack'),
          ],
        );

        await pumpNavalPanel(tester, game: partialGame, humanPlayerId: humanId);

        final headerCheckboxFinder = find.descendant(
          of: find.byType(NavalUnitsPanel),
          matching: find.byWidgetPredicate(
            (w) => w is Checkbox && w.tristate == true,
          ),
        );

        final tile1 = find.widgetWithText(ExpansionTile, 'Fleet p1');
        await tester.tap(
          find.descendant(of: tile1, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        expect(tester.widget<Checkbox>(headerCheckboxFinder).value, isNull);

        await tester.tap(headerCheckboxFinder);
        await tester.pumpAndSettle();

        expect(tester.widget<Checkbox>(headerCheckboxFinder).value, isTrue);
        for (final label in ['Fleet p1', 'Fleet p2', 'Fleet p3']) {
          final tile = find.widgetWithText(ExpansionTile, label);
          expect(tile, findsOneWidget);
          final cb = find.descendant(of: tile, matching: find.byType(Checkbox));
          await tester.ensureVisible(cb);
          expect(tester.widget<Checkbox>(cb).value, isTrue);
        }

        expectNavalCombineEnabled(tester, enabled: true);
      },
    );

    testWidgets(
      'AC: Updating game prunes combine selection to fleets that still exist',
      (WidgetTester tester) async {
        const humanId = 'gp_prune_sel';

        Game gameWithKeepDrop(String keep, String drop) =>
            buildNavalPanelCapitalMergePortFleetsGame(
              humanId: humanId,
              gameId: 'g_prune_two',
              displayName: 'Prune tester',
              fleets: [
                navalPanelPortFleetAtMergePort(keep, humanId, 'ks1', 'carrack'),
                navalPanelPortFleetAtMergePort(drop, humanId, 'ks2', 'fluyte'),
              ],
            );

        final gameTwo = gameWithKeepDrop('stays', 'removed');
        final gameOne = gameTwo.copyWith(
          id: 'g_prune_one',
          worldState: gameTwo.worldState.copyWith(
            fleets: [
              gameTwo.worldState.fleets.firstWhere((f) => f.id == 'stays'),
            ],
          ),
        );

        await pumpNavalPanel(tester, game: gameTwo, humanPlayerId: humanId);
        await tapNavalFleetCheckboxes(tester, ['Fleet stays', 'Fleet removed']);

        await pumpNavalPanel(tester, game: gameOne, humanPlayerId: humanId);

        final tileStays = find.widgetWithText(ExpansionTile, 'Fleet stays');
        final staysCb = find.descendant(
          of: tileStays,
          matching: find.byType(Checkbox),
        );
        expect(
          find.widgetWithText(ExpansionTile, 'Fleet removed'),
          findsNothing,
        );
        expect(tester.widget<Checkbox>(staysCb).value, isTrue);
        expectNavalCombineEnabled(tester, enabled: false);
      },
    );
  });
}
