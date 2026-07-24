// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'support/naval_units_panel_test_support.dart';
import 'widget_test_assets.dart';

const _mergePort = 'oldWorld|mergeport';
const _capProvince = 'oldWorld|cap1';

Province _owProvince(String localId, String humanId, String displayName) {
  return Province(
    id: localId,
    regionId: 'oldWorld',
    ownerId: humanId,
    displayName: displayName,
  );
}

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

Fleet _seaShipFleet({
  required String id,
  required String humanId,
  required String seaZoneId,
  required String shipId,
  String typeId = 'carrack',
}) {
  return Fleet(
    id: id,
    ownerId: humanId,
    regionId: 'oldWorld',
    seaZoneId: seaZoneId,
    inPortAtProvinceId: null,
    ships: [ShipInstance(id: shipId, typeId: typeId)],
  );
}

typedef _PortShipSpec = ({String id, String shipId, String typeId});

Game _mergePortFleetsGame({
  required String humanId,
  required String gameId,
  required String displayName,
  required List<_PortShipSpec> fleets,
  int? nextShipInstanceSeq,
}) {
  return buildNavalPanelCapitalMergePortFleetsGame(
    humanId: humanId,
    gameId: gameId,
    displayName: displayName,
    includeMergePortTileKeys: false,
    nextShipInstanceSeq: nextShipInstanceSeq ?? fleets.length + 1,
    fleets: [
      for (final f in fleets)
        _portShipFleet(
          id: f.id,
          humanId: humanId,
          port: _mergePort,
          shipId: f.shipId,
          typeId: f.typeId,
        ),
    ],
  );
}

(AppEventBus, NavalFleetsUpdatedEvent? Function()) _wireFleetsUpdated() {
  NavalFleetsUpdatedEvent? updated;
  final bus = AppEventBus.create();
  final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) => updated = e);
  addTearDown(sub.cancel);
  return (bus, () => updated);
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

Future<void> _tapCombine(WidgetTester tester, {bool scroll = false}) async {
  final combineFinder = find.widgetWithText(CtActionTextButton, 'Combine');
  if (scroll) {
    await tester.scrollUntilVisible(combineFinder, 120);
    await tester.pumpAndSettle();
  } else {
    await tester.ensureVisible(combineFinder);
  }
  await tester.tap(combineFinder);
  await tester.pumpAndSettle();
}

Future<void> _pumpCheckCombineDisabled(
  WidgetTester tester, {
  required Game game,
  required String humanId,
  required List<String> fleetLabels,
}) async {
  await pumpNavalPanel(tester, game: game, humanPlayerId: humanId);
  await _tapFleetCheckboxes(tester, fleetLabels);
  await _expectCombineEnabled(tester, enabled: false);
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
        final selectAllGame = _mergePortFleetsGame(
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
      final combineGame = _mergePortFleetsGame(
        humanId: humanId,
        gameId: 'g_combine_count',
        displayName: 'Combine tester',
        fleets: const [
          (id: 'test_fleet_1', shipId: 'ship_1', typeId: 'carrack'),
          (id: 'test_fleet_2', shipId: 'ship_2', typeId: 'fluyte'),
        ],
      );

      final (bus, updated) = _wireFleetsUpdated();
      await pumpNavalPanel(
        tester,
        game: combineGame,
        humanPlayerId: humanId,
        bus: bus,
      );
      await _tapFleetCheckboxes(tester, [
        'Fleet test_fleet_1',
        'Fleet test_fleet_2',
      ]);
      await _tapCombine(tester);

      expect(updated(), isNotNull);
      final fleetsAfter = updated()!.game.worldState.fleets;
      final merged = fleetsAfter.firstWhere((f) => f.id == 'test_fleet_1');
      final mergedIds = merged.ships.map((s) => s.id).toList()..sort();
      expect(mergedIds, ['ship_1', 'ship_2']);
      expect(fleetsAfter.any((f) => f.id == 'test_fleet_2'), isFalse);
    });

    for (final case_
        in <
          ({
            String name,
            String humanId,
            Game Function() build,
            List<String> labels,
          })
        >[
          (
            name:
                'AC: Fleets at different locations keep Combine disabled when both checked',
            humanId: 'gp_diff_loc',
            build: () {
              const humanId = 'gp_diff_loc';
              return buildNavalPanelOwFleetsGame(
                gameId: 'g_diff_loc',
                humanId: humanId,
                displayName: 'Diff-loc tester',
                capitalProvinceId: _capProvince,
                oldWorldProvinces: [
                  _owProvince('cap1', humanId, 'Capital'),
                  _owProvince('port_a', humanId, 'Port A'),
                  _owProvince('port_b', humanId, 'Port B'),
                ],
                fleets: [
                  _portShipFleet(
                    id: 'fa',
                    humanId: humanId,
                    port: 'oldWorld|port_a',
                    shipId: 'ship_1',
                  ),
                  _portShipFleet(
                    id: 'fb',
                    humanId: humanId,
                    port: 'oldWorld|port_b',
                    shipId: 'ship_2',
                    typeId: 'fluyte',
                  ),
                ],
                tileKeysByProvince: {
                  _capProvince: ['oldWorld|cap1|0|0'],
                },
                nextShipInstanceSeq: 3,
              );
            },
            labels: const ['Fleet fa', 'Fleet fb'],
          ),
          (
            name:
                'AC: Fleets in different sea zones keep Combine disabled when both checked',
            humanId: 'gp_two_seas',
            build: () {
              const humanId = 'gp_two_seas';
              return buildNavalPanelOwFleetsGame(
                gameId: 'g_two_seas',
                humanId: humanId,
                displayName: 'Two seas tester',
                capitalProvinceId: _capProvince,
                oldWorldProvinces: [
                  _owProvince('coast', humanId, 'Coast'),
                  _owProvince('cap1', humanId, 'Capital'),
                ],
                fleets: [
                  _seaShipFleet(
                    id: 'sea_a',
                    humanId: humanId,
                    seaZoneId: 'zone_alpha',
                    shipId: 'a1',
                  ),
                  _seaShipFleet(
                    id: 'sea_b',
                    humanId: humanId,
                    seaZoneId: 'zone_beta',
                    shipId: 'b1',
                    typeId: 'fluyte',
                  ),
                ],
                portsByProvinceSeaboard: {
                  'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
                  'oldWorld|coast|zone_beta': 'oldWorld|coast|1|0',
                },
                tileKeysByProvince: {
                  _capProvince: ['oldWorld|cap1|0|0'],
                  'oldWorld|coast': ['oldWorld|coast|0|0'],
                },
                nextShipInstanceSeq: 2,
              );
            },
            labels: const ['Fleet sea_a', 'Fleet sea_b'],
          ),
          (
            name:
                'AC: Fleet at sea and fleet in port keep Combine disabled when both checked',
            humanId: 'gp_sea_port',
            build: () {
              const humanId = 'gp_sea_port';
              return buildNavalPanelOwFleetsGame(
                gameId: 'g_sea_port',
                humanId: humanId,
                displayName: 'Sea-port tester',
                capitalProvinceId: _capProvince,
                oldWorldProvinces: [
                  _owProvince('cap1', humanId, 'Capital'),
                  _owProvince('mergeport', humanId, 'Merge Port'),
                  _owProvince('coast', humanId, 'Coast'),
                ],
                fleets: [
                  _seaShipFleet(
                    id: 'at_sea',
                    humanId: humanId,
                    seaZoneId: 'zone_alpha',
                    shipId: 's_sea',
                  ),
                  _portShipFleet(
                    id: 'in_port',
                    humanId: humanId,
                    port: _mergePort,
                    shipId: 's_port',
                    typeId: 'fluyte',
                  ),
                ],
                portsByProvinceSeaboard: {
                  'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
                },
                tileKeysByProvince: {
                  _capProvince: ['oldWorld|cap1|0|0'],
                  'oldWorld|coast': ['oldWorld|coast|0|0'],
                },
                nextShipInstanceSeq: 3,
              );
            },
            labels: const ['Fleet at_sea', 'Fleet in_port'],
          ),
        ]) {
      testWidgets(case_.name, (WidgetTester tester) async {
        await _pumpCheckCombineDisabled(
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
            _portShipFleet(
              id: 'at_capital',
              humanId: humanId,
              port: _capProvince,
              shipId: 'ship_v',
              typeId: 'fluyte',
            ),
          ],
        );

        final (bus, updated) = _wireFleetsUpdated();
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

        await _tapFleetCheckboxes(tester, ['Home Fleet', 'Fleet at_capital']);
        await _tapCombine(tester);
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
        final threeGame = _mergePortFleetsGame(
          humanId: humanId,
          gameId: 'g_three_combine',
          displayName: 'Three combine tester',
          fleets: const [
            (id: 'c1', shipId: 's1', typeId: 'carrack'),
            (id: 'c2', shipId: 's2', typeId: 'fluyte'),
            (id: 'c3', shipId: 's3', typeId: 'carrack'),
          ],
        );

        final (bus, updated) = _wireFleetsUpdated();
        await pumpNavalPanel(
          tester,
          game: threeGame,
          humanPlayerId: humanId,
          bus: bus,
        );
        await _tapFleetCheckboxes(tester, ['Fleet c1', 'Fleet c2', 'Fleet c3']);
        await _tapCombine(tester, scroll: true);

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

        await _tapFleetCheckboxes(tester, ['Home Fleet', 'Fleet sea_source']);
        await _expectCombineEnabled(tester, enabled: true);
        await _tapCombine(tester);
        expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
      },
    );
  });
}
