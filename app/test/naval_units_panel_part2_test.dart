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

    testWidgets('AC: Combining fleets creates correct ship counts', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_combine_count';
      final combineGame = buildNavalPanelMergePortFleetsFromSpecs(
        humanId: humanId,
        gameId: 'g_combine_count',
        displayName: 'Combine tester',
        fleets: const [
          (id: 'test_fleet_1', shipId: 'ship_1', typeId: 'carrack'),
          (id: 'test_fleet_2', shipId: 'ship_2', typeId: 'fluyte'),
        ],
      );

      final (bus, updated) = wireNavalFleetsUpdatedCapture();
      await pumpNavalPanel(
        tester,
        game: combineGame,
        humanPlayerId: humanId,
        bus: bus,
      );
      await tapNavalFleetCheckboxes(tester, [
        'Fleet test_fleet_1',
        'Fleet test_fleet_2',
      ]);
      await tapNavalCombine(tester);

      expect(updated(), isNotNull);
      final fleetsAfter = updated()!.game.worldState.fleets;
      final merged = fleetsAfter.firstWhere((f) => f.id == 'test_fleet_1');
      final mergedIds = merged.ships.map((s) => s.id).toList()..sort();
      expect(mergedIds, ['ship_1', 'ship_2']);
      expect(fleetsAfter.any((f) => f.id == 'test_fleet_2'), isFalse);
    });

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

        final homeCombineGame = buildNavalPanelCapitalHomeAndPeersGame(
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
        );

        final (bus, updated) = wireNavalFleetsUpdatedCapture();
        final subTransfer = wireNavalTransferForWidgetTest(
          bus: bus,
          gameSnapshot: () => homeCombineGame,
        );
        addTearDown(subTransfer.cancel);

        await pumpNavalPanel(
          tester,
          game: homeCombineGame,
          humanPlayerId: humanId,
          bus: bus,
        );

        await tapNavalFleetCheckboxes(tester, ['Home Fleet', 'Fleet at_capital']);
        await tapNavalCombine(tester);
        expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
        await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('fluyte')));
        await tester.pumpAndSettle();
        final confirmTransfer = find.widgetWithText(
          CtNinePatchButton,
          'Transfer',
        );
        expect(confirmTransfer, findsOneWidget);
        final confirmTransferButton = tester.widget<CtNinePatchButton>(
          confirmTransfer,
        );
        expect(confirmTransferButton.enabled, isTrue);
        expect(confirmTransferButton.onPressed, isNotNull);
        confirmTransferButton.onPressed!.call();
        await tester.pumpAndSettle();

        expect(updated(), isNotNull);
        final fleetsAfter = updated()!.game.worldState.fleets;
        expect(fleetsAfter.where((f) => f.id == 'at_capital'), isEmpty);

        final home = fleetsAfter.firstWhere((f) => f.id == homeId);
        final shipIds = home.ships.map((s) => s.id).toList()..sort();
        expect(shipIds, ['ship_h', 'ship_v']);
        expect(home.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Combining three fleets at same port merges all ships into first in panel order',
      (WidgetTester tester) async {
        const humanId = 'gp_three_combine';
        final threeGame = buildNavalPanelMergePortFleetsFromSpecs(
          humanId: humanId,
          gameId: 'g_three_combine',
          displayName: 'Three combine tester',
          fleets: const [
            (id: 'c1', shipId: 's1', typeId: 'carrack'),
            (id: 'c2', shipId: 's2', typeId: 'fluyte'),
            (id: 'c3', shipId: 's3', typeId: 'carrack'),
          ],
        );

        final (bus, updated) = wireNavalFleetsUpdatedCapture();
        await pumpNavalPanel(
          tester,
          game: threeGame,
          humanPlayerId: humanId,
          bus: bus,
        );
        await tapNavalFleetCheckboxes(tester, ['Fleet c1', 'Fleet c2', 'Fleet c3']);
        await tapNavalCombine(tester, scroll: true);

        expect(updated(), isNotNull);
        final fleetsAfter = updated()!.game.worldState.fleets;
        expect(fleetsAfter.length, 1);
        final survivor = fleetsAfter.single;
        expect(survivor.id, 'c1');
        expect(survivor.ships.map((s) => s.id).toList(), ['s1', 's2', 's3']);
        expect(survivor.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Home Fleet and adjacent sea source enable selected-ship transfer',
      (WidgetTester tester) async {
        const humanId = 'gp_home_adjacent';

        final gameAdj = buildNavalPanelCapitalHomeAndPeersGame(
          humanId: humanId,
          gameId: 'g_home_adjacent_transfer',
          displayName: 'Home adjacent tester',
          peerFleets: [
            Fleet(
              id: 'sea_source',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: 'zone_alpha',
              ships: const [
                ShipInstance(id: 'src_1', typeId: 'fluyte'),
                ShipInstance(id: 'src_2', typeId: 'carrack'),
              ],
            ),
          ],
        );

        await pumpNavalPanel(
          tester,
          game: gameAdj,
          humanPlayerId: humanId,
          topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
        );

        await tapNavalFleetCheckboxes(tester, ['Home Fleet', 'Fleet sea_source']);
        expectNavalCombineEnabled(tester, enabled: true);
        await tapNavalCombine(tester);
        expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
      },
    );
  });
}
