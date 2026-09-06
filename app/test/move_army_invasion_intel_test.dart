// Pins move army invasion intel helper (#4216).

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
      const topology = MapTopology(nodes: [], edges: []);
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
      const topology = MapTopology(nodes: [], edges: []);
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
      const topology = MapTopology(nodes: [], edges: []);
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
}
