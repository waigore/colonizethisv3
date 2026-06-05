import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'test_game_factories.dart';

void main() {
  group('buildExpandGame', () {
    test('preserves game id label and turn suffix', () {
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        turnNumber: 42,
      );
      expect(game.id, 'g-2509-expand-phase-planner-peace-t42');
    });

    test('defaults to three affluent GPs when players omitted', () {
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
      );
      expect(game.players, kExpandTestPlayers3Affluent);
    });

    test('accepts old-world units and armies for declare-war fixtures', () {
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        oldWorldUnits: const [],
        armies: const [],
        diplomaticHistoryEvents: const [],
      );
      expect(game.worldState.oldWorld.units, isEmpty);
      expect(game.worldState.armies, isEmpty);
    });
  });

  group('buildExpandSnapshot', () {
    test('defaults to below-quota EXPAND posture for gp1', () {
      final snap = buildExpandSnapshot();
      expect(snap.playerId, kExpandTestGp1);
      expect(snap.threats.atWarWith, isEmpty);
      expect(snap.conquest.oldWorldProvincesOwned, 8);
      expect(
        snap.conquest.provincesToVictory,
        kObserverConquestMinOwProvincesPerGp * 3,
      );
    });

    test('threads invadable OW and adjacent owners', () {
      final snap = buildExpandSnapshot(
        atWarWith: const [kExpandTestGp2],
        invadableOw: const ['oldWorld|m1_a'],
        adjacentOwners: const ['minor1'],
      );
      expect(snap.threats.atWarWith, [kExpandTestGp2]);
      expect(snap.conquest.invadableProvinceIdsSorted, ['oldWorld|m1_a']);
      expect(snap.conquest.adjacentOwnerFactionIdsSorted, ['minor1']);
    });

    test('threads colonial NW fields for military suppression pins', () {
      final snap = buildExpandSnapshot(
        atWarWith: const ['tribe1'],
        invadableNw: const ['newWorld|t1_a'],
      );
      expect(snap.colonial.invadableNewWorldProvinceIdsSorted, [
        'newWorld|t1_a',
      ]);
    });
  });
}
