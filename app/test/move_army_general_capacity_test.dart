// Move army invasion vs general capacity line (#4233).

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'move_dialogs_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  const playerId = 'gp_cap';
  const rivalId = 'gp_rival';
  const from = 'oldWorld|p_from';
  const playerDest = 'oldWorld|p_owned';
  const invasionDest = 'oldWorld|p_invade';

  MapTopology buildTopology() => const MapTopology(
    nodes: [
      TopologyNode(
        id: from,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: playerDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: invasionDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [
      TopologyEdge(id1: from, id2: playerDest),
      TopologyEdge(id1: from, id2: invasionDest),
    ],
  );

  Game buildGame({
    List<General> generals = const [],
    int generalCap = 2,
  }) {
    return Game(
      id: 'g_cap',
      generals: generals,
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: const [
            Province(
              id: from,
              regionId: 'oldWorld',
              ownerId: playerId,
              displayName: 'Origin',
            ),
            Province(
              id: playerDest,
              regionId: 'oldWorld',
              ownerId: playerId,
              displayName: 'Owned Dest',
            ),
            Province(
              id: invasionDest,
              regionId: 'oldWorld',
              ownerId: rivalId,
              displayName: 'Invade Dest',
            ),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: playerId,
              locationProvinceId: from,
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: const [
          Army(
            id: 'a_move',
            ownerId: playerId,
            regionId: 'oldWorld',
            stationedProvinceId: from,
            regimentUnitIds: ['u1'],
            isHomeArmy: false,
          ),
          Army(
            id: 'a_other',
            ownerId: playerId,
            regionId: 'oldWorld',
            stationedProvinceId: from,
            regimentUnitIds: [],
            isHomeArmy: false,
          ),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            from: ['oldWorld|p_from|0|0'],
            playerDest: ['oldWorld|p_owned|0|0'],
            invasionDest: ['oldWorld|p_invade|0|0'],
          },
        },
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p_from|0|0': 'fullyVisible',
            'oldWorld|p_owned|0|0': 'fullyVisible',
            'oldWorld|p_invade|0|0': 'fullyVisible',
          },
        },
      ),
      players: [
        Player(
          id: playerId,
          displayName: 'Player',
          isHuman: true,
          capitalProvinceId: from,
          generalCap: generalCap,
        ),
        Player(
          id: rivalId,
          displayName: 'Rival',
          isHuman: false,
          capitalProvinceId: invasionDest,
        ),
      ],
    );
  }

  Future<void> pumpDialog(
    WidgetTester tester, {
    required Game game,
    required Orders draftOrders,
  }) async {
    final topology = buildTopology();
    final army = game.worldState.armies.firstWhere((a) => a.id == 'a_move');
    await tester.pumpWidget(
      moveDialogsSpecsFrameWithOpener(
        (context) => () {
          showDialog<void>(
            context: context,
            builder: (_) => MoveArmyDialog(
              army: army,
              game: game,
              humanPlayerId: playerId,
              bus: AppEventBus.create(),
              topology: topology,
              draftOrders: draftOrders,
              playerView: buildPlayerView(game, topology, playerId),
            ),
          );
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('owned destination hides invasion capacity line', (tester) async {
    final game = buildGame(
      generals: const [General(id: 'g1', ownerId: playerId)],
    );
    await pumpDialog(tester, game: game, draftOrders: const Orders());
    await tester.tap(find.text('Owned Dest'));
    await tester.pump();

    expect(find.textContaining('Invasions this turn'), findsNothing);
  });

  testWidgets('invasion destination shows invasion vs general counts', (
    tester,
  ) async {
    final draft = Orders(
      armyMoveOrdersByPlayerId: {
        playerId: [
          const ArmyMoveOrder(
            armyId: 'a_other',
            destinationProvinceId: invasionDest,
          ),
        ],
      },
    );
    final game = buildGame(
      generals: const [
        General(id: 'g1', ownerId: playerId),
        General(id: 'g2', ownerId: playerId),
      ],
    );
    await pumpDialog(tester, game: game, draftOrders: draft);

    await tester.tap(find.text('Invade Dest'));
    await tester.pump();

    expect(find.text('Invasions this turn: 2 · Generals: 2'), findsOneWidget);
    final confirm = find.widgetWithText(CtNinePatchButton, 'Confirm');
    expect(tester.widget<CtNinePatchButton>(confirm).onPressed, isNotNull);
  });

  testWidgets('soft warning when invasions exceed generals', (tester) async {
    final draft = Orders(
      armyMoveOrdersByPlayerId: {
        playerId: [
          const ArmyMoveOrder(
            armyId: 'a_other',
            destinationProvinceId: invasionDest,
          ),
        ],
      },
    );
    final game = buildGame(
      generals: const [General(id: 'g1', ownerId: playerId)],
      generalCap: 1,
    );
    await pumpDialog(tester, game: game, draftOrders: draft);
    await tester.tap(find.text('Invade Dest'));
    await tester.pump();

    expect(find.text('Invasions this turn: 2 · Generals: 1'), findsOneWidget);
    expect(
      find.text(
        'More invasions than generals — extra armies fight with weaker command.',
      ),
      findsOneWidget,
    );
    final confirm = find.widgetWithText(CtNinePatchButton, 'Confirm');
    expect(tester.widget<CtNinePatchButton>(confirm).onPressed, isNotNull);
  });
}
