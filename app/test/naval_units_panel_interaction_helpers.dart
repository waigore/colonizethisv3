// Naval panel widget-test interaction helpers (Refs #3730, #4305).
//
// SPEC: SPEC/ui/naval-units-panel.md; SPEC/program/repo-lint.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'app_shell_harness.dart';
import 'naval_panel_combine_tables.dart';
import 'naval_units_panel_host_helpers.dart';
import 'naval_units_panel_scoped_harness.dart';
import 'naval_units_panel_test_scenarios.dart';
import 'naval_units_panel_wire_helpers.dart';
import 'units_panel_test_shared.dart';
/// ExpansionTile finder for a fleet row label.
Finder navalFleetTileFinder(String label) =>
    find.widgetWithText(ExpansionTile, label);

Future<void> expandNavalFleetTile(
  WidgetTester tester,
  Finder fleetFinder,
) async {
  await tester.ensureVisible(fleetFinder);
  await tester.tap(fleetFinder);
  await tester.pumpAndSettle();
}

/// Wired locate bus + captured [LocateMapTileEvent] list (Refs #4021 densify).
(AppEventBus bus, List<LocateMapTileEvent> events) wireNavalLocateCaptureBus() {
  final events = <LocateMapTileEvent>[];
  final bus = AppEventBus.create();
  bus.on<LocateMapTileEvent>().listen(events.add);
  return (bus, events);
}

Future<bool> tapLocateOnNavalFleetTile(
  WidgetTester tester,
  Finder fleetTile,
) async {
  await tester.ensureVisible(fleetTile);
  final locateFinder = find.descendant(
    of: fleetTile,
    matching: find.byTooltip('Locate fleet'),
  );
  if (locateFinder.evaluate().isEmpty) return false;
  await tester.ensureVisible(locateFinder.first);
  await tester.tap(locateFinder.first, warnIfMissed: false);
  await tester.pumpAndSettle();
  return true;
}

Future<void> expandAndTapNavalSplit(
  WidgetTester tester,
  Finder fleetFinder,
) async {
  await expandNavalFleetTile(tester, fleetFinder);
  final splitButton = find.descendant(
    of: fleetFinder,
    matching: find.byTooltip('Split'),
  );
  expect(splitButton, findsOneWidget);
  await tester.tap(splitButton);
  await tester.pumpAndSettle();
}

Future<void> expandAndExpectNavalSplit(
  WidgetTester tester,
  Finder fleetFinder,
) async {
  await expandNavalFleetTile(tester, fleetFinder);
  expect(
    find.descendant(of: fleetFinder, matching: find.byTooltip('Split')),
    findsOneWidget,
  );
}

Future<void> confirmNavalSplitMovingFirstShip(
  WidgetTester tester,
  Fleet targetFleet,
) async {
  final moveTypeId = targetFleet.ships.first.typeId;
  await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne(moveTypeId)));
  await tester.pumpAndSettle();
  final confirmSplit = find.text('Confirm Split');
  expect(confirmSplit, findsOneWidget);
  await tester.tap(confirmSplit);
  await tester.pumpAndSettle();
}

(AppEventBus, NavalFleetsUpdatedEvent? Function()) wireNavalSplitUpdatedBus({
  required Game Function() gameSnapshot,
}) =>
    wireNavalFleetBusWithWire(
      wire: (bus) =>
          wireNavalSplitForWidgetTest(bus: bus, gameSnapshot: gameSnapshot),
    );

(AppEventBus, NavalFleetsUpdatedEvent? Function()) wireNavalFleetsUpdatedCapture() {
  NavalFleetsUpdatedEvent? updated;
  final bus = AppEventBus.create();
  final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) => updated = e);
  addTearDown(sub.cancel);
  return (bus, () => updated);
}

Future<void> tapNavalFleetCheckboxes(
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

void expectNavalCombineEnabled(
  WidgetTester tester, {
  required bool enabled,
}) {
  expect(
    tester
        .widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        )
        .enabled,
    enabled,
  );
}

Future<void> tapNavalConfirmTransfer(
  WidgetTester tester, {
  String? moveAllTypeId,
  String? moveOneTypeId,
}) async {
  if (moveAllTypeId != null) {
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll(moveAllTypeId)));
    await tester.pumpAndSettle();
  } else if (moveOneTypeId != null) {
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne(moveOneTypeId)));
    await tester.pumpAndSettle();
  }
  final confirmTransfer = find.widgetWithText(CtNinePatchButton, 'Transfer');
  expect(confirmTransfer, findsOneWidget);
  final confirmTransferButton = tester.widget<CtNinePatchButton>(
    confirmTransfer,
  );
  expect(confirmTransferButton.enabled, isTrue);
  expect(confirmTransferButton.onPressed, isNotNull);
  confirmTransferButton.onPressed!.call();
  await tester.pumpAndSettle();
}

Future<NavalFleetsUpdatedEvent?> pumpNavalHomeFleetTransferAll(
  WidgetTester tester, {
  required Game game,
  required String humanId,
  required List<String> fleetLabels,
  required String transferTypeId,
}) async {
  final (bus, updated) = wireNavalFleetsUpdatedCapture();
  final subTransfer = wireNavalTransferForWidgetTest(
    bus: bus,
    gameSnapshot: () => game,
  );
  addTearDown(subTransfer.cancel);
  await pumpNavalPanel(
    tester,
    game: game,
    humanPlayerId: humanId,
    bus: bus,
  );
  await tapNavalFleetCheckboxes(tester, fleetLabels);
  await tapNavalCombine(tester);
  expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
  await tapNavalConfirmTransfer(
    tester,
    moveAllTypeId: transferTypeId,
  );
  return updated();
}

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

void expectNavalCombineOutcome(
  NavalFleetsUpdatedEvent? updated,
  NavalPanelCombineOutcomeCase case_,
) {
  expect(updated, isNotNull);
  final fleetsAfter = updated!.game.worldState.fleets;
  if (case_.expectedFleetCount != null) {
    expect(fleetsAfter.length, case_.expectedFleetCount);
  }
  final survivor = fleetsAfter.firstWhere((f) => f.id == case_.expectedSurvivorId);
  final shipIds = survivor.ships.map((s) => s.id).toList()..sort();
  final expected = [...case_.expectedShipIds]..sort();
  expect(shipIds, expected);
  expect(survivor.mission, case_.expectedSurvivorMission);
}

Future<void> tapNavalCombine(
  WidgetTester tester, {
  bool scroll = false,
}) async {
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

Future<void> pumpNavalCheckCombineDisabled(
  WidgetTester tester, {
  required Game game,
  required String humanId,
  required List<String> fleetLabels,
  MapTopology topology = const MapTopology(),
}) async {
  await pumpNavalPanel(
    tester,
    game: game,
    humanPlayerId: humanId,
    topology: topology,
  );
  await tapNavalFleetCheckboxes(tester, fleetLabels);
  expectNavalCombineEnabled(tester, enabled: false);
}

Future<NavalFleetsUpdatedEvent?> pumpNavalTapCheckCombine(
  WidgetTester tester, {
  required Game game,
  required String humanId,
  required List<String> labels,
  bool scroll = false,
  bool? expectCombineEnabled,
}) async {
  final (bus, latest) = wireNavalFleetsUpdatedCapture();
  await pumpNavalPanel(tester, game: game, humanPlayerId: humanId, bus: bus);
  await tapNavalFleetCheckboxes(tester, labels, scroll: scroll);
  if (expectCombineEnabled != null) {
    expectNavalCombineEnabled(tester, enabled: expectCombineEnabled);
  }
  await tapNavalCombine(tester, scroll: scroll);
  return latest();
}

Future<void> pumpNavalCombineOutcomeCase(
  WidgetTester tester,
  NavalPanelCombineOutcomeCase case_,
) async {
  if (case_.pinCollapsedSplitToolbar) {
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
        findsOneWidget,
      );
    }
    await tapNavalFleetCheckboxes(tester, case_.labels);
    expect(
      find.descendant(of: tileA, matching: find.byTooltip('Split')),
      findsOneWidget,
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

(AppEventBus, NavalFleetsUpdatedEvent? Function()) wireNavalFleetBusWithWire({
  required StreamSubscription<dynamic> Function(AppEventBus bus) wire,
}) {
  NavalFleetsUpdatedEvent? updated;
  final bus = AppEventBus.create();
  addTearDown(
    bus.on<NavalFleetsUpdatedEvent>().listen((e) {
      updated = e;
    }).cancel,
  );
  addTearDown(wire(bus).cancel);
  return (bus, () => updated);
}

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
  final homeFleet =
      gameState.worldState.fleets.firstWhere((f) => f.id == homeId);
  final sourceFleet =
      gameState.worldState.fleets.firstWhere((f) => f.id == 'sea_source');
  expect(homeFleet.ships.map((s) => s.id).toSet().contains('src_1'), isTrue);
  expect(sourceFleet.ships.map((s) => s.id).toSet().contains('src_1'), isFalse);
  expect(sourceFleet.ships.map((s) => s.id).toSet().contains('src_2'), isTrue);
}
