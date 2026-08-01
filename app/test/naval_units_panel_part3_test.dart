// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'naval_units_panel_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  group('NavalUnitsPanel', () {
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

    for (final case_ in navalPanelCombineDisabledCases()) {
      testWidgets(case_.name, (WidgetTester tester) async {
        await pumpNavalCheckCombineDisabled(
          tester,
          game: case_.build(),
          humanId: case_.humanId,
          fleetLabels: case_.labels,
        );
      });
    }

    testWidgets(
      'AC: Combining into Home Fleet merges ships into home id when Home is selected',
      (WidgetTester tester) async {
        const humanId = 'gp_home_combine';
        final homeId = homeFleetIdFor(humanId);

        final updated = await pumpNavalHomeFleetTransferAll(
          tester,
          game: buildNavalPanelCapitalHomeAndPeersGame(
            humanId: humanId,
            gameId: 'g_home_combine',
            displayName: 'Home combine tester',
            homeMission: FleetMission.patrol,
            homeShips: const [ShipInstance(id: 'ship_h', typeId: 'carrack')],
            nextShipInstanceSeq: 3,
            peerFleets: [
              navalPanelPortShipFleet(
                id: 'at_capital',
                humanId: humanId,
                port: kNavalPanelCapProvince,
                shipId: 'ship_v',
                typeId: 'fluyte',
              ),
            ],
          ),
          humanId: humanId,
          fleetLabels: const ['Home Fleet', 'Fleet at_capital'],
          transferTypeId: 'fluyte',
        );

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        expect(fleetsAfter.where((f) => f.id == 'at_capital'), isEmpty);

        final home = fleetsAfter.firstWhere((f) => f.id == homeId);
        final shipIds = home.ships.map((s) => s.id).toList()..sort();
        expect(shipIds, ['ship_h', 'ship_v']);
        expect(home.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Home Fleet and adjacent sea source enable selected-ship transfer',
      (WidgetTester tester) async {
        const humanId = 'gp_home_adjacent';
        await pumpNavalPanel(
          tester,
          game: buildNavalPanelHomeAdjacentSeaSourceGame(humanId: humanId),
          humanPlayerId: humanId,
          topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
        );
        await tapNavalFleetCheckboxes(tester, ['Home Fleet', 'Fleet sea_source']);
        expectNavalCombineEnabled(tester, enabled: true);
        await tapNavalCombine(tester);
        expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: Home Fleet transfer moves selected ships and keeps source when ships remain',
      (WidgetTester tester) async {
        await pumpNavalHomePartialTransfer(
          tester,
          humanId: 'gp_home_transfer_apply',
        );
      },
    );

    testWidgets(
      'AC: Home Fleet and non-adjacent sea source keep Combine disabled',
      (WidgetTester tester) async {
        const humanId = 'gp_home_non_adjacent';
        await pumpNavalCheckCombineDisabled(
          tester,
          game: buildNavalPanelHomeNonAdjacentSeaGame(humanId: humanId),
          humanId: humanId,
          fleetLabels: const ['Home Fleet', 'Fleet sea_far'],
          topology: buildUnitsPanelCapitalAdjacentSeaTopology(
            seaZoneId: 'zone_far',
            includeEdge: false,
          ),
        );
      },
    );

    for (final case_ in navalPanelCombineOutcomeCases()) {
      testWidgets(case_.name, (WidgetTester tester) async {
        await pumpNavalCombineOutcomeCase(tester, case_);
      });
    }

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
