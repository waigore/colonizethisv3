import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'capital_and_gp_fall_terminal_gp_cases.dart';

void main() {
  _capital_and_gp_fall_terminal_testTests();
}

void _capital_and_gp_fall_terminal_testTests() {
  group('applyFactionTerminalFall (Minor)', () {
    test('transfers provinces and assets to conqueror and removes faction', () {
      final game = minorCapitalLossGame(
        id: 'g-minor-fall',
        minorId: 'm1',
        capitalProvinceId: 'oldWorld|mcap',
        capitalOwnerId: 'p2',
        newWorldProvinces: const [
          Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'm1'),
        ],
        units: [capitalTestUnit('u-m', 'm1', 'oldWorld|mcap')],
        fleets: [capitalTestFleet('f-m', 'm1')],
      );

      final result = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {'m1': 'oldWorld|mcap'},
        previousCapitalByTribe: const {},
      );

      expect(result.minorNations, isEmpty);
      expect(result.worldState.tryGetProvince('newWorld|n1')?.ownerId, 'p2');
      expect(
        result.worldState.oldWorld.units.any((u) => u.ownerId == 'm1'),
        isFalse,
      );
      expect(result.worldState.fleets.any((f) => f.ownerId == 'm1'), isFalse);
    });

    test('does not fall when faction still owns capital province', () {
      final game = minorCapitalLossGame(
        id: 'g-minor-hold',
        minorId: 'm1',
        capitalProvinceId: 'oldWorld|mcap',
        capitalOwnerId: 'm1',
      );

      final result = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {'m1': 'oldWorld|mcap'},
        previousCapitalByTribe: const {},
      );

      expect(result.minorNations.single.id, 'm1');
    });

    test('does not fall when faction still owns a province in the region', () {
      final game = minorCapitalLossGame(
        id: 'g-minor-region',
        minorId: 'm1',
        capitalProvinceId: 'oldWorld|mcap',
        capitalOwnerId: 'p2',
        extraOldWorldProvinces: const [
          Province(id: 'oldWorld|m2', regionId: 'oldWorld', ownerId: 'm1'),
        ],
      );

      final result = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {'m1': 'oldWorld|mcap'},
        previousCapitalByTribe: const {},
      );

      expect(result.minorNations.single.id, 'm1');
    });

    test('skips when previous capital province is missing', () {
      final game = capitalLossGame(
        id: 'g-minor-missing',
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: const [MinorNation(id: 'm1')],
      );

      final result = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {'m1': 'oldWorld|ghost'},
        previousCapitalByTribe: const {},
      );

      expect(result.minorNations.single.id, 'm1');
    });

    test('skips faction not present in the game', () {
      final game = capitalLossGame(
        id: 'g-minor-absent',
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
      );

      final result = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {'mX': 'oldWorld|mcap'},
        previousCapitalByTribe: const {},
      );

      expect(result.minorNations, isEmpty);
    });
  });

  group('applyFactionTerminalFall (Tribe)', () {
    test('transfers tribe provinces to conqueror and removes tribe', () {
      final game = capitalLossGame(
        id: 'g-tribe-fall',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|t2', regionId: 'oldWorld', ownerId: 't1'),
        ],
        newWorldProvinces: const [
          Province(id: 'newWorld|tcap', regionId: 'newWorld', ownerId: 'p2'),
        ],
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        tribes: const [Tribe(id: 't1')],
      );

      final result = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {},
        previousCapitalByTribe: const {'t1': 'newWorld|tcap'},
      );

      expect(result.tribes, isEmpty);
      expect(result.worldState.tryGetProvince('oldWorld|t2')?.ownerId, 'p2');
    });
  });

  registerCapitalAndGpFallTerminalGpCases();
}
