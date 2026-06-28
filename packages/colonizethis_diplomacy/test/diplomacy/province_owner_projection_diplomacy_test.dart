import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Phase 6b (WorldState projection) coverage: the diplomacy full-world owner
/// scans now read from the shared [ProvinceOwnerCache] projection and remain
/// behaviour-preserving (SPEC/program/worldstate-projection.md; Refs #3393).
Province _prov(String regionId, String localId, String? owner) => Province(
  id: '$regionId|$localId',
  regionId: regionId,
  ownerId: owner,
);

Game _gameWithOwnership() => TestFixtures.minimalGame(
  players: const [
    Player(id: 'gp1', displayName: 'GP', isHuman: true, treasury: 100000),
  ],
  minorNations: const [
    MinorNation(id: 'mn1', displayName: 'Minor One'),
    MinorNation(id: 'mn2', displayName: 'Minor Two'),
  ],
  oldWorld: RegionData(
    provinces: [
      _prov('oldWorld', 'a', 'mn1'),
      _prov('oldWorld', 'b', 'gp1'),
      _prov('oldWorld', 'u', null),
    ],
  ),
  newWorld: RegionData(
    provinces: [
      _prov('newWorld', 'c', 'mn1'),
      _prov('newWorld', 'd', 'mn2'),
    ],
  ),
);

void main() {
  group('provinceCountOwnedBy (ProvinceOwnerCache-backed)', () {
    test(
      'positive: counts provinces across both worlds and matches the cache',
      () {
        final game = _gameWithOwnership();
        // mn1 owns oldWorld|a + newWorld|c => 2 (full-world, both regions).
        expect(provinceCountOwnedBy(game, 'mn1'), 2);
        expect(
          provinceCountOwnedBy(game, 'mn1'),
          ProvinceOwnerCache.of(game.worldState).countOwnedBy('mn1'),
        );
      },
    );

    test('negative: a faction owning no province counts zero', () {
      final game = _gameWithOwnership();
      expect(provinceCountOwnedBy(game, 'mn9'), 0);
      expect(
        provinceCountOwnedBy(game, 'mn9'),
        ProvinceOwnerCache.of(game.worldState).countOwnedBy('mn9'),
      );
    });

    test('negative: unowned provinces are excluded from every owner count', () {
      final game = _gameWithOwnership();
      final cache = ProvinceOwnerCache.of(game.worldState);
      // gp1 owns one province; the null-owner province does not inflate counts.
      expect(provinceCountOwnedBy(game, 'gp1'), 1);
      expect(provinceCountOwnedBy(game, 'gp1'), cache.countOwnedBy('gp1'));
      expect(cache.unownedProvinces.map((p) => p.id), ['oldWorld|u']);
    });
  });

  group('faction absorption full-world province transfer', () {
    test(
      'positive: absorbing a minor transfers its old- AND new-world provinces',
      () {
        final game = _gameWithOwnership();
        // Pre-condition: mn1 owns provinces in both regions.
        expect(
          ProvinceOwnerCache.of(
            game.worldState,
          ).provincesOwnedBy('mn1').map((p) => p.id).toList()..sort(),
          ['newWorld|c', 'oldWorld|a'],
        );

        final next = FactionAbsorptionEngine.absorbMinorOrTribeIntoGp(
          game,
          'gp1',
          'mn1',
          1,
        );

        // Both regions' mn1 provinces are now owned by gp1.
        final cacheAfter = ProvinceOwnerCache.of(next.worldState);
        expect(cacheAfter.countOwnedBy('mn1'), 0);
        expect(cacheAfter.ownerOf('oldWorld|a'), 'gp1');
        expect(cacheAfter.ownerOf('newWorld|c'), 'gp1');
      },
    );

    test(
      'negative: provinces owned by a different faction are not transferred',
      () {
        final game = _gameWithOwnership();
        final next = FactionAbsorptionEngine.absorbMinorOrTribeIntoGp(
          game,
          'gp1',
          'mn1',
          1,
        );
        final cacheAfter = ProvinceOwnerCache.of(next.worldState);
        // mn2's new-world province and the unowned province are untouched.
        expect(cacheAfter.ownerOf('newWorld|d'), 'mn2');
        expect(cacheAfter.ownerOf('oldWorld|u'), isNull);
      },
    );
  });
}
