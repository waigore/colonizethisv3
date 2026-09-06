// Pump helpers for part1 naval panel pins (Refs #4224 Slice D).

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart'
    show kCtE2EFleetMissionActionKey;
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'naval_units_panel_test_support.dart';

Future<void> pumpNavalMoveAndNarrowActionsPin(
  WidgetTester tester, {
  required Game game,
  required String humanPlayerIdWithFleets,
}) async {
  const homeId = 'gp_move_home';
  await pumpNavalPanel(
    tester,
    game: buildNavalPanelCapitalHomeAndPeersGame(
      humanId: homeId,
      gameId: 'g_move_home',
      displayName: 'Move Home Test',
      peerFleets: const [],
      homeShips: const [ShipInstance(id: 'home_ship', typeId: 'carrack')],
    ),
    humanPlayerId: homeId,
  );
  expect(
    find.descendant(
      of: find.widgetWithText(ExpansionTile, 'Home Fleet'),
      matching: find.byTooltip('Move'),
    ),
    findsNothing,
  );

  final humanId = humanPlayerIdWithFleets;
  final nonHomeFleets = navalNonHomeFleetsWithShips(game, humanId);
  if (nonHomeFleets.isEmpty) return;
  final fleetTile = find.widgetWithText(
    ExpansionTile,
    'Fleet ${nonHomeFleets.first.id}',
  );
  await pumpNavalPanel(tester, game: game, humanPlayerId: humanId);
  expect(fleetTile, findsOneWidget);
  final moveButton = find.descendant(
    of: fleetTile,
    matching: find.byTooltip('Move'),
  );
  await tester.ensureVisible(moveButton);
  await tester.tap(moveButton);
  await tester.pumpAndSettle();
  expect(find.byType(MoveFleetDialog), findsOneWidget);
  expect(tester.takeException(), isNull);

  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(320, 800));
  await pumpNavalPanel(tester, game: game, humanPlayerId: humanId);
  expect(
    find.descendant(of: fleetTile, matching: find.byIcon(Icons.route)),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: fleetTile,
      matching: find.byKey(kCtE2EFleetMissionActionKey),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(of: fleetTile, matching: find.byIcon(Icons.call_split)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: fleetTile, matching: find.text('Move')),
    findsNothing,
  );
  expect(
    find.descendant(of: fleetTile, matching: find.text('Mission')),
    findsNothing,
  );
}

Future<void> pumpNavalSplitWatcherPin(
  WidgetTester tester, {
  required Game game,
  required String humanId,
}) async {
  final observedFleetCount = ValueNotifier<int>(game.worldState.fleets.length);
  final bus = AppEventBus.create();
  final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
    observedFleetCount.value = e.game.worldState.fleets.length;
  });
  final subSplit = wireNavalSplitForWidgetTest(
    bus: bus,
    gameSnapshot: () => game,
  );
  addTearDown(() async {
    await sub.cancel();
    await subSplit.cancel();
    observedFleetCount.dispose();
  });
  final targetFleet = game.worldState.fleets.firstWhere(
    (f) => f.ownerId == humanId && f.shipTypeIds.length >= 2,
  );
  await pumpNavalPanel(
    tester,
    game: game,
    humanPlayerId: humanId,
    widget: buildNavalPanelWithFleetCountWatcher(
      game: game,
      humanPlayerId: humanId,
      bus: bus,
      observedFleetCount: observedFleetCount,
    ),
  );
  expect(
    find.text('observed-fleet-count:${game.worldState.fleets.length}'),
    findsOneWidget,
  );
  final fleet = navalFleetTileFinder(navalFleetTileLabel(targetFleet, humanId));
  await expandAndTapNavalSplit(tester, fleet);
  await confirmNavalSplitMovingFirstShip(tester, targetFleet);
  expect(
    find.text('observed-fleet-count:${game.worldState.fleets.length + 1}'),
    findsOneWidget,
  );
}

Future<void> pumpNavalHomeNeverDeletedPin(WidgetTester tester) async {
  const humanId = 'gp_home_never_deleted';
  final homeId = homeFleetIdFor(humanId);
  final updated = await pumpNavalHomeFleetTransferAll(
    tester,
    game: buildNavalPanelCapitalHomeAndPeersGame(
      humanId: humanId,
      gameId: 'g_home_never_deleted',
      displayName: 'Home never deleted tester',
      nextShipInstanceSeq: 3,
      peerFleets: [
        navalPanelPortPeer(
          id: 'donor',
          humanId: humanId,
          ships: const [ShipInstance(id: 'ship_d', typeId: 'fluyte')],
        ),
      ],
    ),
    humanId: humanId,
    fleetLabels: const ['Home Fleet', 'Fleet donor'],
    transferTypeId: 'fluyte',
  );
  final fleets = updated!.game.worldState.fleets;
  expect(fleets.where((f) => f.id == homeId), isNotEmpty);
  expect(
    (fleets.firstWhere((f) => f.id == homeId).ships.map((s) => s.id).toList()
      ..sort()),
    ['home_1', 'ship_d'],
  );
  expect(fleets.any((f) => f.id == 'donor'), isFalse);
}

Future<void> pumpNavalNonHomeSplitEmptyBlockedPin(WidgetTester tester) async {
  const humanId = 'gp_nonhome_removed';
  final g = buildNavalPanelCapitalHomeAndPeersGame(
    humanId: humanId,
    gameId: 'g_nonhome_removed',
    displayName: 'Non-home removed tester',
    nextShipInstanceSeq: 3,
    peerFleets: [
      navalPanelPortPeer(
        id: 'split_me',
        humanId: humanId,
        ships: const [ShipInstance(id: 'ship_s1', typeId: 'fluyte')],
      ),
    ],
  );
  final (bus, updated) = wireNavalFleetBusWithWire(
    wire: (b) => wireNavalSplitForWidgetTest(bus: b, gameSnapshot: () => g),
  );
  await pumpNavalPanel(tester, game: g, humanPlayerId: humanId, bus: bus);
  final fleetTile = find.widgetWithText(ExpansionTile, 'Fleet split_me');
  await expandAndTapNavalSplit(tester, fleetTile);
  final typeId = g.worldState.fleets
      .firstWhere((f) => f.id == 'split_me')
      .ships
      .single
      .typeId;
  await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne(typeId)));
  await tester.pumpAndSettle();
  expect(
    tester
        .widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Confirm Split'),
        )
        .enabled,
    isFalse,
  );
  expect(updated(), isNull);
}
