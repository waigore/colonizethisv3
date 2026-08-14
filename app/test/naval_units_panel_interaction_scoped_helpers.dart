// Naval panel scoped/autoclose/transfer interaction helpers (Refs #4352 Slice D).
// SPEC: SPEC/ui/naval-units-panel.md; SPEC/program/repo-lint.md.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'naval_panel_combine_tables.dart';
import 'naval_units_panel_host_helpers.dart';
import 'naval_units_panel_scoped_harness.dart';
import 'naval_units_panel_interaction_tile_helpers.dart';
import 'naval_units_panel_test_scenarios.dart';
import 'naval_units_panel_wire_helpers.dart';
import 'units_panel_test_shared.dart';

Future<void> pumpNavalAutocloseScenario(
  WidgetTester tester,
  NavalPanelAutocloseCase case_,
) async {
  final (bus, closeEvents) = await pumpNavalAutocloseCase(
    tester,
    humanId: case_.humanId,
    gameId: case_.gameId,
    displayName: case_.displayName,
    locationScopeKey: case_.locationScopeKey,
    topology: case_.topology,
    removeFleetOnNextFrame: case_.removeFleetOnNextFrame,
  );
  if (case_.expectFleetRow) {
    expect(find.textContaining('Fleet f1'), findsOneWidget);
  }
  if (case_.emitMove) await emitNavalScopedMove(tester, bus, case_.humanId);
  expect(closeEvents.length, case_.closeCount);
}

(AppEventBus bus, List<ClosePanelEvent> events) wireNavalClosePanelCapture() {
  final events = <ClosePanelEvent>[];
  final bus = AppEventBus.create();
  final sub = bus.on<ClosePanelEvent>().listen(events.add);
  addTearDown(sub.cancel);
  return (bus, events);
}

Future<void> pumpNavalScopedHarness(
  WidgetTester tester, {
  required Game game,
  required String humanPlayerId,
  required AppEventBus bus,
  required MapTopology topology,
  required String? locationScopeKey,
  bool removeFleetOnNextFrame = false,
}) async {
  await tester.pumpWidget(
    ScopedNavalPanelHarness(
      game: game,
      humanPlayerId: humanPlayerId,
      bus: bus,
      topology: topology,
      locationScopeKey: locationScopeKey,
      removeFleetOnNextFrame: removeFleetOnNextFrame,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> emitNavalScopedMove(
  WidgetTester tester,
  AppEventBus bus,
  String humanId,
) async {
  bus.emit(
    NavalMoveFleetRequestedEvent(
      humanPlayerId: humanId,
      moveOrder: const NavalMoveOrder(
        fleetId: 'f1',
        destinationSeaZoneId: 'oldWorld|s2',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<(AppEventBus, List<ClosePanelEvent>)> pumpNavalAutocloseCase(
  WidgetTester tester, {
  required String humanId,
  required String gameId,
  required String displayName,
  String? locationScopeKey = 'sea:oldWorld|s1',
  MapTopology? topology,
  bool removeFleetOnNextFrame = false,
}) async {
  final (bus, closeEvents) = wireNavalClosePanelCapture();
  await pumpNavalScopedHarness(
    tester,
    game: buildNavalPanelSingleSeaFleetGame(
      humanId: humanId,
      gameId: gameId,
      displayName: displayName,
    ),
    humanPlayerId: humanId,
    bus: bus,
    topology: topology ?? buildNavalTwoSeaZonesTopology(),
    locationScopeKey: locationScopeKey,
    removeFleetOnNextFrame: removeFleetOnNextFrame,
  );
  return (bus, closeEvents);
}

List<Fleet> navalNonHomeFleetsWithShips(Game game, String humanId) {
  return game.worldState.fleets
      .where(
        (f) =>
            f.ownerId == humanId &&
            f.shipTypeIds.isNotEmpty &&
            f.id != homeFleetIdFor(humanId),
      )
      .toList();
}

Fleet navalPanelPortPeer({
  required String id,
  required String humanId,
  required List<ShipInstance> ships,
  String port = kNavalPanelCapProvince,
}) => Fleet(
  id: id,
  ownerId: humanId,
  regionId: 'oldWorld',
  inPortAtProvinceId: port,
  ships: ships,
);

Future<void> pumpNavalHomePartialTransfer(
  WidgetTester tester, {
  required String humanId,
}) async {
  var gameState = buildNavalPanelHomeAdjacentSeaSourceGame(
    humanId: humanId,
    gameId: 'g_${humanId}_partial_transfer',
  );
  final homeId = homeFleetIdFor(humanId);
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
    topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
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
  expect(homeFleet.ships.map((s) => s.id).toSet().contains('src_1'), isTrue);
  expect(sourceFleet.ships.map((s) => s.id).toSet().contains('src_1'), isFalse);
  expect(sourceFleet.ships.map((s) => s.id).toSet().contains('src_2'), isTrue);
}
