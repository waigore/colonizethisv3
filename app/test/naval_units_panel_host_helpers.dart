// Naval panel widget-test host/pump helpers (Refs #3730, #4305).
//
// SPEC: SPEC/ui/naval-units-panel.md; SPEC/program/repo-lint.md.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';

import 'app_shell_harness.dart';
import 'naval_units_panel_test_scenarios.dart';
import 'units_panel_test_shared.dart';

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
  int overseasCargoUsed = 0,
  bool isCargoUsedReliable = true,
  bool cargoNotDefined = false,
}) {
  final resolvedBus = bus ?? AppEventBus.create();
  return buildPanelScaffoldShell(
    NavalUnitsPanel(
      game: game,
      humanPlayerId: humanPlayerId,
      bus: resolvedBus,
      topology: topology,
      draftOrders: draftOrders,
      locationScopeKey: locationScopeKey,
      overseasCargoUsed: overseasCargoUsed,
      isCargoUsedReliable: isCargoUsedReliable,
      cargoNotDefined: cargoNotDefined,
    ),
  );
}

/// Pumps [buildNavalPanel] (or an optional prebuilt [widget]) and settles.
///
/// Canonical naval panel pump for naval panel suites — do not
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
  int overseasCargoUsed = 0,
  bool isCargoUsedReliable = true,
  bool cargoNotDefined = false,
}) async {
  await pumpSettledWidget(
    tester,
    widget ??
        buildNavalPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          bus: bus,
          topology: topology,
          draftOrders: draftOrders,
          locationScopeKey: locationScopeKey,
          overseasCargoUsed: overseasCargoUsed,
          isCargoUsedReliable: isCargoUsedReliable,
          cargoNotDefined: cargoNotDefined,
        ),
  );
}

Future<void> pumpNavalMockupFidelityPanel(
  WidgetTester tester, {
  required Game game,
  String humanPlayerId = kNavalMockupFidelityHumanId,
}) async {
  await pumpNavalPanel(
    tester,
    game: game,
    humanPlayerId: humanPlayerId,
    widget: buildPanelScaffoldShell(
      NavalUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
        topology: const MapTopology(),
      ),
      viewport: const Size(480, 720),
    ),
  );
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
  return buildPanelScaffoldShell(
    NavalUnitsPanel(
      game: game,
      humanPlayerId: humanPlayerId,
      bus: bus ?? AppEventBus.create(),
      topology: topology,
    ),
    viewport: size,
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
