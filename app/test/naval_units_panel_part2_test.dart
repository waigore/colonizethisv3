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

Fleet _portShipFleet({
  required String id,
  required String humanId,
  required String port,
  required String shipId,
  String typeId = 'carrack',
}) {
  return Fleet(
    id: id,
    ownerId: humanId,
    regionId: 'oldWorld',
    inPortAtProvinceId: port,
    ships: [ShipInstance(id: shipId, typeId: typeId)],
  );
}

Future<void> _tapFleetCheckboxes(
  WidgetTester tester,
  Iterable<String> fleetLabels,
) async {
  for (final label in fleetLabels) {
    final tile = find.widgetWithText(ExpansionTile, label);
    expect(tile, findsOneWidget);
    final cb = find.descendant(of: tile, matching: find.byType(Checkbox));
    await tester.ensureVisible(cb);
    await tester.tap(cb);
    await tester.pumpAndSettle();
  }
}

Future<void> _expectCombineEnabled(
  WidgetTester tester, {
  required bool enabled,
}) async {
  final combineBtn = tester.widget<CtActionTextButton>(
    find.widgetWithText(CtActionTextButton, 'Combine'),
  );
  expect(combineBtn.enabled, enabled);
}

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
        const mergePort = 'oldWorld|mergeport';

        final selectAllGame = buildNavalPanelCapitalMergePortFleetsGame(
          humanId: humanId,
          gameId: 'g_select_all',
          displayName: 'Select-all tester',
          includeMergePortTileKeys: false,
          nextShipInstanceSeq: 3,
          fleets: [
            _portShipFleet(
              id: 'a',
              humanId: humanId,
              port: mergePort,
              shipId: 'ship_1',
            ),
            _portShipFleet(
              id: 'b',
              humanId: humanId,
              port: mergePort,
              shipId: 'ship_2',
              typeId: 'fluyte',
            ),
          ],
        );

        await tester.pumpWidget(
          buildNavalPanel(game: selectAllGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

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
      const mergePort = 'oldWorld|mergeport';

      final combineGame = buildNavalPanelCapitalMergePortFleetsGame(
        humanId: humanId,
        gameId: 'g_combine_count',
        displayName: 'Combine tester',
        includeMergePortTileKeys: false,
        nextShipInstanceSeq: 3,
        fleets: [
          _portShipFleet(
            id: 'test_fleet_1',
            humanId: humanId,
            port: mergePort,
            shipId: 'ship_1',
          ),
          _portShipFleet(
            id: 'test_fleet_2',
            humanId: humanId,
            port: mergePort,
            shipId: 'ship_2',
            typeId: 'fluyte',
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
        buildNavalPanel(game: combineGame, humanPlayerId: humanId, bus: bus),
      );
      await tester.pumpAndSettle();

      await _tapFleetCheckboxes(tester, [
        'Fleet test_fleet_1',
        'Fleet test_fleet_2',
      ]);
      final combineFinder = find.widgetWithText(CtActionTextButton, 'Combine');
      await tester.ensureVisible(combineFinder);
      await tester.tap(combineFinder);
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      final fleetsAfter = updated!.game.worldState.fleets;
      final merged = fleetsAfter.firstWhere((f) => f.id == 'test_fleet_1');
      final mergedIds = merged.ships.map((s) => s.id).toList()..sort();
      expect(mergedIds, ['ship_1', 'ship_2']);
      expect(fleetsAfter.any((f) => f.id == 'test_fleet_2'), isFalse);
    });

    testWidgets(
      'AC: Fleets at different locations keep Combine disabled when both checked',
      (WidgetTester tester) async {
        const humanId = 'gp_diff_loc';
        const capProvince = 'oldWorld|cap1';
        const portA = 'oldWorld|port_a';
        const portB = 'oldWorld|port_b';

        final diffLocGame = buildNavalPanelOwFleetsGame(
          gameId: 'g_diff_loc',
          humanId: humanId,
          displayName: 'Diff-loc tester',
          capitalProvinceId: capProvince,
          oldWorldProvinces: [
            Province(
              id: 'cap1',
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Capital',
            ),
            Province(
              id: 'port_a',
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Port A',
            ),
            Province(
              id: 'port_b',
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Port B',
            ),
          ],
          fleets: [
            Fleet(
              id: 'fa',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: portA,
              ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
            ),
            Fleet(
              id: 'fb',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: portB,
              ships: const [ShipInstance(id: 'ship_2', typeId: 'fluyte')],
            ),
          ],
          tileKeysByProvince: {
            capProvince: ['oldWorld|cap1|0|0'],
          },
          nextShipInstanceSeq: 3,
        );

        await tester.pumpWidget(
          buildNavalPanel(game: diffLocGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        await _tapFleetCheckboxes(tester, ['Fleet fa', 'Fleet fb']);
        await _expectCombineEnabled(tester, enabled: false);
      },
    );

    testWidgets(
      'AC: Combining into Home Fleet merges ships into home id when Home is selected',
      (WidgetTester tester) async {
        const humanId = 'gp_home_combine';
        const capProvince = 'oldWorld|cap1';
        final homeId = homeFleetIdFor(humanId);

        final homeCombineGame = buildNavalPanelCapitalHomeAndPeersGame(
          humanId: humanId,
          gameId: 'g_home_combine',
          displayName: 'Home combine tester',
          homeMission: FleetMission.patrol,
          homeShips: const [ShipInstance(id: 'ship_h', typeId: 'carrack')],
          nextShipInstanceSeq: 3,
          peerFleets: [
            Fleet(
              id: 'at_capital',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: capProvince,
              ships: const [ShipInstance(id: 'ship_v', typeId: 'fluyte')],
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        final subTransfer = wireNavalTransferForWidgetTest(
          bus: bus,
          gameSnapshot: () => homeCombineGame,
        );
        addTearDown(sub.cancel);
        addTearDown(subTransfer.cancel);

        await tester.pumpWidget(
          buildNavalPanel(
            game: homeCombineGame,
            humanPlayerId: humanId,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        await _tapFleetCheckboxes(tester, [
          'Home Fleet',
          'Fleet at_capital',
        ]);
        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();
        expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
        await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('fluyte')));
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
        const mergePort = 'oldWorld|mergeport';

        final threeGame = buildNavalPanelCapitalMergePortFleetsGame(
          humanId: humanId,
          gameId: 'g_three_combine',
          displayName: 'Three combine tester',
          includeMergePortTileKeys: false,
          nextShipInstanceSeq: 4,
          fleets: [
            _portShipFleet(
              id: 'c1',
              humanId: humanId,
              port: mergePort,
              shipId: 's1',
            ),
            _portShipFleet(
              id: 'c2',
              humanId: humanId,
              port: mergePort,
              shipId: 's2',
              typeId: 'fluyte',
            ),
            _portShipFleet(
              id: 'c3',
              humanId: humanId,
              port: mergePort,
              shipId: 's3',
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
          buildNavalPanel(game: threeGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        await _tapFleetCheckboxes(tester, [
          'Fleet c1',
          'Fleet c2',
          'Fleet c3',
        ]);
        final combineBtnFinder = find.widgetWithText(
          CtActionTextButton,
          'Combine',
        );
        await tester.scrollUntilVisible(combineBtnFinder, 120);
        await tester.pumpAndSettle();
        await tester.tap(combineBtnFinder);
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        expect(fleetsAfter.length, 1);
        final survivor = fleetsAfter.single;
        expect(survivor.id, 'c1');
        final ids = survivor.ships.map((s) => s.id).toList();
        expect(ids, ['s1', 's2', 's3']);
        expect(survivor.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Fleets in different sea zones keep Combine disabled when both checked',
      (WidgetTester tester) async {
        const humanId = 'gp_two_seas';
        const capProvince = 'oldWorld|cap1';

        final twoSeaGame = buildNavalPanelOwFleetsGame(
          gameId: 'g_two_seas',
          humanId: humanId,
          displayName: 'Two seas tester',
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
              id: 'sea_a',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: 'zone_alpha',
              inPortAtProvinceId: null,
              ships: const [ShipInstance(id: 'a1', typeId: 'carrack')],
            ),
            Fleet(
              id: 'sea_b',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: 'zone_beta',
              inPortAtProvinceId: null,
              ships: const [ShipInstance(id: 'b1', typeId: 'fluyte')],
            ),
          ],
          portsByProvinceSeaboard: {
            'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
            'oldWorld|coast|zone_beta': 'oldWorld|coast|1|0',
          },
          tileKeysByProvince: {
            capProvince: ['oldWorld|cap1|0|0'],
            'oldWorld|coast': ['oldWorld|coast|0|0'],
          },
          nextShipInstanceSeq: 2,
        );

        await tester.pumpWidget(
          buildNavalPanel(game: twoSeaGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        await _tapFleetCheckboxes(tester, ['Fleet sea_a', 'Fleet sea_b']);
        await _expectCombineEnabled(tester, enabled: false);
      },
    );

    testWidgets(
      'AC: Fleet at sea and fleet in port keep Combine disabled when both checked',
      (WidgetTester tester) async {
        const humanId = 'gp_sea_port';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final seaPortGame = buildNavalPanelOwFleetsGame(
          gameId: 'g_sea_port',
          humanId: humanId,
          displayName: 'Sea-port tester',
          capitalProvinceId: capProvince,
          oldWorldProvinces: [
            Province(
              id: 'cap1',
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Capital',
            ),
            Province(
              id: 'mergeport',
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Merge Port',
            ),
            Province(
              id: 'coast',
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Coast',
            ),
          ],
          fleets: [
            Fleet(
              id: 'at_sea',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: 'zone_alpha',
              inPortAtProvinceId: null,
              ships: const [ShipInstance(id: 's_sea', typeId: 'carrack')],
            ),
            Fleet(
              id: 'in_port',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 's_port', typeId: 'fluyte')],
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

        await tester.pumpWidget(
          buildNavalPanel(game: seaPortGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        await _tapFleetCheckboxes(tester, ['Fleet at_sea', 'Fleet in_port']);
        await _expectCombineEnabled(tester, enabled: false);
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
        final topology = buildNavalCapitalAdjacentSeaTopology();

        await tester.pumpWidget(
          buildNavalPanel(
            game: gameAdj,
            humanPlayerId: humanId,
            topology: topology,
          ),
        );
        await tester.pumpAndSettle();

        await _tapFleetCheckboxes(tester, [
          'Home Fleet',
          'Fleet sea_source',
        ]);
        await _expectCombineEnabled(tester, enabled: true);

        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();
        expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
      },
    );
  });
}
