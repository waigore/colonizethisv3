// Shared widget-test scaffolding for the `NavalUnitsPanel` test family
// (Refs #3730, #4048). Host, pump, wire, and locate helpers.
// Scenario Games: naval_units_panel_test_scenarios.dart.
//
// SPEC: SPEC/ui/naval-units-panel.md; SPEC/program/repo-lint.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        applyNavalSplitFleet,
        applyNavalTransferShipsBetweenFleets,
        homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';

import 'app_shell_harness.dart';

export 'naval_units_panel_test_scenarios.dart';
export 'units_panel_test_shared.dart';

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

/// Pumps [buildNavalPanel] (or an optional prebuilt [widget]) and settles.
///
/// Canonical naval panel pump for `naval_units_panel_part*_test.dart` — do not
/// re-declare a local `_pumpNaval` / `pumpNaval` in part suites (Refs #4035).
Future<void> pumpNavalPanel(
  WidgetTester tester, {
  required Game game,
  required String humanPlayerId,
  AppEventBus? bus,
  MapTopology topology = const MapTopology(),
  Orders draftOrders = const Orders(),
  String? locationScopeKey,
  Widget? widget,
}) async {
  await tester.pumpWidget(
    widget ??
        buildNavalPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          bus: bus,
          topology: topology,
          draftOrders: draftOrders,
          locationScopeKey: locationScopeKey,
        ),
  );
  await tester.pumpAndSettle();
}

/// Panel ExpansionTile title for [fleet] owned by [humanId].
String navalFleetTileLabel(Fleet fleet, String humanId) {
  return fleet.id == homeFleetIdFor(humanId)
      ? 'Home Fleet'
      : 'Fleet ${fleet.id}';
}

/// Appends [extraFleets] onto [base] (dual-region / locate inject helpers).
Game withNavalPanelExtraFleets(Game base, List<Fleet> extraFleets) {
  return base.copyWith(
    worldState: base.worldState.copyWith(
      fleets: [...base.worldState.fleets, ...extraFleets],
    ),
  );
}

/// Drops fleets the panel would treat as Home Fleet at [humanId]'s capital.
Game withoutNavalPanelCapitalHomeFleets(Game base, String humanId) {
  final player = base.players.firstWhere(
    (p) => p.id == humanId,
    orElse: () => base.players.first,
  );
  final capitalTile = player.capitalTile;
  if (capitalTile == null) {
    return base;
  }
  final capitalParts = capitalTile.toTileKey().split('|');
  final capitalRegionId = capitalParts[0];
  final capitalProvinceLocalId = capitalParts[1];
  final filtered = base.worldState.fleets.where((f) {
    if (f.ownerId != humanId) return true;
    if (f.isAtSea) return true;
    final inPortId = f.inPortAtProvinceId;
    if (inPortId == null) return true;
    return !(f.regionId == capitalRegionId &&
        (inPortId == capitalProvinceLocalId ||
            inPortId == '$capitalRegionId|$capitalProvinceLocalId'));
  }).toList();
  return base.copyWith(worldState: base.worldState.copyWith(fleets: filtered));
}

/// First non-capital province with a resolvable locate tile key, if any.
({Province province, String tileKey})? firstNavalNonCapitalLocateTarget(
  Game game,
  String humanId,
) {
  final player = game.players.firstWhere(
    (p) => p.id == humanId,
    orElse: () => game.players.first,
  );
  final capitalTile = player.capitalTile;
  if (capitalTile == null) return null;
  final capitalRegionId = capitalTile.toTileKey().split('|').first;

  for (final province in [
    ...game.worldState.oldWorld.provinces,
    ...game.worldState.newWorld.provinces,
  ]) {
    if (province.regionId == capitalRegionId) continue;
    final tileKey = navalProvinceLocateTileKey(game, province);
    if (tileKey == null) continue;
    return (province: province, tileKey: tileKey);
  }
  return null;
}

/// Mirrors production `tileKeyForProvinceLocation` selection for locate pins.
String? navalProvinceLocateTileKey(Game game, Province province) {
  if (province.townTileKey != null && province.townTileKey!.isNotEmpty) {
    return province.townTileKey;
  }
  final byProvince =
      game.worldState.tileKeysByRegionAndProvince[province.regionId];
  final prefixedId = '${province.regionId}|${province.id}';
  final tiles = byProvince?[prefixedId] ?? byProvince?[province.id];
  if (tiles != null && tiles.isNotEmpty) return tiles.first;
  return null;
}

/// Wide viewport shell so [UnitsPanelShell] can exceed the 400dp base width.
///
/// Composes [buildAppShell] (editorial-monocle) rather than a raw [MaterialApp]
/// host (Refs #4035 AC4).
Widget buildNavalPanelWideViewport({
  required Game game,
  required String humanPlayerId,
  Size size = const Size(1400, 900),
  AppEventBus? bus,
  MapTopology topology = const MapTopology(),
}) {
  return buildAppShell(
    viewport: size,
    child: Scaffold(
      body: NavalUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: bus ?? AppEventBus.create(),
        topology: topology,
      ),
    ),
  );
}

/// Panel host plus an external fleet-count watcher for cross-panel event pins.
///
/// Composes [buildAppShell] (editorial-monocle) rather than a raw [MaterialApp]
/// host (Refs #4035 AC4).
Widget buildNavalPanelWithFleetCountWatcher({
  required Game game,
  required String humanPlayerId,
  required AppEventBus bus,
  required ValueNotifier<int> observedFleetCount,
}) {
  return buildAppShell(
    child: Scaffold(
      body: Column(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: observedFleetCount,
            builder: (context, count, _) => Text('observed-fleet-count:$count'),
          ),
          Expanded(
            child: NavalUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              bus: bus,
              topology: const MapTopology(),
            ),
          ),
        ],
      ),
    ),
  );
}

