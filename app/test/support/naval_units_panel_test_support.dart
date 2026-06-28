// Shared widget-test scaffolding for the `NavalUnitsPanel` test family.
//
// The five `app/test/naval_units_panel_part*_test.dart` files each previously
// re-declared identical top-level `wireNavalSplitForWidgetTest` /
// `wireNavalTransferForWidgetTest` event bridges plus an identical local
// `buildPanel(...)` closure that wraps `NavalUnitsPanel` in a plain
// `MaterialApp` > `Scaffold`. Consolidating them here keeps each part file's
// per-test fixtures and assertions local while removing the copy-pasted shell
// and bus wiring.
//
// Refs #3730 (consolidate app test scaffolding; partN shared setup).
// SPEC: SPEC/ui/naval-units-panel.md (panel behavior under test),
// SPEC/program/repo-lint.md (test static-analysis scope).

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show applyNavalSplitFleet, applyNavalTransferShipsBetweenFleets;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';

/// Mirrors the running shell's handling of [NavalSplitFleetRequestedEvent] for
/// widget tests: applies [applyNavalSplitFleet] to the latest game snapshot and
/// re-emits the result as a [NavalFleetsUpdatedEvent] so the panel rebuilds.
///
/// [gameSnapshot] is read lazily on each event so callers can mutate their
/// local game reference between interactions. The returned subscription should
/// be cancelled by the test (e.g. via `addTearDown`).
StreamSubscription<NavalSplitFleetRequestedEvent> wireNavalSplitForWidgetTest({
  required AppEventBus bus,
  required Game Function() gameSnapshot,
}) {
  return bus.on<NavalSplitFleetRequestedEvent>().listen((e) {
    final next = applyNavalSplitFleet(
      game: gameSnapshot(),
      humanPlayerId: e.humanPlayerId,
      originalFleetId: e.originalFleetId,
      shipInstanceIdsToNewFleet: e.shipInstanceIdsToNewFleet,
    );
    bus.emit(NavalFleetsUpdatedEvent(game: next));
  });
}

/// Mirrors the running shell's handling of [NavalTransferShipsRequestedEvent]
/// for widget tests: applies [applyNavalTransferShipsBetweenFleets] to the
/// latest game snapshot and re-emits a [NavalFleetsUpdatedEvent].
///
/// See [wireNavalSplitForWidgetTest] for the [gameSnapshot]/teardown contract.
StreamSubscription<NavalTransferShipsRequestedEvent>
wireNavalTransferForWidgetTest({
  required AppEventBus bus,
  required Game Function() gameSnapshot,
}) {
  return bus.on<NavalTransferShipsRequestedEvent>().listen((e) {
    final next = applyNavalTransferShipsBetweenFleets(
      game: gameSnapshot(),
      humanPlayerId: e.humanPlayerId,
      sourceFleetId: e.sourceFleetId,
      targetFleetId: e.targetFleetId,
      shipInstanceIdsToTransfer: e.shipInstanceIdsToTransfer,
    );
    bus.emit(NavalFleetsUpdatedEvent(game: next));
  });
}

/// Builds the canonical [NavalUnitsPanel] host used across the panel's widget
/// tests: a plain [MaterialApp] > [Scaffold] wrapping the panel. When [bus] is
/// omitted a fresh [AppEventBus] is created so tests that do not need to drive
/// events still get a valid bus.
Widget buildNavalPanel({
  required Game game,
  required String humanPlayerId,
  AppEventBus? bus,
  MapTopology topology = const MapTopology(),
  Orders draftOrders = const Orders(),
  String? locationScopeKey,
}) {
  final resolvedBus = bus ?? AppEventBus.create();
  return MaterialApp(
    home: Scaffold(
      body: NavalUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: resolvedBus,
        topology: topology,
        draftOrders: draftOrders,
        locationScopeKey: locationScopeKey,
      ),
    ),
  );
}
