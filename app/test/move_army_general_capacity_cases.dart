// Fixtures for move army general-capacity dialog tests (Refs #4734 Slice E, #4233).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';

import 'move_dialogs_specs_test_support.dart';

const kMoveArmyCapPlayerId = 'gp_cap';
const kMoveArmyCapRivalId = 'gp_rival';
const kMoveArmyCapFrom = 'oldWorld|p_from';
const kMoveArmyCapOwnedDest = 'oldWorld|p_owned';
const kMoveArmyCapInvasionDest = 'oldWorld|p_invade';

MapTopology moveArmyGeneralCapacityTopology() => const MapTopology(
      nodes: [
        TopologyNode(
          id: kMoveArmyCapFrom,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: kMoveArmyCapOwnedDest,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: kMoveArmyCapInvasionDest,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [
        TopologyEdge(id1: kMoveArmyCapFrom, id2: kMoveArmyCapOwnedDest),
        TopologyEdge(id1: kMoveArmyCapFrom, id2: kMoveArmyCapInvasionDest),
      ],
    );

Game buildMoveArmyGeneralCapacityGame({
  List<General> generals = const [],
  int generalCap = 2,
  Stockpile stockpile = const Stockpile(),
  List<Unit> extraUnits = const [],
}) {
  return Game(
    id: 'g_cap',
    generals: generals,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: kMoveArmyCapFrom,
            regionId: 'oldWorld',
            ownerId: kMoveArmyCapPlayerId,
            displayName: 'Origin',
          ),
          Province(
            id: kMoveArmyCapOwnedDest,
            regionId: 'oldWorld',
            ownerId: kMoveArmyCapPlayerId,
            displayName: 'Owned Dest',
          ),
          Province(
            id: kMoveArmyCapInvasionDest,
            regionId: 'oldWorld',
            ownerId: kMoveArmyCapRivalId,
            displayName: 'Invade Dest',
          ),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: kMoveArmyCapPlayerId,
            locationProvinceId: kMoveArmyCapFrom,
          ),
          ...extraUnits,
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'a_move',
          ownerId: kMoveArmyCapPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: kMoveArmyCapFrom,
          regimentUnitIds: ['u1'],
          isHomeArmy: false,
        ),
        Army(
          id: 'a_other',
          ownerId: kMoveArmyCapPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: kMoveArmyCapFrom,
          regimentUnitIds: [],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          kMoveArmyCapFrom: ['oldWorld|p_from|0|0'],
          kMoveArmyCapOwnedDest: ['oldWorld|p_owned|0|0'],
          kMoveArmyCapInvasionDest: ['oldWorld|p_invade|0|0'],
        },
      },
      playerVisibilityByTile: const {
        kMoveArmyCapPlayerId: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
      },
    ),
    players: [
      Player(
        id: kMoveArmyCapPlayerId,
        displayName: 'Player',
        isHuman: true,
        capitalProvinceId: kMoveArmyCapFrom,
        generalCap: generalCap,
        stockpile: stockpile,
      ),
      Player(
        id: kMoveArmyCapRivalId,
        displayName: 'Rival',
        isHuman: false,
        capitalProvinceId: kMoveArmyCapInvasionDest,
      ),
    ],
  );
}

Future<void> pumpMoveArmyGeneralCapacityDialog(
  WidgetTester tester, {
  required Game game,
  required Orders draftOrders,
}) async {
  final topology = moveArmyGeneralCapacityTopology();
  final army = game.worldState.armies.firstWhere((a) => a.id == 'a_move');
  await tester.pumpWidget(
    moveDialogsSpecsFrameWithOpener(
      (context) => () {
        showDialog<void>(
          context: context,
          builder: (_) => MoveArmyDialog(
            army: army,
            game: game,
            humanPlayerId: kMoveArmyCapPlayerId,
            bus: AppEventBus.create(),
            topology: topology,
            draftOrders: draftOrders,
            playerView: buildPlayerView(game, topology, kMoveArmyCapPlayerId),
          ),
        );
      },
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
