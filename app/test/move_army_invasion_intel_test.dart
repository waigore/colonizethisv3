// Pins move army invasion intel helper and DLG20001 invasion rows (#4216).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_invasion_intel.dart';

import 'move_army_invasion_intel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('computeMoveArmyInvasionIntelSummary', () {
    test('unknown when playerView is null', () {
      final game = buildMoveArmyInvasionIntelBaseGame(
        visibilityByTile: {'oldWorld|p_invade|0|0': 'fullyVisible'},
      );
      final summary = computeMoveArmyInvasionIntelSummary(
        game: game,
        playerView: null,
        humanPlayerId: kMoveArmyIntelHumanId,
        destinationProvinceId: kMoveArmyIntelInvasionDest,
      );
      expect(summary.intelLevel, MoveArmyInvasionIntelLevel.unknown);
    });

    test('unknown when invasion tiles are not fully visible', () {
      final game = buildMoveArmyInvasionIntelBaseGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fogged',
        },
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kMoveArmyIntelHumanId);
      final summary = computeMoveArmyInvasionIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: kMoveArmyIntelHumanId,
        destinationProvinceId: kMoveArmyIntelInvasionDest,
      );
      expect(summary.intelLevel, MoveArmyInvasionIntelLevel.unknown);
    });

    test('full intel counts combat-capable defenders and fort level', () {
      final game = buildMoveArmyInvasionIntelBaseGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
        fortLevel: 2,
        invasionUnits: [
          Unit(
            id: 'd1',
            type: 'musketeers',
            ownerId: kMoveArmyIntelRivalId,
            locationProvinceId: kMoveArmyIntelInvasionDest,
          ),
          Unit(
            id: 'd2',
            type: 'pikemen',
            ownerId: kMoveArmyIntelRivalId,
            locationProvinceId: kMoveArmyIntelInvasionDest,
          ),
          Unit(
            id: 'spy1',
            type: 'spy',
            ownerId: kMoveArmyIntelRivalId,
            locationProvinceId: kMoveArmyIntelInvasionDest,
          ),
        ],
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kMoveArmyIntelHumanId);
      final summary = computeMoveArmyInvasionIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: kMoveArmyIntelHumanId,
        destinationProvinceId: kMoveArmyIntelInvasionDest,
      );
      expect(summary.intelLevel, MoveArmyInvasionIntelLevel.full);
      expect(summary.defenderCombatCapableCount, 2);
      expect(summary.unopposed, isFalse);
      expect(summary.fortLevel, 2);
      expect(summary.defenderTypesByRegimentId['musketeers'], 1);
      expect(summary.defenderTypesByRegimentId['pikemen'], 1);
    });

    test('full intel with zero combat-capable defenders is unopposed', () {
      final game = buildMoveArmyInvasionIntelBaseGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
        invasionUnits: [
          Unit(
            id: 'spy1',
            type: 'spy',
            ownerId: kMoveArmyIntelRivalId,
            locationProvinceId: kMoveArmyIntelInvasionDest,
          ),
        ],
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kMoveArmyIntelHumanId);
      final summary = computeMoveArmyInvasionIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: kMoveArmyIntelHumanId,
        destinationProvinceId: kMoveArmyIntelInvasionDest,
      );
      expect(summary.unopposed, isTrue);
      expect(summary.defenderCombatCapableCount, 0);
    });
  });

  test('moveArmyOwnRegimentCount matches army regiment ids', () {
    final army = Army(
      id: 'a',
      ownerId: kMoveArmyIntelHumanId,
      regionId: 'oldWorld',
      stationedProvinceId: kMoveArmyIntelFrom,
      regimentUnitIds: ['u1', 'u2'],
      isHomeArmy: false,
    );
    expect(moveArmyOwnRegimentCount(army), 2);
  });

  group('MoveArmyDialog invasion intel UI', () {
    testWidgets('shows own army count on dialog body', (tester) async {
      final topology = buildMoveArmyInvasionIntelUiTopology();
      final game = buildMoveArmyInvasionIntelUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
      );
      await pumpMoveArmyInvasionIntelDialog(
        tester,
        game: game,
        topology: topology,
      );
      expect(find.text('Your army: 1 regiments'), findsOneWidget);
    });

    testWidgets('full intel invasion row shows defender count and fort label', (
      tester,
    ) async {
      final topology = buildMoveArmyInvasionIntelUiTopology();
      final game = buildMoveArmyInvasionIntelUiGame(
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
            ownerId: kMoveArmyIntelUiRivalId,
            locationProvinceId: kMoveArmyIntelUiInvasionDest,
          ),
        ],
      );
      await pumpMoveArmyInvasionIntelDialog(
        tester,
        game: game,
        topology: topology,
      );
      expect(find.text('Defenders: 1 regiments'), findsOneWidget);
      expect(find.text('Wood fort siege'), findsOneWidget);
      expect(find.text('Defenders unknown'), findsNothing);
    });

    testWidgets('unknown intel invasion row shows defenders unknown', (
      tester,
    ) async {
      final topology = buildMoveArmyInvasionIntelUiTopology();
      final game = buildMoveArmyInvasionIntelUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fogged',
        },
      );
      await pumpMoveArmyInvasionIntelDialog(
        tester,
        game: game,
        topology: topology,
      );
      expect(find.text('Defenders unknown'), findsOneWidget);
      expect(find.textContaining('Defenders:'), findsNothing);
      expect(find.text('Unopposed capture'), findsNothing);
    });

    testWidgets('owned destination row has no invasion intel lines', (
      tester,
    ) async {
      final topology = buildMoveArmyInvasionIntelUiTopology();
      final game = buildMoveArmyInvasionIntelUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
      );
      await pumpMoveArmyInvasionIntelDialog(
        tester,
        game: game,
        topology: topology,
      );
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
      final topology = buildMoveArmyInvasionIntelUiTopology();
      final game = buildMoveArmyInvasionIntelUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
        extraUnits: [
          Unit(
            id: 'd1',
            type: 'pikemen',
            ownerId: kMoveArmyIntelUiRivalId,
            locationProvinceId: kMoveArmyIntelUiInvasionDest,
          ),
        ],
      );
      await pumpMoveArmyInvasionIntelDialog(
        tester,
        game: game,
        topology: topology,
      );
      await tester.tap(find.text('Invade Dest'));
      await tester.pump();
      expect(find.textContaining('Musketeers'), findsWidgets);
      expect(find.textContaining('Pikemen'), findsOneWidget);
    });
  });
}
