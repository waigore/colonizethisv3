// Shared widget-test scaffolding for the `NavalUnitsPanel` test family.
//
// The five `app/test/naval_units_panel_part*_test.dart` files each previously
// re-declared identical top-level `wireNavalSplitForWidgetTest` /
// `wireNavalTransferForWidgetTest` event bridges plus an identical local
// `buildPanel(...)` closure that wraps `NavalUnitsPanel` in a
// `buildAppShell` > `Scaffold`. Consolidating them here keeps each part file's
// per-test fixtures and assertions local while removing the copy-pasted shell
// and bus wiring.
//
// Refs #3730 (consolidate app test scaffolding; partN shared setup).
// SPEC: SPEC/ui/naval-units-panel.md (panel behavior under test),
// SPEC/program/repo-lint.md (test static-analysis scope).

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        applyNavalSplitFleet,
        applyNavalTransferShipsBetweenFleets,
        homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

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
/// tests: editorial-monocle [buildAppShell] > [Scaffold] wrapping the panel.
/// When [bus] is omitted a fresh [AppEventBus] is created so tests that do not
/// need to drive events still get a valid bus.
Widget buildNavalPanel({
  required Game game,
  required String humanPlayerId,
  AppEventBus? bus,
  MapTopology topology = const MapTopology(),
  Orders draftOrders = const Orders(),
  String? locationScopeKey,
}) {
  final resolvedBus = bus ?? AppEventBus.create();
  return buildAppShell(
    child: Scaffold(
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

/// Home-fleet-only game for part1 default assertions (single Split tooltip).
/// Refs #3656: lightweight fixture replaces procedural map generation.
Game buildNavalPanelHomeFleetOnlyGame() {
  final base = buildNavalPanelTestGame();
  final homeFleet = base.worldState.fleets.firstWhere(
    (f) => f.inPortAtProvinceId != null,
  );
  return base.copyWith(
    worldState: base.worldState.copyWith(fleets: [homeFleet]),
  );
}

/// Minimal sea-fleet game whose zone label comes from [seaZoneDisplayNameById].
Game buildNavalPanelNamedSeaZoneGame({
  String humanId = 'gp_named_sea',
  String zoneId = 'zone_alpha',
  String displayName = 'Caribbean Sea',
}) {
  const capProvince = 'oldWorld|cap1';
  return Game(
    id: 'named-sea',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: 'cap1',
            regionId: 'oldWorld',
            ownerId: humanId,
            displayName: 'Capital',
          ),
        ],
      ),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: 'sea_named',
          ownerId: humanId,
          regionId: 'oldWorld',
          seaZoneId: zoneId,
          ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
        ),
      ],
      seaZoneDisplayNameById: {'oldWorld|$zoneId': displayName},
      portsByProvinceSeaboard: const {
        'oldWorld|cap1|zone_alpha': 'oldWorld|cap1|0|0',
      },
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          capProvince: ['oldWorld|cap1|0|0'],
        },
      },
    ),
    players: [
      Player(
        id: humanId,
        displayName: 'Named Sea Tester',
        isHuman: true,
        capitalProvinceId: capProvince,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: capProvince,
          x: 0,
          y: 0,
        ),
      ),
    ],
  );
}

/// Single home-fleet game used for ship-type display-name composition asserts.
Game buildNavalPanelShipLabelGame({String humanId = 'gp_ship_display'}) {
  const capProvince = 'oldWorld|cap1';
  final homeId = homeFleetIdFor(humanId);
  return Game(
    id: 'g_ship_labels',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: 'cap1',
            regionId: 'oldWorld',
            ownerId: humanId,
            displayName: 'Capital',
          ),
        ],
      ),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: homeId,
          ownerId: humanId,
          regionId: 'oldWorld',
          inPortAtProvinceId: capProvince,
          ships: const [ShipInstance(id: 'h1', typeId: 'carrack')],
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          capProvince: ['oldWorld|cap1|0|0'],
        },
      },
    ),
    players: [
      Player(
        id: humanId,
        displayName: 'Ship Label Tester',
        isHuman: true,
        capitalProvinceId: capProvince,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: capProvince,
          x: 0,
          y: 0,
        ),
      ),
    ],
  );
}
