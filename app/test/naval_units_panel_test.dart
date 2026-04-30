// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        applyNavalSplitFleet,
        applyNavalTransferShipsBetweenFleets,
        homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

part 'naval_units_panel_test_body_part.g.dart';

/// Mirrors shell handling of [NavalSplitFleetRequestedEvent] for widget tests.
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

/// Mirrors shell handling of [NavalTransferShipsRequestedEvent] for widget tests.
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


void main() {
  _defineTests();
}
