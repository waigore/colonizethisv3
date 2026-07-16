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

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
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
import 'panel_test_fixtures.dart';
import 'units_panel_test_shared.dart';

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
  return buildNavalPanelCapitalHomeAndPeersGame(
    humanId: humanId,
    gameId: 'g_ship_labels',
    displayName: 'Ship Label Tester',
    peerFleets: const [],
    homeShips: const [ShipInstance(id: 'h1', typeId: 'carrack')],
  );
}

/// OW capital + optional extra provinces / fleets for naval panel scenarios
/// (Refs #4013 densify of `naval_units_panel_part{3,4}_test.dart`).
Game buildNavalPanelOwFleetsGame({
  required String gameId,
  required String humanId,
  required String displayName,
  required List<Province> oldWorldProvinces,
  required List<Fleet> fleets,
  String? capitalProvinceId,
  Map<String, List<String>> tileKeysByProvince = const {},
  Map<String, String> portsByProvinceSeaboard = const {},
  Map<String, String> seaZoneDisplayNameById = const {},
  int? nextShipInstanceSeq,
  int treasury = 0,
}) {
  final player = capitalProvinceId == null
      ? Player(
          id: humanId,
          displayName: displayName,
          isHuman: true,
          treasury: treasury,
        )
      : Player(
          id: humanId,
          displayName: displayName,
          isHuman: true,
          capitalProvinceId: capitalProvinceId,
          capitalTile: CapitalTile(
            regionId: 'oldWorld',
            provinceId: capitalProvinceId,
            x: 0,
            y: 0,
          ),
          treasury: treasury,
        );
  return Game(
    id: gameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: const RegionData(),
      fleets: fleets,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
      seaZoneDisplayNameById: seaZoneDisplayNameById,
      tileKeysByRegionAndProvince: {'oldWorld': tileKeysByProvince},
      nextShipInstanceSeq: nextShipInstanceSeq ?? 1,
    ),
    players: [player],
  );
}

/// Capital province owned by [humanId] with a home fleet plus peer fleets.
Game buildNavalPanelCapitalHomeAndPeersGame({
  required String humanId,
  required String gameId,
  required String displayName,
  required List<Fleet> peerFleets,
  List<ShipInstance> homeShips = const [
    ShipInstance(id: 'home_1', typeId: 'carrack'),
  ],
  FleetMission homeMission = FleetMission.none,
  String capitalLocalId = 'cap1',
  int? nextShipInstanceSeq,
}) {
  final capProvince = 'oldWorld|$capitalLocalId';
  final homeId = homeFleetIdFor(humanId);
  return buildNavalPanelOwFleetsGame(
    gameId: gameId,
    humanId: humanId,
    displayName: displayName,
    capitalProvinceId: capProvince,
    oldWorldProvinces: [
      Province(
        id: capitalLocalId,
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'Capital',
      ),
    ],
    fleets: [
      Fleet(
        id: homeId,
        ownerId: humanId,
        regionId: 'oldWorld',
        inPortAtProvinceId: capProvince,
        ships: homeShips,
        mission: homeMission,
      ),
      ...peerFleets,
    ],
    tileKeysByProvince: {
      capProvince: ['$capProvince|0|0'],
    },
    nextShipInstanceSeq: nextShipInstanceSeq,
  );
}

/// Capital + merge-port provinces with fleets typically berthed at the merge port.
///
/// When [includeMergePortTileKeys] is false, only the capital province has a
/// locate tile key so merge-port fleet rows are not wrapped in a locate
/// [InkWell] (widget tests need taps to reach [ExpansionTile] / checkboxes).
Game buildNavalPanelCapitalMergePortFleetsGame({
  required String humanId,
  required String gameId,
  required String displayName,
  required List<Fleet> fleets,
  String capitalLocalId = 'cap1',
  String mergePortLocalId = 'mergeport',
  String mergePortDisplayName = 'Merge Port',
  int? nextShipInstanceSeq,
  bool playerHasCapital = true,
  bool includeMergePortTileKeys = true,
}) {
  final capProvince = 'oldWorld|$capitalLocalId';
  final mergePort = 'oldWorld|$mergePortLocalId';
  final provinces = <Province>[
    if (playerHasCapital)
      Province(
        id: capitalLocalId,
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'Capital',
      ),
    Province(
      id: mergePortLocalId,
      regionId: 'oldWorld',
      ownerId: humanId,
      displayName: mergePortDisplayName,
    ),
  ];
  return buildNavalPanelOwFleetsGame(
    gameId: gameId,
    humanId: humanId,
    displayName: displayName,
    capitalProvinceId: playerHasCapital ? capProvince : null,
    oldWorldProvinces: provinces,
    fleets: fleets,
    tileKeysByProvince: {
      if (playerHasCapital) capProvince: ['$capProvince|0|0'],
      if (includeMergePortTileKeys) mergePort: ['$mergePort|0|0'],
    },
    nextShipInstanceSeq: nextShipInstanceSeq,
  );
}

/// Single sea-fleet game (no capital) for location-scope / auto-close pins.
Game buildNavalPanelSingleSeaFleetGame({
  required String humanId,
  required String gameId,
  required String displayName,
  String fleetId = 'f1',
  String seaZoneId = 's1',
  String shipId = 'ship_1',
  String shipTypeId = 'frigate',
}) {
  return buildNavalPanelOwFleetsGame(
    gameId: gameId,
    humanId: humanId,
    displayName: displayName,
    oldWorldProvinces: const [],
    fleets: [
      Fleet(
        id: fleetId,
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: seaZoneId,
        ships: [ShipInstance(id: shipId, typeId: shipTypeId)],
      ),
    ],
  );
}

/// Empty-world human with no fleets (empty-state message pins).
Game buildNavalPanelEmptyHumanGame({
  String humanId = 'p_empty',
  String gameId = 'empty_naval',
  String displayName = 'Solo',
}) {
  return buildNavalPanelOwFleetsGame(
    gameId: gameId,
    humanId: humanId,
    displayName: displayName,
    oldWorldProvinces: const [],
    fleets: const [],
  );
}

/// Beachhead-mission sea fleet for status-line pins.
Game buildNavalPanelBeachheadMissionGame({
  String humanId = 'p_beach',
  String gameId = 'beach_test',
  String fleetId = 'bf1',
  String seaZoneId = 'atlantic',
}) {
  return Game(
    id: gameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(units: []),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: fleetId,
          ownerId: humanId,
          regionId: 'oldWorld',
          seaZoneId: seaZoneId,
          shipTypeIds: const ['carrack'],
          mission: FleetMission.beachhead,
        ),
      ],
      portsByProvinceSeaboard: {
        'oldWorld|lisbon|$seaZoneId': 'oldWorld|lisbon|0|0',
      },
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
        },
      },
    ),
    players: [Player(id: humanId, displayName: 'P', isHuman: true)],
  );
}

/// Capital province adjacent to a named sea zone (Combine adjacency cases;
/// shared via [buildUnitsPanelCapitalAdjacentSeaTopology], Refs #4021).
MapTopology buildNavalCapitalAdjacentSeaTopology({
  String capitalNodeId = 'oldWorld|cap1',
  String seaZoneId = 'zone_alpha',
  bool includeEdge = true,
}) {
  return buildUnitsPanelCapitalAdjacentSeaTopology(
    capitalNodeId: capitalNodeId,
    seaZoneId: seaZoneId,
    includeEdge: includeEdge,
  );
}

/// Two OW sea zones linked for Move / scoped auto-close cases.
MapTopology buildNavalTwoSeaZonesTopology({
  String fromZoneId = 'oldWorld|s1',
  String toZoneId = 'oldWorld|s2',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: fromZoneId,
        regionId: fromZoneId.split('|').first,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: toZoneId,
        regionId: toZoneId.split('|').first,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: fromZoneId, id2: toZoneId)],
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

/// Home + at-sea fleet with a draft-move target display name (part5 subtitle).
Game buildNavalPanelDraftMoveSubtitleGame({
  String humanId = 'gp_draft_line',
  String gameId = 'g_draft_line',
  String capitalLocalId = 'capital',
  String seaFleetId = 'f_at_sea',
  String seaZoneId = 'sz0',
  String destinationZoneId = 'sz1',
  String destinationDisplayName = 'Target Sea',
}) {
  final capProvince = 'oldWorld|$capitalLocalId';
  return buildNavalPanelOwFleetsGame(
    gameId: gameId,
    humanId: humanId,
    displayName: 'P',
    capitalProvinceId: capProvince,
    oldWorldProvinces: [
      Province(
        id: capitalLocalId,
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'Capital',
      ),
    ],
    fleets: [
      Fleet(
        id: homeFleetIdFor(humanId),
        ownerId: humanId,
        regionId: 'oldWorld',
        inPortAtProvinceId: capProvince,
        ships: const [],
      ),
      Fleet(
        id: seaFleetId,
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: seaZoneId,
        ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
      ),
    ],
    seaZoneDisplayNameById: {
      'oldWorld|$destinationZoneId': destinationDisplayName,
    },
  );
}
