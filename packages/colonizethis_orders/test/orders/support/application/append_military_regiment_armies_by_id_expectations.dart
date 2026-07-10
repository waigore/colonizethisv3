// Compact appendMilitaryRegimentToArmy armiesById assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'append_military_regiment_armies_by_id_fixtures.dart';

/// Pins for [appendMilitaryRegimentArmiesByIdScenarios] rows.
enum AppendMilitaryRegimentArmiesByIdTarget {
  createNewArmyPathEquivalence,
  appendExistingArmyPathEquivalence,
  mutatesArmiesByIdWhenAppending,
  mutatesArmiesByIdWhenCreating,
  multipleRecruitsWithSharedMap,
  fallsBackWhenPartialMap,
}

void runAppendMilitaryRegimentArmiesByIdExpectation(
  AppendMilitaryRegimentArmiesByIdTarget target,
) {
  switch (target) {
    case AppendMilitaryRegimentArmiesByIdTarget.createNewArmyPathEquivalence:
      final game = amrEmptyArmyGame();
      final viaMap = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        amrCapProvinceId,
        'u_new',
        armiesById: armiesByIdForWorld(game.worldState),
      );
      final viaScan = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        amrCapProvinceId,
        'u_new',
      );

      expect(viaMap.worldState.armies.length, viaScan.worldState.armies.length);
      expect(viaMap.worldState.armies.single.id, viaScan.worldState.armies.single.id);
      expect(
        viaMap.worldState.armies.single.regimentUnitIds,
        viaScan.worldState.armies.single.regimentUnitIds,
      );
      expect(
        viaMap.worldState.armies.single.isHomeArmy,
        viaScan.worldState.armies.single.isHomeArmy,
      );

    case AppendMilitaryRegimentArmiesByIdTarget.appendExistingArmyPathEquivalence:
      final game = amrGameWithExistingHomeArmy();
      final viaMap = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        amrCapProvinceId,
        'u_new',
        armiesById: armiesByIdForWorld(game.worldState),
      );
      final viaScan = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        amrCapProvinceId,
        'u_new',
      );

      expect(viaMap.worldState.armies.length, 1);
      expect(viaScan.worldState.armies.length, 1);
      expect(
        viaMap.worldState.armies.single.regimentUnitIds,
        viaScan.worldState.armies.single.regimentUnitIds,
      );
      expect(
        viaMap.worldState.armies.single.regimentUnitIds,
        ['u_existing', 'u_new'],
      );

    case AppendMilitaryRegimentArmiesByIdTarget.mutatesArmiesByIdWhenAppending:
      final game = amrGameWithExistingHomeArmy();
      final armiesById = armiesByIdForWorld(game.worldState);
      final homeArmyId = homeArmyIdFor(amrPlayerId);
      expect(armiesById[homeArmyId]!.regimentUnitIds, ['u_existing']);

      final next = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        amrCapProvinceId,
        'u_new',
        armiesById: armiesById,
      );

      expect(
        armiesById[homeArmyId]!.regimentUnitIds,
        ['u_existing', 'u_new'],
      );
      expect(
        next.worldState.armies.single.regimentUnitIds,
        ['u_existing', 'u_new'],
      );

    case AppendMilitaryRegimentArmiesByIdTarget.mutatesArmiesByIdWhenCreating:
      final game = amrEmptyArmyGame();
      final armiesById = armiesByIdForWorld(game.worldState);
      expect(armiesById, isEmpty);

      final next = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        amrCapProvinceId,
        'u_new',
        armiesById: armiesById,
      );

      final homeArmyId = homeArmyIdFor(amrPlayerId);
      expect(armiesById.containsKey(homeArmyId), isTrue);
      expect(armiesById[homeArmyId]!.regimentUnitIds, ['u_new']);
      expect(next.worldState.armies.single.id, homeArmyId);

    case AppendMilitaryRegimentArmiesByIdTarget.multipleRecruitsWithSharedMap:
      final start = amrEmptyArmyGame();

      var mapGame = start;
      final armiesById = armiesByIdForWorld(start.worldState);
      for (final id in const ['u_a', 'u_b', 'u_c']) {
        mapGame = appendMilitaryRegimentToArmy(
          mapGame,
          start.players.single,
          amrCapProvinceId,
          id,
          armiesById: armiesById,
        );
      }

      var scanGame = start;
      for (final id in const ['u_a', 'u_b', 'u_c']) {
        scanGame = appendMilitaryRegimentToArmy(
          scanGame,
          start.players.single,
          amrCapProvinceId,
          id,
        );
      }

      expect(
        mapGame.worldState.armies.single.regimentUnitIds,
        scanGame.worldState.armies.single.regimentUnitIds,
      );
      expect(
        mapGame.worldState.armies.single.regimentUnitIds,
        ['u_a', 'u_b', 'u_c'],
      );

    case AppendMilitaryRegimentArmiesByIdTarget.fallsBackWhenPartialMap:
      final game = amrGameWithExistingHomeArmy();
      final partialMap = <String, Army>{};

      final next = appendMilitaryRegimentToArmy(
        game,
        game.players.single,
        amrCapProvinceId,
        'u_new',
        armiesById: partialMap,
      );

      expect(next.worldState.armies.length, 1);
      expect(
        next.worldState.armies.single.regimentUnitIds,
        ['u_existing', 'u_new'],
      );
      expect(
        partialMap[homeArmyIdFor(amrPlayerId)]!.regimentUnitIds,
        ['u_existing', 'u_new'],
      );
  }
}
