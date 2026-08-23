import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/army_commands.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';
import 'army_commands_split_cases.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Exercises the pure army combine/split commands in
/// `lib/src/world/army_commands.dart`. SPEC/ui/military-units-army-management.md
/// and SPEC/game/military-armies.md.

Army _army(
  String id, {
  String ownerId = 'p1',
  String stationedProvinceId = 'oldWorld|p1',
  List<String> regimentUnitIds = const ['r1'],
  bool isHomeArmy = false,
}) {
  return Army(
    id: id,
    ownerId: ownerId,
    regionId: 'oldWorld',
    stationedProvinceId: stationedProvinceId,
    regimentUnitIds: regimentUnitIds,
    isHomeArmy: isHomeArmy,
  );
}

void main() {
  group('applyArmyCombine', () {
    test('returns same game when fewer than two army ids supplied', () {
      final game = gameWithArmies(armies: [_army('a1')]);
      final next = applyArmyCombine(
        game: game,
        playerId: 'p1',
        armyIds: const ['a1'],
      );
      expect(next, same(game));
    });

    test('returns same game when fewer than two owned armies match', () {
      final game = gameWithArmies(
        armies: [
          _army('a1'),
          _army('a2', ownerId: 'p2'),
        ],
      );
      final next = applyArmyCombine(
        game: game,
        playerId: 'p1',
        armyIds: const ['a1', 'a2'],
      );
      expect(next, same(game));
    });

    test(
      'returns same game when selected armies sit in different provinces',
      () {
        final game = gameWithArmies(
          armies: [
            _army('a1', stationedProvinceId: 'oldWorld|p1'),
            _army('a2', stationedProvinceId: 'oldWorld|p2'),
          ],
        );
        final next = applyArmyCombine(
          game: game,
          playerId: 'p1',
          armyIds: const ['a1', 'a2'],
        );
        expect(next, same(game));
      },
    );

    test('merges regiments into the home army when one is present', () {
      final game = gameWithArmies(
        armies: [
          _army('a2', regimentUnitIds: const ['r2']),
          _army('home', regimentUnitIds: const ['r1'], isHomeArmy: true),
        ],
      );
      final next = applyArmyCombine(
        game: game,
        playerId: 'p1',
        armyIds: const ['a2', 'home'],
      );
      expect(next.worldState.armies, hasLength(1));
      final merged = next.worldState.armies.single;
      expect(merged.id, 'home');
      expect(merged.isHomeArmy, isTrue);
      expect(merged.regimentUnitIds, ['r1', 'r2']);
    });

    test('merges into the lowest-id army when no home army participates', () {
      final game = gameWithArmies(
        armies: [
          _army('b', regimentUnitIds: const ['r3', 'r1']),
          _army('a', regimentUnitIds: const ['r2']),
        ],
      );
      final next = applyArmyCombine(
        game: game,
        playerId: 'p1',
        armyIds: const ['b', 'a'],
      );
      expect(next.worldState.armies, hasLength(1));
      final merged = next.worldState.armies.single;
      expect(merged.id, 'a');
      // Regiment ids are de-duplicated and sorted.
      expect(merged.regimentUnitIds, ['r1', 'r2', 'r3']);
    });

    test('preserves unrelated armies and keeps the army list sorted by id', () {
      final game = gameWithArmies(
        armies: [
          _army('a2', regimentUnitIds: const ['r2']),
          _army('a1', regimentUnitIds: const ['r1']),
          _army('z9', regimentUnitIds: const ['r9']),
        ],
      );
      final next = applyArmyCombine(
        game: game,
        playerId: 'p1',
        armyIds: const ['a1', 'a2'],
      );
      final ids = next.worldState.armies.map((a) => a.id).toList();
      expect(ids, ['a1', 'z9']);
    });

    test('de-duplicates regiment ids shared across combined armies', () {
      final game = gameWithArmies(
        armies: [
          _army('a1', regimentUnitIds: const ['r1', 'shared']),
          _army('a2', regimentUnitIds: const ['shared', 'r2']),
        ],
      );
      final next = applyArmyCombine(
        game: game,
        playerId: 'p1',
        armyIds: const ['a1', 'a2'],
      );
      expect(next.worldState.armies.single.regimentUnitIds, [
        'r1',
        'r2',
        'shared',
      ]);
    });
  });

  registerArmyCommandsSplitCases();
}
