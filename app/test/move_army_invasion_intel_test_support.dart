// Shared Game/topology fixtures for move-army invasion intel tests (Refs #4352).

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'move_dialogs_specs_test_support.dart';

const kMoveArmyIntelHumanId = 'gp_intel';
const kMoveArmyIntelRivalId = 'gp_rival';
const kMoveArmyIntelFrom = 'oldWorld|p_from';
const kMoveArmyIntelInvasionDest = 'oldWorld|p_invade';

const kMoveArmyIntelUiHumanId = 'gp_intel_ui';
const kMoveArmyIntelUiRivalId = 'gp_rival_ui';
const kMoveArmyIntelUiFrom = 'oldWorld|p_from';
const kMoveArmyIntelUiOwnedDest = 'oldWorld|p_owned';
const kMoveArmyIntelUiInvasionDest = 'oldWorld|p_invade';

Game buildMoveArmyInvasionIntelBaseGame({
  required Map<String, String> visibilityByTile,
  int fortLevel = 0,
  List<Unit> invasionUnits = const [],
}) {
  return Game(
    id: 'g_intel',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: kMoveArmyIntelFrom,
            regionId: 'oldWorld',
            ownerId: kMoveArmyIntelHumanId,
            displayName: 'Origin',
          ),
          Province(
            id: kMoveArmyIntelInvasionDest,
            regionId: 'oldWorld',
            ownerId: kMoveArmyIntelRivalId,
            displayName: 'Invade Dest',
            fortLevel: fortLevel,
          ),
        ],
        units: [
          Unit(
            id: 'u_mover',
            type: 'musketeers',
            ownerId: kMoveArmyIntelHumanId,
            locationProvinceId: kMoveArmyIntelFrom,
          ),
          ...invasionUnits,
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'a_intel',
          ownerId: kMoveArmyIntelHumanId,
          regionId: 'oldWorld',
          stationedProvinceId: kMoveArmyIntelFrom,
          regimentUnitIds: ['u_mover'],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          kMoveArmyIntelFrom: ['oldWorld|p_from|0|0'],
          kMoveArmyIntelInvasionDest: ['oldWorld|p_invade|0|0'],
        },
      },
      playerVisibilityByTile: {kMoveArmyIntelHumanId: visibilityByTile},
    ),
    players: const [
      Player(
        id: kMoveArmyIntelHumanId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: kMoveArmyIntelFrom,
      ),
      Player(
        id: kMoveArmyIntelRivalId,
        displayName: 'Rival',
        isHuman: false,
        capitalProvinceId: kMoveArmyIntelInvasionDest,
      ),
    ],
  );
}

MapTopology buildMoveArmyInvasionIntelUiTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: kMoveArmyIntelUiFrom,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: kMoveArmyIntelUiOwnedDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: kMoveArmyIntelUiInvasionDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [
      TopologyEdge(id1: kMoveArmyIntelUiFrom, id2: kMoveArmyIntelUiOwnedDest),
      TopologyEdge(
        id1: kMoveArmyIntelUiFrom,
        id2: kMoveArmyIntelUiInvasionDest,
      ),
    ],
  );
}

Game buildMoveArmyInvasionIntelUiGame({
  required Map<String, String> visibilityByTile,
  int fortLevel = 0,
  List<Unit> extraUnits = const [],
}) {
  return Game(
    id: 'g_intel_ui',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: kMoveArmyIntelUiFrom,
            regionId: 'oldWorld',
            ownerId: kMoveArmyIntelUiHumanId,
            displayName: 'Origin',
          ),
          Province(
            id: kMoveArmyIntelUiOwnedDest,
            regionId: 'oldWorld',
            ownerId: kMoveArmyIntelUiHumanId,
            displayName: 'Owned Dest',
          ),
          Province(
            id: kMoveArmyIntelUiInvasionDest,
            regionId: 'oldWorld',
            ownerId: kMoveArmyIntelUiRivalId,
            displayName: 'Invade Dest',
            fortLevel: fortLevel,
          ),
        ],
        units: [
          Unit(
            id: 'u_mover',
            type: 'musketeers',
            ownerId: kMoveArmyIntelUiHumanId,
            locationProvinceId: kMoveArmyIntelUiFrom,
          ),
          ...extraUnits,
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'a_ui',
          ownerId: kMoveArmyIntelUiHumanId,
          regionId: 'oldWorld',
          stationedProvinceId: kMoveArmyIntelUiFrom,
          regimentUnitIds: ['u_mover'],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          kMoveArmyIntelUiFrom: ['oldWorld|p_from|0|0'],
          kMoveArmyIntelUiOwnedDest: ['oldWorld|p_owned|0|0'],
          kMoveArmyIntelUiInvasionDest: ['oldWorld|p_invade|0|0'],
        },
      },
      playerVisibilityByTile: {kMoveArmyIntelUiHumanId: visibilityByTile},
    ),
    players: const [
      Player(
        id: kMoveArmyIntelUiHumanId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: kMoveArmyIntelUiFrom,
      ),
      Player(
        id: kMoveArmyIntelUiRivalId,
        displayName: 'Rival',
        isHuman: false,
        capitalProvinceId: kMoveArmyIntelUiInvasionDest,
      ),
    ],
  );
}

Future<void> pumpMoveArmyInvasionIntelDialog(
  WidgetTester tester, {
  required Game game,
  required MapTopology topology,
}) async {
  final army = game.worldState.armies.first;
  final view = buildPlayerView(game, topology, kMoveArmyIntelUiHumanId);
  await tester.pumpWidget(
    moveDialogsSpecsFrameWithOpener(
      (context) => () {
        showDialog<void>(
          context: context,
          builder: (_) => MoveArmyDialog(
            army: army,
            game: game,
            humanPlayerId: kMoveArmyIntelUiHumanId,
            bus: AppEventBus.create(),
            topology: topology,
            draftOrders: const Orders(),
            playerView: view,
          ),
        );
      },
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
