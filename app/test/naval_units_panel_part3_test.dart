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

      final updated = await pumpNavalTapCheckCombine(
        tester,
        game: combineGame,
        humanId: humanId,
        labels: const ['Fleet test_fleet_1', 'Fleet test_fleet_2'],
      );

      expect(updated, isNotNull);
      final fleetsAfter = updated!.game.worldState.fleets;
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

        final updated = await pumpNavalHomeFleetTransferAll(
          tester,
          game: homeCombineGame,
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

        final updated = await pumpNavalTapCheckCombine(
          tester,
          game: threeGame,
          humanId: humanId,
          labels: const ['Fleet c1', 'Fleet c2', 'Fleet c3'],
          scroll: true,
        );

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
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

    testWidgets(
      'AC: Home Fleet transfer moves selected ships and keeps source when ships remain',
      (WidgetTester tester) async {
        const humanId = 'gp_home_transfer_apply';
        final homeId = homeFleetIdFor(humanId);

        var gameState = buildNavalPanelCapitalHomeAndPeersGame(
          humanId: humanId,
          gameId: 'g_home_transfer_apply',
          displayName: 'Home transfer tester',
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
        final topology = buildUnitsPanelCapitalAdjacentSeaTopology();
        final bus = AppEventBus.create();
        final subTransfer = wireNavalTransferForWidgetTest(
          bus: bus,
          gameSnapshot: () => gameState,
        );
        final subUpdated = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          gameState = e.game;
        });
        addTearDown(subTransfer.cancel);
        addTearDown(subUpdated.cancel);

        await pumpNavalPanel(
          tester,
          game: gameState,
          humanPlayerId: humanId,
          topology: topology,
          bus: bus,
        );

        await tapNavalFleetCheckboxes(tester, ['Home Fleet', 'Fleet sea_source']);
        await tapNavalCombine(tester);

        await tapNavalConfirmTransfer(tester, moveOneTypeId: 'fluyte');

        final homeFleet = gameState.worldState.fleets.firstWhere(
          (f) => f.id == homeId,
        );
        final sourceFleet = gameState.worldState.fleets.firstWhere(
          (f) => f.id == 'sea_source',
        );
        final homeShipIds = homeFleet.ships.map((s) => s.id).toSet();
        final sourceShipIds = sourceFleet.ships.map((s) => s.id).toSet();
        expect(homeShipIds.contains('src_1'), isTrue);
        expect(sourceShipIds.contains('src_1'), isFalse);
        expect(sourceShipIds.contains('src_2'), isTrue);
      },
    );

    testWidgets(
      'AC: Home Fleet and non-adjacent sea source keep Combine disabled',
      (WidgetTester tester) async {
        const humanId = 'gp_home_non_adjacent';

        final gameNonAdjacent = buildNavalPanelCapitalHomeAndPeersGame(
          humanId: humanId,
          gameId: 'g_home_non_adjacent_transfer',
          displayName: 'Home non-adjacent tester',
          peerFleets: [
            Fleet(
              id: 'sea_far',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: 'zone_far',
              ships: const [ShipInstance(id: 'src_1', typeId: 'fluyte')],
            ),
          ],
        );

        await pumpNavalPanel(
          tester,
          game: gameNonAdjacent,
          humanPlayerId: humanId,
          topology: buildUnitsPanelCapitalAdjacentSeaTopology(
            seaZoneId: 'zone_far',
            includeEdge: false,
          ),
        );

        await tapNavalFleetCheckboxes(tester, ['Home Fleet', 'Fleet sea_far']);
        expectNavalCombineEnabled(tester, enabled: false);
      },
    );

    for (final case_ in navalPanelCombineOutcomeCases()) {
      testWidgets(case_.name, (WidgetTester tester) async {
        if (case_.name.contains('Collapsed')) {
          final (bus, latest) = wireNavalFleetsUpdatedCapture();
          await pumpNavalPanel(
            tester,
            game: case_.build(),
            humanPlayerId: case_.humanId,
            bus: bus,
          );
          final tileA = find.widgetWithText(ExpansionTile, 'Fleet col_a');
          final tileB = find.widgetWithText(ExpansionTile, 'Fleet col_b');
          for (final tile in [tileA, tileB]) {
            expect(
              find.descendant(of: tile, matching: find.byTooltip('Split')),
              findsOne,
            );
          }
          await tapNavalFleetCheckboxes(tester, case_.labels);
          expect(
            find.descendant(of: tileA, matching: find.byTooltip('Split')),
            findsOne,
          );
          await tapNavalCombine(tester);
          expectNavalCombineOutcome(latest(), case_);
          return;
        }
        final updated = await pumpNavalTapCheckCombine(
          tester,
          game: case_.build(),
          humanId: case_.humanId,
          labels: case_.labels,
          scroll: case_.scroll,
          expectCombineEnabled: case_.expectCombineEnabled,
        );
        expectNavalCombineOutcome(updated, case_);
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
