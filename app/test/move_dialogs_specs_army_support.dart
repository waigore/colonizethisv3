// Army-dialog fixtures for move_dialogs_specs_army_test (Refs #4352).

import 'dart:async';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'move_dialogs_specs_test_support.dart';

const kMoveArmySpecsPlayerId = 'gp_specs_army';
const kMoveArmySpecsRivalId = 'gp_specs_rival';
const kMoveArmySpecsFrom = 'oldWorld|p_from';
const kMoveArmySpecsOwnedDest = 'oldWorld|p_owned';
const kMoveArmySpecsInvasionDest = 'oldWorld|p_invade';
const kMoveArmySpecsIsolatedPlayerId = 'gp_isolated';
const kMoveArmySpecsIsolatedFrom = 'oldWorld|p_isolated';

MapTopology buildMoveArmySpecsTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: kMoveArmySpecsFrom,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: kMoveArmySpecsOwnedDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: kMoveArmySpecsInvasionDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [
      TopologyEdge(id1: kMoveArmySpecsFrom, id2: kMoveArmySpecsOwnedDest),
      TopologyEdge(id1: kMoveArmySpecsFrom, id2: kMoveArmySpecsInvasionDest),
    ],
  );
}

Game buildMoveArmySpecsGame() {
  return Game(
    id: 'g_specs_army',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: kMoveArmySpecsFrom,
            regionId: 'oldWorld',
            ownerId: kMoveArmySpecsPlayerId,
            displayName: 'Origin',
          ),
          Province(
            id: kMoveArmySpecsOwnedDest,
            regionId: 'oldWorld',
            ownerId: kMoveArmySpecsPlayerId,
            displayName: 'Owned Dest',
          ),
          Province(
            id: kMoveArmySpecsInvasionDest,
            regionId: 'oldWorld',
            ownerId: kMoveArmySpecsRivalId,
            displayName: 'Invade Dest',
          ),
        ],
        units: [
          Unit(
            id: 'u_specs',
            type: 'musketeers',
            ownerId: kMoveArmySpecsPlayerId,
            locationProvinceId: kMoveArmySpecsFrom,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'aspecs',
          ownerId: kMoveArmySpecsPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: kMoveArmySpecsFrom,
          regimentUnitIds: ['u_specs'],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          kMoveArmySpecsFrom: ['oldWorld|p_from|0|0'],
          kMoveArmySpecsOwnedDest: ['oldWorld|p_owned|0|0'],
          kMoveArmySpecsInvasionDest: ['oldWorld|p_invade|0|0'],
        },
      },
      playerVisibilityByTile: const {
        kMoveArmySpecsPlayerId: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(
        id: kMoveArmySpecsPlayerId,
        displayName: 'Specs Player',
        isHuman: true,
        capitalProvinceId: kMoveArmySpecsFrom,
      ),
      Player(
        id: kMoveArmySpecsRivalId,
        displayName: 'Specs Rival',
        isHuman: false,
        capitalProvinceId: kMoveArmySpecsInvasionDest,
      ),
    ],
  );
}

Game buildMoveArmySpecsIsolatedGame() {
  return Game(
    id: 'g_isolated_army',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: kMoveArmySpecsIsolatedFrom,
            regionId: 'oldWorld',
            ownerId: kMoveArmySpecsIsolatedPlayerId,
            displayName: 'Lonely',
          ),
        ],
        units: [
          Unit(
            id: 'u_isolated',
            type: 'musketeers',
            ownerId: kMoveArmySpecsIsolatedPlayerId,
            locationProvinceId: kMoveArmySpecsIsolatedFrom,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'aisolated',
          ownerId: kMoveArmySpecsIsolatedPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: kMoveArmySpecsIsolatedFrom,
          regimentUnitIds: ['u_isolated'],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          kMoveArmySpecsIsolatedFrom: ['oldWorld|p_isolated|0|0'],
        },
      },
    ),
    players: const [
      Player(
        id: kMoveArmySpecsIsolatedPlayerId,
        displayName: 'Isolated',
        isHuman: true,
        capitalProvinceId: kMoveArmySpecsIsolatedFrom,
      ),
    ],
  );
}

const isolatedMoveArmySpecsTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: kMoveArmySpecsIsolatedFrom,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);

Future<void> pumpMoveArmySpecsDialog(
  WidgetTester tester, {
  required AppEventBus bus,
  Game? game,
  MapTopology? topology,
  String humanPlayerId = kMoveArmySpecsPlayerId,
}) async {
  final resolvedGame = game ?? buildMoveArmySpecsGame();
  final resolvedTopology = topology ?? buildMoveArmySpecsTopology();
  final army = resolvedGame.worldState.armies.first;
  await tester.pumpWidget(
    moveDialogsSpecsFrameWithOpener(
      (context) => () {
        showDialog<void>(
          context: context,
          builder: (_) => MoveArmyDialog(
            army: army,
            game: resolvedGame,
            humanPlayerId: humanPlayerId,
            bus: bus,
            topology: resolvedTopology,
            draftOrders: const Orders(),
          ),
        );
      },
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

(
  AppEventBus bus,
  ArmyMoveRequestedEvent? Function() getCaptured,
  StreamSubscription<ArmyMoveRequestedEvent> sub,
)
subscribeArmyMoveRequested() {
  ArmyMoveRequestedEvent? captured;
  final bus = AppEventBus.create();
  final sub = bus.on<ArmyMoveRequestedEvent>().listen((e) {
    captured = e;
  });
  return (bus, () => captured, sub);
}

Future<void> openInvasionWarConfirm(
  WidgetTester tester,
  AppEventBus bus,
) async {
  await pumpMoveArmySpecsDialog(tester, bus: bus);
  await tester.tap(find.text('Invade Dest'));
  await tester.pump();
  await tester.tap(find.widgetWithText(CtNinePatchButton, 'Confirm'));
  await tester.pumpAndSettle();
  expect(find.text('Declare war?'), findsOneWidget);
}

Future<TextStyle?> invasionDeclareWarTriggerStyle(WidgetTester tester) async {
  await pumpMoveArmySpecsDialog(tester, bus: AppEventBus.create());
  final triggerFinder = find.text('declare war on Specs Rival');
  expect(triggerFinder, findsOneWidget);
  return tester.widget<Text>(triggerFinder).style;
}

Finder warConfirmSubShell() {
  return find.ancestor(
    of: find.text('Declare war?'),
    matching: find.byType(CtDialogShell),
  );
}
