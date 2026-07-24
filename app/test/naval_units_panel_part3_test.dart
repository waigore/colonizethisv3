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

import 'naval_units_panel_test_support.dart';
import 'widget_test_assets.dart';

const String _mergePort = 'oldWorld|mergeport';

Future<void> _tapFleetCheckboxes(
  WidgetTester tester,
  Iterable<String> fleetLabels, {
  bool scroll = false,
}) async {
  for (final label in fleetLabels) {
    late final Finder cb;
    if (scroll) {
      final title = find.text(label);
      await tester.scrollUntilVisible(title, 120);
      await tester.pumpAndSettle();
      final tile = find.ancestor(
        of: title,
        matching: find.byType(ExpansionTile),
      );
      cb = find.descendant(of: tile, matching: find.byType(Checkbox));
      await tester.scrollUntilVisible(cb, 120);
      await tester.pumpAndSettle();
    } else {
      final tile = find.widgetWithText(ExpansionTile, label);
      expect(tile, findsOneWidget);
      cb = find.descendant(of: tile, matching: find.byType(Checkbox));
    }
    await tester.ensureVisible(cb);
    await tester.tap(cb);
    await tester.pumpAndSettle();
  }
}

Future<void> _tapCombine(WidgetTester tester) async {
  final combine = find.widgetWithText(CtActionTextButton, 'Combine');
  await tester.scrollUntilVisible(combine, 120);
  await tester.pumpAndSettle();
  await tester.tap(combine);
  await tester.pumpAndSettle();
}

void _expectCombineEnabled(WidgetTester tester, {required bool enabled}) {
  expect(
    tester
        .widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        )
        .enabled,
    enabled,
  );
}

(AppEventBus, NavalFleetsUpdatedEvent? Function()) _wireFleetsUpdated() {
  NavalFleetsUpdatedEvent? updated;
  final bus = AppEventBus.create();
  addTearDown(
    bus.on<NavalFleetsUpdatedEvent>().listen((e) => updated = e).cancel,
  );
  return (bus, () => updated);
}

Fleet _pf(
  String id,
  String humanId,
  String shipId,
  String typeId, {
  FleetMission mission = FleetMission.none,
}) => Fleet(
  id: id,
  ownerId: humanId,
  regionId: 'oldWorld',
  inPortAtProvinceId: _mergePort,
  ships: [ShipInstance(id: shipId, typeId: typeId)],
  mission: mission,
);

Game _mergePortGame({
  required String humanId,
  required String gameId,
  required String displayName,
  required List<Fleet> fleets,
  bool playerHasCapital = true,
  int nextShipInstanceSeq = 3,
}) => buildNavalPanelCapitalMergePortFleetsGame(
  humanId: humanId,
  gameId: gameId,
  displayName: displayName,
  playerHasCapital: playerHasCapital,
  nextShipInstanceSeq: nextShipInstanceSeq,
  fleets: fleets,
);

Game _sameSeaCombineGame({required String humanId}) {
  const capProvince = 'oldWorld|cap1';
  return buildNavalPanelOwFleetsGame(
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
}

Future<NavalFleetsUpdatedEvent?> _pumpCheckCombine(
  WidgetTester tester, {
  required Game game,
  required String humanId,
  required List<String> labels,
  bool scroll = false,
  bool? expectCombineEnabled,
}) async {
  final (bus, latest) = _wireFleetsUpdated();
  await pumpNavalPanel(tester, game: game, humanPlayerId: humanId, bus: bus);
  await _tapFleetCheckboxes(tester, labels, scroll: scroll);
  if (expectCombineEnabled != null) {
    _expectCombineEnabled(tester, enabled: expectCombineEnabled);
  }
  await _tapCombine(tester);
  return latest();
}

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

        await _tapFleetCheckboxes(tester, ['Home Fleet', 'Fleet sea_source']);
        await _tapCombine(tester);

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

        await _tapFleetCheckboxes(tester, ['Home Fleet', 'Fleet sea_far']);
        _expectCombineEnabled(tester, enabled: false);
      },
    );

    testWidgets('AC: combine same-sea + mission-clear survivors', (
      WidgetTester tester,
    ) async {
      const sameSeaId = 'gp_same_sea_combine';
      final sameSea = await _pumpCheckCombine(
        tester,
        game: _sameSeaCombineGame(humanId: sameSeaId),
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
      final cleared = await _pumpCheckCombine(
        tester,
        game: _mergePortGame(
          humanId: missionId,
          gameId: 'g_mission_clear',
          displayName: 'Mission clear tester',
          fleets: [
            _pf(
              'm1',
              missionId,
              'ms1',
              'carrack',
              mission: FleetMission.patrol,
            ),
            _pf(
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

        // No capital => no synthetic Home Fleet row; select-all stays one locality.
        final partialGame = _mergePortGame(
          humanId: humanId,
          gameId: 'g_partial_header',
          displayName: 'Partial header tester',
          playerHasCapital: false,
          nextShipInstanceSeq: 4,
          fleets: [
            _pf('p1', humanId, 'ps1', 'carrack'),
            _pf('p2', humanId, 'ps2', 'fluyte'),
            _pf('p3', humanId, 'ps3', 'carrack'),
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

        _expectCombineEnabled(tester, enabled: true);
      },
    );

    testWidgets(
      'AC: Three-fleet combine survivor is first in panel order regardless of check order',
      (WidgetTester tester) async {
        const humanId = 'gp_reverse_check';
        final updated = await _pumpCheckCombine(
          tester,
          game: _mergePortGame(
            humanId: humanId,
            gameId: 'g_reverse_check',
            displayName: 'Reverse check tester',
            nextShipInstanceSeq: 4,
            fleets: [
              _pf('r1', humanId, 'rs1', 'carrack'),
              _pf('r2', humanId, 'rs2', 'fluyte'),
              _pf('r3', humanId, 'rs3', 'carrack'),
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

        Game gameWithKeepDrop(String keep, String drop) => _mergePortGame(
          humanId: humanId,
          gameId: 'g_prune_two',
          displayName: 'Prune tester',
          fleets: [
            _pf(keep, humanId, 'ks1', 'carrack'),
            _pf(drop, humanId, 'ks2', 'fluyte'),
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
        await _tapFleetCheckboxes(tester, ['Fleet stays', 'Fleet removed']);

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
        _expectCombineEnabled(tester, enabled: false);
      },
    );

    testWidgets(
      'AC: Collapsed rows keep inline Split action while checkbox selection works',
      (WidgetTester tester) async {
        const humanId = 'gp_collapsed_cb';
        final collapsedGame = _mergePortGame(
          humanId: humanId,
          gameId: 'g_collapsed_cb',
          displayName: 'Collapsed cb tester',
          fleets: [
            _pf('col_a', humanId, 'cs1', 'carrack'),
            _pf('col_b', humanId, 'cs2', 'fluyte'),
          ],
        );

        final (bus, latest) = _wireFleetsUpdated();
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

        await _tapFleetCheckboxes(tester, ['Fleet col_a', 'Fleet col_b']);
        expect(
          find.descendant(of: tileA, matching: find.byTooltip('Split')),
          findsOne,
        );
        await _tapCombine(tester);

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
