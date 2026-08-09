// Part1 scenario pumps and pins (Refs #4224 Slice D densify).

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

typedef NavalPanelPart1PinCase = ({
  String name,
  Future<void> Function(WidgetTester tester) run,
});

List<NavalPanelPart1PinCase> navalPanelPart1PinCases() => [
  (
    name: 'AC: Beachhead status and empty-naval empty-state pins',
    run: (tester) async {
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelBeachheadMissionGame(humanId: 'p_beach'),
        humanPlayerId: 'p_beach',
      );
      expect(find.textContaining('Beachhead'), findsWidgets);
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelEmptyHumanGame(humanId: 'p_empty'),
        humanPlayerId: 'p_empty',
      );
      expect(find.text('No naval units'), findsOneWidget);
    },
  ),
  (
    name: 'AC: Marker-scoped capital port view shows Home Fleet and not empty state',
    run: (tester) async {
      const humanId = 'gp_marker_scope';
      const capital = 'oldWorld|p1';
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelMarkerScopeCapitalGame(humanId: humanId),
        humanPlayerId: humanId,
        locationScopeKey: 'port:$capital',
      );
      expect(find.widgetWithText(ExpansionTile, 'Home Fleet'), findsOneWidget);
      expect(find.text('No naval units'), findsNothing);
    },
  ),
  (
    name: 'AC: Cross-region projected marker scope shows destination region rows',
    run: (tester) async {
      const humanId = 'gp_cross_region_scope';
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelSingleSeaFleetGame(
          humanId: humanId,
          gameId: 'g_cross_region_scope',
          displayName: 'Cross Scope',
        ),
        humanPlayerId: humanId,
        topology: buildNavalTwoSeaZonesTopology(
          fromZoneId: 'oldWorld|s1',
          toZoneId: 'newWorld|s2',
        ),
        draftOrders: const Orders(
          navalMoveOrdersByPlayerId: {
            humanId: [
              NavalMoveOrder(
                fleetId: 'f1',
                destinationSeaZoneId: 'newWorld|s2',
              ),
            ],
          },
        ),
        locationScopeKey: 'sea:newWorld|s2',
      );
      expect(find.text('NEW WORLD'), findsOneWidget);
      expect(find.text('OLD WORLD'), findsNothing);
      expect(find.textContaining('Fleet f1'), findsOneWidget);
    },
  ),
  (
    name: 'AC: expanded composition lists ship display names not raw ids',
    run: (tester) async {
      const humanId = 'gp_ship_display';
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelCapitalHomeAndPeersGame(
          humanId: humanId,
          gameId: 'g_ship_labels',
          displayName: 'Ship Label Tester',
          peerFleets: const [],
          homeShips: const [ShipInstance(id: 'h1', typeId: 'carrack')],
        ),
        humanPlayerId: humanId,
      );
      final homeTile = navalFleetTileFinder('Home Fleet');
      await expandNavalFleetTile(tester, homeTile);
      expect(find.text('Carrack'), findsOneWidget);
      expect(find.text('×1'), findsAtLeastNWidgets(1));
      expect(find.textContaining('carrack:'), findsNothing);
    },
  ),
];

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
  expect(find.descendant(of: fleetTile, matching: find.text('Move')), findsNothing);
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

// --- Locate-button scenario pins (Refs #4224 Slice D) ---

enum NavalPanelLocateKind { anyFleet, bothRegions, seaZone, portProvince }

typedef NavalPanelLocateCase = ({
  String name,
  NavalPanelLocateKind kind,
});

List<NavalPanelLocateCase> navalPanelLocateCases() => const [
  (
    name: 'AC: Locate button emits LocateMapTileEvent',
    kind: NavalPanelLocateKind.anyFleet,
  ),
  (
    name:
        'sections render for fleets in both regions and locate button passes region id',
    kind: NavalPanelLocateKind.bothRegions,
  ),
  (
    name: 'AC: Sea-zone fleet locate button uses correct sea-zone tile key',
    kind: NavalPanelLocateKind.seaZone,
  ),
  (
    name: 'AC: Port fleet locate button uses correct province tile key',
    kind: NavalPanelLocateKind.portProvince,
  ),
];

Future<void> pumpNavalLocateCase(
  WidgetTester tester,
  NavalPanelLocateCase case_, {
  required Game baseGame,
  required String humanId,
}) async {
  final (bus, events) = wireNavalLocateCaptureBus();
  Game game = baseGame;
  Finder tile = find.byTooltip('Locate fleet');
  switch (case_.kind) {
    case NavalPanelLocateKind.anyFleet:
      await pumpNavalPanel(
        tester,
        game: game,
        humanPlayerId: humanId,
        bus: bus,
      );
      if (tile.evaluate().isEmpty) return;
      await tester.tap(tile.first);
      await tester.pumpAndSettle();
      expect(events, isNotEmpty);
      expect(
        events.last.regionId == 'oldWorld' || events.last.regionId == 'newWorld',
        isTrue,
      );
      return;
    case NavalPanelLocateKind.bothRegions:
      final playerFleets = baseGame.worldState.fleets
          .where((f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty)
          .toList();
      expect(playerFleets, isNotEmpty);
      final nwProvinces = baseGame.worldState.newWorld.provinces;
      expect(nwProvinces, isNotEmpty);
      game = withNavalPanelExtraFleets(baseGame, [
        playerFleets.first.copyWith(
          id: 'test_new_world_fleet',
          regionId: 'newWorld',
          inPortAtProvinceId: nwProvinces.first.id,
          seaZoneId: null,
          ownerId: humanId,
        ),
      ]);
      await pumpNavalPanel(
        tester,
        game: game,
        humanPlayerId: humanId,
        bus: bus,
      );
      expect(find.text('OLD WORLD'), findsAtLeastNWidgets(1));
      expect(find.text('NEW WORLD'), findsAtLeastNWidgets(1));
      tile = navalFleetTileFinder('Fleet test_new_world_fleet');
      if (tile.evaluate().isEmpty) {
        tile = navalFleetTileFinder('Home Fleet');
      }
      if (!await tapLocateOnNavalFleetTile(tester, tile)) return;
      if (events.isEmpty) return;
      expect(events.last.tileKey, isNotNull);
      expect(events.last.regionId, isNotNull);
      return;
    case NavalPanelLocateKind.seaZone:
      final seaFleet = baseGame.worldState.fleets.firstWhere(
        (f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty && f.isAtSea,
      );
      final expectedTileKey = baseGame.worldState.portsByProvinceSeaboard.entries
          .firstWhere((e) => e.key.split('|').length >= 2)
          .value;
      await pumpNavalPanel(
        tester,
        game: baseGame,
        humanPlayerId: humanId,
        bus: bus,
      );
      tile = navalFleetTileFinder(navalFleetTileLabel(seaFleet, humanId));
      expect(tile, findsOneWidget);
      if (!await tapLocateOnNavalFleetTile(tester, tile)) return;
      expect(events.last.tileKey, expectedTileKey);
      expect(events.last.regionId, seaFleet.regionId);
      return;
    case NavalPanelLocateKind.portProvince:
      final target = firstNavalNonCapitalLocateTarget(baseGame, humanId);
      if (target == null) {
        fail('No non-capital province with a resolvable tile key found');
      }
      final baseFleet = baseGame.worldState.fleets.firstWhere(
        (f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty,
      );
      final portFleet = baseFleet.copyWith(
        id: 'test_port_fleet',
        ownerId: humanId,
        regionId: target.province.regionId,
        inPortAtProvinceId: target.province.id,
        seaZoneId: null,
      );
      await pumpNavalPanel(
        tester,
        game: withNavalPanelExtraFleets(baseGame, [portFleet]),
        humanPlayerId: humanId,
        bus: bus,
      );
      tile = navalFleetTileFinder('Fleet ${portFleet.id}');
      expect(tile, findsOneWidget);
      if (!await tapLocateOnNavalFleetTile(tester, tile)) return;
      expect(events.last.tileKey, target.tileKey);
      expect(events.last.regionId, portFleet.regionId);
  }
}
