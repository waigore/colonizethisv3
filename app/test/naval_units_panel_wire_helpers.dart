// Naval panel widget-test bus wire helpers (Refs #3730, #4305).
//
// SPEC: SPEC/ui/naval-units-panel.md; SPEC/program/repo-lint.md.

import 'dart:async';

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show applyNavalSplitFleet, applyNavalTransferShipsBetweenFleets;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'app_shell_harness.dart';

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
