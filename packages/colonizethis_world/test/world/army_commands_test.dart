import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/army_commands.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Exercises the pure army combine/split commands in
/// `lib/src/world/army_commands.dart`. SPEC/ui/military-units-army-management.md
/// and SPEC/game/military-armies.md.
Game _gameWithArmies(List<Army> armies, {int nextArmySeq = 1}) =>
    TestFixtures.minimalGame(
      id: 'g_army_cmd',
      players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      armies: armies,
      nextArmySeq: nextArmySeq,
    );

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
      final game = _gameWithArmies([_army('a1')]);
      final next = applyArmyCombine(
        game: game,
        playerId: 'p1',
        armyIds: const ['a1'],
      );
      expect(next, same(game));
    });

    test('returns same game when fewer than two owned armies match', () {
      final game = _gameWithArmies([
        _army('a1'),
        _army('a2', ownerId: 'p2'),
      ]);
      final next = applyArmyCombine(
        game: game,
        playerId: 'p1',
        armyIds: const ['a1', 'a2'],
      );
      expect(next, same(game));
    });

    test('returns same game when selected armies sit in different provinces', () {
      final game = _gameWithArmies([
        _army('a1', stationedProvinceId: 'oldWorld|p1'),
        _army('a2', stationedProvinceId: 'oldWorld|p2'),
      ]);
      final next = applyArmyCombine(
        game: game,
        playerId: 'p1',
        armyIds: const ['a1', 'a2'],
      );
      expect(next, same(game));
    });

    test('merges regiments into the home army when one is present', () {
      final game = _gameWithArmies([
        _army('a2', regimentUnitIds: const ['r2']),
        _army('home', regimentUnitIds: const ['r1'], isHomeArmy: true),
      ]);
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
      final game = _gameWithArmies([
        _army('b', regimentUnitIds: const ['r3', 'r1']),
        _army('a', regimentUnitIds: const ['r2']),
      ]);
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
      final game = _gameWithArmies([
        _army('a2', regimentUnitIds: const ['r2']),
        _army('a1', regimentUnitIds: const ['r1']),
        _army('z9', regimentUnitIds: const ['r9']),
      ]);
      final next = applyArmyCombine(
        game: game,
        playerId: 'p1',
        armyIds: const ['a1', 'a2'],
      );
      final ids = next.worldState.armies.map((a) => a.id).toList();
      expect(ids, ['a1', 'z9']);
    });

    test('de-duplicates regiment ids shared across combined armies', () {
      final game = _gameWithArmies([
        _army('a1', regimentUnitIds: const ['r1', 'shared']),
        _army('a2', regimentUnitIds: const ['shared', 'r2']),
      ]);
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

  group('applyArmySplit', () {
    test('returns same game when no units are selected to move', () {
      final game = _gameWithArmies([
        _army('a1', regimentUnitIds: const ['r1', 'r2']),
      ]);
      final next = applyArmySplit(
        game: game,
        playerId: 'p1',
        sourceArmyId: 'a1',
        unitIdsToMove: const [],
      );
      expect(next, same(game));
    });

    test('returns same game when the source army does not exist', () {
      final game = _gameWithArmies([
        _army('a1', regimentUnitIds: const ['r1', 'r2']),
      ]);
      final next = applyArmySplit(
        game: game,
        playerId: 'p1',
        sourceArmyId: 'missing',
        unitIdsToMove: const ['r1'],
      );
      expect(next, same(game));
    });

    test('returns same game when the source army has a different owner', () {
      final game = _gameWithArmies([
        _army('a1', ownerId: 'p2', regimentUnitIds: const ['r1', 'r2']),
      ]);
      final next = applyArmySplit(
        game: game,
        playerId: 'p1',
        sourceArmyId: 'a1',
        unitIdsToMove: const ['r1'],
      );
      expect(next, same(game));
    });

    test('returns same game when a moved unit is not in the source army', () {
      final game = _gameWithArmies([
        _army('a1', regimentUnitIds: const ['r1', 'r2']),
      ]);
      final next = applyArmySplit(
        game: game,
        playerId: 'p1',
        sourceArmyId: 'a1',
        unitIdsToMove: const ['r3'],
      );
      expect(next, same(game));
    });

    test('rejects splitting all regiments out of a non-home army', () {
      final game = _gameWithArmies([
        _army('a1', regimentUnitIds: const ['r1', 'r2']),
      ]);
      final next = applyArmySplit(
        game: game,
        playerId: 'p1',
        sourceArmyId: 'a1',
        unitIdsToMove: const ['r1', 'r2'],
      );
      expect(next, same(game));
    });

    test('splits selected regiments into a freshly minted army', () {
      final game = _gameWithArmies([
        _army('a1', regimentUnitIds: const ['r1', 'r2', 'r3']),
      ], nextArmySeq: 7);
      final next = applyArmySplit(
        game: game,
        playerId: 'p1',
        sourceArmyId: 'a1',
        unitIdsToMove: const ['r3', 'r2'],
      );

      expect(next.worldState.nextArmySeq, 8);
      final source = next.worldState.armies.firstWhere((a) => a.id == 'a1');
      expect(source.regimentUnitIds, ['r1']);

      final created = next.worldState.armies.firstWhere(
        (a) => a.id == 'army_7',
      );
      expect(created.ownerId, 'p1');
      expect(created.regionId, 'oldWorld');
      expect(created.stationedProvinceId, 'oldWorld|p1');
      expect(created.isHomeArmy, isFalse);
      // New army regiment ids are sorted.
      expect(created.regimentUnitIds, ['r2', 'r3']);
    });

    test('allows a home army to split all of its regiments', () {
      final game = _gameWithArmies([
        _army('home', regimentUnitIds: const ['r1', 'r2'], isHomeArmy: true),
      ], nextArmySeq: 3);
      final next = applyArmySplit(
        game: game,
        playerId: 'p1',
        sourceArmyId: 'home',
        unitIdsToMove: const ['r1', 'r2'],
      );

      final home = next.worldState.armies.firstWhere((a) => a.id == 'home');
      expect(home.regimentUnitIds, isEmpty);
      expect(home.isHomeArmy, isTrue);

      final created = next.worldState.armies.firstWhere(
        (a) => a.id == 'army_3',
      );
      expect(created.regimentUnitIds, ['r1', 'r2']);
      expect(created.isHomeArmy, isFalse);
    });
  });
}
