// Pins move army invasion intel helper and DLG20001 invasion rows (#4216).

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_invasion_intel.dart';

import 'move_dialogs_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  const humanId = 'gp_intel';
  const rivalId = 'gp_rival';
  const from = 'oldWorld|p_from';
  const invasionDest = 'oldWorld|p_invade';

  Game buildBaseGame({
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
              id: from,
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Origin',
            ),
            Province(
              id: invasionDest,
              regionId: 'oldWorld',
              ownerId: rivalId,
              displayName: 'Invade Dest',
              fortLevel: fortLevel,
            ),
          ],
          units: [
            Unit(
              id: 'u_mover',
              type: 'musketeers',
              ownerId: humanId,
              locationProvinceId: from,
            ),
            ...invasionUnits,
          ],
        ),
        newWorld: const RegionData(),
        armies: const [
          Army(
            id: 'a_intel',
            ownerId: humanId,
            regionId: 'oldWorld',
            stationedProvinceId: from,
            regimentUnitIds: ['u_mover'],
            isHomeArmy: false,
          ),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            from: ['oldWorld|p_from|0|0'],
            invasionDest: ['oldWorld|p_invade|0|0'],
          },
        },
        playerVisibilityByTile: {humanId: visibilityByTile},
      ),
      players: const [
        Player(
          id: humanId,
          displayName: 'Human',
          isHuman: true,
          capitalProvinceId: from,
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

  group('computeMoveArmyInvasionIntelSummary', () {
    test('unknown when playerView is null', () {
      final game = buildBaseGame(
        visibilityByTile: {
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
      );
      final summary = computeMoveArmyInvasionIntelSummary(
        game: game,
        playerView: null,
        humanPlayerId: humanId,
        destinationProvinceId: invasionDest,
      );
      expect(summary.intelLevel, MoveArmyInvasionIntelLevel.unknown);
    });

    test('unknown when invasion tiles are not fully visible', () {
      final game = buildBaseGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fogged',
        },
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, humanId);
      final summary = computeMoveArmyInvasionIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: humanId,
        destinationProvinceId: invasionDest,
      );
      expect(summary.intelLevel, MoveArmyInvasionIntelLevel.unknown);
    });

    test('full intel counts combat-capable defenders and fort level', () {
      final game = buildBaseGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
        fortLevel: 2,
        invasionUnits: [
          Unit(
            id: 'd1',
            type: 'musketeers',
            ownerId: rivalId,
            locationProvinceId: invasionDest,
          ),
          Unit(
            id: 'd2',
            type: 'pikemen',
            ownerId: rivalId,
            locationProvinceId: invasionDest,
          ),
          Unit(
            id: 'spy1',
            type: 'spy',
            ownerId: rivalId,
            locationProvinceId: invasionDest,
          ),
        ],
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, humanId);
      final summary = computeMoveArmyInvasionIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: humanId,
        destinationProvinceId: invasionDest,
      );
      expect(summary.intelLevel, MoveArmyInvasionIntelLevel.full);
      expect(summary.defenderCombatCapableCount, 2);
      expect(summary.unopposed, isFalse);
      expect(summary.fortLevel, 2);
      expect(summary.defenderTypesByRegimentId['musketeers'], 1);
      expect(summary.defenderTypesByRegimentId['pikemen'], 1);
    });

    test('full intel with zero combat-capable defenders is unopposed', () {
      final game = buildBaseGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
        invasionUnits: [
          Unit(
            id: 'spy1',
            type: 'spy',
            ownerId: rivalId,
            locationProvinceId: invasionDest,
          ),
        ],
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, humanId);
      final summary = computeMoveArmyInvasionIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: humanId,
        destinationProvinceId: invasionDest,
      );
      expect(summary.unopposed, isTrue);
      expect(summary.defenderCombatCapableCount, 0);
    });
  });

  test('moveArmyOwnRegimentCount matches army regiment ids', () {
    final army = Army(
      id: 'a',
      ownerId: humanId,
      regionId: 'oldWorld',
      stationedProvinceId: from,
      regimentUnitIds: ['u1', 'u2'],
      isHomeArmy: false,
    );
    expect(moveArmyOwnRegimentCount(army), 2);
  });

  group('MoveArmyDialog invasion intel UI', () {
    const playerId = 'gp_intel_ui';
    const rivalId = 'gp_rival_ui';
    const from = 'oldWorld|p_from';
    const playerDest = 'oldWorld|p_owned';
    const invasionDest = 'oldWorld|p_invade';

    MapTopology buildTopology() {
      return const MapTopology(
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
    }

    Game buildUiGame({
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
                fortLevel: fortLevel,
              ),
            ],
            units: [
              Unit(
                id: 'u_mover',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: from,
              ),
              ...extraUnits,
            ],
          ),
          newWorld: const RegionData(),
          armies: const [
            Army(
              id: 'a_ui',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: from,
              regimentUnitIds: ['u_mover'],
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
          playerVisibilityByTile: {playerId: visibilityByTile},
        ),
        players: const [
          Player(
            id: playerId,
            displayName: 'Human',
            isHuman: true,
            capitalProvinceId: from,
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
      required MapTopology topology,
    }) async {
      final army = game.worldState.armies.first;
      final view = buildPlayerView(game, topology, playerId);
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

    testWidgets('shows own army count on dialog body', (tester) async {
      final topology = buildTopology();
      final game = buildUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
      );
      await pumpDialog(tester, game: game, topology: topology);
      expect(find.text('Your army: 1 regiments'), findsOneWidget);
    });

    testWidgets('full intel invasion row shows defender count and fort label', (
      tester,
    ) async {
      final topology = buildTopology();
      final game = buildUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
        fortLevel: 1,
        extraUnits: [
          Unit(
            id: 'd1',
            type: 'pikemen',
            ownerId: rivalId,
            locationProvinceId: invasionDest,
          ),
        ],
      );
      await pumpDialog(tester, game: game, topology: topology);
      expect(find.text('Defenders: 1 regiments'), findsOneWidget);
      expect(find.text('Wood fort siege'), findsOneWidget);
      expect(find.text('Defenders unknown'), findsNothing);
    });

    testWidgets('unknown intel invasion row shows defenders unknown', (
      tester,
    ) async {
      final topology = buildTopology();
      final game = buildUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fogged',
        },
      );
      await pumpDialog(tester, game: game, topology: topology);
      expect(find.text('Defenders unknown'), findsOneWidget);
      expect(find.textContaining('Defenders:'), findsNothing);
      expect(find.text('Unopposed capture'), findsNothing);
    });

    testWidgets('owned destination row has no invasion intel lines', (
      tester,
    ) async {
      final topology = buildTopology();
      final game = buildUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
      );
      await pumpDialog(tester, game: game, topology: topology);
      final ownedRow = find.ancestor(
        of: find.text('Owned Dest'),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString().contains('MoveDialogDestinationRow'),
        ),
      );
      expect(ownedRow, findsOneWidget);
      expect(
        find.descendant(of: ownedRow, matching: find.text('Defenders unknown')),
        findsNothing,
      );
    });

    testWidgets('selected invasion row shows regiment type breakdown', (
      tester,
    ) async {
      final topology = buildTopology();
      final game = buildUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
        extraUnits: [
          Unit(
            id: 'd1',
            type: 'pikemen',
            ownerId: rivalId,
            locationProvinceId: invasionDest,
          ),
        ],
      );
      await pumpDialog(tester, game: game, topology: topology);
      await tester.tap(find.text('Invade Dest'));
      await tester.pump();
      expect(find.textContaining('Musketeers'), findsWidgets);
      expect(find.textContaining('Pikemen'), findsOneWidget);
    });
  });
}
