// Refs #3393 Phase 6b (slice 9) — behaviour-preserving migration of the
// end-of-turn military-victory scan onto `ProvinceOwnerCache`
// (SPEC/program/worldstate-projection.md § Phase 6b slice 9). These tests
// assert `findMilitaryVictoryWinner` returns exactly the winner the prior
// `provincesForRegion(kRegionOldWorld)` owner-count scan produced.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/src/turn/end_of_turn_resolver.dart';
import 'package:colonizethis_test/test.dart';

/// Pre-migration `findMilitaryVictoryWinner`: a full old-world owner-count scan
/// filtered to Great Powers controlling 31+ Old World provinces.
String? _manualFindMilitaryVictoryWinner(Game game) {
  const int requiredProvinces = 31;
  final countsByOwner = <String, int>{};
  for (final province in game.worldState.provincesForRegion(kRegionOldWorld)) {
    final ownerId = province.ownerId;
    if (ownerId == null || ownerId.isEmpty) continue;
    countsByOwner.update(ownerId, (v) => v + 1, ifAbsent: () => 1);
  }
  final gpIds = game.players.map((p) => p.id).toSet();
  String? winnerId;
  for (final entry in countsByOwner.entries) {
    if (!gpIds.contains(entry.key)) continue;
    if (entry.value >= requiredProvinces) {
      if (winnerId == null || entry.key.compareTo(winnerId) < 0) {
        winnerId = entry.key;
      }
    }
  }
  return winnerId;
}

void main() {
  group('findMilitaryVictoryWinner ProvinceOwnerCache migration', () {
    Game gameWith({
      required List<Province> oldWorldProvinces,
      required List<Player> players,
      List<MinorNation> minorNations = const [],
    }) => Game(
      id: 'g-slice9',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: oldWorldProvinces),
        newWorld: const RegionData(provinces: []),
      ),
      players: players,
      minorNations: minorNations,
    );

    List<Province> ownedOldWorld(String ownerId, int count, {int from = 0}) => [
      for (var i = from; i < from + count; i++)
        Province(
          id: 'oldWorld|p$i',
          regionId: kRegionOldWorld,
          ownerId: ownerId,
        ),
    ];

    test('returns the GP owning exactly 31 Old World provinces', () {
      final game = gameWith(
        oldWorldProvinces: ownedOldWorld('gp1', 31),
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
      );

      expect(findMilitaryVictoryWinner(game), 'gp1');
      expect(
        findMilitaryVictoryWinner(game),
        _manualFindMilitaryVictoryWinner(game),
      );
    });

    test(
      'returns null when the leading GP owns only 30 Old World provinces',
      () {
        final game = gameWith(
          oldWorldProvinces: ownedOldWorld('gp1', 30),
          players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
        );

        expect(findMilitaryVictoryWinner(game), isNull);
        expect(
          findMilitaryVictoryWinner(game),
          _manualFindMilitaryVictoryWinner(game),
        );
      },
    );

    test(
      'returns null when 31+ Old World provinces are held by a non-GP minor',
      () {
        // minor1 owns 31 old-world provinces but is not a Great Power, so no
        // military victory is awarded — identical to the pre-migration scan.
        final game = gameWith(
          oldWorldProvinces: ownedOldWorld('minor1', 31),
          players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        );

        expect(findMilitaryVictoryWinner(game), isNull);
        expect(
          findMilitaryVictoryWinner(game),
          _manualFindMilitaryVictoryWinner(game),
        );
      },
    );

    test(
      'picks the lexicographically smallest GP id when several reach quota',
      () {
        final game = gameWith(
          oldWorldProvinces: [
            ...ownedOldWorld('gp2', 31),
            ...ownedOldWorld('gp1', 31, from: 31),
          ],
          players: const [
            Player(id: 'gp2', displayName: 'B', isHuman: false),
            Player(id: 'gp1', displayName: 'A', isHuman: false),
          ],
        );

        expect(findMilitaryVictoryWinner(game), 'gp1');
        expect(
          findMilitaryVictoryWinner(game),
          _manualFindMilitaryVictoryWinner(game),
        );
      },
    );
  });
}
