// Fixtures for DLG30001 destination hostile-fleet intel goldens (Refs #4573).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'move_fleet_destination_intel_test_support.dart';

const Size kMoveFleetDestinationIntelGoldenViewport = Size(360, 620);

const moveFleetDestIntelOriginSea = 'sea_origin';
const moveFleetDestIntelCoastProvinceLocal = 'coast_home';
const moveFleetDestIntelCoastProvince =
    'oldWorld|$moveFleetDestIntelCoastProvinceLocal';

MapTopology buildMoveFleetDestinationIntelGoldenTopology({
  bool includeOwnedPort = false,
}) {
  final nodes = <TopologyNode>[
    const TopologyNode(
      id: moveFleetDestIntelOriginSea,
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    const TopologyNode(
      id: moveFleetDestIntelSea,
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    if (includeOwnedPort)
      const TopologyNode(
        id: moveFleetDestIntelCoastProvinceLocal,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
  ];
  final edges = <TopologyEdge>[
    const TopologyEdge(
      id1: moveFleetDestIntelOriginSea,
      id2: moveFleetDestIntelSea,
    ),
    if (includeOwnedPort)
      const TopologyEdge(
        id1: moveFleetDestIntelOriginSea,
        id2: moveFleetDestIntelCoastProvinceLocal,
      ),
  ];
  return MapTopology(nodes: nodes, edges: edges);
}

Game buildMoveFleetDestinationIntelGoldenGame({
  required Map<String, String> visibilityByTile,
  List<Fleet> hostileFleets = const [],
  bool includeOwnedPort = false,
}) {
  final selfFleet = Fleet(
    id: 'f_self',
    ownerId: moveFleetDestIntelHumanId,
    regionId: 'oldWorld',
    seaZoneId: moveFleetDestIntelOriginSea,
    ships: const [ShipInstance(id: 'ss1', typeId: 'carrack')],
  );
  return Game(
    id: 'g_move_dest_intel_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: 'oldWorld|p_home',
            regionId: 'oldWorld',
            ownerId: moveFleetDestIntelHumanId,
            displayName: 'Home',
          ),
          if (includeOwnedPort)
            Province(
              id: moveFleetDestIntelCoastProvince,
              regionId: 'oldWorld',
              ownerId: moveFleetDestIntelHumanId,
              displayName: 'Coast Port',
            ),
        ],
      ),
      newWorld: const RegionData(),
      fleets: [selfFleet, ...hostileFleets],
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          moveFleetDestIntelPrefixedSea: const [moveFleetDestIntelSeaTile],
          if (includeOwnedPort)
            moveFleetDestIntelCoastProvince: const [
              'oldWorld|$moveFleetDestIntelCoastProvinceLocal|0|0',
            ],
        },
      },
      seaZoneDisplayNameById: const {
        'oldWorld|$moveFleetDestIntelOriginSea': 'Origin Sea',
        'oldWorld|$moveFleetDestIntelSea': 'Hostile Sea',
      },
      playerVisibilityByTile: {moveFleetDestIntelHumanId: visibilityByTile},
    ),
    players: const [
      Player(
        id: moveFleetDestIntelHumanId,
        displayName: 'England',
        isHuman: true,
      ),
      Player(
        id: moveFleetDestIntelRivalId,
        displayName: 'Spain',
        isHuman: false,
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: moveFleetDestIntelHumanId,
        factionId2: moveFleetDestIntelRivalId,
        state: RelationState.atWar,
      ),
    ],
  );
}

Map<String, String> moveFleetDestIntelFullVisibilityTiles() => const {
      moveFleetDestIntelSeaTile: 'fullyVisible',
    };

Future<void> pumpMoveFleetDestinationIntelGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required MapTopology topology,
  PlayerView? playerView,
}) async {
  final fleet = game.worldState.fleets.firstWhere((f) => f.id == 'f_self');
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: kMoveFleetDestinationIntelGoldenViewport,
    settle: false,
    includeLocalizations: true,
    scaffoldBackgroundColor:
        AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: MoveFleetDialog(
      game: game,
      topology: topology,
      humanPlayerId: moveFleetDestIntelHumanId,
      fleet: fleet,
      bus: AppEventBus.create(),
      playerView: playerView,
    ),
  );
}
