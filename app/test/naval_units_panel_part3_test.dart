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

        final moveOneFluyte = find.byKey(
          CtTransferListKeys.leftMoveOne('fluyte'),
        );
        expect(moveOneFluyte, findsOneWidget);
        await tester.tap(moveOneFluyte);
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

    testWidgets('AC: combine same-sea + mission-clear survivors', (
      WidgetTester tester,
    ) async {
      const sameSeaId = 'gp_same_sea_combine';
      final sameSea = await pumpNavalTapCheckCombine(
        tester,
        game: buildNavalPanelSameSeaCombineGame(humanId: sameSeaId),
        humanId: sameSeaId,
        labels: const ['Fleet sea_1', 'Fleet sea_2'],
        expectCombineEnabled: true,
      );
      expect(sameSea, isNotNull);
      final sameSeaSurvivor = sameSea!.game.worldState.fleets.single;
      expect(sameSeaSurvivor.id, 'sea_1');
      expect((sameSeaSurvivor.ships.map((s) => s.id).toList()..sort()), [
        'ss1',
        'ss2',
      ]);
      expect(sameSeaSurvivor.mission, FleetMission.none);

      const missionId = 'gp_mission_clear';
      final cleared = await pumpNavalTapCheckCombine(
        tester,
        game: buildNavalPanelMergePortFleetsGame(
          humanId: missionId,
          gameId: 'g_mission_clear',
          displayName: 'Mission clear tester',
          fleets: [
            navalPanelPortFleetAtMergePort(
              'm1',
              missionId,
              'ms1',
              'carrack',
              mission: FleetMission.patrol,
            ),
            navalPanelPortFleetAtMergePort(
              'm2',
              missionId,
              'ms2',
              'fluyte',
              mission: FleetMission.blockade,
            ),
          ],
        ),
        humanId: missionId,
        labels: const ['Fleet m1', 'Fleet m2'],
      );
      expect(cleared, isNotNull);
      expect(
        cleared!.game.worldState.fleets.firstWhere((f) => f.id == 'm1').mission,
        FleetMission.none,
      );
    });

    testWidgets(
      'AC: Partial row selection shows indeterminate header; header tap selects all',
      (WidgetTester tester) async {
        const humanId = 'gp_partial_header';

        final partialGame = buildNavalPanelMergePortFleetsGame(
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
      'AC: Three-fleet combine survivor is first in panel order regardless of check order',
      (WidgetTester tester) async {
        const humanId = 'gp_reverse_check';
        final updated = await pumpNavalTapCheckCombine(
          tester,
          game: buildNavalPanelMergePortFleetsGame(
            humanId: humanId,
            gameId: 'g_reverse_check',
            displayName: 'Reverse check tester',
            nextShipInstanceSeq: 4,
            fleets: [
              navalPanelPortFleetAtMergePort('r1', humanId, 'rs1', 'carrack'),
              navalPanelPortFleetAtMergePort('r2', humanId, 'rs2', 'fluyte'),
              navalPanelPortFleetAtMergePort('r3', humanId, 'rs3', 'carrack'),
            ],
          ),
          humanId: humanId,
          labels: const ['Fleet r3', 'Fleet r2', 'Fleet r1'],
          scroll: true,
        );
        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        expect(fleetsAfter.length, 1);
        final survivor = fleetsAfter.single;
        expect(survivor.id, 'r1');
        expect(survivor.ships.map((s) => s.id).toList(), ['rs1', 'rs2', 'rs3']);
      },
    );

    testWidgets(
      'AC: Updating game prunes combine selection to fleets that still exist',
      (WidgetTester tester) async {
        const humanId = 'gp_prune_sel';

        Game gameWithKeepDrop(String keep, String drop) =>
            buildNavalPanelMergePortFleetsGame(
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

    testWidgets(
      'AC: Collapsed rows keep inline Split action while checkbox selection works',
      (WidgetTester tester) async {
        const humanId = 'gp_collapsed_cb';
        final collapsedGame = buildNavalPanelMergePortFleetsGame(
          humanId: humanId,
          gameId: 'g_collapsed_cb',
          displayName: 'Collapsed cb tester',
          fleets: [
            navalPanelPortFleetAtMergePort('col_a', humanId, 'cs1', 'carrack'),
            navalPanelPortFleetAtMergePort('col_b', humanId, 'cs2', 'fluyte'),
          ],
        );

        final (bus, latest) = wireNavalFleetsUpdatedCapture();
        await pumpNavalPanel(
          tester,
          game: collapsedGame,
          humanPlayerId: humanId,
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

        await tapNavalFleetCheckboxes(tester, ['Fleet col_a', 'Fleet col_b']);
        expect(
          find.descendant(of: tileA, matching: find.byTooltip('Split')),
          findsOne,
        );
        await tapNavalCombine(tester);

        final updated = latest();
        expect(updated, isNotNull);
        final merged = updated!.game.worldState.fleets.firstWhere(
          (f) => f.id == 'col_a',
        );
        final mergedIds = merged.ships.map((s) => s.id).toList()..sort();
        expect(mergedIds, ['cs1', 'cs2']);
      },
    );
  });
}
