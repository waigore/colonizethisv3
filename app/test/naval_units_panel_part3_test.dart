// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'support/naval_units_panel_test_support.dart';
import 'support/widget_test_assets.dart';

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
        final topology = buildNavalCapitalAdjacentSeaTopology();
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

        await tester.pumpWidget(
          buildNavalPanel(
            game: gameState,
            humanPlayerId: humanId,
            topology: topology,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final homeFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        final sourceFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet sea_source',
        );
        await tester.tap(
          find.descendant(of: homeFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: sourceFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();

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
        expect(
          tester.widget<CtNinePatchButton>(confirmTransfer).enabled,
          isTrue,
        );
        final confirmTransferButton = tester.widget<CtNinePatchButton>(
          confirmTransfer,
        );
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
        final topology = buildNavalCapitalAdjacentSeaTopology(
          seaZoneId: 'zone_far',
          includeEdge: false,
        );

        await tester.pumpWidget(
          buildNavalPanel(
            game: gameNonAdjacent,
            humanPlayerId: humanId,
            topology: topology,
          ),
        );
        await tester.pumpAndSettle();

        final homeFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        final sourceFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet sea_far',
        );
        await tester.tap(
          find.descendant(of: homeFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: sourceFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        final combineBtn = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        );
        expect(combineBtn.enabled, isFalse);
      },
    );

    testWidgets(
      'AC: Two fleets in the same sea zone combine; mission becomes none',
      (WidgetTester tester) async {
        const humanId = 'gp_same_sea_combine';
        const capProvince = 'oldWorld|cap1';

        final sameSeaGame = buildNavalPanelOwFleetsGame(
          gameId: 'g_same_sea_combine',
          humanId: humanId,
          displayName: 'Same-sea combine',
          capitalProvinceId: capProvince,
          oldWorldProvinces: [
            Province(
              id: 'coast',
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Coast',
            ),
            Province(
              id: 'cap1',
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Capital',
            ),
          ],
          fleets: [
            Fleet(
              id: 'sea_1',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: 'zone_alpha',
              inPortAtProvinceId: null,
              ships: const [ShipInstance(id: 'ss1', typeId: 'carrack')],
              mission: FleetMission.patrol,
            ),
            Fleet(
              id: 'sea_2',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: 'zone_alpha',
              inPortAtProvinceId: null,
              ships: const [ShipInstance(id: 'ss2', typeId: 'fluyte')],
            ),
          ],
          portsByProvinceSeaboard: {
            'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
          },
          tileKeysByProvince: {
            capProvince: ['oldWorld|cap1|0|0'],
            'oldWorld|coast': ['oldWorld|coast|0|0'],
          },
          nextShipInstanceSeq: 3,
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildNavalPanel(game: sameSeaGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final finder1 = find.widgetWithText(ExpansionTile, 'Fleet sea_1');
        final finder2 = find.widgetWithText(ExpansionTile, 'Fleet sea_2');
        expect(finder1, findsOneWidget);
        expect(finder2, findsOneWidget);

        await tester.tap(
          find.descendant(of: finder1, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: finder2, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        final combineBtn = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        );
        expect(combineBtn.enabled, isTrue);

        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        expect(fleetsAfter.length, 1);
        final survivor = fleetsAfter.single;
        expect(survivor.id, 'sea_1');
        final shipIds = survivor.ships.map((s) => s.id).toList()..sort();
        expect(shipIds, ['ss1', 'ss2']);
        expect(survivor.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Combining two non-home fleets clears non-none missions on survivor',
      (WidgetTester tester) async {
        const humanId = 'gp_mission_clear';
        const mergePort = 'oldWorld|mergeport';

        final missionGame = buildNavalPanelCapitalMergePortFleetsGame(
          humanId: humanId,
          gameId: 'g_mission_clear',
          displayName: 'Mission clear tester',
          nextShipInstanceSeq: 3,
          fleets: [
            Fleet(
              id: 'm1',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ms1', typeId: 'carrack')],
              mission: FleetMission.patrol,
            ),
            Fleet(
              id: 'm2',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ms2', typeId: 'fluyte')],
              mission: FleetMission.blockade,
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildNavalPanel(game: missionGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final t1 = find.widgetWithText(ExpansionTile, 'Fleet m1');
        final t2 = find.widgetWithText(ExpansionTile, 'Fleet m2');
        await tester.tap(
          find.descendant(of: t1, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: t2, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final merged = updated!.game.worldState.fleets.firstWhere(
          (f) => f.id == 'm1',
        );
        expect(merged.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Partial row selection shows indeterminate header; header tap selects all',
      (WidgetTester tester) async {
        const humanId = 'gp_partial_header';
        const mergePort = 'oldWorld|mergeport';

        // No capital => no synthetic Home Fleet row; select-all stays one locality.
        final partialGame = buildNavalPanelCapitalMergePortFleetsGame(
          humanId: humanId,
          gameId: 'g_partial_header',
          displayName: 'Partial header tester',
          playerHasCapital: false,
          nextShipInstanceSeq: 4,
          fleets: [
            Fleet(
              id: 'p1',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ps1', typeId: 'carrack')],
            ),
            Fleet(
              id: 'p2',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ps2', typeId: 'fluyte')],
            ),
            Fleet(
              id: 'p3',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ps3', typeId: 'carrack')],
            ),
          ],
        );

        await tester.pumpWidget(
          buildNavalPanel(game: partialGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

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

        final combineBtn = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        );
        expect(combineBtn.enabled, isTrue);
      },
    );

    testWidgets(
      'AC: Three-fleet combine survivor is first in panel order regardless of check order',
      (WidgetTester tester) async {
        const humanId = 'gp_reverse_check';
        const mergePort = 'oldWorld|mergeport';

        final revGame = buildNavalPanelCapitalMergePortFleetsGame(
          humanId: humanId,
          gameId: 'g_reverse_check',
          displayName: 'Reverse check tester',
          nextShipInstanceSeq: 4,
          fleets: [
            Fleet(
              id: 'r1',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'rs1', typeId: 'carrack')],
            ),
            Fleet(
              id: 'r2',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'rs2', typeId: 'fluyte')],
            ),
            Fleet(
              id: 'r3',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'rs3', typeId: 'carrack')],
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildNavalPanel(game: revGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        for (final label in ['Fleet r3', 'Fleet r2', 'Fleet r1']) {
          final titleFinder = find.text(label);
          await tester.scrollUntilVisible(titleFinder, 120);
          await tester.pumpAndSettle();
          final tile = find.ancestor(
            of: titleFinder,
            matching: find.byType(ExpansionTile),
          );
          final cb = find.descendant(of: tile, matching: find.byType(Checkbox));
          await tester.scrollUntilVisible(cb, 120);
          await tester.pumpAndSettle();
          await tester.ensureVisible(cb);
          await tester.tap(cb);
          await tester.pumpAndSettle();
        }

        final combineFinder = find.widgetWithText(
          CtActionTextButton,
          'Combine',
        );
        await tester.scrollUntilVisible(combineFinder, 120);
        await tester.pumpAndSettle();
        await tester.tap(combineFinder);
        await tester.pumpAndSettle();

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
        const mergePort = 'oldWorld|mergeport';

        Game gameWithKeepDrop(String keep, String drop) =>
            buildNavalPanelCapitalMergePortFleetsGame(
              humanId: humanId,
              gameId: 'g_prune_two',
              displayName: 'Prune tester',
              nextShipInstanceSeq: 3,
              fleets: [
                Fleet(
                  id: keep,
                  ownerId: humanId,
                  regionId: 'oldWorld',
                  inPortAtProvinceId: mergePort,
                  ships: const [ShipInstance(id: 'ks1', typeId: 'carrack')],
                ),
                Fleet(
                  id: drop,
                  ownerId: humanId,
                  regionId: 'oldWorld',
                  inPortAtProvinceId: mergePort,
                  ships: const [ShipInstance(id: 'ks2', typeId: 'fluyte')],
                ),
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

        await tester.pumpWidget(
          buildNavalPanel(game: gameTwo, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final tileStays = find.widgetWithText(ExpansionTile, 'Fleet stays');
        final tileRemoved = find.widgetWithText(ExpansionTile, 'Fleet removed');
        await tester.tap(
          find.descendant(of: tileStays, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: tileRemoved, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          buildNavalPanel(game: gameOne, humanPlayerId: humanId),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final staysCb = find.descendant(
          of: tileStays,
          matching: find.byType(Checkbox),
        );
        final removedFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet removed',
        );
        expect(removedFinder, findsNothing);
        expect(tester.widget<Checkbox>(staysCb).value, isTrue);

        final combineBtn = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        );
        expect(combineBtn.enabled, isFalse);
      },
    );

    testWidgets(
      'AC: Collapsed rows keep inline Split action while checkbox selection works',
      (WidgetTester tester) async {
        const humanId = 'gp_collapsed_cb';
        const mergePort = 'oldWorld|mergeport';

        final collapsedGame = buildNavalPanelCapitalMergePortFleetsGame(
          humanId: humanId,
          gameId: 'g_collapsed_cb',
          displayName: 'Collapsed cb tester',
          nextShipInstanceSeq: 3,
          fleets: [
            Fleet(
              id: 'col_a',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'cs1', typeId: 'carrack')],
            ),
            Fleet(
              id: 'col_b',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'cs2', typeId: 'fluyte')],
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildNavalPanel(game: collapsedGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final tileA = find.widgetWithText(ExpansionTile, 'Fleet col_a');
        final tileB = find.widgetWithText(ExpansionTile, 'Fleet col_b');

        expect(
          find.descendant(of: tileA, matching: find.byTooltip('Split')),
          findsOne,
        );
        expect(
          find.descendant(of: tileB, matching: find.byTooltip('Split')),
          findsOne,
        );

        await tester.tap(
          find.descendant(of: tileA, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: tileB, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(of: tileA, matching: find.byTooltip('Split')),
          findsOne,
        );

        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        final merged = fleetsAfter.firstWhere((f) => f.id == 'col_a');
        final mergedIds = merged.ships.map((s) => s.id).toList()..sort();
        expect(mergedIds, ['cs1', 'cs2']);
      },
    );
  });
}
