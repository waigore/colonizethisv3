// Shared widget-test scaffolding for the `MilitaryUnitsPanel` test family.
//
// The `MilitaryUnitsPanel` test files (`military_units_panel_test.dart`,
// `_display_test.dart`, `_army_test.dart`, `_army_split_test.dart`) each
// previously re-declared an identical local `buildPanel(...)` closure (a
// `buildAppShell` > `Scaffold` host for `MilitaryUnitsPanel`), identical
// `expandFirstArmyExpansion` / `expandAllArmyExpansions` `ExpansionTile`
// helpers, and an `ArmySplitTestHarness` widget that mirrors the running
// shell's `ArmySplitRequestedEvent` handling (hosted via [pumpArmySplitHarness] >
// [buildAppShell]). Consolidating them here keeps each test file's per-test
// fixtures and assertions local while removing the copy-pasted shell, tree
// helpers, and bus wiring.
//
// Refs #3730 (consolidate app test scaffolding; shared family setup).
// SPEC: SPEC/ui/military-units-panel.md (panel behavior under test),
// SPEC/program/repo-lint.md (test static-analysis scope).

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart' show applyArmySplit;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';

import 'app_shell_harness.dart';
import 'panel_fixtures/core.dart';
import 'units_panel_test_shared.dart';

/// Builds the canonical [MilitaryUnitsPanel] host used across the panel's
/// widget tests: editorial-monocle [buildAppShell] > [Scaffold] wrapping the
/// panel. When [bus] is omitted a fresh [AppEventBus] is created so tests that
/// do not need to drive events still get a valid bus.
Widget buildMilitaryPanel({
  required Game game,
  required String humanPlayerId,
  AppEventBus? bus,
  MapTopology? topology,
  Orders draftOrders = const Orders(),
}) {
  return buildAppShell(
    child: Scaffold(
      body: MilitaryUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: bus ?? AppEventBus.create(),
        topology: topology ?? const MapTopology(),
        draftOrders: draftOrders,
      ),
    ),
  );
}

/// Minimal province + tile-key lookup game for
/// `tileKeyForProvinceLocation` edge cases (Refs #4013).
Game buildMilitaryProvinceTileLookupGame({
  String id = 'min',
  String regionId = 'oldWorld',
  String provinceId = 'p1',
  String tileKey = 'oldWorld|p1|0|0',
  String? ownerId,
}) {
  final prefixedId = '$regionId|$provinceId';
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: regionId,
            ownerId: ownerId,
            townTileKey: null,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        regionId: {
          prefixedId: [tileKey],
        },
      },
    ),
    players: const [],
  );
}

/// Sea-zone fleet display scenario shared by military panel display asserts
/// (Refs #4013 densify of `military_units_panel_display_test.dart`).
Game buildMilitarySeaFleetDisplayGame({
  required String id,
  required String playerId,
  required List<String> shipTypeIds,
  required FleetMission mission,
  String seaZoneId = 'atlantic',
  String fleetId = 'fleet1',
  bool includeLisbonProvince = false,
  String playerDisplayName = 'Test',
}) {
  const provinceId = 'lisbon';
  const tileKey = 'oldWorld|lisbon|0|0';
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        units: const [],
        provinces: includeLisbonProvince
            ? [
                Province(
                  id: provinceId,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                ),
              ]
            : const [],
      ),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: fleetId,
          ownerId: playerId,
          regionId: 'oldWorld',
          seaZoneId: seaZoneId,
          shipTypeIds: shipTypeIds,
          mission: mission,
        ),
      ],
      portsByProvinceSeaboard: const {
        'oldWorld|lisbon|atlantic': tileKey,
      },
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          'oldWorld|lisbon': [tileKey],
        },
      },
    ),
    players: [
      Player(id: playerId, displayName: playerDisplayName, isHuman: true),
    ],
  );
}

/// Land-army display scenario at `oldWorld|lisbon` (medals / status pins).
Game buildMilitaryArmyAtLisbonDisplayGame({
  required String id,
  required String playerId,
  required String armyId,
  required List<Unit> units,
  String playerDisplayName = 'Test',
}) {
  const provinceId = 'oldWorld|lisbon';
  const tileKey = 'oldWorld|lisbon|0|0';
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        units: units,
        provinces: [
          Province(
            id: provinceId,
            regionId: 'oldWorld',
            ownerId: playerId,
            townTileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      fleets: const [],
      armies: [
        Army(
          id: armyId,
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: provinceId,
          regimentUnitIds: units.map((u) => u.id).toList(growable: false),
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          provinceId: [tileKey],
        },
      },
    ),
    players: [
      Player(id: playerId, displayName: playerDisplayName, isHuman: true),
    ],
  );
}

/// Home-army-at-capital scenario for split-UI / shell harness smoke (Refs #4013).
Game buildMilitaryHomeArmyAtCapitalGame({
  required String id,
  required String playerId,
  required List<String> regimentIds,
  String capitalProvinceId = 'oldWorld|cap',
  String townTileKey = 'tk_cap',
  String armyId = 'home_army',
  int nextArmySeq = 1,
  String playerDisplayName = 'Splitter',
  String regimentType = kPanelTestRegimentType,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: capitalProvinceId,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: 'Capital',
            townTileKey: townTileKey,
          ),
        ],
        units: [
          for (final regimentId in regimentIds)
            Unit(
              id: regimentId,
              type: regimentType,
              ownerId: playerId,
              locationProvinceId: capitalProvinceId,
            ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [
        Army(
          id: armyId,
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: capitalProvinceId,
          regimentUnitIds: List<String>.from(regimentIds),
          isHomeArmy: true,
        ),
      ],
      nextArmySeq: nextArmySeq,
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          capitalProvinceId: [townTileKey],
        },
      },
    ),
    players: [
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: true,
        capitalProvinceId: capitalProvinceId,
      ),
    ],
  );
}

/// Adjacent OW province pair topology for army move / locate / invasion tests
/// (Refs #4013 densify of `military_units_panel_army_test.dart`; shared via
/// [buildUnitsPanelAdjacentOwProvincesTopology], Refs #4021).
MapTopology buildMilitaryAdjacentOwProvincesTopology({
  String fromProvinceId = 'oldWorld|p2',
  String toProvinceId = 'oldWorld|p3',
  String regionId = 'oldWorld',
}) {
  return buildUnitsPanelAdjacentOwProvincesTopology(
    fromProvinceId: fromProvinceId,
    toProvinceId: toProvinceId,
    regionId: regionId,
  );
}

/// Sea-fleet location header uses [seaZoneDisplayNameById] (Refs #4021).
Game buildMilitarySeaZoneLabelGame({
  String id = 'g_mil_sea_label',
  String humanId = 'gp_mil_sea_label',
  String capitalProvinceId = 'oldWorld|c1',
  String capitalLocalId = 'c1',
  String seaZoneId = 'zone_x',
  String seaZoneDisplayName = 'Mil Named Sea',
  String playerDisplayName = 'Mil Sea Tester',
}) {
  return buildPanelTestGame(
    id: id,
    players: [
      buildUnitsPanelHumanPlayer(
        id: humanId,
        displayName: playerDisplayName,
        capitalProvinceId: capitalProvinceId,
      ),
    ],
    oldWorldProvinces: [
      Province(
        id: capitalLocalId,
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'Cap',
      ),
    ],
    fleets: [
      Fleet(
        id: 'f_at_sea',
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: seaZoneId,
        ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
      ),
    ],
    seaZoneDisplayNameById: {'oldWorld|$seaZoneId': seaZoneDisplayName},
  );
}

/// Field army + named province for regiment/army display name pins (Refs #4021).
Game buildMilitaryProvinceDisplayNamesGame({
  String id = 'g_display_mil',
  String playerId = 'gp_display_names',
  String provinceLocal = 'lisbon',
  String provinceDisplayName = 'Lisbon Harbor',
  String regimentId = 'levy1',
  String regimentType = 'peasant_levies',
  String armyId = 'army_field',
  String playerDisplayName = 'Tester',
}) {
  final fullProvince = 'oldWorld|$provinceLocal';
  final townTile = 'oldWorld|$provinceLocal|0|0';
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        units: [
          Unit(
            id: regimentId,
            type: regimentType,
            ownerId: playerId,
            locationProvinceId: fullProvince,
            medals: 0,
            status: UnitStatus.idle,
          ),
        ],
        provinces: [
          Province(
            id: fullProvince,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: provinceDisplayName,
            townTileKey: townTile,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [
        Army(
          id: armyId,
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: fullProvince,
          regimentUnitIds: [regimentId],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          fullProvince: [townTile],
        },
      },
    ),
    players: [
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: true,
        capitalProvinceId: fullProvince,
      ),
    ],
  );
}

/// Two non-home armies at one owned province (Combine bus-event scenario).
Game buildMilitaryTwoFieldArmiesAtProvinceGame({
  required String id,
  required String playerId,
  String provinceId = 'oldWorld|p2',
  String townTileKey = 'tk',
  String armyIdA = 'ax',
  String armyIdB = 'ay',
  String regimentIdA = 'uu1',
  String regimentIdB = 'uu2',
  String capitalProvinceId = 'oldWorld|cap',
  String playerDisplayName = 'C',
  String regimentType = 'musketeers',
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: 'oldWorld',
            ownerId: playerId,
            townTileKey: townTileKey,
          ),
        ],
        units: [
          Unit(
            id: regimentIdA,
            type: regimentType,
            ownerId: playerId,
            locationProvinceId: provinceId,
          ),
          Unit(
            id: regimentIdB,
            type: regimentType,
            ownerId: playerId,
            locationProvinceId: provinceId,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [
        Army(
          id: armyIdA,
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: provinceId,
          regimentUnitIds: [regimentIdA],
          isHomeArmy: false,
        ),
        Army(
          id: armyIdB,
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: provinceId,
          regimentUnitIds: [regimentIdB],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          provinceId: [townTileKey],
        },
      },
    ),
    players: [
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: true,
        capitalProvinceId: capitalProvinceId,
      ),
    ],
  );
}

/// Field army at [stationProvinceId] with an adjacent owned dest for Move/Locate.
Game buildMilitaryFieldArmyWithAdjacentOwnedGame({
  required String id,
  required String playerId,
  required String armyId,
  required List<String> regimentUnitIds,
  String stationProvinceId = 'oldWorld|p2',
  String adjacentProvinceId = 'oldWorld|p3',
  String? stationTownTileKey = 'tk',
  String? stationDisplayName,
  String? adjacentDisplayName,
  String playerDisplayName = 'M',
  String regimentType = 'musketeers',
  bool includeTileKeysAndVisibility = true,
}) {
  final stationTile = '$stationProvinceId|0|0';
  final adjacentTile = '$adjacentProvinceId|0|0';
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: stationProvinceId,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: stationDisplayName,
            townTileKey: stationTownTileKey,
          ),
          Province(
            id: adjacentProvinceId,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: adjacentDisplayName,
          ),
        ],
        units: [
          for (final regimentId in regimentUnitIds)
            Unit(
              id: regimentId,
              type: regimentType,
              ownerId: playerId,
              locationProvinceId: stationProvinceId,
            ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [
        Army(
          id: armyId,
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: stationProvinceId,
          regimentUnitIds: List<String>.from(regimentUnitIds),
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: includeTileKeysAndVisibility
          ? {
              'oldWorld': {
                stationProvinceId: [stationTile],
                adjacentProvinceId: [adjacentTile],
              },
            }
          : const {},
      playerVisibilityByTile: includeTileKeysAndVisibility
          ? {
              playerId: {
                stationTile: 'fullyVisible',
                adjacentTile: 'fullyVisible',
              },
            }
          : const {},
    ),
    players: [
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: true,
        capitalProvinceId: stationProvinceId,
      ),
    ],
  );
}

/// Cross-region OW+NW owned destinations for MoveArmyDialog faction grouping.
Game buildMilitaryCrossRegionOwnedMoveGame({
  required String id,
  required String playerId,
  String armyId = 'amove',
  String regimentId = 'u1',
  String fromProvinceId = 'oldWorld|p2',
  String oldDestProvinceId = 'oldWorld|p3',
  String newDestProvinceId = 'newWorld|n2',
  String fromDisplayName = 'From',
  String oldDestDisplayName = 'Old Port',
  String newDestDisplayName = 'New Port',
  String fromTownTileKey = 'tk_from',
  String playerDisplayName = 'Grouped',
  String regimentType = 'musketeers',
}) {
  final fromTile = '$fromProvinceId|0|0';
  final oldDestTile = '$oldDestProvinceId|0|0';
  final newDestTile = '$newDestProvinceId|0|0';
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: fromProvinceId,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: fromDisplayName,
            townTileKey: fromTownTileKey,
          ),
          Province(
            id: oldDestProvinceId,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: oldDestDisplayName,
          ),
        ],
        units: [
          Unit(
            id: regimentId,
            type: regimentType,
            ownerId: playerId,
            locationProvinceId: fromProvinceId,
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(
            id: newDestProvinceId,
            regionId: 'newWorld',
            ownerId: playerId,
            displayName: newDestDisplayName,
          ),
        ],
      ),
      armies: [
        Army(
          id: armyId,
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: fromProvinceId,
          regimentUnitIds: [regimentId],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          fromProvinceId: [fromTile],
          oldDestProvinceId: [oldDestTile],
        },
        'newWorld': {
          newDestProvinceId: [newDestTile],
        },
      },
      playerVisibilityByTile: {
        playerId: {
          fromTile: 'fullyVisible',
          oldDestTile: 'fullyVisible',
          newDestTile: 'fullyVisible',
        },
      },
    ),
    players: [
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: true,
        capitalProvinceId: fromProvinceId,
      ),
    ],
  );
}

/// Adjacent hostile province for invasion declare-war confirm (empty relations).
Game buildMilitaryInvasionAdjacentHostileGame({
  required String id,
  required String playerId,
  required String enemyId,
  String armyId = 'ainv',
  String regimentId = 'ui1',
  String stationProvinceId = 'oldWorld|p2',
  String hostileProvinceId = 'oldWorld|p3',
  String hostileDisplayName = 'Hostile',
  String playerDisplayName = 'Inv',
  String enemyDisplayName = 'Enemy',
  String regimentType = 'musketeers',
}) {
  final stationTile = '$stationProvinceId|0|0';
  final hostileTile = '$hostileProvinceId|0|0';
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: stationProvinceId,
            regionId: 'oldWorld',
            ownerId: playerId,
          ),
          Province(
            id: hostileProvinceId,
            regionId: 'oldWorld',
            ownerId: enemyId,
            displayName: hostileDisplayName,
          ),
        ],
        units: [
          Unit(
            id: regimentId,
            type: regimentType,
            ownerId: playerId,
            locationProvinceId: stationProvinceId,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [
        Army(
          id: armyId,
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: stationProvinceId,
          regimentUnitIds: [regimentId],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          stationProvinceId: [stationTile],
          hostileProvinceId: [hostileTile],
        },
      },
      playerVisibilityByTile: {
        playerId: {
          stationTile: 'fullyVisible',
          hostileTile: 'fullyVisible',
        },
      },
    ),
    players: [
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: true,
        capitalProvinceId: stationProvinceId,
      ),
      Player(
        id: enemyId,
        displayName: enemyDisplayName,
        isHuman: true,
        capitalProvinceId: hostileProvinceId,
      ),
    ],
    diplomacyRelations: const [],
  );
}

/// Taps the first [ExpansionTile] in the tree (if any) and settles, expanding
/// the first army/fleet group so its detail rows render.
Future<void> expandFirstArmyExpansion(WidgetTester tester) async {
  final tiles = find.byType(ExpansionTile);
  if (tiles.evaluate().isEmpty) {
    return;
  }
  await tester.tap(tiles.first);
  await tester.pumpAndSettle();
}

/// Taps every [ExpansionTile] currently in the tree (settling after each) so
/// all army/fleet groups expand and their detail rows render.
Future<void> expandAllArmyExpansions(WidgetTester tester) async {
  final finder = find.byType(ExpansionTile);
  final n = finder.evaluate().length;
  for (var i = 0; i < n; i++) {
    await tester.tap(finder.at(i));
    await tester.pumpAndSettle();
  }
}

/// Tall viewport for army-split interaction tests ([ListView] rows need height).
const Size kArmySplitTestViewport = Size(480, 900);

/// Pumps [ArmySplitTestHarness] inside the canonical editorial-monocle
/// [buildAppShell] > [Scaffold] host at [kArmySplitTestViewport].
Future<void> pumpArmySplitHarness(
  WidgetTester tester, {
  required Game initialGame,
  required String humanPlayerId,
  required AppEventBus bus,
}) {
  return pumpAppShell(
    tester,
    viewport: kArmySplitTestViewport,
    child: Scaffold(
      body: ArmySplitTestHarness(
        initialGame: initialGame,
        humanPlayerId: humanPlayerId,
        bus: bus,
      ),
    ),
    settle: true,
  );
}

/// Applies [ArmySplitRequestedEvent] like `AppEventHandlerScope` and rebuilds
/// the panel with the updated [Game] (widget tests do not mount the full
/// shell). Used by the split-UI tests that drive a real split through the bus.
class ArmySplitTestHarness extends StatefulWidget {
  const ArmySplitTestHarness({
    super.key,
    required this.initialGame,
    required this.humanPlayerId,
    required this.bus,
  });

  final Game initialGame;
  final String humanPlayerId;
  final AppEventBus bus;

  @override
  State<ArmySplitTestHarness> createState() => _ArmySplitTestHarnessState();
}

class _ArmySplitTestHarnessState extends State<ArmySplitTestHarness> {
  late Game _game;
  StreamSubscription<ArmySplitRequestedEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _game = widget.initialGame;
    _sub = widget.bus.on<ArmySplitRequestedEvent>().listen((e) {
      final next = applyArmySplit(
        game: _game,
        playerId: e.humanPlayerId,
        sourceArmyId: e.sourceArmyId,
        unitIdsToMove: e.unitIdsToMove,
      );
      setState(() => _game = next);
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MilitaryUnitsPanel(
      game: _game,
      humanPlayerId: widget.humanPlayerId,
      bus: widget.bus,
      topology: const MapTopology(),
      draftOrders: const Orders(),
    );
  }
}
