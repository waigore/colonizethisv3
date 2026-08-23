import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/army_commands.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';

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

void registerArmyCommandsSplitCases() {
  group('applyArmySplit', () {
    test('returns same game when no units are selected to move', () {
      final game = gameWithArmies(
        armies: [
          _army('a1', regimentUnitIds: const ['r1', 'r2']),
        ],
      );
      final next = applyArmySplit(
        game: game,
        playerId: 'p1',
        sourceArmyId: 'a1',
        unitIdsToMove: const [],
      );
      expect(next, same(game));
    });

    test('returns same game when the source army does not exist', () {
      final game = gameWithArmies(
        armies: [
          _army('a1', regimentUnitIds: const ['r1', 'r2']),
        ],
      );
      final next = applyArmySplit(
        game: game,
        playerId: 'p1',
        sourceArmyId: 'missing',
        unitIdsToMove: const ['r1'],
      );
      expect(next, same(game));
    });

    test('returns same game when the source army has a different owner', () {
      final game = gameWithArmies(
        armies: [
          _army('a1', ownerId: 'p2', regimentUnitIds: const ['r1', 'r2']),
        ],
      );
      final next = applyArmySplit(
        game: game,
        playerId: 'p1',
        sourceArmyId: 'a1',
        unitIdsToMove: const ['r1'],
      );
      expect(next, same(game));
    });

    test('returns same game when a moved unit is not in the source army', () {
      final game = gameWithArmies(
        armies: [
          _army('a1', regimentUnitIds: const ['r1', 'r2']),
        ],
      );
      final next = applyArmySplit(
        game: game,
        playerId: 'p1',
        sourceArmyId: 'a1',
        unitIdsToMove: const ['r3'],
      );
      expect(next, same(game));
    });

    test('rejects splitting all regiments out of a non-home army', () {
      final game = gameWithArmies(
        armies: [
          _army('a1', regimentUnitIds: const ['r1', 'r2']),
        ],
      );
      final next = applyArmySplit(
        game: game,
        playerId: 'p1',
        sourceArmyId: 'a1',
        unitIdsToMove: const ['r1', 'r2'],
      );
      expect(next, same(game));
    });

    test('splits selected regiments into a freshly minted army', () {
      final game = gameWithArmies(
        armies: [
          _army('a1', regimentUnitIds: const ['r1', 'r2', 'r3']),
        ],
        nextArmySeq: 7,
      );
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
      final game = gameWithArmies(
        armies: [
          _army('home', regimentUnitIds: const ['r1', 'r2'], isHomeArmy: true),
        ],
        nextArmySeq: 3,
      );
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
